import 'package:flutter/material.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import 'package:yako_theme_switch/yako_theme_switch.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});
  @override
  State<AboutScreen> createState() => _InnerState();
}

//这里是在一个页面中加了PageView，PageView可以载入更多的StatefulWidget或者StatelessWidget（也就是页面中加载其他页面作为子控件）
class _InnerState extends State<AboutScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TDNavBar(
        backgroundColor: Theme.of(context).primaryColor,
        title: '',
         onBack: () {}
      ),
      body: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).primaryColor,
                          Theme.of(context).cardColor,
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
                TDCellGroup(
                  theme: TDCellGroupTheme.cardTheme,
                  cells: [
                    TDCell(
                        leftIcon: Icons.verified_user_outlined,
                        title: "当前版本",
                        note: "1.0.0",
                        onClick: (_) {}),
                    TDCell(
                        leftIcon: Icons.arrow_circle_up_rounded,
                        title: "版本更新",
                        arrow: true,
                        onClick: (_) {}),
                    TDCell(
                        leftIcon: Icons.groups_2_sharp,
                        title: "联系我们",
                        arrow: true,
                        onClick: (_) {}),
                  ],
                )
              ],
            ),
          ],
        ),
      );
  }
}
