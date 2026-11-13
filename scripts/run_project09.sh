#!/usr/bin/env bash
set -euo pipefail
root="$PWD"
mkdir -p .tools/compiler/{10,11} .tools/State .tools/Sokoban test-results
exec > >(tee test-results/verification.log) 2>&1
printf 'commit=%s\n' "$(git rev-parse HEAD)"
git fetch origin edidada/project11
git show 8c7bdcac1ddcb96ade280375e6f4221ace25eb3e:projects/10/jack_analyzer.py > .tools/compiler/10/jack_analyzer.py
git show 8c7bdcac1ddcb96ade280375e6f4221ace25eb3e:projects/11/jack_compiler.py > .tools/compiler/11/jack_compiler.py
git clone https://github.com/nand2tetris/nand2tetris_simulator.git .tools/simulator
git -C .tools/simulator checkout 327b7e4337b31efb815e1c1e3913c0efd299bcf2
mkdir -p .tools/simulator/InstallDir/bin/classes
find .tools/simulator -name '*.java' -print > .tools/java-sources.txt
javac -encoding UTF-8 -d .tools/simulator/InstallDir/bin/classes @.tools/java-sources.txt
cp projects/09/Sokoban/*.jack .tools/Sokoban/
cp projects/09/Sokoban/Board.jack tests/project09/Main.jack .tools/State/
python3 .tools/compiler/11/jack_compiler.py .tools/Sokoban
python3 .tools/compiler/11/jack_compiler.py .tools/State
# Execute the complete, independently verified Jack OS with its Sys.init.
git fetch origin edidada/project12
for module in Array Keyboard Math Memory Output Screen String Sys; do
    git show "a967e8977f4479414aa077f1bbbf340157051018:projects/12/$module.jack" > ".tools/Sokoban/$module.jack"
    cp ".tools/Sokoban/$module.jack" .tools/State/
done
python3 .tools/compiler/11/jack_compiler.py .tools/Sokoban
python3 .tools/compiler/11/jack_compiler.py .tools/State
python3 - <<'PY'
from pathlib import Path
lines=['load,','output-file state.out,','repeat 5000000 { vmstep; }']
for a in range(8000,8019):
    lines += [f'output-list RAM[{a}]%D1.6.1;', 'output;']
Path('.tools/State/state.tst').write_text('\n'.join(lines)+'\n')
PY
(cd .tools/simulator/InstallDir && timeout 120 java -Djava.awt.headless=true -cp bin/classes VMEmulatorMain "$root/.tools/State/state.tst")
cp .tools/State/state.out test-results/
python3 - <<'PY'
from pathlib import Path
import re,json
values=[int(s.strip('| ')) for s in Path('test-results/state.out').read_text().splitlines() if re.fullmatch(r'\|\s*-?\d+\s*\|',s)]
expected=[18,0,0,17,1,-1,35,5,2,-1,0,21,-1,3,18,0,0,-1,12345]
assert values==expected,(values,expected)
Path('test-results/state-results.json').write_text(json.dumps({'actual':values,'expected':expected,'passed':len(values)},indent=2))
print('STATE_ASSERTIONS_OK count=19')
PY
bash scripts/verify_project09_gui.sh
