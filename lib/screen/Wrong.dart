import 'package:flutter/material.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import 'package:yako_theme_switch/yako_theme_switch.dart';

class WrongScreen extends StatefulWidget {
  const WrongScreen({super.key, required this.title});
  final String title;
  @override
  State<WrongScreen> createState() => _InnerState();
}

//这里是在一个页面中加了PageView，PageView可以载入更多的StatefulWidget或者StatelessWidget（也就是页面中加载其他页面作为子控件）
class _InnerState extends State<WrongScreen> {
  
  //这修改页面4的内容
  @override
  Widget build(BuildContext context) {
    var screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: TDNavBar(title: '疑难题集', onBack: () {}),
      body: const SingleChildScrollView(
        scrollDirection: Axis.vertical, //
      ),
    );
  }
}
