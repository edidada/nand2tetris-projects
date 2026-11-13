#!/usr/bin/env bash
set -euo pipefail
root="$PWD"
cat > .tools/gui.jsh <<'JAVA'
import Hack.VMEmulator.*;
import SimulatorsGUI.KeyboardComponent;
import javax.swing.*;
import java.awt.*;
import java.awt.event.*;
import java.awt.image.*;
import java.nio.file.*;
import javax.imageio.ImageIO;
void runGame() throws Exception {
    String root=System.getenv("PROJECT09_ROOT");
    VMEmulator vm=new VMEmulator();
    var field=VMEmulator.class.getDeclaredField("cpu");field.setAccessible(true);
    CPU cpu=(CPU)field.get(vm);
    cpu.getProgram().loadProgram(root+"/.tools/Sokoban");cpu.boot();
    KeyboardComponent keyboard=new KeyboardComponent();
    Hack.CPUEmulator.Keyboard adapter=new Hack.CPUEmulator.Keyboard(cpu.getRAM(),keyboard);
    JFrame frame=new JFrame("Project09 official keyboard input");
    SwingUtilities.invokeAndWait(()->{frame.setContentPane(keyboard);frame.pack();frame.setLocation(30,30);frame.setVisible(true);keyboard.getKeyEventHandler().requestFocusInWindow();});
    Robot robot=new Robot();robot.setAutoDelay(20);robot.waitForIdle();
    Point point=keyboard.getKeyEventHandler().getLocationOnScreen();
    robot.mouseMove(point.x+40,point.y+12);robot.mousePress(InputEvent.BUTTON1_DOWN_MASK);robot.mouseRelease(InputEvent.BUTTON1_DOWN_MASK);robot.waitForIdle();
    class Harness {
        void steps() throws Exception { for(int i=0;i<500000;i++)cpu.executeInstruction(); }
        int[] words() { int[] a=new int[8192];for(int i=0;i<a.length;i++)a[i]=cpu.getRAM().getValueAt(16384+i);return a; }
        void save(String name) throws Exception {
            int[] a=words();BufferedImage image=new BufferedImage(512,256,BufferedImage.TYPE_INT_RGB);
            for(int y=0;y<256;y++)for(int x=0;x<512;x++)image.setRGB(x,y,((a[y*32+x/16] >>> (x%16))&1)==1?0:0xffffff);
            ImageIO.write(image,"png",Path.of(root,"test-results",name+".png").toFile());
        }
        void press(int key,int code) throws Exception {
            robot.keyPress(key);robot.waitForIdle();
            if(cpu.getRAM().getValueAt(24576)!=code)throw new Exception("press "+key);
            steps();
            int[] held=words();steps();
            if(!java.util.Arrays.equals(held,words()))throw new Exception("Held key repeated a move");
            robot.keyRelease(key);robot.waitForIdle();
            if(cpu.getRAM().getValueAt(24576)!=0)throw new Exception("release "+key);
            steps();
        }
        boolean pixel(int x,int y) {return ((cpu.getRAM().getValueAt(16384+y*32+x/16) >>> (x%16))&1)==1;}
    }
    Harness h=new Harness();for(int i=0;i<10;i++)h.steps();h.save("initial");int[] initial=h.words();
    h.press(KeyEvent.VK_RIGHT,132);h.save("push");
    // Top box has left its original location and now occupies the goal.
    if(h.pixel(144+3*24+4,40+2*24+4) || !h.pixel(144+4*24+4,40+2*24+4))throw new Exception("Push pixels wrong");
    h.press(KeyEvent.VK_DOWN,133);h.press(KeyEvent.VK_DOWN,133);h.press(KeyEvent.VK_LEFT,130);h.press(KeyEvent.VK_RIGHT,132);
    h.save("solved");int[] solved=h.words();
    h.press(KeyEvent.VK_LEFT,130);
    if(!java.util.Arrays.equals(solved,h.words()))throw new Exception("Won state still moving");
    h.press(KeyEvent.VK_R,82);h.save("restart");
    if(!java.util.Arrays.equals(initial,h.words()))throw new Exception("Reset framebuffer differs");
    h.press(KeyEvent.VK_Q,81);h.save("quit");
    if(java.util.Arrays.equals(initial,h.words()))throw new Exception("Quit screen unchanged");
    SwingUtilities.invokeAndWait(()->frame.dispose());
    System.out.println("GUI_APPLICATION_OK events=8 push_pixels=true held_key=true win_lock=true reset_exact=true quit=true");
}
try{runGame();}catch(Throwable e){e.printStackTrace();System.exit(1);}
/exit
JAVA
(cd .tools/simulator/InstallDir && PROJECT09_ROOT="$root" timeout 180 xvfb-run -a jshell --class-path bin/classes "$root/.tools/gui.jsh") 2>&1 | tee test-results/gui.log
grep -q 'GUI_APPLICATION_OK events=8' test-results/gui.log
