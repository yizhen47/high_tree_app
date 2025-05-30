import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/tool/question/question_bank.dart';
import 'package:flutter_application_1/tool/question/question_controller.dart';
import 'package:flutter_application_1/tool/study_data.dart';
import 'package:flutter_application_1/tool/question/wrong_question_book.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

class BankManagerScreen extends StatefulWidget {
  const BankManagerScreen({super.key, required this.title});
  final String title;
  @override
  State<BankManagerScreen> createState() => _InnerState();
}

//这里是在一个页面中加了PageView，PageView可以载入更多的StatefulWidget或者StatelessWidget（也就是页面中加载其他页面作为子控件）
class _InnerState extends State<BankManagerScreen> {
  List<String> selectIds = QuestionBank.getAllLoadedQuestionBankIds();
  List<String> lastSelectIds = QuestionBank.getAllLoadedQuestionBankIds();
  //这修改页面2的内容
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TDNavBar(
        title: '题库设置',
        onBack: () {},
      ),
      body: Column(
        children: [
          Flexible(
              fit: FlexFit.tight,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(15),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "当前状态",
                            style: TextStyle(
                                fontSize: 18,
                                color: Colors.black,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    TDSwipeCell(
                      groupTag: 'test',
                      left: TDSwipeCellPanel(
                        children: [
                          TDSwipeCellAction(
                            flex: 60,
                            backgroundColor: TDTheme.of(context).warningColor4,
                            label: '导出',
                            onPressed: (context) async {
                              if (WrongQuestionBook.instance
                                      .getWrongQuestionIds()
                                      .length <=
                                  10) {
                                TDToast.showWarning('错题数量太少', context: context);
                                return;
                              }
                              var saveFilePath =
                                  await FilePicker.platform.saveFile(
                                dialogTitle: "请选择保存路径",
                                fileName: "custom.qset",
                              );
                              if (saveFilePath == null) return;
                              WrongQuestionBook.instance
                                  .exportWrongQuestion(saveFilePath);
                            },
                          ),
                        ],
                      ),
                      right: TDSwipeCellPanel(
                        children: [
                          TDSwipeCellAction(
                            flex: 60,
                            backgroundColor: TDTheme.of(context).errorColor6,
                            label: '清空',
                            onPressed: (_) {
                              showGeneralDialog(
                                context: context,
                                pageBuilder: (BuildContext buildContext,
                                    Animation<double> animation,
                                    Animation<double> secondaryAnimation) {
                                  return TDAlertDialog(
                                      title: "清空错题本",
                                      content: "确定清空错题本吗？清空的错题将无法恢复！",
                                      rightBtnAction: () {
                                        WrongQuestionBook.instance
                                            .clearWrongQuestion();
                                        Navigator.of(context).pop();
                                        setState(() {});
                                      });
                                },
                              );
                            },
                          ),
                        ],
                      ),
                      cell: TDCell(
                          title: '我的错题本',
                          note: '错题存放',
                          description:
                              '错题数量: ${WrongQuestionBook.instance.getWrongQuestionIds().length}'),
                    ),
                    const Padding(
                      padding: EdgeInsets.all(15),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "题库管理",
                            style: TextStyle(
                                fontSize: 18,
                                color: Colors.black,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    FutureBuilder(
                      future: QuestionBank.getAllImportedQuestionBanks(),
                      builder: (context, snapshot) {
                        // 请求已结束
                        if (snapshot.connectionState == ConnectionState.done) {
                          if (snapshot.hasError) {
                            // 请求失败，显示错误
                            return Text("Error: ${snapshot.error}"
                                '${snapshot.stackTrace}');
                          } else {
                            // 屏幕宽度
                            var screenWidth = MediaQuery.of(context).size.width;
                            var list = List.from(snapshot.data!.map((action) {
                              return {
                                'id': action.id,
                                'title': action.displayName,
                                "note": action.version,
                                'description': action.id,
                              };
                            }));

                            final cellLength = ValueNotifier<int>(list.length);
                            return ValueListenableBuilder(
                              valueListenable: cellLength,
                              builder:
                                  (BuildContext context, value, Widget? child) {
                                return TDCellGroup(
                                  cells: list
                                      .map((e) => TDCell(
                                          title: e['title'],
                                          note: '题库版本${(e['note'])}',
                                          description: e['description']))
                                      .toList(),
                                  builder: (context, cell, index) {
                                    return TDSwipeCell(
                                      slidableKey: ValueKey(list[index]['id']),
                                      groupTag: 'test',
                                      onChange: (direction, open) {},
                                      left: TDSwipeCellPanel(
                                        extentRatio: 60 / screenWidth,
                                        children: [
                                          TDSwipeCellAction(
                                            flex: 60,
                                            backgroundColor: TDTheme.of(context)
                                                .warningColor4,
                                            label: '编辑',
                                            onPressed: (context) {},
                                          ),
                                        ],
                                      ),
                                      right: TDSwipeCellPanel(
                                        extentRatio: 60 / screenWidth,
                                        children: [
                                          TDSwipeCellAction(
                                            backgroundColor:
                                                TDTheme.of(context).errorColor6,
                                            label: '删除',
                                            onPressed: (_) {
                                              showGeneralDialog(
                                                context: context,
                                                pageBuilder: (BuildContext
                                                        buildContext,
                                                    Animation<double> animation,
                                                    Animation<double>
                                                        secondaryAnimation) {
                                                  return TDAlertDialog(
                                                      title: "删除题库",
                                                      content:
                                                          "确定删除题库吗？删除的题库将无法恢复！",
                                                      rightBtnAction: () async {
                                                        cellLength.value =
                                                            list.length;
                                                        await QuestionBank
                                                            .deleteQuestionBank(
                                                                list[index]
                                                                    ['id']);
                                                        list.removeAt(index);
                                                        Navigator.of(context)
                                                            .pop();
                                                        setState(() {});
                                                      });
                                                },
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                      cell: cell,
                                    );
                                  },
                                );
                              },
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
                  ])),
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
                      if (!Platform.isWindows) {
                        showGeneralDialog(
                          context: context,
                          pageBuilder: (BuildContext buildContext,
                              Animation<double> animation,
                              Animation<double> secondaryAnimation) {
                            return const TDConfirmDialog(
                              title: "提示",
                              content: '''本功能仅windows系统支持''',
                            );
                          },
                        );
                      } else {
                        var fromFilePath = await FilePicker.platform.pickFiles(
                            allowMultiple: false, allowedExtensions: ["docx","md"]);
                        if (fromFilePath == null) return;
                        var saveFilePath = await FilePicker.platform.saveFile(
                          dialogTitle: "请选择保存路径",
                          fileName: "custom.qset",
                        );

                        if (saveFilePath == null) return;

                        createQuestionBank(
                            [fromFilePath.files.single.path!, saveFilePath]);
                        // await FlutterIsolate.spawn(createQuestionBank,
                        //     [fromFilePath.files.single.path!, saveFilePath]);
                      }
                    },
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 15, top: 15),
                      child: Icon(
                        Icons.create_outlined,
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
                                '''左边第一个按钮用于导入题库qset文件，第二个按钮用于将word转换为qset文件。在题库编辑中可以设置当前错题记录位置''',
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
    if (StudyData.instance.studyType == StudyType.studyMode &&
        selectIds.length > 1) {
      StudyData.instance.studyType = StudyType.testMode;
    }
    StudyData.instance.studySection = null;

    LearningPlanManager.instance.updateLearningPlan();
  }
}

@pragma('vm:entry-point')
void createQuestionBank(List<String> paths) {
  QuestionBank.create(paths[0], paths[1]);
}
