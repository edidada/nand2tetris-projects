# Nand2Tetris Project 01 实验报告

官方 nand2tetris/projects 为实验模板；本分支 edidada/project01 实现15个组合逻辑芯片，从 Nand 构造 Not、And、Or、Xor，再组合 Mux/DMux、16位并行版本及多路选择分配。保留官方每个 .tst 和 .cmp，不使用 BUILTIN 声明替代实现。

独立 project01.yml 配置 JDK17，检出官方 Java 模拟器固定提交327b7e4337b31efb815e1c1e3913c0efd299bcf2并编译，在 headless 模式逐个运行15个原始测试，要求每个出现 Comparison ended successfully。这是官方源代码模拟器验证，不是只测试自写布尔函数。工具来源 https://www.nand2tetris.org/software 。本地未编译，尚未向任何课程平台提交；其他 Project 不据此认定完成。

本项目的实验语言是课程 HDL（目录 verilog 仅用于本地硬件语言归类，并非标准 Verilog）；Java 是外部官方模拟器的原有构建，不改为本项目代码。
