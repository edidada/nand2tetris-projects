// This file is part of www.nand2tetris.org
// and the book "The Elements of Computing Systems"
// by Nisan and Schocken, MIT Press.
// File name: projects/04/Fill.asm

// Runs an infinite loop that listens to the keyboard input.
// When a key is pressed (any key), the program blackens the screen,
// i.e. writes "black" in every pixel;
// the screen should remain fully black as long as the key is pressed. 
// When no key is pressed, the program clears the screen, i.e. writes
// "white" in every pixel;
// the screen should remain fully clear as long as no key is pressed.

(POLL)
@KBD
D=M
@WHITE
D;JEQ
@color
M=-1
@START
0;JMP
(WHITE)
@color
M=0
(START)
@SCREEN
D=A
@pixel
M=D
(PAINT)
@color
D=M
@pixel
A=M
M=D
@pixel
M=M+1
D=M
@KBD
D=D-A
@PAINT
D;JLT
@POLL
0;JMP
