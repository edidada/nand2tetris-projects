# Nand2Tetris Project12：Jack OS

官方要求：https://www.nand2tetris.org/project12 。官方 projects/main 基线为 5bd2184edfd4945ff8a28eb0b237c12cdbe9e498；独立分支 edidada/project12，工作流 project12.yml。本地只编辑与静态检查，全部编译、模拟和GUI验证均在Actions执行。Jack是实验语言，Java只作官方工具运行时。

## 实现

| 类 | 实现与边界 |
| --- | --- |
| Math | 16轮位乘法；负数域倍增除法避免最小整数取绝对值溢出；连续奇数求整数平方根；abs/min/max。 |
| Memory | 地址有序空闲链表、首次适配、拆分、前后相邻块合并；heap为2048..16383；直接peek/poke。 |
| Array | 分配/释放委托Memory，保持Jack对象地址语义。 |
| String | 零容量、容量和下标检查、字符增删、首个非数字截断、负数域解析及-32768格式化。 |
| Screen | 字掩码矩形、Bresenham线、逐行实心圆，白色绘制保留周围像素。 |
| Output | 原字体表并补齐starter空白A字形；23×64光标；按字节绘制而不覆盖相邻字符；整数、换行和退格。 |
| Keyboard | 内存映射按键；等待按下和释放；回显；行编辑与整数输入。 |
| Sys | 按依赖初始化、调用Main、halt/error、以Jack忙循环实现wait。 |

## 远端验证

scripts/run_project12.sh从固定Project11提交8c7bdcac1ddcb96ade280375e6f4221ace25eb3e读取已验收编译器，官方模拟器固定327b7e4337b31efb815e1c1e3913c0efd299bcf2。全部八个OS类一起加载，不让内置OS掩盖缺失实现；所有原始测试、参考及Pong源码保持不变。

- 原MathTest、MemoryTest、ArrayTest，以及附加的原MemoryDiag：范围、不重叠、释放和8000/7000字再分配。
- 26项独立RAM断言：有符号整数/字符串边界、内存合并后12000字再分配、正反向线、实心圆、跨word清除、邻接字符位图。
- 原Screen/Output/String示例完整运行并导出8192个screen word及PNG；原String的12行预期由实际像素字体解码断言。已查看房屋/太阳、字符集和字符串图。
- 原KeyboardTest先使用RAM按键脚本，再由OS Robot键盘事件进入官方KeyboardComponent及Keyboard监听器；18次按下/释放包含PageDown、3、JACK和-32123的退格纠错。屏幕必须恰有四个ok及最终成功信息。GUI路径不直接写键盘RAM。
- 原Pong完整八类OS集成：初始、左移、右移、Esc退出、接球场景。球拍位置先左后右，Esc必须出现Game Over；长场景Score必须大于0。已观测Score:1后漏球结束，并查看运行图。

## wait计时的执行环境

无界面直接CPU执行不节流，wait(2000)曾测得94.838ms、3633000步；这不是两秒验收。官方内置Sys.wait使用Thread.sleep，自实现的Jack Sys.vm不调用它。

源码确认官方HackController默认第3速度档，在不显示动画的FastForwardTask中每约2000条命令等待1ms。验证通过实际GUI控制器，不复制调度器、不修改默认速度、不按runner修改忙循环常数；相同wait(2000)已实测2405.447ms。该观察只适用于注明的工具模式，不能宣称任意机器/速度档都有精确墙钟保证。

最后一项运行未修改的官方SysTest/Main.jack，通过GUI按键释放进入Sys.wait，再检查结束提示。自动化采用公开记录的±25%观察容差（1500..2500ms），它是本自学验证的近似标准，不是官方私有grader阈值。最新提交必须重新跑完全部验证；最终SHA、结论、计时与图片统一存langnote课程台账和结果JSON，旧绿色运行不能替代新HEAD。

本次为公开自学验收与自动GUI输入，不冒充真人课堂操作或学校提交；GUI默认速度计时也不代表headless计时。未通过最终工作流前不能将本报告本身当作通过证据。
