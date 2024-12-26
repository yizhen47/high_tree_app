import 'package:extended_text/extended_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/screen/question.dart';
import 'package:flutter_application_1/tool/question_bank.dart';
import 'package:flutter_application_1/tool/text_string_handle.dart';
import 'package:flutter_application_1/tool/wrong_question_book.dart';
import 'package:flutter_application_1/widget/question_text.dart';
import 'package:latext/latext.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

class WrongQuestionScreen extends StatefulWidget {
  const WrongQuestionScreen({super.key});
  @override
  State<WrongQuestionScreen> createState() => _WrongQuestionScreenInnerState();
}

class _WrongQuestionScreenInnerState extends State<WrongQuestionScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: TDNavBar(title: '错题查看', onBack: () {}),
        body: const WrongQuestionWidth());
  }
}

class WrongQuestionWidth extends StatefulWidget {
  const WrongQuestionWidth({super.key});
  @override
  State<WrongQuestionWidth> createState() => _WrongQuestionWidthInnerState();
}

class _WrongQuestionWidthInnerState extends State<WrongQuestionWidth> {
  @override
  Widget build(BuildContext context) {
    var screenWidth = MediaQuery.of(context).size.width;
    var screenHeight = MediaQuery.of(context).size.height;

    List<Map<String, dynamic>> list;
    List<Map<String, dynamic>> reFreshData() {
      list = List.from(
          WrongQuestionBook.instance.getWrongQuestionIds().map((action) {
        var q = WrongQuestionBook.instance.getWrongQuestion(action);
        return {
          'id': action,
          'title': q.question["q"],
          "note": q.fromKonwledgePoint.last,
          'description': q.fromDisplayName,
          "data": q,
        };
      }));
      return list;
    }

    list = reFreshData();

    final cellLength = ValueNotifier<int>(list.length);
    List<Map<String, dynamic>> filteredList = List.from(list);

    void filterSearchResults(String query) {
      if (query.isNotEmpty) {
        filteredList = list
            .where((item) => (item['note'].contains(query) ||
                item['title'].toLowerCase().contains(query.toLowerCase())))
            .toList();
      } else {
        filteredList = List.from(list);
      }
      cellLength.value = filteredList.length;
    }

    return Column(
      children: [
        TDSearchBar(
          placeHolder: "输入关键词",
          style: TDSearchStyle.square,
          onTextChanged: (String text) {
            filterSearchResults(text);
          },
        ),
        Expanded(
          child: ValueListenableBuilder(
            valueListenable: cellLength,
            builder: (BuildContext context, value, Widget? child) {
              return TDCellGroup(
                cells: filteredList
                    .map((e) => TDCell(
                          note: hideText('${(e['note'])}', maxLen: 10),
                          description: e['description'],
                          leftIconWidget: WrongQuestionBook.instance.getQuestion(e['id']).note.isNotEmpty ? Container(
                            width: 8,
                            height: 80,
                            color: Theme.of(context).primaryColor,
                          ) : null,
                          onClick: (_) {
                            Navigator.of(context).push(
                              TDSlidePopupRoute(
                                // modalBarrierColor:
                                //     TDTheme.of(context).fontGyColor2,
                                slideTransitionFrom: SlideTransitionFrom.center,
                                builder: (_) {
                                  SingleQuestionData q = e['data'];
                                  return TDPopupCenterPanel(
                                    radius: 15,
                                    backgroundColor: Colors.transparent,
                                    closeClick: () {
                                      Navigator.maybePop(context);
                                    },
                                    child: SizedBox(
                                      width: screenWidth - 80,
                                      height: screenHeight - 150,
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
                          titleWidget: ExtendedText(e['title'],
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              softWrap: true,
                              specialTextSpanBuilder:
                                  MathIncludeTextSpanBuilder(),
                              style: TextStyle(
                                fontSize: 16,
                                color: TDTheme.of(context).fontGyColor1,
                              )),
                        ))
                    .toList(),
                scrollable: true,
                builder: (context, cell, index) {
                  return TDSwipeCell(
                    slidableKey: ValueKey(filteredList[index]['id']),
                    groupTag: 'test',
                    onChange: (direction, open) {},
                    left: TDSwipeCellPanel(
                      extentRatio: 60 / screenWidth,
                      children: [
                        TDSwipeCellAction(
                          flex: 60,
                          backgroundColor: TDTheme.of(context).warningColor4,
                          label: '笔记',
                          onPressed: (_) {
                            Navigator.of(context).push(
                              TDSlidePopupRoute(
                                // modalBarrierColor:
                                //     TDTheme.of(context).fontGyColor2,
                                slideTransitionFrom: SlideTransitionFrom.center,
                                builder: (_) {
                                  final TextEditingController
                                      laTeXInputController =
                                      TextEditingController(
                                          text: r'What do you think about $L'
                                              '\''
                                              r' = {L}{\sqrt{1-\frac{v^2}{c^2}}}$ ?'
                                              r'\n'
                                              r'And some display $\LaTeX$: $$\boxed{\rm{A function: } f(x) = \frac{5}{3} \cdot x}$$');
                                  if (WrongQuestionBook.instance
                                      .getQuestion(filteredList[index]['id']!)
                                      .note
                                      .isNotEmpty) {
                                    laTeXInputController.text =
                                        WrongQuestionBook.instance
                                            .getQuestion(
                                                filteredList[index]['id']!)
                                            .note;
                                  }
                                  var latexText = laTeXInputController.text;
                                  return StatefulBuilder(
                                    builder: (context, innerSetState) {
                                      return TDPopupCenterPanel(
                                        radius: 15,
                                        // backgroundColor: Colors.transparent,
                                        closeClick: () {
                                          Navigator.maybePop(context);
                                        },
                                        child: SizedBox(
                                          width: screenWidth - 80,
                                          height: screenHeight - 150,
                                          child: Padding(
                                            padding: const EdgeInsets.fromLTRB(
                                                10, 30, 10, 10),
                                            child: Scaffold(
                                                body: Column(
                                              children: [
                                                Flexible(
                                                  flex: 1,
                                                  child: Column(
                                                    children: [
                                                      SingleChildScrollView(
                                                        child: Padding(
                                                          padding:
                                                              EdgeInsets.all(
                                                                  10),
                                                          child: Builder(
                                                            builder:
                                                                (context) =>
                                                                    LaTexT(
                                                              laTeXCode: Text(
                                                                latexText,
                                                                style: Theme.of(
                                                                        context)
                                                                    .textTheme
                                                                    .bodyMedium,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      TDInput(
                                                        controller:
                                                            laTeXInputController,
                                                        backgroundColor:
                                                            Colors.white,
                                                        hintText: '请输入文字',
                                                        type: TDInputType
                                                            .cardStyle,
                                                        onChanged: (text) {
                                                          innerSetState(() {
                                                            latexText = text;
                                                          });
                                                        },
                                                        needClear: false,
                                                        maxLines: 6,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(10),
                                                        child: TDButton(
                                                          onTap: () {
                                                            Navigator.of(
                                                                    context)
                                                                .pop();
                                                          },
                                                          size: TDButtonSize
                                                              .large,
                                                          type: TDButtonType
                                                              .outline,
                                                          shape: TDButtonShape
                                                              .rectangle,
                                                          theme: TDButtonTheme
                                                              .primary,
                                                          text: '取消',
                                                        ),
                                                      ),
                                                    ),
                                                    Expanded(
                                                      child: Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(10),
                                                        child: TDButton(
                                                          onTap: () {
                                                            var questionId =
                                                                filteredList[
                                                                        index]
                                                                    ['id'];
                                                            WrongQuestionBook
                                                                .instance
                                                                .mksureQuestion(
                                                                    questionId);
                                                            WrongQuestionBook
                                                                .instance
                                                                .getQuestion(
                                                                    questionId)
                                                                .note = latexText;
                                                            setState(() {
                                                              
                                                            });
                                                            Navigator.of(
                                                                    context)
                                                                .pop();
                                                          },
                                                          size: TDButtonSize
                                                              .large,
                                                          type:
                                                              TDButtonType.fill,
                                                          shape: TDButtonShape
                                                              .rectangle,
                                                          theme: TDButtonTheme
                                                              .primary,
                                                          text: '保存',
                                                        ),
                                                      ),
                                                    )
                                                  ],
                                                )
                                              ],
                                            )),
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    right: TDSwipeCellPanel(
                      extentRatio: 60 / screenWidth,
                      children: [
                        TDSwipeCellAction(
                          backgroundColor: TDTheme.of(context).errorColor6,
                          label: '删除',
                          onPressed: (_) {
                            WrongQuestionBook.instance
                                .removeWrongQuestion(filteredList[index]['id']);
                            filteredList.removeAt(index);
                            reFreshData();
                            cellLength.value = filteredList.length;
                          },
                        ),
                      ],
                    ),
                    cell: cell,
                  );
                },
              );
            },
          ),
        )
      ],
    );
  }
}
