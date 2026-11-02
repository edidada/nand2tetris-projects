from pathlib import Path
import unittest
from jack_analyzer import Analyzer, leaf, tokenize

ROOT = Path(__file__).resolve().parent


def lines(text):
    return [line.strip() for line in text.splitlines() if line.strip()]


class AnalyzerTests(unittest.TestCase):
    def test_all_original_xml_fixtures(self):
        files = sorted(ROOT.glob('*/*.jack'))
        self.assertEqual(len(files), 7)
        for path in files:
            with self.subTest(path=str(path)):
                tokens = tokenize(path.read_text())
                xml = '<tokens>\n'+'\n'.join(map(leaf, tokens))+'\n</tokens>\n'
                self.assertEqual(lines(xml), lines(path.with_name(path.stem+'T.xml').read_text()))
                self.assertEqual(lines(Analyzer(tokens).analyze()), lines(path.with_suffix('.xml').read_text()))

    def test_comments_inside_strings_and_xml_escaping(self):
        source = '/* doc */ class X { function void f() { do O.p("// /* <&> */"); return; } }'
        tokens = tokenize(source)
        self.assertIn(('stringConstant', '// /* <&> */'), tokens)
        self.assertIn('&lt;&amp;&gt;', Analyzer(tokens).analyze())
        self.assertEqual(tokenize('// end'), [])

    def test_reject_invalid_input(self):
        for source in ('/* never ends', '"new\nline"', '@', '32768'):
            with self.subTest(source=source), self.assertRaises(ValueError):
                tokenize(source)
        for source in ('class X {', 'class X {} class Y {}',
                       'class X { function void f() { let x = ; } }'):
            with self.subTest(source=source), self.assertRaises(ValueError):
                Analyzer(tokenize(source)).analyze()
