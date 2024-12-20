import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/tool/study_data.dart';
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
  //这修改页面4的内容
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TDNavBar(
          title: '用户信息',
          onBack: () {
            setState(() {});
          }),
      body: SingleChildScrollView(
        child: TDCellGroup(
          cells: [
            TDCell(
              arrow: true,
              title: '头像',
              onClick: (_) async {
                FilePickerResult? result = await FilePicker.platform.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: ['jpg', 'png'],
                );
                if (result != null) {
                  if (result.files.single.path != null) {
                    await StudyData.instance
                        .setAvatar(result.files.single.path!);
                  }
                  setState(() {});
                }
              },
              rightIconWidget: ClipRRect(
                borderRadius: BorderRadius.circular(25.0),
                child: Image(
                  image: StudyData.instance.getAvatar() == null
                      ? const AssetImage("assets/logo.png")
                      : FileImage(File(StudyData.instance.getAvatar()!)),
                  width: 50,
                  height: 50,
                ),
              ),
            ),
            TDCell(
              arrow: true,
              title: '昵称',
              note: StudyData.instance.getUserName(),
              onClick: (_) {
                var ctrl = TextEditingController(
                    text: StudyData.instance.getUserName());
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
              },
            ),
            TDCell(
              arrow: true,
              title: '签名',
              note: StudyData.instance.getSign(),
              onClick: (_) {
                var ctrl =
                    TextEditingController(text: StudyData.instance.getSign());
                showGeneralDialog(
                  context: context,
                  pageBuilder: (BuildContext buildContext, Animation<double> a,
                      Animation<double> b) {
                    return TDInputDialog(
                      textEditingController: ctrl,
                      rightBtn: TDDialogButtonOptions(
                          title: "确认",
                          action: () {
                            StudyData.instance.setSign(ctrl.text);
                            Navigator.of(context).pop();
                            setState(() {});
                          }),
                      title: '签名',
                      hintText: '请输入签名',
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
