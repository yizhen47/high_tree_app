import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/screen/about.dart';
import 'package:flutter_application_1/screen/background_customization.dart';
import 'package:flutter_application_1/tool/study_data.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});
  @override
  State<SettingScreen> createState() => _InnerState();
}

//这里是在一个页面中加了PageView，PageView可以载入更多的StatefulWidget或者StatelessWidget（也就是页面中加载其他页面作为子控件）
class _InnerState extends State<SettingScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TDNavBar(title: '设置', onBack: () {}),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical, // 水平滚动
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Padding(
                    padding: EdgeInsets.fromLTRB(15, 5, 10, 5),
                    child: Text(
                      "个性化(未完成)",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                    )),
                TDCellGroup(
                  cells: [
                    TDCell(
                      leftIcon: Icons.wallpaper,
                      title: "自定义背景",
                      onClick: (_) async {
                        Navigator.push(
                          context,
                          CupertinoPageRoute(
                            builder: (context) => BackgroundCustomizationPage(),
                          ),
                        ).then((_) => setState(() {}));
                      },
                      rightIconWidget: StudyData.instance.useCustomBackground
                          ? const Icon(Icons.check, color: Colors.green)
                          : null,
                    ),
                  ],
                ),
                const Padding(
                    padding: EdgeInsets.fromLTRB(15, 5, 10, 5),
                    child: Text(
                      "其他",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                    )),
                TDCellGroup(
                  cells: [
                    TDCell(
                        leftIcon: Icons.info_outline,
                        title: "关于",
                        onClick: (_) {
                          Navigator.push(
                              context,
                              CupertinoPageRoute(
                                  builder: (context) => const AboutScreen()));
                        }),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
