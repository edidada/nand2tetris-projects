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
for directory in MathTest MemoryTest ArrayTest; do
  python3 projects/11/jack_compiler.py "$root/projects/12/$directory/Main.jack"
done
for test in "$root/projects/12/MathTest/MathTest.tst" "$root/projects/12/MemoryTest/MemoryTest.tst" "$root/projects/12/ArrayTest/ArrayTest.tst" "$root/projects/11/Integration/Integration.tst"; do
  output=$(cd "$simulator/InstallDir" && timeout 180s java -Djava.awt.headless=true -cp bin/classes VMEmulatorMain "$test" 2>&1)
  printf '%s\n%s\n' "$test" "$output"
  [[ "$output" == *"Comparison ended successfully"* ]]
done
