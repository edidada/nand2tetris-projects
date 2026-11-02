"""Full VM translation, extending Project 07's arithmetic/memory implementation."""
import argparse
from pathlib import Path
import re
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1]/'07'))
from vm_translator import Translator as BasicTranslator

SYMBOL = re.compile(r'[A-Za-z_.$:][A-Za-z_.$:0-9]*\Z')


class Translator(BasicTranslator):
    def __init__(self):
        super().__init__()
        self.function = ''

    def call(self, name, count):
        self.counter += 1
        label = f'__RETURN${self.counter}'
        self.emit('@'+label, 'D=A')
        self.push_d()
        for register in ('LCL', 'ARG', 'THIS', 'THAT'):
            self.emit('@'+register, 'D=M')
            self.push_d()
        self.emit('@SP', 'D=M', '@5', 'D=D-A', '@'+str(count), 'D=D-A',
                  '@ARG', 'M=D', '@SP', 'D=M', '@LCL', 'M=D',
                  '@'+name, '0;JMP', '('+label+')')

    def command(self, tokens, filename):
        operation = tokens[0]
        if operation in ('label', 'goto', 'if-goto'):
            if len(tokens) != 2 or not SYMBOL.fullmatch(tokens[1]):
                raise ValueError('Expected valid flow label')
            label = (self.function or filename) + '$' + tokens[1]
            if operation == 'label':
                self.emit('('+label+')')
            elif operation == 'goto':
                self.emit('@'+label, '0;JMP')
            else:
                self.pop_d()
                self.emit('@'+label, 'D;JNE')
        elif operation in ('function', 'call'):
            if (len(tokens) != 3 or not SYMBOL.fullmatch(tokens[1]) or
                    not tokens[2].isascii() or not tokens[2].isdecimal() or
                    not 0 <= int(tokens[2]) <= 32767):
                raise ValueError('Expected function name and nonnegative count')
            name, count = tokens[1], int(tokens[2])
            if operation == 'function':
                self.function = name
                self.emit('('+name+')')
                for _ in range(count):
                    self.emit('@0', 'D=A')
                    self.push_d()
            else:
                self.call(name, count)
        elif operation == 'return':
            if len(tokens) != 1:
                raise ValueError('return takes no operands')
            self.emit('@LCL', 'D=M', '@R13', 'M=D', '@5', 'A=D-A',
                      'D=M', '@R14', 'M=D')
            self.pop_d()
            self.emit('@ARG', 'A=M', 'M=D', '@ARG', 'D=M+1', '@SP', 'M=D')
            for register in ('THAT', 'THIS', 'ARG', 'LCL'):
                self.emit('@R13', 'AM=M-1', 'D=M', '@'+register, 'M=D')
            self.emit('@R14', 'A=M', '0;JMP')
        else:
            super().command(tokens, filename)

    def translate_files(self, files, bootstrap):
        if bootstrap:
            self.emit('@256', 'D=A', '@SP', 'M=D')
            self.call('Sys.init', 0)
            self.emit('@__HALT', '0;JMP')
        for path in files:
            self.function = ''
            if not SYMBOL.fullmatch(path.stem):
                raise ValueError('Invalid VM filename: '+path.stem)
            for number, line in enumerate(path.read_text().splitlines(), 1):
                tokens = line.split('//', 1)[0].split()
                if tokens:
                    try:
                        self.command(tokens, path.stem)
                    except ValueError as error:
                        raise ValueError(f'{path}:{number}: {error}') from error
        self.emit('(__HALT)', '@__HALT', '0;JMP')
        return '\n'.join(self.code)+'\n'


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('source', type=Path)
    parser.add_argument('--bootstrap', choices=('auto', 'on', 'off'), default='auto')
    args = parser.parse_args()
    source = args.source
    files = sorted(source.glob('*.vm')) if source.is_dir() else [source]
    if not files:
        raise ValueError('No VM files')
    has_init = any(re.search(r'^\s*function\s+Sys\.init\s+', p.read_text(), re.M) for p in files)
    bootstrap = args.bootstrap == 'on' or args.bootstrap == 'auto' and has_init
    assembly = Translator().translate_files(files, bootstrap)
    output = source/(source.name+'.asm') if source.is_dir() else source.with_suffix('.asm')
    output.write_text(assembly, encoding='ascii')


if __name__ == '__main__':
    main()
