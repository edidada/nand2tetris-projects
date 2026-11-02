"""Preserve originals; explicitly adapt the two human-keyboard stimuli for CI."""
from pathlib import Path
import re
root = Path('projects/05')
source = (root / 'Memory.tst').read_text()
source, count = re.subn(r'while out <> (?:75|89) \{.*?\}', 'eval;', source, flags=re.S)
assert count == 2
source = source.replace('Memory.out', 'Memory-headless.out').replace('Memory.cmp', 'Memory-headless.cmp')
(root / 'Memory-headless.tst').write_text(source)
expected = (root / 'Memory.cmp').read_text()
assert expected.count('|     75 |') == 1 and expected.count('|     89 |') == 1
expected = expected.replace('|     75 |', '|      0 |').replace('|     89 |', '|      0 |')
(root / 'Memory-headless.cmp').write_text(expected)
print('Memory: retained all RAM/screen comparisons; keyboard stimulus is explicitly unpressed (0), not K/Y.')
