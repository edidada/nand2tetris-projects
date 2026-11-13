"""Expected runtime RAM values, independent of the compiler's VM output."""
from pathlib import Path
root = Path('projects/11/Integration')
expected = [8, 10, 2, 99, 8, 720, 30, 60, 6, 32, 32, 38, 111]
columns = [f'RAM[{8100+i}]' for i in range(len(expected))]
test = ['load,', 'output-file Integration.out,', 'compare-to Integration.cmp,',
        'output-list '+' '.join(c+'%D1.6.1' for c in columns)+';',
        'repeat 1000000 { vmstep; }', 'output;']
(root/'Integration.tst').write_text('\n'.join(test)+'\n')
(root/'Integration.cmp').write_text('|'+ '|'.join(c[:8] for c in columns)+'|\n|'+
                                  '|'.join(f' {v:6} ' for v in expected)+'|\n')
