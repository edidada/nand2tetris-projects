from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from assembler import assemble, COMP

ROOT = Path(__file__).resolve().parent


class AssemblerTests(unittest.TestCase):
    def test_original_machine_code(self):
        for name in ('Add', 'Max', 'Rect'):
            with self.subTest(name=name):
                actual = assemble((ROOT / name.lower() / (name + '.asm')).read_text())
                expected = (ROOT.parent / '05' / (name + '.hack')).read_text()
                self.assertEqual(actual.splitlines(), expected.splitlines())

    def test_original_symbolic_and_numeric_pairs(self):
        for name in ('Max', 'Rect', 'Pong'):
            with self.subTest(name=name):
                folder = ROOT / name.lower()
                self.assertEqual(assemble((folder / (name + '.asm')).read_text()),
                                 assemble((folder / (name + 'L.asm')).read_text()))

    def test_symbols_comments_and_forward_labels(self):
        result = assemble('// comment\n @x // first variable\nM=1\n@END\n0;JMP\n(END)\n@x\nD=M')
        self.assertEqual(result.splitlines()[0], '0000000000010000')
        self.assertEqual(result.splitlines()[2], '0000000000000100')
        self.assertEqual(result.splitlines()[4], '0000000000010000')
        self.assertEqual(assemble('@R15\n@SCREEN\n@KBD').splitlines(),
                         [f'{i:016b}' for i in (15, 16384, 24576)])

    def test_all_destinations_and_jumps(self):
        for dest, bits in (('', 0), ('M', 1), ('D', 2), ('MD', 3),
                           ('A', 4), ('AM', 5), ('AD', 6), ('AMD', 7)):
            for jump, jbits in (('', 0), ('JGT', 1), ('JEQ', 2), ('JGE', 3),
                                ('JLT', 4), ('JNE', 5), ('JLE', 6), ('JMP', 7)):
                prefix = dest + '=' if dest else ''
                suffix = ';' + jump if jump else ''
                for comp in COMP:
                    value = int(assemble(prefix + comp + suffix), 2)
                    self.assertEqual((value >> 3) & 7, bits)
                    self.assertEqual(value & 7, jbits)
                    self.assertEqual(value >> 13, 7)

    def test_invalid_programs(self):
        for source in ('@32768', '@-1', '@', '(X)\n(X)', '(R0)',
                       'D=Q', 'D;JUNK', 'DD=0', '=0', 'D=0;',
                       '(bad-label)', '@bad-label', 'D==A', 'D=A;;JMP'):
            with self.subTest(source=source), self.assertRaises(ValueError):
                assemble(source)
        with self.assertRaises(ValueError):
            assemble('@0\n' * 32769)

    def test_cli_does_not_overwrite_on_invalid_input(self):
        with tempfile.TemporaryDirectory() as directory:
            source, output = Path(directory)/'a.asm', Path(directory)/'a.hack'
            source.write_text('@40000')
            output.write_text('keep')
            result = subprocess.run([sys.executable, str(ROOT/'assembler.py'), str(source)],
                                    capture_output=True)
            self.assertNotEqual(result.returncode, 0)
            self.assertEqual(output.read_text(), 'keep')
