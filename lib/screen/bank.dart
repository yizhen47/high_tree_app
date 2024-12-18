import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/tool/question_bank.dart';
import 'package:flutter_application_1/tool/study_data.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

class BankScreen extends StatefulWidget {
  const BankScreen({super.key, required this.title});
  final String title;
  @override
  State<BankScreen> createState() => _InnerState();
}

//这里是在一个页面中加了PageView，PageView可以载入更多的StatefulWidget或者StatelessWidget（也就是页面中加载其他页面作为子控件）
class _InnerState extends State<BankScreen> {
  List<String> selectIds = QuestionBank.getAllLoadedQuestionBankIds();
  List<String> lastSelectIds = QuestionBank.getAllLoadedQuestionBankIds();
  //这修改页面2的内容
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TDNavBar(title: '题库选择', onBack: () {}),
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
            color: Colors.white,
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
                      QuestionBank.importQuestionBank(
                          File(fromFilePath.files.single.path!));
                      TDToast.showSuccess('导入完毕', context: context);
                      setState(() {});
                    },
                    child: const Padding(
                      padding: EdgeInsets.only(bottom: 15, top: 15),
                      child: Icon(
                        Icons.add_box_outlined,
                        color: Colors.blueAccent,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      List<Future> futures = [];
                      for (var id in lastSelectIds) {
                        if (!selectIds.contains(id)) {
                          futures.add(
                              (await QuestionBank.getQuestionBankById(id))
                                  .removeFromData());
                        }
                      }
                      for (var id in selectIds) {
                        if (!lastSelectIds.contains(id)) {
                          futures.add(
                              (await QuestionBank.getQuestionBankById(id))
                                  .loadIntoData());
                        }
                      }
                      await Future.wait(futures);
                      if (StudyData.instance.getStudyType() ==
                              StudyType.studyMode &&
                          selectIds.length > 1) {
                        StudyData.instance.setStudyType(StudyType.testMode);
                      }
                      StudyData.instance.setStudySection(null);
                      TDToast.showSuccess('加载完毕', context: context);
                    },
                    child: const Padding(
                      padding: EdgeInsets.only(bottom: 15, top: 15),
                      child: Icon(
                        Icons.save_as_outlined,
                        color: Colors.blueAccent,
                      ),
                    ),
                  ),
                ),
                const Expanded(
                  child: InkWell(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 15, top: 15),
                      child: Icon(
                        Icons.quiz_outlined,
                        color: Colors.blueAccent,
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
}
