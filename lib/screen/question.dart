import 'package:flutter/material.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';



//静态页面：创建完毕后就不能更改，没有setState这个刷新控件的函数
class QuestionScreen extends StatelessWidget {
  const QuestionScreen({super.key});

  //这修改页面2的内容
  @override
  Widget build(BuildContext context) {
    var screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: TDNavBar(
          title: ' ',
          onBack: () {
            
          }),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical, // 水平滚动
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            GestureDetector(
                onHorizontalDragUpdate: (details) {
                  if (details.delta.dx > 0) {
                    print('Right Swipe');
                  } else if (details.delta.dx < 0) {
                    print('Left Swipe');
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Card(
                    elevation: 5.0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(50.0),
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text(
                              '''题目
1．已知函数 ．
（1）当 ， 时，求函数值的改变量与自变量的比 ；
（2）当 ， 时，求函数值的改变量与自变量的比 ；
（3）利用导数的定义求 ．''',
                              textScaler: TextScaler.linear(1.6),
                              softWrap: true,
                            ),
                            Text(
                              '知识点',
                              textScaler: TextScaler.linear(1.2),
                            ),
                          ]),
                    ),
                  ),
                ))
          ],
        ),
      ),
    );
  }
}
