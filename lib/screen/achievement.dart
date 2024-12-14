import 'package:flutter/material.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
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
  Widget buildSettingViews(final String name, final GestureTapCallback onTap,
      {final child = const SizedBox(), final text = ''}) {
    return Container(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Stack(
            children: [
              Row(
                verticalDirection: VerticalDirection.down,
                children: [
                  const SizedBox(
                    width: 8,
                  ),
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                ],
              ),
              Row(
                verticalDirection: VerticalDirection.up,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    text,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child,
                  const SizedBox(width: 5),
                  const Icon(
                    Icons.chevron_right,
                    color: Colors.grey,
                    size: 22,
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  //这修改页面4的内容
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: TDNavBar(title: '用户信息', onBack: () {}),
        body: SingleChildScrollView(
          child: Column(mainAxisAlignment: MainAxisAlignment.start, children: [
            buildSettingViews("头像", () {},
                child: const Icon(Icons.person_add_alt)),
            const TDDivider(),
            buildSettingViews("姓名", () {
              Alert(
                  context: context,
                  title: "LOGIN",
                  
                  style: const AlertStyle(
                    backgroundColor: Colors.white
                  ),
                  content: const Column(
                    children: <Widget>[
                      TextField(
                        decoration: InputDecoration(
                          icon: Icon(Icons.account_circle),
                          labelText: 'Username',
                        ),
                      ),
                      TextField(
                        obscureText: true,
                        decoration: InputDecoration(
                          icon: Icon(Icons.lock),
                          labelText: 'Password',
                        ),
                      ),
                    ],
                  ),
                  buttons: [
                    DialogButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        "LOGIN",
                        style: TextStyle(color: Colors.white, fontSize: 20),
                      ),
                    )
                  ]).show();
            }, text: "张三"),
            const TDDivider(),
            buildSettingViews("签名", () {}, text: "11112222"),
            const TDDivider(),
          ]),
        ));
  }
}
