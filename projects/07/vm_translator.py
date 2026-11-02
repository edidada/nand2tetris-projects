"""Hack VM stack arithmetic and memory access translator (Project 07)."""
import argparse
from pathlib import Path

BASE = {'local': 'LCL', 'argument': 'ARG', 'this': 'THIS', 'that': 'THAT'}


class Translator:
    def __init__(self):
        self.code = []
        self.counter = 0

    def emit(self, *instructions):
        self.code.extend(instructions)

    def push_d(self):
        self.emit('@SP', 'A=M', 'M=D', '@SP', 'M=M+1')

    def pop_d(self):
        self.emit('@SP', 'AM=M-1', 'D=M')

    def comparison(self, command):
        self.counter += 1
        prefix = f'__CMP{self.counter}'
        true, false, end, negative, same = [prefix + s for s in ('$T', '$F', '$END', '$NEG', '$SAME')]
        self.pop_d()
        self.emit('@R13', 'M=D', '@SP', 'A=M-1', 'D=M')
        if command != 'eq':
            # Comparing by subtraction alone overflows when signs differ.
            self.emit('@'+negative, 'D;JLT', '@R13', 'D=M',
                      '@'+(true if command == 'gt' else false), 'D;JLT',
                      '@'+same, '0;JMP', '('+negative+')', '@R13', 'D=M',
                      '@'+(true if command == 'lt' else false), 'D;JGE', '('+same+')')
        self.emit('@SP', 'A=M-1', 'D=M', '@R13', 'D=D-M',
                  '@'+true, 'D;'+{'eq': 'JEQ', 'gt': 'JGT', 'lt': 'JLT'}[command],
                  '('+false+')', '@SP', 'A=M-1', 'M=0', '@'+end, '0;JMP',
                  '('+true+')', '@SP', 'A=M-1', 'M=-1', '('+end+')')

    def command(self, tokens, filename):
        operation = tokens[0]
        if len(tokens) == 1:
            if operation in ('add', 'sub', 'and', 'or'):
                self.pop_d()
                self.emit('@SP', 'A=M-1', {'add': 'M=D+M', 'sub': 'M=M-D',
                                          'and': 'M=D&M', 'or': 'M=D|M'}[operation])
            elif operation in ('neg', 'not'):
                self.emit('@SP', 'A=M-1', 'M=-M' if operation == 'neg' else 'M=!M')
            elif operation in ('eq', 'gt', 'lt'):
                self.comparison(operation)
            else:
                raise ValueError('Unknown arithmetic command: ' + operation)
            return
        if len(tokens) != 3 or operation not in ('push', 'pop'):
            raise ValueError('Expected push/pop segment index')
        segment, text = tokens[1:]
        if not text.isascii() or not text.isdecimal() or not 0 <= int(text) <= 32767:
            raise ValueError('Index must be a nonnegative 15-bit integer')
        index = int(text)
        if segment in BASE:
            self.emit('@'+str(index), 'D=A', '@'+BASE[segment], 'D=D+M')
        elif segment == 'constant' and operation == 'push':
            self.emit('@'+str(index), 'D=A')
            self.push_d()
            return
        elif segment in ('temp', 'pointer', 'static'):
            limit = {'temp': 7, 'pointer': 1, 'static': 239}[segment]
            if index > limit:
                raise ValueError('Segment index exceeds limit')
            address = (filename+'.'+str(index) if segment == 'static'
                       else str(index + (5 if segment == 'temp' else 3)))
            self.emit('@'+address, 'D=A')
        else:
            raise ValueError('Unknown or unwritable segment: ' + segment)
        if operation == 'push':
            self.emit('A=D', 'D=M')
            self.push_d()
        else:
            self.emit('@R13', 'M=D')
            self.pop_d()
            self.emit('@R13', 'A=M', 'M=D')

    def translate(self, source, filename):
        for number, raw in enumerate(source.splitlines(), 1):
            tokens = raw.split('//', 1)[0].split()
            if tokens:
                try:
                    self.command(tokens, filename)
                except ValueError as error:
                    raise ValueError(f'{filename}:{number}: {error}') from error
        self.emit('(__HALT)', '@__HALT', '0;JMP')
        return '\n'.join(self.code)+'\n'


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('source', type=Path)
    args = parser.parse_args()
    assembly = Translator().translate(args.source.read_text(), args.source.stem)
    args.source.with_suffix('.asm').write_text(assembly, encoding='ascii')


if __name__ == '__main__':
    main()
