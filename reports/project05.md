# Nand2Tetris Project 05

实现 Hack CPU、完整 Memory-headless、Computer。A 指令直接载入 A 寄存器；C 指令由 6 个控制位驱动 ALU，目标寄存器写使能与跳转均由指令最高位门控。正/零/负条件组合实现七种跳转，PC reset 优先于跳转；同周期更新 A 与跳转时使用时钟前 A 地址。

Memory 对地址 0–16383 映射 RAM16K，16384–24575 映射 Screen，24576 为只读 Keyboard；无效高地址行为按题目不定义。Computer 连接 ROM32K、CPU 与 Memory。

独立 project05.yml 使用固定版本官方 HardwareSimulator，执行 CPU/CPU-external、Memory-headless、Computer Add/Max/Rect 的内部和 external 测试共9项（8项原测试，1项明确调整键盘刺激的Memory-headless）。遵循项目说明使用官方 ARegister/DRegister、RAM16K、屏幕及键盘等内置芯片，使原测试能够读取内部状态；本项目三个 HDL 为本人实现。原 tst/cmp/hack 均未修改，本地未编译或模拟。

原 Memory.tst 包含等待真人持续按 K/Y 的循环，首次CI因此挂起，已取消。CI生成独立 Memory-headless.tst/cmp：保留全部RAM、Screen地址隔离和写使能断言，仅将两次人工按键改为无按键0的读取检查。原Memory.tst/cmp未改，当时不能声称非零按键的Memory集成已经验收。每个模拟器子进程设120秒超时，避免同类交互等待。Project04的CPU Emulator键盘模拟与本项目HardwareSimulator内存测试为不同验收范围。

## 原始 Memory 键盘与屏幕验收补齐

新增 scripts/verify_project05_gui.sh，继续使用固定官方模拟器 327b7e4337b31efb815e1c1e3913c0efd299bcf2。在远端 Xvfb 中启用 HDL 内置 Keyboard 的官方 Swing 组件，通过 java.awt.Robot 输入 Shift+K、释放、Shift+Y、释放。没有调用芯片 setValueAt、没有直接改键盘输出，没有改 Memory.hdl 或原 Memory.tst/cmp。官方 HackController 完整运行原脚本并比较原参考，输出 Comparison ended successfully；测试额外核对 K 释放归零、Y 通过整个 Memory 地址路径输出89及释放归零。

屏幕8192字逐一检查：只有偏移4047和4175为-1，其余全0，即两条16像素水平线，总32黑像素；保存memory-screen.png及原Memory.out。原8项CPU/Computer测试与历史无按键Memory适配仍回归，新增原Memory测试令原始9项全部被覆盖。首次完整通过运行：https://github.com/edidada/nand2tetris-projects/actions/runs/43457214807 。后续最终提交由同分支独立project05.yml再次验证，永久结果归档到langnote课程台账。

这里完成的是可复现的公开自学自动验收，系统按键事件由Robot产生，不冒充真人课堂操作或私有评分。Java仅作为官方验证工具运行时，本地未编译或执行模拟器；新增脚本为shell及运行时JShell代码，没有新增Python文件。前文无按键限制为历史状态，本节原始K/Y测试已补齐该缺口。