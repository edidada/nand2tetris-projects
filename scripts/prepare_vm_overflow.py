"""Generate CPU-level signed-overflow tests with an independent Python oracle."""
from pathlib import Path

root = Path('projects/07/Overflow')
root.mkdir(exist_ok=True)
pairs = [(32767, -1), (-32768, 1), (-32768, 32767),
         (0, -32768), (-32768, -32768), (-1, 32767)]
program, expected = [], []


def push(value):
    if value == -32768:
        return ['push constant 32767', 'push constant 1', 'add']
    return ['push constant '+str(abs(value))] + (['neg'] if value < 0 else [])


for command in ('eq', 'gt', 'lt'):
    for x, y in pairs:
        program += push(x) + push(y) + [command]
        result = {'eq': x == y, 'gt': x > y, 'lt': x < y}[command]
        expected.append(-1 if result else 0)
(root/'Overflow.vm').write_text('\n'.join(program)+'\n')
columns = [f'RAM[{256+i}]' for i in range(len(expected))]
test = ['load Overflow.asm,', 'output-file Overflow.out,', 'compare-to Overflow.cmp,',
        'output-list '+' '.join(c+'%D1.6.1' for c in columns)+';',
        'set RAM[0] 256,', 'repeat 10000 { ticktock; }', 'output;']
(root/'Overflow.tst').write_text('\n'.join(test)+'\n')
(root/'Overflow.cmp').write_text('|'+ '|'.join(columns)+'|\n|'+
                                '|'.join(f' {v:6} ' for v in expected)+'|\n')
