import 'dart:convert';
import 'dart:math';

import 'package:extended_text/extended_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/screen/loading.dart';
import 'package:flutter_application_1/tool/question_bank.dart';
import 'package:flutter_application_1/tool/study_data.dart';
import 'package:flutter_application_1/widget/question_text.dart';
import 'package:path/path.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import '../widget/question_text.dart';

class QuestionScreen extends StatefulWidget {
  const QuestionScreen({super.key, required this.title});
  final String title;
  @override
  State<QuestionScreen> createState() => _InnerState();
}

Card buildCard(
    final String knowledgepoint, final String question, final String? answer) {
  return Card(
      color: Colors.white,
      elevation: 4,
      child: SizedBox(
        height: double.infinity,
        child: SingleChildScrollView(
            child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(
                width: double.infinity,
              ),
              Card(
                color: Colors.blueAccent,
                margin: const EdgeInsets.fromLTRB(0, 4, 4, 4),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(6, 2, 6, 2),
                  child: ExtendedText(
                    knowledgepoint,
                    specialTextSpanBuilder: MathIncludeTextSpanBuilder(),
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ),
              ExtendedText(
                question,
                specialTextSpanBuilder: MathIncludeTextSpanBuilder(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 94, 94, 94),
                ),
              ),
              // const Column(
              //   mainAxisAlignment: MainAxisAlignment.start,
              //   crossAxisAlignment: CrossAxisAlignment.start,
              //   verticalDirection: VerticalDirection.down,
              //   children: [
              //     Text(
              //       '''可以参考以下选项''',
              //       style: TextStyle(
              //         fontSize: 14,
              //         // fontStyle: FontStyle.italic,
              //         color: Colors.grey,
              //         fontFamily: 'Times New Roman',
              //       ),
              //     ),
              //     Row(
              //       children: [
              //         Text(
              //           'A ',
              //           style: TextStyle(
              //             fontSize: 14,
              //             fontWeight: FontWeight.bold,
              //             color: Colors.black,
              //             fontFamily: 'Times New Roman',
              //           ),
              //         ),
              //         SizedBox(
              //           width: 10,
              //         ),
              //         Text(
              //           "不知道",
              //           style: TextStyle(
              //             fontSize: 14,
              //             fontWeight: FontWeight.bold,
              //             color: Colors.grey,
              //             fontFamily: 'Times New Roman',
              //           ),
              //         ),
              //       ],
              //     ),
              //     Row(
              //       children: [
              //         Text(
              //           'B ',
              //           style: TextStyle(
              //             fontSize: 14,
              //             fontWeight: FontWeight.bold,
              //             color: Colors.black,
              //             fontFamily: 'Times New Roman',
              //           ),
              //         ),
              //         SizedBox(
              //           width: 10,
              //         ),
              //         Text(
              //           "TD,以后不再显示",
              //           style: TextStyle(
              //             fontSize: 14,
              //             fontWeight: FontWeight.bold,
              //             color: Colors.grey,
              //             fontFamily: 'Times New Roman',
              //           ),
              //         ),
              //       ],
              //     ),
              //     Row(
              //       children: [
              //         Text(
              //           'C ',
              //           style: TextStyle(
              //             fontSize: 14,
              //             fontWeight: FontWeight.bold,
              //             color: Colors.black,
              //             fontFamily: 'Times New Roman',
              //           ),
              //         ),
              //         SizedBox(
              //           width: 10,
              //         ),
              //         Text(
              //           "钝角",
              //           style: TextStyle(
              //             fontSize: 14,
              //             fontWeight: FontWeight.bold,
              //             color: Colors.grey,
              //             fontFamily: 'Times New Roman',
              //           ),
              //         ),
              //       ],
              //     ),
              //   ],
              // ),
              SizedBox(
                height: 30,
                child: Container(
                  alignment: Alignment.center,
                  child: const TDDivider(
                    color: Colors.black38,
                  ),
                ),
              ),
              const Text(
                "解析",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontFamily: 'Times New Roman',
                ),
              ),
              ExtendedText(
                answer ?? "暂无解析",
                specialTextSpanBuilder: MathIncludeTextSpanBuilder(),
                style: const TextStyle(
                  fontSize: 14,
                  fontFamily: 'Times New Roman',
                ),
              ),
            ],
          ),
        )),
      ));
}

class _InnerState extends State<QuestionScreen> {
  bool _onUndo(
    int? previousIndex,
    int currentIndex,
    CardSwiperDirection direction,
  ) {
    if (direction == CardSwiperDirection.left) {
      questionRemoved[currentIndex] = false;
      questionRemain++;
      leftQuestions.removeLast();
    }
    if (direction == CardSwiperDirection.right) {
      questionRemoved[currentIndex] = false;
      questionRemain++;
      rightQuestions.removeLast();
    }
    return true;
  }

  final CardSwiperController controller = CardSwiperController();

  final List<SingleQuestionData> allQuestions = [];
  final List<bool> questionRemoved = [];
  final List<SingleQuestionData> leftQuestions = [];
  final List<SingleQuestionData> rightQuestions = [];
  int questionRemain = 0;

  //这修改页面2的内容
  @override
  Widget build(BuildContext context) {
    setCurMathImgPath(join(QuestionBank.loadedDirPath!,
        QuestionBank.getAllLoadedQuestionBankIds().single, "assets", "images"));

    return Scaffold(
      appBar: TDNavBar(title: '刷题界面', onBack: () {}),
      floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 150),
          child: FloatingActionButton(
              backgroundColor: const Color.fromARGB(255, 237, 237, 237),
              hoverColor: const Color.fromARGB(255, 207, 207, 207),
              child: const Icon(Icons.reply),
              onPressed: () {
                controller.undo();
              })),
      body: Column(
        children: [
          Flexible(
              child: FutureBuilder(
            future: QuestionBank.getAllLoadedQuestionBanks(),
            builder: (context, snapshot) {
              // 请求已结束
              if (snapshot.connectionState == ConnectionState.done) {
                if (snapshot.hasError) {
                  // 请求失败，显示错误
                  return Text(
                      "Error: ${snapshot.error}" '${snapshot.stackTrace}');
                } else {
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
                  List<Card> cards = [];
                  for (var i = 0; i < 5; i++) {
                    var q = snapshot
                        .data![Random().nextInt(snapshot.data!.length)]
                        .randomChoiceQuestion()
                        .single;
                    allQuestions.add(q);
                    questionRemoved.add(false);
                    questionRemain++;
                    cards.add(buildCard(q.getKonwledgePoint(), q.question['q']!,
                        q.question['w']));
                  }
                  return CardSwiper(
                    controller: controller,
                    onSwipe: (previousIndex, currentIndex, direction) {
                      if (questionRemain > 0) {
                        if (direction == CardSwiperDirection.right) {
                          rightQuestions.add(allQuestions[previousIndex]);
                          questionRemoved[previousIndex] = true;
                          questionRemain--;
                        } else if (direction == CardSwiperDirection.left) {
                          leftQuestions.add(allQuestions[previousIndex]);
                          questionRemoved[previousIndex] = true;
                          questionRemain--;
                        }
                      }
                      return true;
                    },
                    onUndo: _onUndo,
                    cardsCount: cards.length,
                    numberOfCardsDisplayed: 2,
                    cardBuilder:
                        (context, index, percentThresholdX, percentThresholdY) {
                      if (questionRemain == 0) {
                        return Card(
                          color: Colors.white,
                          elevation: 4,
                          child: SizedBox(
                            height: double.infinity,
                            child: Padding(
                              padding: const EdgeInsets.all(15),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                      width: double.infinity,
                                      child: Center(
                                        child: Column(
                                          children: [
                                            const Row(children: [
                                              Icon(
                                                Icons.emoji_flags,
                                                size: 100,
                                              ),
                                              Icon(
                                                Icons.emoji_people,
                                                size: 60,
                                              ),
                                            ]),
                                            const Text(
                                              '''太棒啦，您已完成本次任务！  ''',
                                              style: TextStyle(fontSize: 20),
                                            ),
                                            const Icon(Icons.downhill_skiing,
                                                size: 100),
                                            const Text('''现在你可以左右滑动体验从山顶滑下去的感觉
                                           提示：退出or继续'''),
                                            InkWell(
                                                onTap: () {
                                                  Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                          builder: (context) =>
                                                              const LoadingScreen(
                                                                  title: '')));
                                                },
                                                child: const TDButton(
                                                  text: '继续刷题',
                                                  size: TDButtonSize.large,
                                                  type: TDButtonType.ghost,
                                                  shape:
                                                      TDButtonShape.rectangle,
                                                  theme: TDButtonTheme.primary,
                                                ))
                                          ],
                                        ),
                                      )),
                                ],
                              ),
                            ),
                          ),
                        );
                      } else {
                        while (questionRemoved[index]) {
                          index = (index + 1) % cards.length;
                        }
                      }
                      return cards[index];
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
          )),
          Container(
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).push(TDSlidePopupRoute(
                          modalBarrierColor: TDTheme.of(context).fontGyColor2,
                          slideTransitionFrom: SlideTransitionFrom.bottom,
                          builder: (context) {
                            return TDPopupBottomDisplayPanel(
                              closeClick: () {
                                Navigator.maybePop(context);
                              },
                              child: Container(
                                height: 400,
                              ),
                            );
                          }));
                    },
                    child: const Padding(
                      padding: EdgeInsets.only(bottom: 15, top: 15),
                      child: Icon(Icons.playlist_add_check),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).push(TDSlidePopupRoute(
                          modalBarrierColor: TDTheme.of(context).fontGyColor2,
                          slideTransitionFrom: SlideTransitionFrom.bottom,
                          builder: (context) {
                            return TDPopupBottomDisplayPanel(
                              closeClick: () {
                                Navigator.maybePop(context);
                              },
                              child: Container(
                                height: 200,
                              ),
                            );
                          }));
                    },
                    child: const Padding(
                      padding: EdgeInsets.only(bottom: 15, top: 15),
                      child: Icon(Icons.notes),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).push(TDSlidePopupRoute(
                          modalBarrierColor: TDTheme.of(context).fontGyColor2,
                          slideTransitionFrom: SlideTransitionFrom.bottom,
                          builder: (context) {
                            return TDPopupBottomDisplayPanel(
                                closeClick: () {
                                  Navigator.maybePop(context);
                                },
                                child: const SingleChildScrollView(
                                    child: Column(
                                  children: [
                                    Text("疑难题集"),
                                  ],
                                )));
                          }));

                      const EdgeInsets.only(bottom: 15, top: 15);
                    },
                    child: const Padding(
                      padding: EdgeInsets.only(bottom: 15, top: 15),
                      child: Icon(Icons.quiz_outlined),
                    ),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
