import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/screen/question.dart';
import 'package:simple_ripple_animation/simple_ripple_animation.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import 'package:flutter_application_1/screen/setting.dart';
import 'package:flutter_application_1/screen/achievement.dart';

//静态页面：创建完毕后就不能更改，没有setState这个刷新控件的函数
class QuestionScreen extends StatelessWidget {
  final List<Container> cards = [
    Container(
        alignment: Alignment.center,
        color: const Color.fromARGB(255, 247, 251, 255),
        // ignore: prefer_const_constructors
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
child: Text(
              '第x题',
              style: TextStyle(fontSize: 25),
            ),
            ),
           
            const Text(
              '''1.小明会飞，那么小明的爸爸会不会？
1.小明会飞，那么小明的爸爸会不会？
1.小明会飞，那么小明的爸爸会不会？
''',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 94, 94, 94),
                fontFamily: 'Times New Roman',
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              verticalDirection: VerticalDirection.up,
              children: const [
                Row(
                  children: [
                    Text('''
A
B
C
D''',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 255, 191, 191),
                        )),
                 
                    Column(children: [
                      Row(children: [
                     



                        
Text('''
的内容''',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 180, 180, 180),
                          )),],),


                      Text('''
的内容''',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 180, 180, 180),
                          )),
                      Text('''
的内容''',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 180, 180, 180),
                          )),
                      Text('''
的内容''',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 180, 180, 180),
                          )),
                    ])
                  ],
                ),
                Card(
                  color: Color.fromARGB(32, 255, 255, 255),
                  child: Row(
                    children: [
                      Text(
                        '知识点',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      Padding(
                        padding: EdgeInsets.only(left: 20),
                        child: Text(
                          '知识点',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      )
                    ],
                  ),
                ),
              ],
            )
          ],
        )),
    Container(
      alignment: Alignment.center,
      color: const Color.fromARGB(255, 255, 248, 248),
      child: const Text('2'),
    ),
    Container(
      alignment: Alignment.center,
      color: const Color.fromARGB(255, 248, 255, 252),
      child: const Text('3'),
    )
  ];

  QuestionScreen({super.key});

  //这修改页面2的内容
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: TDNavBar(title: '', onBack: () {}),
        body: Column(
          children: [
            Flexible(
              child: CardSwiper(
                cardsCount: cards.length,
                cardBuilder:
                    (context, index, percentThresholdX, percentThresholdY) =>
                        cards[index],
              ),
            ),
            const Stack(children: <Widget>[
              Padding(
                padding: EdgeInsets.only(bottom: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Expanded(child: Icon(Icons.playlist_add_check)),
                    Expanded(child: Icon(Icons.notes)),
                    Expanded(child: Icon(Icons.quiz_outlined))
                  ],
                ),
              ),
            ]),
          ],
        ));
  }
}
