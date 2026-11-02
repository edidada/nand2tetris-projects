"""Jack tokenizer and recursive descent XML syntax analyzer."""
import argparse
from html import escape
from pathlib import Path
import re

KEYWORDS = set('class constructor function method field static var int char boolean void true false null this let do if else while return'.split())
SYMBOLS = set('{}()[].,;+-*/&|<>=~')


def tokenize(source):
    tokens, index = [], 0
    while index < len(source):
        char = source[index]
        if char.isspace():
            index += 1
        elif source.startswith('//', index):
            end = source.find('\n', index)
            index = len(source) if end == -1 else end + 1
        elif source.startswith('/*', index):
            end = source.find('*/', index + 2)
            if end == -1:
                raise ValueError('Unterminated block comment')
            index = end + 2
        elif char == '"':
            end = source.find('"', index + 1)
            if end == -1 or '\n' in source[index+1:end] or '\r' in source[index+1:end]:
                raise ValueError('Unterminated string constant')
            tokens.append(('stringConstant', source[index+1:end]))
            index = end + 1
        elif char in SYMBOLS:
            tokens.append(('symbol', char))
            index += 1
        elif char in '0123456789':
            match = re.match(r'[0-9]+', source[index:])[0]
            if int(match) > 32767:
                raise ValueError('Integer exceeds 32767')
            tokens.append(('integerConstant', match))
            index += len(match)
        else:
            match = re.match(r'[A-Za-z_][A-Za-z_0-9]*', source[index:])
            if not match:
                raise ValueError(f'Illegal character at offset {index}: {char!r}')
            value = match[0]
            tokens.append(('keyword' if value in KEYWORDS else 'identifier', value))
            index += len(value)
    return tokens


def leaf(token):
    kind, value = token
    return f'<{kind}> {escape(value, quote=False)} </{kind}>'


class Analyzer:
    def __init__(self, tokens):
        self.tokens, self.position, self.output = tokens, 0, []

    def peek(self):
        return self.tokens[self.position][1] if self.position < len(self.tokens) else None

    def take(self, value=None, kind=None):
        if self.position >= len(self.tokens):
            raise ValueError('Unexpected EOF')
        token = self.tokens[self.position]
        if value is not None and token[1] != value or kind is not None and token[0] != kind:
            raise ValueError(f'Token {self.position}: expected {value or kind}, got {token}')
        self.output.append(leaf(token))
        self.position += 1

    def group(self, name, body):
        self.output.append('<'+name+'>')
        body()
        self.output.append('</'+name+'>')

    def type(self, allow_void=False):
        if self.peek() in ('int', 'char', 'boolean') or allow_void and self.peek() == 'void':
            self.take()
        else:
            self.take(kind='identifier')

    def variable(self, declaration):
        self.take()
        self.type()
        self.take(kind='identifier')
        while self.peek() == ',':
            self.take(',')
            self.take(kind='identifier')
        self.take(';')

    def parameters(self):
        if self.peek() != ')':
            self.type()
            self.take(kind='identifier')
            while self.peek() == ',':
                self.take(',')
                self.type()
                self.take(kind='identifier')

    def subroutine_body(self):
        self.take('{')
        while self.peek() == 'var':
            self.group('varDec', lambda: self.variable('var'))
        self.group('statements', self.statements)
        self.take('}')

    def subroutine(self):
        self.take()
        self.type(allow_void=True)
        self.take(kind='identifier')
        self.take('(')
        self.group('parameterList', self.parameters)
        self.take(')')
        self.group('subroutineBody', self.subroutine_body)

    def class_body(self):
        self.take('class')
        self.take(kind='identifier')
        self.take('{')
        while self.peek() in ('static', 'field'):
            self.group('classVarDec', lambda: self.variable('class'))
        while self.peek() in ('constructor', 'function', 'method'):
            self.group('subroutineDec', self.subroutine)
        self.take('}')

    def statements(self):
        methods = {'let': self.let, 'if': self.if_statement, 'while': self.while_statement,
                   'do': self.do, 'return': self.return_statement}
        while self.peek() in methods:
            name = self.peek()
            self.group(name+'Statement', methods[name])

    def let(self):
        self.take('let')
        self.take(kind='identifier')
        if self.peek() == '[':
            self.take('[')
            self.group('expression', self.expression)
            self.take(']')
        self.take('=')
        self.group('expression', self.expression)
        self.take(';')

    def block(self):
        self.take('{')
        self.group('statements', self.statements)
        self.take('}')

    def condition(self):
        self.take('(')
        self.group('expression', self.expression)
        self.take(')')
        self.block()

    def if_statement(self):
        self.take('if')
        self.condition()
        if self.peek() == 'else':
            self.take('else')
            self.block()

    def while_statement(self):
        self.take('while')
        self.condition()

    def do(self):
        self.take('do')
        self.call()
        self.take(';')

    def return_statement(self):
        self.take('return')
        if self.peek() != ';':
            self.group('expression', self.expression)
        self.take(';')

    def call(self):
        self.take(kind='identifier')
        if self.peek() == '.':
            self.take('.')
            self.take(kind='identifier')
        self.take('(')
        self.group('expressionList', self.expression_list)
        self.take(')')

    def expression_list(self):
        if self.peek() != ')':
            self.group('expression', self.expression)
            while self.peek() == ',':
                self.take(',')
                self.group('expression', self.expression)

    def expression(self):
        self.group('term', self.term)
        while self.peek() in ('+', '-', '*', '/', '&', '|', '<', '>', '='):
            self.take()
            self.group('term', self.term)

    def term(self):
        value = self.peek()
        if value in ('-', '~'):
            self.take()
            self.group('term', self.term)
        elif value == '(':
            self.take('(')
            self.group('expression', self.expression)
            self.take(')')
        elif self.position < len(self.tokens):
            kind = self.tokens[self.position][0]
            if kind in ('integerConstant', 'stringConstant') or value in ('true', 'false', 'null', 'this'):
                self.take()
            elif kind == 'identifier':
                following = self.tokens[self.position+1][1] if self.position+1 < len(self.tokens) else None
                if following in ('(', '.'):
                    self.call()
                else:
                    self.take(kind='identifier')
                    if self.peek() == '[':
                        self.take('[')
                        self.group('expression', self.expression)
                        self.take(']')
            else:
                raise ValueError('Invalid term: '+str(value))
        else:
            raise ValueError('Expected term at EOF')

    def analyze(self):
        self.group('class', self.class_body)
        if self.position != len(self.tokens):
            raise ValueError('Trailing tokens after class')
        return '\n'.join(self.output)+'\n'


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('source', type=Path)
    args = parser.parse_args()
    files = sorted(args.source.glob('*.jack')) if args.source.is_dir() else [args.source]
    for path in files:
        tokens = tokenize(path.read_text())
        syntax = Analyzer(tokens).analyze()
        path.with_suffix('.generatedT.xml').write_text('<tokens>\n'+'\n'.join(map(leaf, tokens))+'\n</tokens>\n')
        path.with_suffix('.generated.xml').write_text(syntax)


if __name__ == '__main__':
    main()
