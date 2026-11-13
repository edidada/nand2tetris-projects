# Nand2Tetris Project 11

实现Jack到VM代码生成，复用Project10词法/语法树。维护类级static/field和子程序argument/local符号表，允许局部遮蔽类变量，拒绝同作用域重名和未知变量。constructor按字段数分配对象；method接收隐式this；处理数组左右值、分支/循环、方法/静态函数调用、字符串构造、乘除OS调用及void返回。

独立project11.yml编译原Project11全部Jack示例，并使用官方VM Emulator执行由本编译器编译的原Project12 MathTest、MemoryTest、ArrayTest的Main.jack，原tst/cmp不变，OS调用由官方内置实现提供。这些测试用于编译器验收，不声称本人已实现Project12 OS。另有自编Jack集成测试检查对象、递归、静态状态、数组嵌套调用、字符串首尾空格及局部遮蔽。

初期交互式Square/Pong/Average只编译、Seven屏幕未验收；该历史缺口由下面六示例运行验收补齐。本地不执行编译器、VM或模拟器。

## 六个原始示例实际运行验收（2026-11-14）

独立project11.yml新增scripts/verify_project11_apps.sh。固定官方模拟器327b7e4337b31efb815e1c1e3913c0efd299bcf2，完整Jack OS取自已验收Project12提交a967e8977f4479414aa077f1bbbf340157051018，所有应用和OS均由本分支当前编译器在Actions重新编译。六个示例Jack源码逐一与官方基线5bd2184edfd4945ff8a28eb0b237c12cdbe9e498比较，未修改测试程序来迁就编译器。

| 程序 | 运行与断言 |
| --- | --- |
| Seven | 实际屏幕像素按OS字体解码为7，保留截图 |
| ConvertToBin | 0/1/2/255/256/32767/-32768/-1/-12345/21845十个输入，160个输出位逐项核对，无-1遗留 |
| Square | 系统方向键四向移动像素包围盒断言，X增至32、Z减回30，Q退出进入Sys.halt |
| Average | 系统按键输入数量3及10/20/30，屏幕解码The average is 20 |
| Pong | 系统左右箭头令球拍像素位置分别减少/增加；Esc显示Game Over；独立长跑实际接球Score:1后自然漏球Game Over |
| ComplexArrays | 屏幕解码五行原expected/actual，逐项为5/40/0/77/110 |

共22次OS Robot按下/释放经官方Swing KeyboardComponent和Keyboard监听器输入，无直接写键盘RAM；ConvertToBin按题目约定仅设置输入RAM[8000]。官方CPU由脚本步进，GUI键盘由Xvfb承载，不宣称真人课堂或私有评分。所有屏幕原字、PNG、解码文本和application-results.json作为工件保存，永久证据由langnote台账归档。首次六程序成功运行https://github.com/edidada/nand2tetris-projects/actions/runs/43458042529；最终提交须查看对应同分支运行。

原3个模块VM测试及13项集成RAM结果继续回归。本地只编辑与静态检查，不编译或运行实验；新增shell脚本内嵌临时JShell/字体解码代码，没有新增Python源文件。Java仅为官方模拟器验证工具。
归档复核发现旧回归管道未设置pipefail，子脚本失败可被tee的成功掩盖；已修复工作流，并让四项原回归在隔离目录加载同一固定完整OS，保留所有原tst/cmp与13项集成期望，失败日志直接输出。先前绿色状态不能单独证明旧四项回归通过；最终验收须同时出现ORIGINAL_REGRESSIONS_OK和六应用/屏幕断言成功。