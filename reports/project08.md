# Nand2Tetris Project 08

在 Project07 基础上实现 label/goto/if-goto、function/call/return 与多文件翻译。标签按函数作用域隔离，静态变量仍按文件隔离；call保存返回地址和LCL/ARG/THIS/THAT，设置新ARG/LCL；return使用R13保存frame、R14保存ret，先移动返回值和SP再逆序恢复调用者现场，支持递归及嵌套调用。

CLI 接受单个VM或目录，按文件名排序输出；auto bootstrap仅检测到Sys.init定义时初始化SP=256并调用Sys.init，可通过--bootstrap on/off明确选择。无Sys.init的原SimpleFunction/ProgramFlow由测试预设环境启动。

独立project08.yml真实运行官方CPU Emulator，对照原BasicLoop、FibonacciSeries、SimpleFunction、NestedCall、FibonacciElement和StaticsTest共6项CPU测试及cmp，覆盖循环、递归、函数帧、零初始化、THIS/THAT恢复及跨文件静态变量隔离。原测试不变，本地不运行VM、汇编或模拟器。
