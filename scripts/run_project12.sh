#!/usr/bin/env bash
set -euo pipefail
root="$PWD"
mkdir -p .tools/compiler/10 .tools/compiler/11 test-results
exec > >(tee test-results/verification.log) 2>&1
printf 'commit=%s\n' "$(git rev-parse HEAD)"
# Reuse the independently verified compiler without adding Python source here.
git fetch origin edidada/project11
git show 8c7bdcac1ddcb96ade280375e6f4221ace25eb3e:projects/10/jack_analyzer.py > .tools/compiler/10/jack_analyzer.py
git show 8c7bdcac1ddcb96ade280375e6f4221ace25eb3e:projects/11/jack_compiler.py > .tools/compiler/11/jack_compiler.py
simulator="$root/.tools/simulator"
git clone https://github.com/nand2tetris/nand2tetris_simulator.git "$simulator"
git -C "$simulator" checkout 327b7e4337b31efb815e1c1e3913c0efd299bcf2
mkdir -p "$simulator/InstallDir/bin/classes"
find "$simulator" -name '*.java' -print > .tools/java-sources.txt
javac -encoding UTF-8 -d "$simulator/InstallDir/bin/classes" @.tools/java-sources.txt
git diff --exit-code 5bd2184edfd4945ff8a28eb0b237c12cdbe9e498 -- projects/12/*Test projects/11/Pong
run() {
    local test=$1
    local log="$root/test-results/$(basename "$(dirname "$test")").log"
    (cd "$simulator/InstallDir" && timeout 240 java -Djava.awt.headless=true -cp bin/classes VMEmulatorMain "$test") 2>&1 | tee "$log"
    grep -q 'Comparison ended successfully' "$log"
}
for module in Math Memory Array; do
    directory="$root/.tools/${module}Test"
    mkdir -p "$directory"
    cp "projects/12/${module}Test/"* "$directory/"
    cp "projects/12/$module.jack" "$directory/"
    # The source-built emulator requires an explicit Sys.init entrypoint.
    # Keep other OS modules built in for this isolated module test.
    cat > "$directory/Sys.jack" <<EOF
class Sys {
    function void init() {
        do $module.init();
        do Main.main();
        while (true) { }
        return;
    }
}
EOF
    if [[ $module == Array ]]; then
        sed -i 's/do Array.init();/do Memory.init();/' "$directory/Sys.jack"
    fi
    python3 .tools/compiler/11/jack_compiler.py "$directory"
    run "$directory/${module}Test.tst"
done
# Compile all eight classes together and every supplied program. Later
# integration tests must execute these VM files, rather than built-in OS calls.
for name in String Output Screen Keyboard Sys; do
    directory="$root/.tools/${name}Test"
    mkdir -p "$directory"
    cp projects/12/*.jack "$directory/"
    cp "projects/12/${name}Test/"*.jack "$directory/"
    python3 .tools/compiler/11/jack_compiler.py "$directory"
done
mkdir -p .tools/Pong
cp projects/11/Pong/*.jack projects/12/*.jack .tools/Pong/
python3 .tools/compiler/11/jack_compiler.py .tools/Pong
printf 'PASS: original Math/Memory/Array tests; all eight OS classes and supplied programs/Pong compile. Interactive acceptance remains pending.\n'
