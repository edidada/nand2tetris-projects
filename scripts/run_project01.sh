#!/usr/bin/env bash
set -euo pipefail
root="$PWD"
project="${1:-01}"
[[ "$project" == "01" || "$project" == "02" || "$project" == "03" || "$project" == "05" ]]
simulator="$root/.tools/simulator"
git clone https://github.com/nand2tetris/nand2tetris_simulator.git "$simulator"
git -C "$simulator" checkout 327b7e4337b31efb815e1c1e3913c0efd299bcf2
mkdir -p "$simulator/InstallDir/bin/classes"
find "$simulator" -name '*.java' -print > "$root/.tools/java-sources.txt"
javac -encoding UTF-8 -d "$simulator/InstallDir/bin/classes" @"$root/.tools/java-sources.txt"
while IFS= read -r -d '' test; do
  output=$(cd "$simulator/InstallDir" && java -Djava.awt.headless=true -cp bin/classes HardwareSimulatorMain "$test" 2>&1)
  printf '%s\n%s\n' "$test" "$output"
  [[ "$output" == *"Comparison ended successfully"* ]]
done < <(find "$root/projects/$project" -name '*.tst' -print0 | sort -z)
