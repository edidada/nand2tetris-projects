#!/usr/bin/env bash
set -euo pipefail
root="$PWD"
mkdir -p test-results
# Preserve exact official stimuli, reference values, HDL, and test program.
git diff --exit-code dad0e4ffc793622d415fd8772614137323b1720e -- projects/05/Memory.tst projects/05/Memory.cmp
cat > .tools/memory-gui.jsh <<'JAVA'
import Hack.HardwareSimulator.*;
import Hack.Controller.*;
import Hack.Gates.*;
import SimulatorsGUI.*;
import javax.swing.*;
import java.awt.*;
import java.awt.event.*;
import java.awt.image.*;
import javax.imageio.ImageIO;
import java.nio.file.*;
void verifyMemory() throws Exception {
    String root=System.getenv("PROJECT05_ROOT");
    HardwareSimulator sim=new HardwareSimulator();
    GatesManager.getInstance().enableChipsGUI(true);
    HackController[] controller=new HackController[1];
    Throwable[] failure=new Throwable[1];
    Thread worker=new Thread(()->{try{controller[0]=new HackController(sim,root+"/projects/05/Memory.tst");}catch(Throwable e){failure[0]=e;}});
    worker.start();
    long deadline=System.nanoTime()+60000000000L;
    KeyboardComponent keyboard=null;
    while(keyboard==null && System.nanoTime()<deadline){
        for(var chip:GatesManager.getInstance().getChips())if(chip.getGateClass().getName().equals("Keyboard"))keyboard=(KeyboardComponent)chip.getGUIComponent();
        Thread.sleep(10);
    }
    if(keyboard==null)throw new Exception("Keyboard chip GUI unavailable");
    KeyboardComponent target=keyboard;
    JFrame frame=new JFrame("Original Memory.tst keyboard verification");
    SwingUtilities.invokeAndWait(()->{frame.setContentPane(target);frame.pack();frame.setLocation(40,40);frame.setVisible(true);target.getKeyEventHandler().requestFocusInWindow();});
    Robot robot=new Robot();robot.setAutoDelay(40);robot.waitForIdle();
    Point point=target.getKeyEventHandler().getLocationOnScreen();
    robot.mouseMove(point.x+40,point.y+12);robot.mousePress(InputEvent.BUTTON1_DOWN_MASK);robot.mouseRelease(InputEvent.BUTTON1_DOWN_MASK);robot.waitForIdle();
    while(!sim.getValue("address").equals("24576") && System.nanoTime()<deadline)Thread.sleep(5);
    if(!sim.getValue("address").equals("24576"))throw new Exception("K prompt missing");
    robot.keyPress(KeyEvent.VK_SHIFT);robot.keyPress(KeyEvent.VK_K);robot.waitForIdle();
    while(!(sim.getValue("Screen[4175]").equals("-1") && sim.getValue("address").equals("24576")) && System.nanoTime()<deadline)Thread.sleep(5);
    if(!sim.getValue("Screen[4175]").equals("-1"))throw new Exception("Y prompt not reached");
    robot.keyRelease(KeyEvent.VK_K);robot.keyRelease(KeyEvent.VK_SHIFT);robot.waitForIdle();
    if(!sim.getValue("Keyboard[]").equals("0"))throw new Exception("K release failed");
    robot.keyPress(KeyEvent.VK_SHIFT);robot.keyPress(KeyEvent.VK_Y);robot.waitForIdle();
    worker.join(10000);
    if(worker.isAlive())throw new Exception("Original script did not terminate");
    if(failure[0]!=null)throw new Exception("Controller error",failure[0]);
    var failed=HackController.class.getDeclaredField("comparisonFailed");failed.setAccessible(true);
    if(failed.getBoolean(controller[0]))throw new Exception("Original comparison failed");
    if(!sim.getValue("out").equals("89"))throw new Exception("Y not propagated to Memory.out");
    robot.keyRelease(KeyEvent.VK_Y);robot.keyRelease(KeyEvent.VK_SHIFT);robot.waitForIdle();
    if(!sim.getValue("out").equals("0"))throw new Exception("Release not propagated to Memory.out");
    BufferedImage image=new BufferedImage(512,256,BufferedImage.TYPE_INT_RGB);
    int black=0;
    for(int i=0;i<8192;i++){
        int value=Integer.parseInt(sim.getValue("Screen["+i+"]"));
        int expected=(i==4047 || i==4175)?-1:0;
        if(value!=expected)throw new Exception("Unexpected screen word "+i+"="+value);
        for(int bit=0;bit<16;bit++){boolean on=((value>>>bit)&1)==1;if(on)black++;image.setRGB((i%32)*16+bit,i/32,on?0:0xffffff);}
    }
    if(black!=32)throw new Exception("Expected two 16-pixel lines");
    ImageIO.write(image,"png",Path.of(root,"test-results","memory-screen.png").toFile());
    Files.copy(Path.of(root,"projects/05/Memory.out"),Path.of(root,"test-results/Memory.out"),StandardCopyOption.REPLACE_EXISTING);
    SwingUtilities.invokeAndWait(()->frame.dispose());
    System.out.println("ORIGINAL_MEMORY_GUI_OK keys=K,Y releases=2 screen_words=8192 black_pixels=32 original_compare=true");
}
try{verifyMemory();}catch(Throwable e){e.printStackTrace();System.exit(1);}
/exit
JAVA
(cd .tools/simulator/InstallDir && PROJECT05_ROOT="$root" timeout 120 xvfb-run -a jshell --class-path bin/classes "$root/.tools/memory-gui.jsh") 2>&1 | tee test-results/memory-gui.log
grep -q 'ORIGINAL_MEMORY_GUI_OK' test-results/memory-gui.log
