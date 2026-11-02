# Nand2Tetris Project 11

实现Jack到VM代码生成，复用Project10词法/语法树。维护类级static/field和子程序argument/local符号表，允许局部遮蔽类变量，拒绝同作用域重名和未知变量。constructor按字段数分配对象；method接收隐式this；处理数组左右值、分支/循环、方法/静态函数调用、字符串构造、乘除OS调用及void返回。

独立project11.yml编译原Project11全部Jack示例，并使用官方VM Emulator执行由本编译器编译的原Project12 MathTest、MemoryTest、ArrayTest的Main.jack，原tst/cmp不变，OS调用由官方内置实现提供。这些测试用于编译器验收，不声称本人已实现Project12 OS。另有自编Jack集成测试检查对象、递归、静态状态、数组嵌套调用、字符串首尾空格及局部遮蔽。

交互式Square/Pong/Average只编译，未声称已完成人工游戏/键盘运行验收；Seven实际屏幕输出未单独做人工验收。本地不执行编译器、VM或模拟器。
