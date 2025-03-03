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
  writeNote({filteredList, index, screenWidth, screenHeight, context}) {
    Navigator.of(context).push(
      TDSlidePopupRoute(
        slideTransitionFrom: SlideTransitionFrom.center,
        builder: (_) {
          final TextEditingController laTeXInputController = TextEditingController(
              text: r'What do you think about $L'
                  '\''
                  r' = {L}{\sqrt{1-\frac{v^2}{c^2}}}$ ?'
                  r'\n'
                  r'And some display $\LaTeX$: $$\boxed{\rm{A function: } f(x) = \frac{5}{3} \cdot x}$$');

          // 初始化逻辑保持不变
          if (WrongQuestionBook.instance
              .getQuestion(filteredList[index]['id']!)
              .note
              != null && WrongQuestionBook.instance
              .getQuestion(filteredList[index]['id']!).note!.isNotEmpty) {
            laTeXInputController.text = WrongQuestionBook.instance
                .getQuestion(filteredList[index]['id']!)
                .note!;
          }

          var latexText = laTeXInputController.text;

          return StatefulBuilder(
            builder: (context, innerSetState) {
              return TDPopupCenterPanel(
                radius: 24, // 增加圆角
                child: SizedBox(
                  width: screenWidth - 40, // 增加弹窗宽度
                  height: screenHeight - 100, // 增加弹窗高度
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 30, 20, 20),
                    child: Scaffold(
                      resizeToAvoidBottomInset: true,
                      backgroundColor: Colors.white,
                      body: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 标题栏
                          Row(
                            children: [
                              Icon(Icons.edit_note,
                                  color: Colors.blue[800], size: 24),
                              const SizedBox(width: 12),
                              Text(
                                '编辑笔记',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // 预览区域
                          Expanded(
                            flex: 4,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 6,
                                    offset: Offset(0, 2),
                                  )
                                ],
                              ),
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('预览',
                                      style: TextStyle(
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.w500)),
                                  const SizedBox(height: 10),
                                  Expanded(
                                    child: SingleChildScrollView(
                                      physics: const BouncingScrollPhysics(),
                                      child: LaTexT(
                                        laTeXCode: Text(
                                          latexText,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontFamily: 'FiraCode', // 使用等宽字体
                                            color: Colors.blueGrey[800],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // 输入区域
                          Expanded(
                            flex: 3,
                            child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: Colors.blue[100]!, width: 1.5),
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: Colors.blue[200]!, width: 1.5),
                                  ),
                                  child: TextField(
                                    controller: laTeXInputController,
                                    maxLines: 8,
                                    style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.blue[900],
                                        height: 1.4),
                                    decoration: InputDecoration(
                                      hintText: '输入LaTeX公式...',
                                      hintStyle: TextStyle(
                                          color: Colors.grey[400],
                                          fontSize: 14,
                                          fontStyle: FontStyle.italic),
                                      border: InputBorder.none,
                                      contentPadding: const EdgeInsets.all(16),
                                      suffixIcon: laTeXInputController
                                              .text.isNotEmpty
                                          ? IconButton(
                                              icon: const Icon(Icons.clear,
                                                  size: 20),
                                              onPressed: () {
                                                laTeXInputController.clear();
                                                innerSetState(
                                                    () => latexText = '');
                                              },
                                            )
                                          : null,
                                    ),
                                    onChanged: (text) =>
                                        innerSetState(() => latexText = text),
                                  ),
                                )),
                          ),

                          const SizedBox(height: 25),
                          Row(
                            children: [
                              Expanded(
                                child: TextButton(
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      side: BorderSide(
                                          color: Colors.grey[300]!), // 线框样式
                                    ),
                                  ),
                                  onPressed: () => Navigator.pop(context),
                                  child: Text('取消',
                                      style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 15,
                                          letterSpacing: 1.2)),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextButton(
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    backgroundColor: Colors.blue[50], // 浅色背景
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed: () {
                                    final questionId =
                                        filteredList[index]['id'];
                                    WrongQuestionBook.instance
                                        .mksureQuestion(questionId);
                                    WrongQuestionBook.instance
                                        .getQuestion(questionId)
                                        .note = latexText;
                                    setState(() {});
                                    Navigator.pop(context);
                                  },
                                  child: Text('保存',
                                      style: TextStyle(
                                          color: Colors.blue[800],
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                          letterSpacing: 1.2)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildActionButton(
      {required String text,
      required Color color,
      required IconData icon,
      required Function onTap}) {
    return Material(
      borderRadius: BorderRadius.circular(10),
      color: color,
      child: InkWell(
        onTap: () => onTap(),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(text,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

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
                    .map(
                      (e) => TDCell(
                        note: hideText('${(e['note'])}', maxLen: 10),
                        description: e['description'],
                        leftIconWidget: WrongQuestionBook.instance
                                .getQuestion(e['id'])
                                .note != null && WrongQuestionBook.instance
                                    .getQuestion(e['id'])
                                    .note!
                                    .isNotEmpty
                            ? Container(
                                width: 8,
                                height: 80,
                                color: Theme.of(context).primaryColor,
                              )
                            : null,
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
                                        WrongQuestionBook.instance
                                            .getQuestion(q.question['id']!)
                                            .note),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                        titleWidget: Builder(
                          builder: (context) => LaTexT(
                            laTeXCode: ExtendedText(
                              e['title'],
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              softWrap: true,
                              specialTextSpanBuilder:
                                  MathIncludeTextSpanBuilder(),
                              style: TextStyle(
                                fontSize: 16,
                                color: TDTheme.of(context).fontGyColor1,
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
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
                            onPressed: (context) {
                              writeNote(
                                  filteredList: filteredList,
                                  index: index,
                                  screenWidth: screenWidth,
                                  screenHeight: screenHeight,
                                  context: context);
                            }),
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
