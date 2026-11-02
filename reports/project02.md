# Nand2Tetris Project 02 实验报告

分支 edidada/project02。实现 HalfAdder、FullAdder、Add16、Inc16、ALU 五个芯片。半加器以 XOR/AND 实现和及进位，全加器串接两个半加器，Add16 用16位串行进位，最高位进位丢弃形成模65536运算。

ALU 按官方六控制位依次零化/取反输入、选择 AND 或加法、可选输出取反。最终输出的高位作为 ng，低高两个8位或归约后取反作为 zr。没有用 BUILTIN 替代任何本实验实现。

独立 project02.yml 使用固定提交官方 Java 模拟器、JDK17，运行五个芯片的全部六份原始测试（含ALU-nostat与完整状态测试）。沿用Project01的源码构建脚本，只增加明确的01/02参数范围。本地未编译，不申报校内成绩；最终结果见该分支Actions。
