# Nand2Tetris Project12：Jack OS

官方规范 https://www.nand2tetris.org/project12 ，最新官方 projects main 为 5bd2184edfd4945ff8a28eb0b237c12cdbe9e498。独立 edidada/project12；只实现 Jack 代码，Java 仅运行官方模拟器。未在本地编译或运行实验。

八个类覆盖原始 API：Math 使用固定16轮乘法、负数域倍增除法（避免 -32768 取绝对值溢出）、奇数递减平方根；Memory 使用地址有序空闲链表、首次适配、拆分及前后相邻块合并；Array 转发分配释放；String 支持零容量、负数域数字解析、最小整数输出及容量检查。Screen 使用位掩码矩形填充、Bresenham 线与水平扫描圆；Output 保留原始字体表，按屏幕字节保留相邻字符，维护23×64光标；Keyboard 读取内存映射键盘并等待按下释放；Sys 初始化、等待、错误输出和停机。

独立工作流先执行未修改的原始 Math/Memory/Array 比较测试，再编译所有模块测试及完整 Pong。复用固定 SHA 的 Project11 编译器，模拟器固定官方提交。编译成功不等于交互验收：其余模块运行断言、内存回收压力、屏幕快照、键盘输入、Sys.wait实际计时及完整Pong交互仍需补齐；当前不得计为Project12完成。

追加26项跨模块断言：保留13项已通过结果，增加最大正数字符串、零与首个非数字截断，正反向45度线、半径2实心圆以及跨word白色清除。通过显式RAM值比较验证位布局，原始三项测试仍不修改。最新提交需远端重新验收；完整官方图形/交互验收仍待。

官方ScreenTest、OutputTest、StringTest原始Main现增加完整运行，每项执行2000万VM步后导出8192个屏幕word与512×256 PNG。图像用于检查原始场景显示，空屏直接失败；非空屏本身不代表图形正确，必须查看图片。键盘/Sys.wait/Pong交互仍待。

Pong原始Main/PongGame/Ball/Bat源码保持不变，新增独立启动的初始、左移、右移、Esc退出四个运行场景，完整加载本项目八个OS类；导出屏幕并根据第229行像素断言球拍先左后右，Esc后像素文字必须出现Game Over。脚本输入不是人工GUI操作；Sys.wait真实2秒计时仍待，不因有运行图就宣称完整验收。
