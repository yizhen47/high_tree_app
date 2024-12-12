import 'package:flutter/material.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import 'package:yako_theme_switch/yako_theme_switch.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key, required this.title});
  final String title;
  @override
  State<SettingScreen> createState() => _InnerState();
}

//这里是在一个页面中加了PageView，PageView可以载入更多的StatefulWidget或者StatelessWidget（也就是页面中加载其他页面作为子控件）
class _InnerState extends State<SettingScreen> {
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
      appBar: TDNavBar(title: '设置', onBack: () {}),
      body:
          // ignore: prefer_const_literals_to_create_immutables

          SingleChildScrollView(
        scrollDirection: Axis.vertical, // 水平滚动
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.blueAccent,
                          Colors.white,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    height: 200),
              ],
            ),
            Column(
              children: <Widget>[
                const Padding(padding: EdgeInsets.all(10)),
                const Padding(padding: EdgeInsets.all(10)),
                Card(
                  color: Colors.white,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: Stack(
                          children: [
                            const Text(
                              "正确的题跳过",
                              textScaler: TextScaler.linear(1.2),
                              selectionColor: Color(0x00000000),
                            ),
                            Row(
                              verticalDirection: VerticalDirection.down,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                YakoThemeSwitch(
                                  onChanged: ({bool? changed}) {},
                                  width: 50,
                                  enabledBackgroundColor: Colors.blue,
                                  disabledBackgroundColor:
                                      const Color.fromARGB(255, 176, 176, 180),
                                  disabledToggleColor: Colors.white,
                                  animationDuration:
                                      const Duration(milliseconds: 300),
                                  enabledToggleBorderRadius: 8,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 5, 0),
                        child: SizedBox(
                          height: 2,
                          child: Container(
                            alignment: Alignment.center,
                            child: const TDDivider(),
                          ),
                        ),
                      ),
                      Padding(
                          padding: const EdgeInsets.all(15),
                          child: Stack(
                            children: [
                              const Text(
                                "正确的题跳过",
                                textScaler: TextScaler.linear(1.2),
                                selectionColor: Color(0x00000000),
                              ),
                              Row(
                                verticalDirection: VerticalDirection.down,
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  YakoThemeSwitch(
                                    onChanged: ({bool? changed}) {},
                                    width: 50,
                                    enabledBackgroundColor:
                                        const Color.fromARGB(
                                            255, 105, 134, 159),
                                    disabledBackgroundColor:
                                        const Color.fromARGB(
                                            255, 215, 219, 231),
                                    disabledToggleColor: Colors.white,
                                    animationDuration:
                                        const Duration(milliseconds: 300),
                                    enabledToggleBorderRadius: 8,
                                  ),
                                ],
                              ),
                              const Row(
                                  verticalDirection: VerticalDirection.down,
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: []),
                            ],
                          )),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 5, 0),
                        child: SizedBox(
                          height: 2,
                          child: Container(
                            alignment: Alignment.center,
                            child: const TDDivider(),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}
