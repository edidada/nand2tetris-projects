from pathlib import Path
import re
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
                source = path.read_text()
                if path.parent.name == 'Square' and path.stem == 'SquareGame':
                    # Upstream added lowercase key handling but did not update
                    # the token reference XML. Match that fixture's version
                    # without changing any original input/reference file.
                    source, count = re.subn(r'^.*if \(key = (?:113|122|120)\).*\n', '', source, flags=re.M)
                    self.assertEqual(count, 3)
                tokens = tokenize(source)
                xml = '<tokens>\n'+'\n'.join(map(leaf, tokens))+'\n</tokens>\n'
                self.assertEqual(lines(xml), lines(path.with_name(path.stem+'T.xml').read_text()))
                self.assertEqual(lines(Analyzer(tokenize(path.read_text())).analyze()), lines(path.with_suffix('.xml').read_text()))

    def test_current_squaregame_includes_lowercase_branches(self):
        import xml.etree.ElementTree as ET
        path = ROOT/'Square/SquareGame.jack'
        tree = ET.fromstring(Analyzer(tokenize(path.read_text())).analyze())
        removed = []
        for statements in tree.iter('statements'):
            for node in list(statements):
                if node.tag != 'ifStatement':
                    continue
                condition = node.find('expression')
                if condition is None:
                    continue
                values = [n.text.strip() for n in condition.iter('integerConstant')]
                if values in (['113'], ['122'], ['120']):
                    self.assertEqual(condition.find('term/identifier').text.strip(), 'key')
                    removed.append(int(values[0]))
        self.assertEqual(sorted(removed), [113, 120, 122])
        expected = ET.parse(path.with_suffix('.xml')).getroot()
        def shape(node):
            return node.tag, (node.text or '').strip(), tuple(shape(child) for child in node)
        self.assertEqual(shape(tree), shape(expected))

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
