# Project09：Sokoban 推箱子

## 目标与设计

根据官方 Project09 的交互应用要求，编写独立 Jack 应用，不修改原始 Square 等示例。Board 负责 8×8 仓库、目标、箱子、玩家位置和计数；Main 负责按键按下/释放及生命周期。使用固定 Project12 已验收提交中的完整 Jack OS 服务。

方向键移动，每次按下只移动一格；R 重新开始；Q 退出。实心边界不可穿越，带叉方块为箱子，圆环为目标，小圆为玩家。两个箱子均推到目标后显示 SOLVED，停止方向移动，仍可重置或退出。

初始玩家 (2,2)，箱子 (3,2)/(3,4)，目标 (4,2)/(4,4)。一种解法为右、下、左、下、右。阻挡时不改变状态或计数；推箱之前同时检查后方墙壁与其他箱子。

## 验证状态

独立工作流 .github/workflows/project09.yml 调用两个 shell 脚本。19 项 RAM 断言覆盖初始状态、墙壁阻挡、完整解题、顶墙推箱失败的原子性和重置。8 次 OS Robot 按下/释放经过官方 Swing KeyboardComponent 与 Keyboard 监听器，没有直接写键盘 RAM；检查推箱像素、长按不重复、胜利后锁定移动、重置画面逐字一致和退出画面。保存 initial/push/solved/restart/quit 五张 512×256 屏幕图。首个完整成功运行 https://github.com/edidada/nand2tetris-projects/actions/runs/43456336301；随后将状态栏下移一行，最终提交需由对应的新运行确认。所有编译及运行放在 GitHub Actions，本地仅编辑和静态检查。Java 只作为官方模拟器的工具运行时。

官方要求：https://www.nand2tetris.org/project09

## 固定依赖与验收范围

官方源码基线 5bd2184edfd4945ff8a28eb0b237c12cdbe9e498；编译器 8c7bdcac1ddcb96ade280375e6f4221ace25eb3e；Jack OS a967e8977f4479414aa077f1bbbf340157051018；官方模拟器 327b7e4337b31efb815e1c1e3913c0efd299bcf2。运行时提取既有编译器，不新增 Python 源文件。完整 OS 在 CI 编译并加载，避免源码版模拟器缺少内置 init 入口。GUI 测试在 Xvfb 中生成系统键盘事件，VM 由脚本步进；不宣称经过真人课堂评阅或 Coursera 提交。应用是一关的完整基础版本，符合 Project09 允许的交互应用范围。

早期失败包括模拟器入口不全、OS 初始化步数不足、测试解法路线错误及绘图尚未完成就比较长按画面；最终使用完整 OS，并等候 Sys.wait 输入阶段再比较帧，保留原判胜和状态断言。