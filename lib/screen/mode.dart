import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/screen/question.dart';
import 'package:flutter_application_1/tool/question_bank.dart';
import 'package:flutter_application_1/tool/study_data.dart';
import 'package:flutter_application_1/tool/text_string_handle.dart';
import 'package:flutter_application_1/widget/itd_tree_select.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

class ModeScreen extends StatefulWidget {
  const ModeScreen({super.key, required this.title});
  final String title;
  @override
  State<ModeScreen> createState() => _InnerState();
}

class _InnerState extends State<ModeScreen> {
  final ValueNotifier<int> counter = ValueNotifier<int>(0);
  var desc = StudyData.instance.getStudySection() ?? "未选择";
  Future<Widget> _buildStudyTreeSelect(BuildContext context) async {
    var data = (await QuestionBank.getAllLoadedQuestionBanks()).single;
    List<Map<dynamic, dynamic>> analyzeSeletion(List<Section> sections,
        List<Map<dynamic, dynamic>> top, int needLayer) {
      for (var i = 0; i < sections.length; i++) {
        var section = sections[i];
        var n = {};
        n["label"] = hideText(section.title);
        n["value"] = section.index;
        if (section.children != null && section.children!.isNotEmpty) {
          List<Map<dynamic, dynamic>> children = [];
          n["children"] = children;
          analyzeSeletion(section.children!, n["children"], needLayer - 1);
          List<Map<dynamic, dynamic>> childOptions = [
            {"label": "确认", "value": "99"}
          ];
          var child = childOptions.single;
          children.insert(0, child);
          var layer = needLayer;
          while (layer - 2 > 0) {
            List<Map<dynamic, dynamic>> nchildren = [
              {"label": "确认", "value": "-1"}
            ];
            child["children"] = nchildren;
            child = child["children"].single;
            layer--;
          }
        } else if (needLayer - 1 > 0) {
          var child = n;
          var layer = needLayer;
          while (layer - 1 > 0) {
            List<Map<dynamic, dynamic>> children = [
              {"label": "确认", "value": "-1"}
            ];
            child["children"] = children;
            child = child["children"].single;
            layer--;
          }
        }
        top.add(n);
      }
      return top;
    }

    int getMaxLayer(List<Section> sections) {
      int maxLayer = 0;
      for (var i = 0; i < sections.length; i++) {
        var section = sections[i];
        if (section.children != null && section.children!.isNotEmpty) {
          int layer = getMaxLayer(section.children!);
          if (layer > maxLayer) {
            maxLayer = layer;
          }
        }
      }
      return maxLayer + 1;
    }

    // print(jsonEncode(analyzeSeletion(data.data!, [], getMaxLayer(data.data!))));
    return TDCell(
      arrow: false,
      title: data.displayName,
      description: desc,
      onClick: (cell) {
        TDCascader.showMultiCascader(context,
            title: '选择章节',
            data: (analyzeSeletion(data.data!, [], getMaxLayer(data.data!)))
                as dynamic,
            theme: 'step', onChange: (List<MultiCascaderListModel> selectData) {
          setState(() {
            desc = selectData
                .map((toElement) => toElement.value)
                .join("/")
                .replaceAll("/99", '')
                .replaceAll("/-1", "");
            // var descS = selectData.map((toElement) => toElement.value).join("/").replaceAll("/-1", "");
            StudyData.instance.setStudySection(desc);
          });
        }, onClose: () {
          Navigator.of(context).pop();
        });
      },
    );
  }

  Future<Widget> _buildTestTreeSelect(BuildContext context) async {
    List<ITDSelectOption> options = [];
    var data = (await QuestionBank.getAllLoadedQuestionBanks());

    for (var (i, qdb) in data.indexed) {
      options.add(
          ITDSelectOption(label: '${qdb.displayName}', value: i, children: []));

      for (var (j, sec) in qdb.data!.indexed) {
        options.last.children.add(ITDSelectOption(
            label: hideText('${sec.index}: ${sec.title}'), value: j));
      }
    }
    String? secList = StudyData.instance.getStudySection();
    Map<String, dynamic>? d;
    Map<String, List<int>>? dtype = {};
    if (secList != null) {
      d = json.decode(secList);
      for (var k in d!.entries) {
        dtype[k.key] = [];
        for (var kk in k.value) {
          dtype[k.key]!.add(kk);
        }
      }
    }
    return ITDTreeSelect(
      options: options,
      multiple: true,
      defaultBackValue: dtype,
      // defaultValue: values3,
      onChange: (val, level) {
        StudyData.instance.setStudySection(json.encode(val));
        counter.value++;
      },
    );
  }

  //这修改页面4的内容
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TDNavBar(
        title: '模式选择',
        onBack: () {},
        rightBarItems: [
          TDNavBarItem(
            iconWidget: ValueListenableBuilder<int>(
              valueListenable: counter,
              builder: (context, value, child) {
                return InkWell(
                  onTap: () {
                    if (sectionIsEmpty()) {
                      TDToast.showWarning('章节未选择',
                          direction: IconTextDirection.vertical,
                          context: context);
                    } else {
                      Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  const QuestionScreen(title: '')),
                          (route) => route.isFirst);
                    }
                  },
                  child: TDTag('下一项',
                      size: TDTagSize.large,
                      theme: (sectionIsEmpty())
                          ? TDTagTheme.defaultTheme
                          : TDTagTheme.primary,
                      forceVerticalCenter: false,
                      isOutline: false),
                );
              },
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical, //
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // const Padding(
            //   padding: EdgeInsets.all(15),
            //   child: Column(
            //     mainAxisAlignment: MainAxisAlignment.start,
            //     crossAxisAlignment: CrossAxisAlignment.start,
            //     children: [
            //       Text(
            //         "选择难度",
            //         style: TextStyle(
            //             fontSize: 18,
            //             color: Colors.black,
            //             fontWeight: FontWeight.w600),
            //       ),
            //     ],
            //   ),
            // ),
            // TDRadioGroup(
            //   selectId: '${StudyData.instance.getStudyDifficulty().index}',
            //   onRadioGroupChange: (selectedId) {
            //     if (selectedId != null) {
            //       StudyData.instance.setStudyDifficulty(
            //           StudyDifficulty.values[int.parse(selectedId)]);
            //     }
            //     setState(() {});
            //   },
            //   cardMode: true,
            //   direction: Axis.horizontal,
            //   rowCount: 3,
            //   directionalTdRadios: [
            //     TDRadio(
            //       id: '${StudyDifficulty.easy.index}',
            //       title: StudyDifficulty.easy.displayName,
            //       cardMode: true,
            //     ),
            //     TDRadio(
            //       id: '${StudyDifficulty.normal.index}',
            //       title: StudyDifficulty.normal.displayName,
            //       cardMode: true,
            //     ),
            //     TDRadio(
            //       id: '${StudyDifficulty.hard.index}',
            //       title: StudyDifficulty.hard.displayName,
            //       cardMode: true,
            //     ),
            //   ],
            // ),
            const Padding(
              padding: EdgeInsets.all(15),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "选择模式",
                    style: TextStyle(
                        fontSize: 18,
                        color: Colors.black,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            TDRadioGroup(
              selectId: '${StudyData.instance.getStudyType().index}',
              cardMode: true,
              direction: Axis.horizontal,
              rowCount: 3,
              onRadioGroupChange: (selectedId) {
                if (selectedId != null) {
                  StudyData.instance
                      .setStudyType(StudyType.values[int.parse(selectedId)]);
                }
                StudyData.instance.setStudySection(null);
                setState(() {});
              },
              directionalTdRadios: [
                TDRadio(
                  enable:
                      QuestionBank.getAllLoadedQuestionBankIds().length == 1,
                  id: '${StudyType.studyMode.index}',
                  title: StudyType.studyMode.getDisplayName(),
                  cardMode: true,
                ),
                TDRadio(
                  id: '${StudyType.testMode.index}',
                  title: StudyType.testMode.getDisplayName(),
                  cardMode: true,
                ),
                // TDRadio(
                //   id: '${StudyType.recommandMode.index}',
                //   title: StudyType.recommandMode.getDisplayName(),
                //   cardMode: true,
                // ),
              ],
            ),
            (() {
              if (StudyData.instance.getStudyType() == StudyType.studyMode) {
                return FutureBuilder(
                  future: _buildStudyTreeSelect(context),
                  builder: (context, snapshot) {
                    // 请求已结束
                    if (snapshot.connectionState == ConnectionState.done) {
                      if (snapshot.hasError) {
                        // 请求失败，显示错误
                        return Text("Error: ${snapshot.error}"
                            '${snapshot.stackTrace}');
                      } else {
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.all(15),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "选择章节",
                                    style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.black,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                            snapshot.data!,
                          ],
                        );
                      }
                    } else {
                      return const Center(
                        heightFactor: 10.0,
                        child: TDLoading(
                          size: TDLoadingSize.large,
                          icon: TDLoadingIcon.circle,
                          text: '加载中…',
                          axis: Axis.horizontal,
                        ),
                      );
                    }
                  },
                );
              } else if (StudyData.instance.getStudyType() ==
                  StudyType.testMode) {
                return FutureBuilder(
                  future: _buildTestTreeSelect(context),
                  builder: (context, snapshot) {
                    // 请求已结束
                    if (snapshot.connectionState == ConnectionState.done) {
                      if (snapshot.hasError) {
                        // 请求失败，显示错误
                        return Text("Error: ${snapshot.error}"
                            '${snapshot.stackTrace}');
                      } else {
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.all(15),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "选择题数",
                                    style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.black,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                            TDStepper(
                              size: TDStepperSize.large,
                              value: StudyData.instance.getStudyQuestionNum(),
                              max: 20,
                              min: 2,
                              onChange: (qnum) {
                                StudyData.instance.setStudyQuestionNum(qnum);
                              },
                            ),
                            const Padding(
                              padding: EdgeInsets.all(15),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "选择章节",
                                    style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.black,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                            snapshot.data!,
                          ],
                        );
                      }
                    } else {
                      return const Center(
                        heightFactor: 10.0,
                        child: TDLoading(
                          size: TDLoadingSize.large,
                          icon: TDLoadingIcon.circle,
                          text: '加载中…',
                          axis: Axis.horizontal,
                        ),
                      );
                    }
                  },
                );
              } else {
                return const SizedBox();
              }
            })(),
          ],
        ),
      ),
    );
  }
}

bool sectionIsEmpty() {
  var sec = StudyData.instance.getStudySection();
  if (sec == null) {
    return true;
  }
  if (sec.startsWith("{")) {
    for (var e in (jsonDecode(sec) as Map).entries) {
      if (e.value.length > 0) {
        return false;
      }
    }
    return true;
  } else {
    return false;
  }
}
