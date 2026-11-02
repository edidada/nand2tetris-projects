"""Compile Jack syntax trees to VM code, using Project 10's parser."""
import argparse
from pathlib import Path
import sys
import xml.etree.ElementTree as ET

sys.path.insert(0, str(Path(__file__).resolve().parents[1]/'10'))
from jack_analyzer import Analyzer, tokenize


def text(node):
    # Parser adds exactly one formatting space to each leaf. Preserve any
    # additional leading/trailing spaces belonging to a string constant.
    return node.text[1:-1] if node.tag == 'stringConstant' else node.text.strip()


class Compiler:
    def __init__(self):
        self.code, self.class_symbols, self.symbols = [], {}, {}
        self.counts = dict(static=0, field=0, argument=0, local=0)
        self.labels = 0

    def emit(self, command):
        self.code.append(command)

    def define(self, name, type_name, kind):
        table = self.class_symbols if kind in ('field', 'static') else self.symbols
        if name in table:
            raise ValueError('Duplicate variable: '+name)
        table[name] = (type_name, 'this' if kind == 'field' else kind, self.counts[kind])
        self.counts[kind] += 1

    def lookup(self, name):
        value = self.symbols.get(name, self.class_symbols.get(name))
        if value is None:
            raise ValueError('Undefined variable: '+name)
        return value

    def variable(self, name, command='push'):
        _, segment, index = self.lookup(name)
        self.emit(f'{command} {segment} {index}')

    def declaration(self, node, kind):
        children = list(node)
        type_name = text(children[1])
        for child in children[2:]:
            if child.tag == 'identifier':
                self.define(text(child), type_name, kind)

    def compile(self, source):
        tree = ET.fromstring(Analyzer(tokenize(source)).analyze())
        self.class_name = text(tree[1])
        for node in tree.findall('classVarDec'):
            self.declaration(node, text(node[0]))
        for node in tree.findall('subroutineDec'):
            self.subroutine(node)
        return '\n'.join(self.code)+'\n'

    def subroutine(self, node):
        self.symbols = {}
        self.counts['argument'] = self.counts['local'] = 0
        kind, name = text(node[0]), text(node[2])
        if kind == 'method':
            self.define('this', self.class_name, 'argument')
        params = list(node.find('parameterList'))
        for index in range(0, len(params), 3):
            self.define(text(params[index+1]), text(params[index]), 'argument')
        body = node.find('subroutineBody')
        for declaration in body.findall('varDec'):
            self.declaration(declaration, 'local')
        self.emit(f'function {self.class_name}.{name} {self.counts["local"]}')
        if kind == 'constructor':
            self.emit(f'push constant {self.counts["field"]}')
            self.emit('call Memory.alloc 1')
            self.emit('pop pointer 0')
        elif kind == 'method':
            self.emit('push argument 0')
            self.emit('pop pointer 0')
        self.statements(body.find('statements'))

    def statements(self, node):
        for statement in node:
            getattr(self, statement.tag)(statement)

    def letStatement(self, node):
        name = text(node[1])
        array = text(node[2]) == '['
        expressions = node.findall('expression')
        if array:
            self.variable(name)
            self.expression(expressions[0])
            self.emit('add')
        self.expression(expressions[-1])
        if array:
            self.emit('pop temp 0')
            self.emit('pop pointer 1')
            self.emit('push temp 0')
            self.emit('pop that 0')
        else:
            self.variable(name, 'pop')

    def new_label(self):
        self.labels += 1
        return f'L{self.labels}'

    def ifStatement(self, node):
        yes, no, end = self.new_label(), self.new_label(), self.new_label()
        self.expression(node.find('expression'))
        self.emit('if-goto '+yes)
        self.emit('goto '+no)
        self.emit('label '+yes)
        blocks = node.findall('statements')
        self.statements(blocks[0])
        self.emit('goto '+end)
        self.emit('label '+no)
        if len(blocks) == 2:
            self.statements(blocks[1])
        self.emit('label '+end)

    def whileStatement(self, node):
        test, body, end = self.new_label(), self.new_label(), self.new_label()
        self.emit('label '+test)
        self.expression(node.find('expression'))
        self.emit('if-goto '+body)
        self.emit('goto '+end)
        self.emit('label '+body)
        self.statements(node.find('statements'))
        self.emit('goto '+test)
        self.emit('label '+end)

    def doStatement(self, node):
        self.call(list(node)[1:-1])
        self.emit('pop temp 0')

    def returnStatement(self, node):
        expression = node.find('expression')
        if expression is None:
            self.emit('push constant 0')
        else:
            self.expression(expression)
        self.emit('return')

    def expression(self, node):
        self.term(node[0])
        operations = {'+': 'add', '-': 'sub', '&': 'and', '|': 'or',
                      '<': 'lt', '>': 'gt', '=': 'eq',
                      '*': 'call Math.multiply 2', '/': 'call Math.divide 2'}
        for index in range(1, len(node), 2):
            self.term(node[index+1])
            self.emit(operations[text(node[index])])

    def term(self, node):
        first = node[0]
        value = text(first)
        if first.tag == 'integerConstant':
            self.emit('push constant '+value)
        elif first.tag == 'stringConstant':
            self.emit(f'push constant {len(value)}')
            self.emit('call String.new 1')
            for char in value:
                if ord(char) > 32767:
                    raise ValueError('String character exceeds Jack integer range')
                self.emit(f'push constant {ord(char)}')
                self.emit('call String.appendChar 2')
        elif first.tag == 'keyword':
            self.emit('push pointer 0' if value == 'this' else 'push constant 0')
            if value == 'true':
                self.emit('not')
        elif value in ('-', '~'):
            self.term(node[1])
            self.emit('neg' if value == '-' else 'not')
        elif value == '(':
            self.expression(node[1])
        elif len(node) > 1 and text(node[1]) in ('.', '('):
            self.call(list(node))
        elif len(node) > 1 and text(node[1]) == '[':
            self.variable(value)
            self.expression(node.find('expression'))
            self.emit('add')
            self.emit('pop pointer 1')
            self.emit('push that 0')
        else:
            self.variable(value)

    def call(self, nodes):
        name, arguments = text(nodes[0]), 0
        if text(nodes[1]) == '.':
            if name in self.symbols or name in self.class_symbols:
                type_name, _, _ = self.lookup(name)
                self.variable(name)
                name = type_name
                arguments = 1
            name += '.'+text(nodes[2])
        else:
            self.emit('push pointer 0')
            arguments = 1
            name = self.class_name+'.'+name
        expressions = next(n for n in nodes if n.tag == 'expressionList')
        for expression in expressions.findall('expression'):
            self.expression(expression)
            arguments += 1
        self.emit(f'call {name} {arguments}')


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('source', type=Path)
    args = parser.parse_args()
    files = sorted(args.source.glob('*.jack')) if args.source.is_dir() else [args.source]
    for path in files:
        code = Compiler().compile(path.read_text())
        path.with_suffix('.vm').write_text(code, encoding='ascii')


if __name__ == '__main__':
    main()
