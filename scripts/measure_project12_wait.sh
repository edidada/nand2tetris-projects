#!/usr/bin/env bash
set -euo pipefail
root="$PWD"
simulator="$root/.tools/simulator"
for duration in 0 100 1000 2000; do
    directory="$root/.tools/Wait$duration"
    mkdir -p "$directory"
    cp projects/12/*.jack "$directory/"
    cat > "$directory/Main.jack" <<EOF
class Main {
    function void main() {
        do Memory.poke(8000,1);
        do Sys.wait($duration);
        do Memory.poke(8000,2);
        return;
    }
}
EOF
    python3 .tools/compiler/11/jack_compiler.py "$directory"
done
cat > .tools/measure-wait.jsh <<'EOF'
import Hack.VMEmulator.VMEmulator;
import Hack.VMEmulator.CPU;
void measure(int duration) throws Exception {
    VMEmulator vm = new VMEmulator();
    var field = VMEmulator.class.getDeclaredField("cpu");
    field.setAccessible(true);
    CPU cpu = (CPU)field.get(vm);
    cpu.getProgram().loadProgram(System.getenv("PROJECT12_ROOT")+"/.tools/Wait"+duration);
    cpu.boot();
    long startup=0;
    while(cpu.getRAM().getValueAt(8000)!=1 && startup++<10000000) cpu.executeInstruction();
    if(startup>=10000000) throw new Exception("wait start marker missing");
    long start=System.nanoTime(),steps=0;
    while(cpu.getRAM().getValueAt(8000)!=2 && steps<100000000) {
        for(int i=0;i<1000;i++) cpu.executeInstruction();
        steps+=1000;
    }
    double millis=(System.nanoTime()-start)/1000000.0;
    if(steps>=100000000) throw new Exception("wait end marker missing");
    System.out.printf(java.util.Locale.ROOT,"WAIT requested=%d elapsed_ms=%.3f steps=%d%n",duration,millis,steps);
}
try { for(int d:new int[]{0,100,1000,2000}) measure(d); } catch(Throwable e) { e.printStackTrace(); System.exit(1); }
/exit
EOF
(
    cd "$simulator/InstallDir"
    PROJECT12_ROOT="$root" timeout 180 jshell -R-Djava.awt.headless=true --class-path bin/classes "$root/.tools/measure-wait.jsh"
) 2>&1 | tee test-results/wait-measurement.log
python3 - <<'PY'
from pathlib import Path
import re,json
rows=[dict(requested_ms=int(a),elapsed_ms=float(b),steps=int(c)) for a,b,c in re.findall(r'WAIT requested=(\d+) elapsed_ms=([\d.]+) steps=(\d+)',Path('test-results/wait-measurement.log').read_text())]
assert len(rows)==4,rows
assert rows[1]['steps']<rows[2]['steps']<rows[3]['steps'],rows
for row in rows:
    row['within_25_percent_wall_time']=abs(row['elapsed_ms']-row['requested_ms'])<=row['requested_ms']*0.25 if row['requested_ms'] else None
Path('test-results/wait-measurement.json').write_text(json.dumps({'mode':'headless direct official CPU, current Jack Sys.vm; no built-in sleep or artificial throttling','measurements':rows,'note':'Measured observations; this does not certify GUI normal-speed timing.'},indent=2)+'\n')
print(json.dumps(rows))
PY
