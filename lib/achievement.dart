import 'package:flutter/material.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

class MyApp5 extends StatefulWidget {
  const MyApp5({super.key, required this.title});
  final String title;
  @override
  State<MyApp5> createState() => _MyHomePageState();
}

//这里是在一个页面中加了PageView，PageView可以载入更多的StatefulWidget或者StatelessWidget（也就是页面中加载其他页面作为子控件）
class _MyHomePageState extends State<MyApp5> {
  int _currentIndex = 1;
  final PageController _pageController = PageController(initialPage: 1);

  Future<void> fetchAll() async {}

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  //这修改页面4的内容
  @override
  Widget build(BuildContext context) {
    var screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: TDNavBar(title: '成就', onBack: () {}),
      body: const SingleChildScrollView(
        scrollDirection: Axis.vertical, // 水平滚动
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Column(
              children: [
                Padding(padding: EdgeInsets.all(10)),
                Card(
                  child: Row(children: [
                    Text(
                      "成就1",
                      textScaler: TextScaler.linear(1.5),
                    ),
                    Padding(
                      padding: EdgeInsets.all(10),
                      child: Padding(
                          padding: EdgeInsets.only(left: 30),
                          child: const TDSwitch(
                              isOn: true, trackOnColor: Colors.green)),
                    ),
                  ]),
                ),
                Padding(padding: EdgeInsets.all(10)),
                Card(
                  child: Row(children: [
                    Text(
                      "中途退不计次",
                      textScaler: TextScaler.linear(1.5),
                    ),
                    Padding(
                      padding: EdgeInsets.all(10),
                      child: Padding(
                        padding: EdgeInsets.only(left: 30),
                        child: const TDSwitch(
                            isOn: true, trackOnColor: Colors.green),
                      ),
                    ),
                  ]),
                ),
                Padding(padding: EdgeInsets.all(10)),
                Card(
                  child: Row(children: [
                    Text(
                      "正确的题跳过",
                      textScaler: TextScaler.linear(1.5),
                    ),
                    Padding(
                      padding: EdgeInsets.all(10),
                      child: Padding(
                          padding: EdgeInsets.only(left: 30),
                          child: const TDSwitch(
                              isOn: true, trackOnColor: Colors.green)),
                    ),
                  ]),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
