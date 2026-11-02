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
  python3 projects/08/vm_translator.py "$directory"
done < <(find "$root/projects/08" -name '*.vm' -printf '%h\0' | sort -zu)
while IFS= read -r -d '' test; do
  output=$(cd "$simulator/InstallDir" && timeout 120s java -Djava.awt.headless=true -cp bin/classes CPUEmulatorMain "$test" 2>&1)
  printf '%s\n%s\n' "$test" "$output"
  [[ "$output" == *"Comparison ended successfully"* ]]
done < <(find "$root/projects/08" -name '*.tst' ! -name '*VME.tst' -print0 | sort -z)
