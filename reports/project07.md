# Nand2Tetris Project 07

实现 VM 到 Hack 汇编翻译：9种算术/逻辑命令及 constant/local/argument/this/that/temp/pointer/static 内存段。栈顶操作维护 SP；pop 先将目标地址存入R13，再取栈顶，避免间接地址被覆盖；静态变量以文件名为前缀。gt/lt 先比较符号，不同符号直接判定，同号才减法，避免16位溢出。

独立 project07.yml 在 Actions 构建固定版本官方CPU Emulator，将官方5份VM输入翻译为同名asm，再执行原SimpleAdd、StackTest、BasicTest、PointerTest、StaticTest的CPU测试和cmp。不用VM Emulator执行原VM冒充翻译器验收。原测试不变，本地不编译或执行。此项目不含函数调用和程序流命令（Project08）。

补充生成Overflow VM/CPU测试：18对eq/gt/lt比较，包含32767与-1、-32768与正数及相同最小值；预期用Python整数比较独立生成，真实执行翻译后机器指令，而非只匹配输出汇编字符串。
