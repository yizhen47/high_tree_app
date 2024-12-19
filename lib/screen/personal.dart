import 'package:flutter/material.dart';
import 'package:flutter_application_1/tool/study_data.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import 'package:file_picker/file_picker.dart';

class PersonalScreen extends StatefulWidget {
  const PersonalScreen({super.key, required this.title});
  final String title;
  @override
  State<PersonalScreen> createState() => _InnerState();
}

//这里是在一个页面中加了PageView，PageView可以载入更多的StatefulWidget或者StatelessWidget（也就是页面中加载其他页面作为子控件）
class _InnerState extends State<PersonalScreen> {
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
        appBar: TDNavBar(title: '用户信息', onBack: () {
          setState(() {
            
          });
        }),
        body: SingleChildScrollView(
          child: Column(mainAxisAlignment: MainAxisAlignment.start, children: [
            buildSettingViews("头像", () {},
                child: const Icon(Icons.person_add_alt)),
            buildSettingViews("昵称", () {
              var ctrl =
                  TextEditingController(text: StudyData.instance.getUserName());
              showGeneralDialog(
                context: context,
                pageBuilder: (BuildContext buildContext, Animation<double> a,
                    Animation<double> b) {
                  return TDInputDialog(
                    textEditingController: ctrl,
                    rightBtn: TDDialogButtonOptions(
                        title: "确认",
                        action: () {
                          StudyData.instance.setUserName(ctrl.text);
                          Navigator.of(context).pop();
                          setState(() {});
                        }),
                    title: '昵称',
                    hintText: '请输入昵称',
                  );
                },
              );
            }, text: StudyData.instance.getUserName()),
            buildSettingViews("签名", () {
              var ctrl2 =
                  TextEditingController(text: StudyData.instance.getSign());
              showGeneralDialog(
                context: context,
                pageBuilder: (BuildContext buildContext, Animation<double> a,
                    Animation<double> b) {
                  return TDInputDialog(
                    textEditingController: ctrl2,
                    rightBtn: TDDialogButtonOptions(
                        title: "确认",
                        action: () {
                          StudyData.instance.setSign(ctrl2.text);
                          Navigator.of(context).pop();
                          setState(() {});
                        }),
                    title: '签名',
                    hintText: '请输入签名',
                  );
                },
              );
            }, text: StudyData.instance.getSign()),
          ]),
        ));
  }
}
