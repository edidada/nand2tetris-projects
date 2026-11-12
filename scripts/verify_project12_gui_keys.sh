#!/usr/bin/env bash
set -euo pipefail
root="$PWD"
cat > .tools/gui-keys.jsh <<'EOF'
import Hack.VMEmulator.VMEmulator;
import Hack.VMEmulator.CPU;
import SimulatorsGUI.KeyboardComponent;
import javax.swing.*;
import java.awt.*;
import java.awt.event.KeyEvent;
import java.nio.file.*;
import javax.imageio.ImageIO;
void verifyKeys() throws Exception {
    VMEmulator vm=new VMEmulator();
    var field=VMEmulator.class.getDeclaredField("cpu"); field.setAccessible(true);
    CPU cpu=(CPU)field.get(vm);
    cpu.getProgram().loadProgram(System.getenv("PROJECT12_ROOT")+"/.tools/KeyboardTest"); cpu.boot();
    KeyboardComponent keyboard=new KeyboardComponent();
    Hack.CPUEmulator.Keyboard adapter=new Hack.CPUEmulator.Keyboard(cpu.getRAM(),keyboard);
    JFrame frame=new JFrame("Official Nand2Tetris keyboard event verification");
    SwingUtilities.invokeAndWait(()->{frame.setContentPane(keyboard);frame.pack();frame.setLocation(50,50);frame.setVisible(true);keyboard.getKeyEventHandler().requestFocusInWindow();});
    Robot robot=new Robot(); robot.setAutoDelay(30);robot.waitForIdle();
    Point point=keyboard.getKeyEventHandler().getLocationOnScreen();
    robot.mouseMove(point.x+40,point.y+12);robot.mousePress(java.awt.event.InputEvent.BUTTON1_DOWN_MASK);robot.mouseRelease(java.awt.event.InputEvent.BUTTON1_DOWN_MASK);robot.waitForIdle();
    for(int i=0;i<1000000;i++)cpu.executeInstruction();
    int[] keys={KeyEvent.VK_PAGE_DOWN,KeyEvent.VK_3,KeyEvent.VK_J,KeyEvent.VK_A,KeyEvent.VK_X,KeyEvent.VK_BACK_SPACE,KeyEvent.VK_C,KeyEvent.VK_K,KeyEvent.VK_ENTER,KeyEvent.VK_MINUS,KeyEvent.VK_3,KeyEvent.VK_2,KeyEvent.VK_1,KeyEvent.VK_2,KeyEvent.VK_X,KeyEvent.VK_BACK_SPACE,KeyEvent.VK_3,KeyEvent.VK_ENTER};
    int[] expected={137,51,74,65,88,129,67,75,128,45,51,50,49,50,88,129,51,128};
    for(int n=0;n<keys.length;n++){
        boolean shift=keys[n]>=KeyEvent.VK_A && keys[n]<=KeyEvent.VK_Z;
        if(shift)robot.keyPress(KeyEvent.VK_SHIFT);
        robot.keyPress(keys[n]);robot.waitForIdle();
        if(cpu.getRAM().getValueAt(24576)!=expected[n])throw new Exception("GUI press mismatch "+n+" got "+cpu.getRAM().getValueAt(24576));
        for(int i=0;i<2000000;i++)cpu.executeInstruction();
        robot.keyRelease(keys[n]);if(shift)robot.keyRelease(KeyEvent.VK_SHIFT);robot.waitForIdle();
        if(cpu.getRAM().getValueAt(24576)!=0)throw new Exception("GUI release mismatch "+n);
        for(int i=0;i<2000000;i++)cpu.executeInstruction();
    }
    for(int i=0;i<2000000;i++)cpu.executeInstruction();
    StringBuilder words=new StringBuilder();
    for(int i=16384;i<24576;i++)words.append(cpu.getRAM().getValueAt(i)).append('\n');
    Files.writeString(Path.of(System.getenv("PROJECT12_ROOT"),"test-results","gui-keyboard-words.txt"),words);
    ImageIO.write(robot.createScreenCapture(new Rectangle(frame.getLocationOnScreen(),frame.getSize())),"png",Path.of(System.getenv("PROJECT12_ROOT"),"test-results","gui-keyboard-component.png").toFile());
    SwingUtilities.invokeAndWait(()->frame.dispose());
    System.out.println("GUI_KEY_EVENTS_OK count="+keys.length+" official KeyboardComponent -> Keyboard listener -> RAM; no direct RAM writes");
}
try{verifyKeys();}catch(Throwable e){e.printStackTrace();System.exit(1);}
/exit
EOF
(
    cd "$root/.tools/simulator/InstallDir"
    PROJECT12_ROOT="$root" timeout 180 xvfb-run -a jshell --class-path bin/classes "$root/.tools/gui-keys.jsh"
) 2>&1 | tee test-results/gui-keyboard.log
grep -q 'GUI_KEY_EVENTS_OK count=18' test-results/gui-keyboard.log
python3 - <<'PY'
from pathlib import Path
import re
words=[int(s)&65535 for s in Path('test-results/gui-keyboard-words.txt').read_text().splitlines()]
assert len(words)==8192
font={}
for args in re.findall(r'do Output.create\(([^)]+)\)',Path('projects/12/Output.jack').read_text()):
    values=[int(x.strip()) for x in args.split(',')];font[tuple(values[1:])]=chr(values[0])
font[(0,)*11]=' '
lines=[''.join(font.get(tuple((words[(row*11+y)*32+col//2]>>(8*(col%2)))&255 for y in range(11)),'?') for col in range(64)).rstrip() for row in range(23)]
assert any('Test completed successfully' in line for line in lines),lines
assert sum(line=='ok' for line in lines)==4,lines
Path('test-results/gui-keyboard-screen.txt').write_text('\n'.join(lines)+'\n')
print('PASS: official KeyboardTest four stages via GUI OS key events')
PY
