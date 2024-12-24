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

    final TextEditingController laTeXInputController = TextEditingController(
      text: r'What do you think about $L'
          '\''
          r' = {L}{\sqrt{1-\frac{v^2}{c^2}}}$ ?'
          r'\n'
          r'And some display $\LaTeX$: $$\boxed{\rm{A function: } f(x) = \frac{5}{3} \cdot x}$$'
          r'\n'
          r'$\KaTeX$-Flutter provides easy processing of $LaTeX$ embedded into any text.'
          r'\n'
          r'$$\left\{\begin{array}{l}3 x-4 y=1 \\ -3 x+7 y=5\end{array}\right.$$',
    );

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
                                          q.question['note']),
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
                          label: '编辑',
                          onPressed: (_) {
                            Navigator.of(context).push(
                              TDSlidePopupRoute(
                                // modalBarrierColor:
                                //     TDTheme.of(context).fontGyColor2,
                                slideTransitionFrom: SlideTransitionFrom.center,
                                builder: (_) {
                                  return TDPopupCenterPanel(
                                      radius: 15,
                                      // backgroundColor: Colors.transparent,
                                      closeClick: () {
                                        Navigator.maybePop(context);
                                      },
                                      child: SizedBox(
                                        width: screenWidth - 80,
                                        height: screenHeight - 150,
                                        child: Scaffold(
                                            body: Column(
                                          children: [
                                            TextField(
                                              keyboardType:
                                                  TextInputType.multiline,
                                              maxLines: null,
                                              decoration: const InputDecoration(
                                                  labelText:
                                                      'Your LaTeX code here',
                                                  helperText:
                                                      'Use \$ as delimiter. Use \$\$ for display LaTeX.'),
                                              controller: laTeXInputController,
                                            ),
                                            Builder(
                                              builder: (context) => LaTexT(
                                                laTeXCode: Text(
                                                  laTeXInputController.text,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodyMedium,
                                                ),
                                              ),
                                            )
                                          ],
                                        )
                                            //   child: buildQuestionCard(
                                            //       q.getKonwledgePoint(),
                                            //       q.question['q']!,
                                            //       q.question['w'],
                                            //       q.question['note']),
                                            ),
                                      ));
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
