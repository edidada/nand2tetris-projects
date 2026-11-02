# Nand2Tetris Project 06

使用 Python 标准库实现 Hack 双遍汇编器。第一遍删除注释/空白并登记 ROM 标签；第二遍为变量分配从 RAM16 开始的地址，编码全部28种 comp、8种 dest 和8种 jump。保留预定义寄存器、SP/LCL/ARG/THIS/THAT、SCREEN/KBD。检查无效符号、重复标签、超范围 A 地址和 ROM 溢出；先完成解析再写输出，因此错误输入不覆盖已有输出。

命令：`python projects/06/assembler.py input.asm [-o output.hack]`。时间与输入字符数线性，空间与程序及符号数量线性。

独立 project06.yml 仅在 GitHub Actions 执行6组 unittest：Add/Max/Rect 与项目05提供的原机器码逐行相同；Max/Rect/Pong 的符号版与官方数值版翻译一致；变量/前向标签/预定义符号；全部目的和跳转组合；非法输入；CLI失败保留已有文件。原示例 asm/hack 未改。这里是公开样例与补充测试验收，不声称校内私有评分。本地未执行汇编或测试。
