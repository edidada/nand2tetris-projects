#!/usr/bin/env bash
set -euo pipefail
root="$PWD"
project="04"
simulator="$root/.tools/simulator"
git clone https://github.com/nand2tetris/nand2tetris_simulator.git "$simulator"
git -C "$simulator" checkout 327b7e4337b31efb815e1c1e3913c0efd299bcf2
mkdir -p "$simulator/InstallDir/bin/classes"
find "$simulator" -name '*.java' -print > "$root/.tools/java-sources.txt"
javac -encoding UTF-8 -d "$simulator/InstallDir/bin/classes" @"$root/.tools/java-sources.txt"
while IFS= read -r -d '' directory; do
  python3 projects/11/jack_compiler.py "$directory"
done < <(find "$root/projects/11" -name '*.jack' -printf '%h\0' | sort -zu)
python3 scripts/prepare_compiler_integration.py
git fetch origin edidada/project12
for name in MathTest MemoryTest ArrayTest Integration; do
  directory="$root/.tools/regression/$name"
  mkdir -p "$directory"
  if [[ "$name" == Integration ]]; then source="$root/projects/11/Integration"; else source="$root/projects/12/$name"; fi
  cp "$source/"*.jack "$source/"*.tst "$source/"*.cmp "$directory/"
  for module in Array Keyboard Math Memory Output Screen String Sys; do
    git show "a967e8977f4479414aa077f1bbbf340157051018:projects/12/$module.jack" > "$directory/$module.jack"
  done
  python3 projects/11/jack_compiler.py "$directory"
  if ! (cd "$simulator/InstallDir" && timeout 180s java -Djava.awt.headless=true -cp bin/classes VMEmulatorMain "$directory/$name.tst") > "$directory/run.log" 2>&1; then
    cat "$directory/run.log"
    exit 1
  fi
  cat "$directory/run.log"
  grep -q 'Comparison ended successfully' "$directory/run.log"
  mkdir -p test-results/regression
  cp "$directory/run.log" "test-results/regression/$name.log"
  cp "$directory/$name.out" "test-results/regression/$name.out"
done
printf 'ORIGINAL_REGRESSIONS_OK comparisons=4 integration_assertions=13\n'