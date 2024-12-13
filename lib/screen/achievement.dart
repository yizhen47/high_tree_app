import 'package:flutter/material.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import 'package:file_picker/file_picker.dart';

class AchievementScreen extends StatefulWidget {
  const AchievementScreen({super.key, required this.title});
  final String title;
  @override
  State<AchievementScreen> createState() => _InnerState();
}

//这里是在一个页面中加了PageView，PageView可以载入更多的StatefulWidget或者StatelessWidget（也就是页面中加载其他页面作为子控件）
class _InnerState extends State<AchievementScreen> {

  //这修改页面4的内容
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TDNavBar(title: '用户信息', onBack: () {}),
      body: const SingleChildScrollView(
        scrollDirection: Axis.vertical, // 水平滚动
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Column(
              children: [
                Padding(padding: EdgeInsets.all(10)),
                Text(
                  '请输入昵称：',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.grey,
                  ),
                ),
                TextField(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Enter a search term',
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
