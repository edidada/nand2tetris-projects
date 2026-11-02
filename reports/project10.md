# Nand2Tetris Project 10

实现Jack词法分析和递归下降语法分析，输出token XML及完整语法树XML。支持注释、字符串、XML特殊字符转义、类/子程序/变量声明、全部五类语句、表达式、数组、方法调用与一元运算。字符串内的//与/*不作为注释；缺失引号、注释结束符、超范围整数、非法语法或类后多余token报错。

独立project10.yml对官方ArrayTest、ExpressionLessSquare、Square中的7份Jack分别比较token和syntax两类XML，共14份原参考文件。只忽略每行缩进和空行，不忽略token内部内容或结构；原Jack/XML均未修改。另测试注释/字符串/XML转义与非法输入。CLI写.generated.xml/.generatedT.xml，保留原参考输出。只在Actions执行，不在本地运行分析器。Project09游戏尚未完成，Project10仅语法分析，不声称实现后续代码生成。
