#!/usr/bin/env bash
set -euo pipefail
root="$PWD"
mkdir -p test-results
# Runtime reuse only: no extra Python source is committed.
git fetch origin edidada/project12
for app in Seven ConvertToBin Square Average Pong ComplexArrays; do
    mkdir -p ".tools/apps/$app"
    cp "projects/11/$app/"*.jack ".tools/apps/$app/"
    for module in Array Keyboard Math Memory Output Screen String Sys; do
        git show "a967e8977f4479414aa077f1bbbf340157051018:projects/12/$module.jack" > ".tools/apps/$app/$module.jack"
    done
    python3 projects/11/jack_compiler.py ".tools/apps/$app"
done
git diff --exit-code 5bd2184edfd4945ff8a28eb0b237c12cdbe9e498 -- projects/11/Seven projects/11/ConvertToBin projects/11/Square projects/11/Average projects/11/Pong projects/11/ComplexArrays
cat > .tools/apps.jsh <<'JAVA'
import Hack.VMEmulator.*;
import SimulatorsGUI.*;
import javax.swing.*;
import java.awt.*;
import java.awt.event.*;
import java.awt.image.*;
import javax.imageio.ImageIO;
import java.nio.file.*;
void verifyApps() throws Exception {
    String root=System.getenv("PROJECT11_ROOT");
    class App {
        VMEmulator vm; CPU cpu; Robot robot; JFrame frame;
        App(String name) throws Exception {
            vm=new VMEmulator();var f=VMEmulator.class.getDeclaredField("cpu");f.setAccessible(true);cpu=(CPU)f.get(vm);
            cpu.getProgram().loadProgram(root+"/.tools/apps/"+name);cpu.boot();
            KeyboardComponent keyboard=new KeyboardComponent();
            new Hack.CPUEmulator.Keyboard(cpu.getRAM(),keyboard);
            frame=new JFrame(name);
            SwingUtilities.invokeAndWait(()->{frame.setContentPane(keyboard);frame.pack();frame.setLocation(30,30);frame.setVisible(true);keyboard.getKeyEventHandler().requestFocusInWindow();});
            robot=new Robot();robot.setAutoDelay(20);robot.waitForIdle();
            Point p=keyboard.getKeyEventHandler().getLocationOnScreen();robot.mouseMove(p.x+40,p.y+12);robot.mousePress(InputEvent.BUTTON1_DOWN_MASK);robot.mouseRelease(InputEvent.BUTTON1_DOWN_MASK);robot.waitForIdle();
        }
        void steps(int n) throws Exception {for(int i=0;i<n;i++)cpu.executeInstruction();}
        void key(int key,int code,int n) throws Exception {
            robot.keyPress(key);robot.waitForIdle();if(cpu.getRAM().getValueAt(24576)!=code)throw new Exception("Key code mismatch "+key);
            steps(n);robot.keyRelease(key);robot.waitForIdle();if(cpu.getRAM().getValueAt(24576)!=0)throw new Exception("Release mismatch");steps(500000);
        }
        void save(String name) throws Exception {
            BufferedImage im=new BufferedImage(512,256,BufferedImage.TYPE_INT_RGB);StringBuilder words=new StringBuilder();
            for(int i=0;i<8192;i++){int w=cpu.getRAM().getValueAt(16384+i);words.append(w).append('\n');for(int b=0;b<16;b++)im.setRGB(i%32*16+b,i/32,((w>>>b)&1)==1?0:0xffffff);}
            ImageIO.write(im,"png",Path.of(root,"test-results",name+".png").toFile());Files.writeString(Path.of(root,"test-results",name+"-words.txt"),words);
        }
        int[] bounds(){int x0=512,y0=256,x1=-1,y1=-1;for(int y=0;y<256;y++)for(int x=0;x<512;x++)if(((cpu.getRAM().getValueAt(16384+y*32+x/16) >>> (x%16))&1)==1){x0=Math.min(x0,x);y0=Math.min(y0,y);x1=Math.max(x1,x);y1=Math.max(y1,y);}return new int[]{x0,y0,x1,y1};}
        void close() throws Exception {SwingUtilities.invokeAndWait(()->frame.dispose());}
    }
    App a=new App("Seven");a.steps(5000000);a.save("seven");a.close();
    int[] seeds={0,1,2,255,256,32767,-32768,-1,-12345,21845};
    for(int seed:seeds){a=new App("ConvertToBin");a.cpu.getRAM().setValueAt(8000,(short)seed,false);a.steps(5000000);for(int bit=0;bit<16;bit++)if(a.cpu.getRAM().getValueAt(8001+bit)!=((seed>>>bit)&1))throw new Exception("Conversion "+seed+" bit "+bit);a.close();}
    System.out.println("CONVERT_TO_BIN_OK inputs=10 bits=160");
    a=new App("ComplexArrays");a.steps(5000000);a.save("complex-arrays");a.close();
    a=new App("Average");a.steps(5000000);
    int[] keys={KeyEvent.VK_3,KeyEvent.VK_ENTER,KeyEvent.VK_1,KeyEvent.VK_0,KeyEvent.VK_ENTER,KeyEvent.VK_2,KeyEvent.VK_0,KeyEvent.VK_ENTER,KeyEvent.VK_3,KeyEvent.VK_0,KeyEvent.VK_ENTER};
    int[] codes={51,128,49,48,128,50,48,128,51,48,128};
    for(int i=0;i<keys.length;i++)a.key(keys[i],codes[i],500000);
    a.steps(5000000);a.save("average");a.close();
    a=new App("Square");a.steps(5000000);a.save("square-initial");int[] initial=a.bounds();
    a.key(KeyEvent.VK_RIGHT,132,500000);int[] right=a.bounds();if(right[0]<=initial[0])throw new Exception("Square right");
    a.key(KeyEvent.VK_DOWN,133,500000);int[] down=a.bounds();if(down[1]<=right[1])throw new Exception("Square down");
    a.key(KeyEvent.VK_LEFT,130,500000);int[] left=a.bounds();if(left[0]>=down[0])throw new Exception("Square left");
    a.key(KeyEvent.VK_UP,131,5000000);int[] up=a.bounds();if(up[1]>=left[1])throw new Exception("Square up");
    a.key(KeyEvent.VK_X,88,500000);int[] grown=a.bounds();if(grown[2]-grown[0]!=32)throw new Exception("Square grow "+java.util.Arrays.toString(grown));
    a.save("square-grown");a.key(KeyEvent.VK_Z,90,500000);int[] shrunk=a.bounds();if(shrunk[2]-shrunk[0]!=30)throw new Exception("Square shrink");
    a.key(KeyEvent.VK_Q,81,500000);if(!a.vm.getValue("currentFunction").equals("Sys.halt"))throw new Exception("Square quit");a.close();
    System.out.println("SQUARE_GUI_OK directions=4 grow=32 shrink=30 quit=true");
    a=new App("Pong");a.steps(1000000);a.save("pong-initial");a.key(KeyEvent.VK_LEFT,130,1000000);a.save("pong-left");a.key(KeyEvent.VK_RIGHT,132,1000000);a.save("pong-right");a.key(KeyEvent.VK_ESCAPE,140,2000000);a.save("pong-escape");a.close();
    a=new App("Pong");a.steps(1000000);a.key(KeyEvent.VK_RIGHT,132,40000000);a.save("pong-score");a.close();
    System.out.println("SIX_APPLICATIONS_EXECUTED gui_events=22 original_sources_unchanged=true");
}
try{verifyApps();}catch(Throwable e){e.printStackTrace();System.exit(1);}
/exit
JAVA
(cd .tools/simulator/InstallDir && PROJECT11_ROOT="$root" timeout 300 xvfb-run -a jshell --class-path bin/classes "$root/.tools/apps.jsh") 2>&1 | tee test-results/apps.log
grep -q 'SIX_APPLICATIONS_EXECUTED' test-results/apps.log
python3 - <<'PY'
from pathlib import Path
import re,json
font={}
for args in re.findall(r'do Output.create\(([^)]+)\)',Path('.tools/apps/Seven/Output.jack').read_text()):
    values=[int(x.strip()) for x in args.split(',')];font[tuple(values[1:])]=chr(values[0])
font[(0,)*11]=' '
def text(name):
    w=[int(s)&65535 for s in Path(f'test-results/{name}-words.txt').read_text().splitlines()]
    lines=[''.join(font.get(tuple((w[(r*11+y)*32+c//2]>>(8*(c%2)))&255 for y in range(11)),'?') for c in range(64)).rstrip() for r in range(23)]
    Path(f'test-results/{name}-screen.txt').write_text('\n'.join(lines)+'\n')
    return lines
assert text('seven')[0].startswith('7')
lines=text('complex-arrays')
for n,value in enumerate([5,40,0,77,110],1):
    assert any(f'Test {n}: expected result: {value}; actual result: {value}' in s for s in lines),lines
assert any('The average is 20' in s for s in text('average'))
assert any('Game Over' in s for s in text('pong-escape'))
score=text('pong-score');assert any('Score: 1' in s for s in score),score
assert any('Game Over' in s for s in score),score
positions={}
for phase in ['initial','left','right']:
    words=[int(s)&65535 for s in Path(f'test-results/pong-{phase}-words.txt').read_text().splitlines()]
    xs=[x for x in range(512) if words[229*32+x//16] & (1<<(x%16))]
    assert xs,phase
    positions[phase]=[min(xs),max(xs)]
assert positions['left'][0]<positions['initial'][0],positions
assert positions['right'][0]>positions['left'][0],positions
Path('test-results/application-results.json').write_text(json.dumps({'applications':6,'conversion_inputs':10,'conversion_bits':160,'complex_array_results':[5,40,0,77,110],'average':20,'seven':7,'gui_events':22,'square':{'directions':4,'grown_size':32,'shrunk_size':30,'quit':True},'pong':{'paddle_positions':positions,'score':1,'escape_game_over':True,'miss_game_over':True}},indent=2)+'\n')
print('SCREEN_ASSERTIONS_OK seven=7 complex_arrays=5 average=20 pong_score=1 paddle_directions=2')
PY
