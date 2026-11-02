"""Two-pass Hack assembler; standard library only."""
import argparse
from pathlib import Path
import re

COMP = dict(zip(
    ('0', '1', '-1', 'D', 'A', '!D', '!A', '-D', '-A', 'D+1', 'A+1',
     'D-1', 'A-1', 'D+A', 'D-A', 'A-D', 'D&A', 'D|A',
     'M', '!M', '-M', 'M+1', 'M-1', 'D+M', 'D-M', 'M-D', 'D&M', 'D|M'),
    ('0101010', '0111111', '0111010', '0001100', '0110000', '0001101',
     '0110001', '0001111', '0110011', '0011111', '0110111', '0001110',
     '0110010', '0000010', '0010011', '0000111', '0000000', '0010101',
     '1110000', '1110001', '1110011', '1110111', '1110010', '1000010',
     '1010011', '1000111', '1000000', '1010101')))
JUMP = {s: i for i, s in enumerate(('', 'JGT', 'JEQ', 'JGE', 'JLT', 'JNE', 'JLE', 'JMP'))}
SYMBOL = re.compile(r'[A-Za-z_.$:][A-Za-z_.$:0-9]*\Z')


def assemble(source):
    symbols = {f'R{i}': i for i in range(16)}
    symbols.update(SP=0, LCL=1, ARG=2, THIS=3, THAT=4, SCREEN=16384, KBD=24576)
    instructions = []
    for number, raw in enumerate(source.splitlines(), 1):
        line = ''.join(raw.split('//', 1)[0].split())
        if not line:
            continue
        if line.startswith('('):
            if not line.endswith(')') or not SYMBOL.fullmatch(line[1:-1]):
                raise ValueError(f'Line {number}: invalid label')
            label = line[1:-1]
            if label in symbols or len(instructions) > 32767:
                raise ValueError(f'Line {number}: duplicate/reserved label or ROM overflow')
            symbols[label] = len(instructions)
        else:
            instructions.append((number, line))
    if len(instructions) > 32768:
        raise ValueError('Program exceeds 32K ROM')
    words, next_variable = [], 16
    for number, line in instructions:
        try:
            if line.startswith('@'):
                value = line[1:]
                if re.fullmatch('[0-9]+', value):
                    address = int(value)
                elif SYMBOL.fullmatch(value):
                    if value not in symbols:
                        if next_variable >= 16384:
                            raise ValueError('Variable space exhausted')
                        symbols[value] = next_variable
                        next_variable += 1
                    address = symbols[value]
                else:
                    raise ValueError('Invalid A operand')
                if not 0 <= address <= 32767:
                    raise ValueError('A operand outside 15 bits')
                word = address
            else:
                if line.count('=') > 1 or line.count(';') > 1:
                    raise ValueError('Malformed C instruction')
                destination, expression = line.split('=') if '=' in line else ('', line)
                computation, jump = expression.split(';') if ';' in expression else (expression, '')
                if '=' in line and not destination or ';' in line and not jump:
                    raise ValueError('Empty destination or jump')
                if len(set(destination)) != len(destination) or any(c not in 'ADM' for c in destination):
                    raise ValueError('Invalid destination')
                dest = sum({'A': 4, 'D': 2, 'M': 1}[c] for c in destination)
                word = 0b1110000000000000 | int(COMP[computation], 2) << 6 | dest << 3 | JUMP[jump]
            words.append(f'{word:016b}')
        except (KeyError, ValueError) as error:
            raise ValueError(f'Line {number}: {line}: {error}') from error
    return '\n'.join(words) + ('\n' if words else '')


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('source', type=Path)
    parser.add_argument('-o', '--output', type=Path)
    args = parser.parse_args()
    output = args.output or args.source.with_suffix('.hack')
    # Validate the whole program before opening the output.
    binary = assemble(args.source.read_text(encoding='utf-8-sig'))
    output.write_text(binary, encoding='ascii')


if __name__ == '__main__':
    main()
