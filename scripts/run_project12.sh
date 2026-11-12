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
    cp "projects/12/${module}Test/"*.jack "projects/12/${module}Test/"*.tst "projects/12/${module}Test/"*.cmp "$directory/"
    cp projects/12/*.jack "$directory/"
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
# Cross-module runtime assertions with every OS implementation loaded.
directory="$root/.tools/Integration"
mkdir -p "$directory"
cp projects/12/*.jack "$directory/"
cat > "$directory/Main.jack" <<'EOF'
class Main {
    function void main() {
        var Array out, a, b, c, whole;
        var String s;
        var int i;
        let out = Array.new(26);
        let out[0] = Math.divide(-32767-1, 2);
        let out[1] = Math.divide(32767, -1);
        let out[2] = Math.sqrt(32767);
        let s = String.new(6);
        do s.setInt(-32767-1);
        let out[3] = s.length();
        let out[4] = s.intValue();
        do s.dispose();
        let a = Array.new(100);
        let b = Array.new(200);
        let c = Array.new(300);
        do b.dispose();
        do a.dispose();
        do c.dispose();
        let whole = Array.new(12000);
        let whole[11999] = 12345;
        let out[5] = whole[11999];
        do whole.dispose();
        do Screen.clearScreen();
        do Screen.setColor(true);
        do Screen.drawPixel(511,255);
        let out[6] = Memory.peek(24575);
        do Screen.setColor(false);
        do Screen.drawPixel(511,255);
        let out[7] = Memory.peek(24575);
        do Screen.setColor(true);
        do Screen.drawRectangle(15,0,16,0);
        let out[8] = Memory.peek(16384);
        let out[9] = Memory.peek(16385);
        do Output.moveCursor(0,0);
        do Output.printChar(65);
        let out[10] = Memory.peek(16384);
        let out[11] = Keyboard.keyPressed();
        let out[12] = 777;
        let s = String.new(6);
        do s.setInt(32767);
        let out[13] = s.intValue();
        do s.setInt(0);
        let out[14] = s.length();
        let out[15] = s.charAt(0);
        do s.eraseLastChar();
        do s.appendChar(45);
        do s.appendChar(49);
        do s.appendChar(50);
        do s.appendChar(120);
        do s.appendChar(51);
        let out[16] = s.intValue();
        do s.dispose();
        do Screen.clearScreen();
        do Screen.setColor(true);
        do Screen.drawLine(0,0,15,15);
        let out[17] = Memory.peek(16384);
        let out[18] = Memory.peek(16864);
        do Screen.drawLine(15,0,0,15);
        let out[19] = Memory.peek(16384);
        let out[20] = Memory.peek(16864);
        do Screen.clearScreen();
        do Screen.drawCircle(16,16,2);
        let out[21] = Memory.peek(16833);
        let out[22] = Memory.peek(16896);
        let out[23] = Memory.peek(16897);
        do Screen.setColor(false);
        do Screen.drawRectangle(14,14,18,18);
        let out[24] = Memory.peek(16896);
        let out[25] = Memory.peek(16897);
        let i = 0;
        while (i < 26) { do Memory.poke(8000+i,out[i]); let i=i+1; }
        return;
    }
}
EOF
python3 .tools/compiler/11/jack_compiler.py "$directory"
expected=(-16384 -32767 181 6 -32768 12345 -32768 0 -32768 1 16140 0 777 32767 1 48 -12 1 -32768 -32767 -32767 1 -16384 7 0 0)
for start in 0 13; do
    name="Integration$start"
    {
        echo 'load,'
        echo "output-file $name.out,"
        echo "compare-to $name.cmp,"
        printf 'output-list '
        for ((i=start;i<start+13;i++)); do printf 'RAM[%s]%%D1.6.1 ' "$((8000+i))"; done
        printf ';\nrepeat 8000000 { vmstep; }\noutput;\n'
    } > "$directory/$name.tst"
    {
        printf '|'
        for ((i=start;i<start+13;i++)); do printf '%.8s|' "RAM[$((8000+i))]"; done
        printf '\n|'
        for ((i=start;i<start+13;i++)); do printf ' %6d |' "${expected[i]}"; done
        printf '\n'
    } > "$directory/$name.cmp"
    run "$directory/$name.tst" || { cp "$directory/$name.out" "$directory/$name.cmp" test-results/; exit 1; }
    cp "$directory/$name.out" test-results/
done
printf 'PASS: original Math/Memory/Array tests; all eight OS classes and supplied programs/Pong compile. Interactive acceptance remains pending.\n'
