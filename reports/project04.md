# Nand2Tetris Project 04

实现 Hack 汇编 Mult 与 Fill。Mult 反复累加 R0，R1 次，结果写入 R2；覆盖原要求的非负数及乘积小于 32768，含零乘数。Fill 持续轮询 KBD，每轮选取 0 或 -1，遍历 SCREEN 的全部 8192 个字后再轮询，不写入 KBD 地址。

独立 project04.yml 使用与前面项目一致的固定版本官方 Java 模拟器（JDK17），运行原 Mult.tst 和 FillAutomatic.tst，不改测试及 cmp。Fill 的人工交互脚本不在无界面 CI 中冒充自动测试，自动脚本真实模拟按下和松开键盘，各执行 100 万 CPU 周期，检查屏幕地址采样。只在 GitHub Actions 编译及执行。
