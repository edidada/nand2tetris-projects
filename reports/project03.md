# Nand2Tetris Project 03 实验报告

分支edidada/project03，实现Bit、Register、RAM8、RAM64、RAM512、RAM4K、RAM16K、PC。以唯一允许的时序原语DFF保存位；Mux决定加载新值或保留当前值；16位Register并联16个Bit。RAM以高地址位解复用load、低位选择块内地址，再复用选中块输出；层级地址切分分别为3、6、9、12位，RAM16K顶层为四个RAM4K。

PC由Inc16、三层Mux16与Register组成，reset优先于load，load优先于inc，其余保持；只有时钟推进才更新保存值。所有本实验HDL均实现PARTS，不使用BUILTIN替代。官方b目录按课程框架使用提供的基础芯片，a目录的自写基本时序芯片单独验收。

独立project03.yml复用固定SHA官方模拟器及JDK17，递归运行a/b目录八份原.tst并逐项要求原.cmp比较成功。仅Actions编译和执行，未向课程平台提交。其他Project不据此认定完成。
