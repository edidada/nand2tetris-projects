# Nand2Tetris Project 05

实现 Hack CPU、完整 Memory、Computer。A 指令直接载入 A 寄存器；C 指令由 6 个控制位驱动 ALU，目标寄存器写使能与跳转均由指令最高位门控。正/零/负条件组合实现七种跳转，PC reset 优先于跳转；同周期更新 A 与跳转时使用时钟前 A 地址。

Memory 对地址 0–16383 映射 RAM16K，16384–24575 映射 Screen，24576 为只读 Keyboard；无效高地址行为按题目不定义。Computer 连接 ROM32K、CPU 与 Memory。

独立 project05.yml 使用固定版本官方 HardwareSimulator，执行 CPU/CPU-external、Memory、Computer Add/Max/Rect 的内部和 external 原测试共9项。遵循项目说明使用官方 ARegister/DRegister、RAM16K、屏幕及键盘等内置芯片，使原测试能够读取内部状态；本项目三个 HDL 为本人实现。原 tst/cmp/hack 均未修改，本地未编译或模拟。
