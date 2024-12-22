import 'package:extended_text/extended_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/tool/question_bank.dart';
import 'package:flutter_application_1/tool/wrong_question_book.dart';
import 'package:flutter_application_1/widget/question_text.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

class WrongQuestionScreen extends StatefulWidget {
  const WrongQuestionScreen({super.key});
  @override
  State<WrongQuestionScreen> createState() => _InnerState();
}

//这里是在一个页面中加了PageView，PageView可以载入更多的StatefulWidget或者StatelessWidget（也就是页面中加载其他页面作为子控件）
class _InnerState extends State<WrongQuestionScreen> {
  @override
  Widget build(BuildContext context) {
    var screenWidth = MediaQuery.of(context).size.width;

    var list = List.from(
        WrongQuestionBook.instance.getWrongQuestionIds().map((action) {
      var q = WrongQuestionBook.instance.getWrongQuestion(action);
      return {
        'id': action,
        'title': q.question["w"],
        "note": q.fromKonwledgePoint.last,
        'description': q.fromDisplayName,
      };
    }));

    final cellLength = ValueNotifier<int>(list.length);
    return Scaffold(
        appBar: TDNavBar(title: '错题查看', onBack: () {}),
        body: Column(
          children: [
            ValueListenableBuilder(
              valueListenable: cellLength,
              builder: (BuildContext context, value, Widget? child) {
                return TDCellGroup(
                  cells: list
                      .map((e) => TDCell(
                            note: '${(e['note'])}',
                            description: e['description'],
                            titleWidget: ExtendedText(e['title'],
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                softWrap: true,
                                specialTextSpanBuilder: MathIncludeTextSpanBuilder(),
                                style: TextStyle(
                                  fontSize: 16,
                                  color: TDTheme.of(context).fontGyColor1,
                                )),
                          ))
                      .toList(),
                  builder: (context, cell, index) {
                    return TDSwipeCell(
                      slidableKey: ValueKey(list[index]['id']),
                      groupTag: 'test',
                      onChange: (direction, open) {},
                      left: TDSwipeCellPanel(
                        extentRatio: 60 / screenWidth,
                        // dragDismissible: true,
                        onDismissed: (context) {
                          list.removeAt(index);
                          cellLength.value = list.length;
                        },
                        children: [
                          TDSwipeCellAction(
                            flex: 60,
                            backgroundColor: TDTheme.of(context).warningColor4,
                            label: '编辑',
                            onPressed: (context) {},
                          ),
                        ],
                      ),
                      right: TDSwipeCellPanel(
                        extentRatio: 60 / screenWidth,
                        // dragDismissible: true,
                        onDismissed: (context) {
                          list.removeAt(index);
                          cellLength.value = list.length;
                        },
                        children: [
                          TDSwipeCellAction(
                            backgroundColor: TDTheme.of(context).errorColor6,
                            label: '删除',
                            onPressed: (_) {
                              showGeneralDialog(
                                context: context,
                                pageBuilder: (BuildContext buildContext,
                                    Animation<double> animation,
                                    Animation<double> secondaryAnimation) {
                                  return TDAlertDialog(
                                      title: "删除题库",
                                      content: "确定删除题库吗？删除的题库将无法恢复！",
                                      rightBtnAction: () async {
                                        cellLength.value = list.length;
                                        await QuestionBank.deleteQuestionBank(
                                            list[index]['id']);
                                        list.removeAt(index);
                                        Navigator.of(context).pop();
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
            ),
          ],
        ));
  }
}
