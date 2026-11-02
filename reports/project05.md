# Nand2Tetris Project 05

实现 Hack CPU、完整 Memory-headless、Computer。A 指令直接载入 A 寄存器；C 指令由 6 个控制位驱动 ALU，目标寄存器写使能与跳转均由指令最高位门控。正/零/负条件组合实现七种跳转，PC reset 优先于跳转；同周期更新 A 与跳转时使用时钟前 A 地址。

Memory 对地址 0–16383 映射 RAM16K，16384–24575 映射 Screen，24576 为只读 Keyboard；无效高地址行为按题目不定义。Computer 连接 ROM32K、CPU 与 Memory。

独立 project05.yml 使用固定版本官方 HardwareSimulator，执行 CPU/CPU-external、Memory-headless、Computer Add/Max/Rect 的内部和 external 测试共9项（8项原测试，1项明确调整键盘刺激的Memory-headless）。遵循项目说明使用官方 ARegister/DRegister、RAM16K、屏幕及键盘等内置芯片，使原测试能够读取内部状态；本项目三个 HDL 为本人实现。原 tst/cmp/hack 均未修改，本地未编译或模拟。

原 Memory.tst 包含等待真人持续按 K/Y 的循环，首次CI因此挂起，已取消。CI生成独立 Memory-headless.tst/cmp：保留全部RAM、Screen地址隔离和写使能断言，仅将两次人工按键改为无按键0的读取检查。原Memory.tst/cmp未改，不能声称非零按键的Memory集成已经验收。每个模拟器子进程设120秒超时，避免同类交互等待。Project04的CPU Emulator键盘模拟与本项目HardwareSimulator内存测试为不同验收范围。
