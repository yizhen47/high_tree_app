import 'package:extended_text/extended_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/screen/question.dart';
import 'package:flutter_application_1/screen/question_card.dart';
import 'package:flutter_application_1/tool/question/question_bank.dart';
import 'package:flutter_application_1/tool/text_string_handle.dart';
import 'package:flutter_application_1/tool/question/wrong_question_book.dart';
import 'package:flutter_application_1/widget/itd_collapse.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

class CollapseDataItem {
  String headerValue;
  bool isExpanded;
  List<CollapseDataItem>? children;
  List<SingleQuestionData>? question;
  ValueNotifier<int> counter = ValueNotifier<int>(0);

  CollapseDataItem(
      {required this.headerValue,
      this.isExpanded = false,
      this.children,
      this.question});
}

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenInnerState();
}

class _SearchScreenInnerState extends State<SearchScreen> {
  final ValueNotifier<int> counter = ValueNotifier<int>(0);

  List<Map<String, dynamic>> list = [];
  List<CollapseDataItem> basicData = [
    CollapseDataItem(headerValue: '全部', children: [
      CollapseDataItem(headerValue: '数学'),
      CollapseDataItem(headerValue: '物理'),
    ]),
    CollapseDataItem(headerValue: '化学'),
    CollapseDataItem(headerValue: '生物'),
    CollapseDataItem(headerValue: '英语'),
    CollapseDataItem(headerValue: '语文'),
    CollapseDataItem(headerValue: '历史'),
  ];
  CollapseDataItem analyzeData(Section section, List<String> fromKonwledgePoint,
      List<String> fromKonwledgeIndex, String fromId, String fromDisplayName) {
    fromKonwledgePoint = List.from(fromKonwledgePoint)..add(section.title);
    fromKonwledgeIndex = List.from(fromKonwledgeIndex)..add(section.index);
    return CollapseDataItem(
      headerValue: section.title,
      children: section.children != null
          ? section.children!.map((e) {
              return analyzeData(e, fromKonwledgePoint, fromKonwledgeIndex,
                  fromId, fromDisplayName);
            }).toList()
          : [],
      question: section.questions != null
          ? section.sectionQuestionOnly(fromId, fromDisplayName)
          : [],
    );
  }

  Future<List<CollapseDataItem>> reFreshData() async {
    var bankList = await QuestionBank.getAllLoadedQuestionBanks();
    return bankList.map((e) {
      return CollapseDataItem(
          headerValue: e.displayName!,
          children: e.data!
              .map((q) => analyzeData(q, [], [], e.id!, e.displayName!))
              .toList());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    var screenWidth = MediaQuery.of(context).size.width;
    var screenHeight = MediaQuery.of(context).size.height;
    ValueListenableBuilder<int> buildNestedCollapse(
        List<CollapseDataItem> items, CollapseDataItem? parent) {
      return ValueListenableBuilder<int>(
          valueListenable: parent != null ? parent.counter : counter,
          builder: (context, value, child) {
            return ITDCollapse.accordion(
              style: ITDCollapseStyle.block,
              expansionCallback: (int index, bool isExpanded) {
                items[index].isExpanded = !items[index].isExpanded;
                if (parent != null) {
                  parent.counter.value++;
                } else {
                  counter.value++;
                }
              },
              children: items.map((CollapseDataItem item) {
                return ITDCollapsePanel(
                    headerBuilder: (BuildContext context, bool isExpanded) {
                      return Row(children: [
                        Icon(
                          Icons.menu,
                          // color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        Text(
                          hideText(item.headerValue, maxLen: 10),
                          style: TextStyle(fontWeight: FontWeight.bold),
                        )
                      ]);
                    },
                    value: item.headerValue,
                    isExpanded: item.isExpanded,
                    bodyBuilder: (context, isExpand) => isExpand
                        ? Column(children: [
                            item.question != null
                                ? TDCellGroup(
                                    cells: item.question!
                                        .map((e) => TDCell(
                                              // description: e.question['id']!,
                                              leftIconWidget: WrongQuestionBook.instance.getQuestion(e.question['id']!) != null
                                              
                                              && WrongQuestionBook
                                                      .instance
                                                      .getQuestion(
                                                          e.question['id']!)
                                                      .note!
                                                      .isNotEmpty
                                                  ? Container(
                                                      width: 8,
                                                      height: 80,
                                                      color: Theme.of(context)
                                                          .primaryColor,
                                                    )
                                                  : null,
                                              onClick: (_) {
                                                Navigator.of(context).push(
                                                  TDSlidePopupRoute(
                                                    // modalBarrierColor:
                                                    //     TDTheme.of(context).fontGyColor2,
                                                    slideTransitionFrom:
                                                        SlideTransitionFrom
                                                            .center,
                                                    builder: (_) {
                                                      SingleQuestionData q = e;
                                                      return TDPopupCenterPanel(
                                                        radius: 15,
                                                        backgroundColor:
                                                            Colors.transparent,
                                                        closeClick: () {
                                                          Navigator.maybePop(
                                                              context);
                                                        },
                                                        child: SizedBox(
                                                          width:
                                                              screenWidth - 80,
                                                          height: screenHeight -
                                                              150,
                                                          child: buildQuestionCard(
                                                              context,
                                                              q.getKonwledgePoint(),
                                                              q.question['q']!,
                                                              q.question['w'],
                                                              WrongQuestionBook.instance.getQuestion(q.question['id']!).note),
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                );
                                              },
                                              titleWidget: ExtendedText(
                                                  e.question['q']!,
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  softWrap: true,
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    color: TDTheme.of(context)
                                                        .fontGyColor1,
                                                  )),
                                            ))
                                        .toList(),
                                    builder: (context, cell, index) {
                                      return TDSwipeCell(
                                        groupTag: 'test',
                                        onChange: (direction, open) {},
                                        left: TDSwipeCellPanel(
                                          extentRatio: 120 / screenWidth,
                                          children: [
                                            TDSwipeCellAction(
                                                flex: 60,
                                                backgroundColor:
                                                    TDTheme.of(context)
                                                        .warningColor4,
                                                label: '加入错题本',
                                                onPressed: (_) {
                                                  WrongQuestionBook.instance
                                                      .addWrongQuestion(
                                                          item.question![index].question['id']!,
                                                          item.question![index]); 
                                                  TDToast.showSuccess(context: context,
                                                      "添加成功");
                                                }),
                                          ],
                                        ),
                                        // right: TDSwipeCellPanel(
                                        //   extentRatio: 60 / screenWidth,
                                        //   children: [
                                        //     TDSwipeCellAction(
                                        //       backgroundColor:
                                        //           TDTheme.of(context)
                                        //               .errorColor6,
                                        //       label: '删除',
                                        //       onPressed: (_) {},
                                        //     ),
                                        //   ],
                                        // ),
                                        cell: cell,
                                      );
                                    },
                                  )
                                : const Text('此处无题目'),
                            item.children != null
                                ? buildNestedCollapse(item.children!, item)
                                : const Text('No further items'),
                          ])
                        : const SizedBox());
              }).toList(),
            );
          });
    }

    return Scaffold(
        appBar: TDNavBar(title: '题库浏览', onBack: () {}),
        body: Column(
          children: [
            // TDSearchBar(
            //   placeHolder: "输入关键词",
            //   style: TDSearchStyle.square,
            //   onTextChanged: (String text) {},
            // ),
            Expanded(
              child: SingleChildScrollView(
                child: FutureBuilder(
                  future: reFreshData(),
                  builder: (context, snapshot) {
                    // 请求已结束
                    if (snapshot.connectionState == ConnectionState.done) {
                      if (snapshot.hasError) {
                        // 请求失败，显示错误
                        return Text("Error: ${snapshot.error}"
                            '${snapshot.stackTrace}');
                      } else {
                        return ValueListenableBuilder<int>(
                            valueListenable: counter,
                            builder: (context, value, child) {
                              return buildNestedCollapse(snapshot.data!, null);
                            });
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
            ),
          ],
        ));
  }
}
