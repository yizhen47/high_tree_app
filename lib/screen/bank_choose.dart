import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/screen/mode.dart';
import 'package:flutter_application_1/tool/question_bank.dart';
import 'package:flutter_application_1/tool/question_controller.dart';
import 'package:flutter_application_1/tool/study_data.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

class BankChooseScreen extends StatefulWidget {
  const BankChooseScreen({super.key});
  @override
  State<BankChooseScreen> createState() => _InnerState();
}

//这里是在一个页面中加了PageView，PageView可以载入更多的StatefulWidget或者StatelessWidget（也就是页面中加载其他页面作为子控件）
class _InnerState extends State<BankChooseScreen> {
  List<String> selectIds = QuestionBank.getAllLoadedQuestionBankIds();
  //这修改页面2的内容
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TDNavBar(
        title: '题库选择',
        onBack: () {},
        rightBarItems: [
          TDNavBarItem(
            iconWidget: InkWell(
              onTap: () async {
                if (selectIds.isNotEmpty) {
                  TDToast.showLoadingWithoutText(context: context);
                  await saveLoadedOption();
                  TDToast.dismissLoading();
                  Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ModeScreen(title: '')),
                      (route) => route.isFirst);
                } else {
                  TDToast.showWarning('题库未选择',
                      direction: IconTextDirection.vertical, context: context);
                }
              },
              child: TDTag('下一项',
                  size: TDTagSize.large,
                  theme: selectIds.isNotEmpty
                      ? TDTagTheme.primary
                      : TDTagTheme.defaultTheme,
                  forceVerticalCenter: false,
                  isOutline: false),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Flexible(
            fit: FlexFit.tight,
            child: FutureBuilder(
              future: QuestionBank.getAllImportedQuestionBanks(),
              builder: (context, snapshot) {
                // 请求已结束
                if (snapshot.connectionState == ConnectionState.done) {
                  if (snapshot.hasError) {
                    // 请求失败，显示错误
                    return Text(
                        "Error: ${snapshot.error}" '${snapshot.stackTrace}');
                  } else {
                    return Column(
                      children: [
                        const SizedBox(
                          height: 20,
                        ),
                        TDCheckboxGroupContainer(
                          selectIds: selectIds,
                          cardMode: true,
                          direction: Axis.vertical,
                          // maxSelected: 1,
                          directionalTdCheckboxes:
                              List.from((snapshot.data!.map((e) {
                            return TDCheckbox(
                              id: e.id,
                              title: e.displayName,
                              titleMaxLine: 2,
                              subTitleMaxLine: 2,
                              subTitle: e.id,
                              cardMode: true,
                            );
                          }))),
                          onCheckBoxGroupChange: (List<String> selectIds) {
                            this.selectIds = selectIds;
                            setState(() {
                              
                            });
                          },
                        ),
                      ],
                    );
                  }
                } else {
                  return const Center(
                    child: TDLoading(
                      size: TDLoadingSize.large,
                      icon: TDLoadingIcon.circle,
                      text: '加载中…',
                      axis: Axis.horizontal,
                    ),
                  );
                }
              },
            ),
          ),
          Container(
            color: Theme.of(context).cardColor,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      var fromFilePath = await FilePicker.platform.pickFiles(
                          allowMultiple: false,
                          type: FileType.custom,
                          allowedExtensions: ["qset", "zip", "rar", "7z"]);
                      if (fromFilePath == null) return;
                      await QuestionBank.importQuestionBank(
                          File(fromFilePath.files.single.path!));
                      TDToast.showSuccess('导入完毕', context: context);
                      setState(() {});
                    },
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 15, top: 15),
                      child: Icon(
                        Icons.add_box_outlined,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      await saveLoadedOption();
                      TDToast.showSuccess('加载完毕', context: context);
                      setState(() {});
                    },
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 15, top: 15),
                      child: Icon(
                        Icons.save_as_outlined,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      showGeneralDialog(
                        context: context,
                        pageBuilder: (BuildContext buildContext,
                            Animation<double> animation,
                            Animation<double> secondaryAnimation) {
                          return const TDConfirmDialog(
                            title: "帮助",
                            content:
                                '''左边第一个按钮用于导入题库qset文件，第二个按钮用于保存已导入的题库，直接点击下一步也会进行保存操作''',
                          );
                        },
                      );
                    },
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 15, top: 15),
                      child: Icon(
                        Icons.quiz_outlined,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> saveLoadedOption() async {
    List<Future> futures = [];
    var lastSelectIds = QuestionBank.getAllLoadedQuestionBankIds();
    for (var id in lastSelectIds) {
      if (!selectIds.contains(id)) {
        futures
            .add((await QuestionBank.getQuestionBankById(id)).removeFromData());
      }
    }
    for (var id in selectIds) {
      if (!lastSelectIds.contains(id)) {
        futures
            .add((await QuestionBank.getQuestionBankById(id)).loadIntoData());
      }
    }
    await Future.wait(futures);
    if (StudyData.instance.getStudyType() == StudyType.studyMode &&
        selectIds.length > 1) {
      StudyData.instance.setStudyType(StudyType.testMode);
    }
    StudyData.instance.setStudySection(null);

    QuestionController.updateInstance();

  }
}
