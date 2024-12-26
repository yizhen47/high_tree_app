import 'package:extended_text/extended_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/screen/question.dart';
import 'package:flutter_application_1/tool/question_bank.dart';
import 'package:flutter_application_1/tool/text_string_handle.dart';
import 'package:flutter_application_1/tool/wrong_question_book.dart';
import 'package:flutter_application_1/widget/question_text.dart';
import 'package:latext/latext.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenInnerState();
}

class _SearchScreenInnerState extends State<SearchScreen> {
  List<Map<String, dynamic>> list = [];

  Future<void> reFreshData() async {
    var bankList = await QuestionBank.getAllLoadedQuestionBanks();
    List<Map<String, dynamic>> qList = [];
    for (var bank in bankList) {
      qList.addAll(bank.sectionQuestion().map((q) => {
            'id': q.question['id']!,
            'title': q.question["q"],
            "note": q.fromKonwledgePoint.last,
            'description': q.fromDisplayName,
            "data": q,
          }));
    }
    // print(qList);
    setState(() {
      list = qList;
      print("ok");
    });
  }

  @override
  Widget build(BuildContext context) {
    var screenWidth = MediaQuery.of(context).size.width;
    var screenHeight = MediaQuery.of(context).size.height;

    if(list.isEmpty) reFreshData();

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

    return Scaffold(
        appBar: TDNavBar(title: '题库浏览', onBack: () {}),
        body: Column(
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
                                    slideTransitionFrom:
                                        SlideTransitionFrom.center,
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
                        cell: cell,
                      );
                    },
                  );
                },
              ),
            )
          ],
        ));
  }
}
