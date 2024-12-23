import 'package:extended_text/extended_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/tool/text_string_handle.dart';
import 'package:flutter_application_1/tool/wrong_question_book.dart';
import 'package:flutter_application_1/widget/question_text.dart';
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
        body: WrongQuestionWidth()
    );
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
                              backgroundColor:
                                  TDTheme.of(context).warningColor4,
                              label: '编辑',
                              onPressed: (context) {},
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
                                WrongQuestionBook.instance.removeWrongQuestion(
                                    filteredList[index]['id']);
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
