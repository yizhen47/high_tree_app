import 'package:flutter/material.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';

//静态页面：创建完毕后就不能更改，没有setState这个刷新控件的函数
class QuestionScreen extends StatelessWidget {
  final List<Card> cards = [
    Card(
      color: Colors.white,
      elevation: 4,
      child: SingleChildScrollView(
          child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(
              width: double.infinity,
            ),
            Card(
              color: Colors.blueAccent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              child: const Padding(
                padding: EdgeInsets.fromLTRB(6, 2, 6, 2),
                child: Text(
                  '知识点: 一元微分方程',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ),
            const Text(
              '''小明会飞，那么小明的爸爸会不会？
''',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 94, 94, 94),
              ),
            ),
            const Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              verticalDirection: VerticalDirection.down,
              children: [
                Text(
                  '''可以参考以下选项''',
                  style: TextStyle(
                    fontSize: 14,
                    // fontStyle: FontStyle.italic,
                    color: Colors.grey,
                    fontFamily: 'Times New Roman',
                  ),
                ),
                Row(
                  children: [
                    Text(
                      'A ',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        fontFamily: 'Times New Roman',
                      ),
                    ),
                    SizedBox(
                      width: 10,
                    ),
                    Text(
                      "不知道",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        fontFamily: 'Times New Roman',
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      'B ',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        fontFamily: 'Times New Roman',
                      ),
                    ),
                    SizedBox(
                      width: 10,
                    ),
                    Text(
                      "TD,以后不再显示",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        fontFamily: 'Times New Roman',
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      'C ',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        fontFamily: 'Times New Roman',
                      ),
                    ),
                    SizedBox(
                      width: 10,
                    ),
                    Text(
                      "钝角",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        fontFamily: 'Times New Roman',
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(
              height: 30,
              child: Container(
                alignment: Alignment.center,
                child: const TDDivider(
                  color: Colors.black38,
                ),
              ),
            ),
            const Text(
              "解析",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
                fontFamily: 'Times New Roman',
              ),
            ),
            const Text(
              '''这个问题实际上是一个逻辑推理题，涉及遗传学和生物学的基本原理。从字面上看，“小明会飞”这个前提条件本身并不符合人类的生理特征，因为人类没有飞行的能力。因此，这个问题可以被解读为一个假设性的或寓言性质的问题。

### 分析角度一：生物学与遗传学

1. **遗传特性**：在生物学上，如果“会飞”是一种可遗传的特性，那么这种特性必须是通过基因传递的。然而，人类并没有飞行的基因。即使假设“会飞”是一种突变，这种突变也必须是显性的，并且能够稳定地遗传给后代。
2. **环境因素**：假设“会飞”是由于某种特殊环境或技术手段（如飞行器）实现的，那么这种能力并不是遗传的，而是外部条件导致的。在这种情况下，小明的爸爸是否能飞取决于他是否具备相同的外部条件。

### 分析角度二：假设性问题

1. **假设性情境**：如果将“小明会飞”视为一个假设性的情境，那么我们需要考虑这个假设的背景。例如，如果这是一个科幻故事中的设定，那么在这个设定下，小明的爸爸可能会有类似的能力，具体取决于故事的背景设定。
2. **逻辑推理**：如果我们假设“会飞”是一种超自然的能力，那么这种能力的来源可以是多种多样的，包括遗传、修炼、外星科技等。在这种情况下，小明的爸爸是否会飞取决于这种能力的传递机制。

### 结论

综上所述，从生物学和遗传学的角度来看，如果“会飞”是一种不可遗传的外部条件或超自然能力，那么小明的爸爸不一定具备这种能力。如果“会飞”是一种可遗传的基因突变，那么小明的爸爸有可能具备这种能力，但这需要更多的背景信息来确定。

最终，这个问题的答案取决于“会飞”这一前提的具体背景和设定。如果没有更多的信息，我们无法得出一个确切的结论。
''',
              style: TextStyle(
                fontSize: 14,
                fontFamily: 'Times New Roman',
              ),
            ),
          ],
        ),
      )),
    ),
    const Card(
      color: Colors.white,
      elevation: 10,
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            color: Colors.blueAccent,
            child: Padding(
              padding: EdgeInsets.fromLTRB(6, 2, 6, 2),
              child: Text(
                '知识点: 一元微分方程',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
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
                    Row(
                      children: [
                        Text('''
的内容''',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(255, 180, 180, 180),
                            )),
                      ],
                    ),
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
            ],
          )
        ],
      ),
    ),
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
