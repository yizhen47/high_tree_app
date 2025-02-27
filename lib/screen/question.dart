import 'dart:convert';
import 'dart:math';

import 'package:extended_text/extended_text.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/screen/loading.dart';
import 'package:flutter_application_1/screen/mode.dart';
import 'package:flutter_application_1/screen/wrong_question.dart';
import 'package:flutter_application_1/tool/question_bank.dart';
import 'package:flutter_application_1/tool/study_data.dart';
import 'package:flutter_application_1/tool/wrong_question_book.dart';
import 'package:flutter_application_1/widget/question_text.dart';
import 'package:latext/latext.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:uuid/uuid.dart';

class QuestionScreen extends StatefulWidget {
  const QuestionScreen({super.key, required this.title});
  final String title;

  @override
  State<QuestionScreen> createState() => _InnerState();
}

Card buildKnowledgeCard(BuildContext context, final String index,
    final String title, final String knowledge,
    {final String? images}) {
  return Card(
    elevation: 6,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(color: Colors.grey.shade100, width: 1),
    ),
    child: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).cardColor,
            Theme.of(context).cardColor.withOpacity(0.8),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    index,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade800,
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Knowledge Content
            Text(
              knowledge,
              style: TextStyle(
                fontSize: 15,
                height: 1.6,
                color: Colors.grey.shade700,
              ),
            ),

            // Image Section
            if (images != null) ...[
              const SizedBox(height: 24),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Image.network(
                    images,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 200,
                        alignment: Alignment.center,
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

Card buildQuestionCard(BuildContext context, final String knowledgepoint,
    final String question, final String? answer, final String? note) {
  final ValueNotifier<bool> isExpanded = ValueNotifier(false);
  return Card(
    color: Theme.of(context).cardColor,
    elevation: 3,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(color: Colors.grey.shade200),
    ),
    child: ValueListenableBuilder<bool>(
      valueListenable: isExpanded,
      builder: (context, expanded, _) {
        return ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: 200, // 最小高度
            maxHeight: 500, // 最大高度
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min, // 重要：让内容决定高度
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.library_books_outlined,
                            size: 16, color: Theme.of(context).primaryColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ExtendedText(
                            knowledgepoint,
                            specialTextSpanBuilder:
                                MathIncludeTextSpanBuilder(),
                            style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 题目内容
                  Container(
                    padding: const EdgeInsets.only(left: 8),
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(
                          color: Colors.blueGrey.withOpacity(0.3),
                          width: 3,
                        ),
                      ),
                    ),
                    child: LaTexT(
                      laTeXCode: ExtendedText(
                        question,
                        specialTextSpanBuilder: MathIncludeTextSpanBuilder(),
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.5,
                          color: Colors.grey.shade800,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),

                  // 展开按钮

                  // 解析切换按钮
                  GestureDetector(
                      onTap: () => isExpanded.value = !expanded,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              expanded ? Icons.expand_less : Icons.expand_more,
                              color: Colors.blueGrey.shade600,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              expanded ? '收起解析' : '展开解析',
                              style: TextStyle(
                                color: Colors.blueGrey.shade600,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )),
                  // 解析内容（始终保留空间）
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: expanded ? 1 : 0,
                    child: AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      child: expanded
                          ? _buildAnswerSection(answer, note, context)
                          : const SizedBox.shrink(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}

Widget _buildAnswerSection(String? answer, String? note, BuildContext context) {
  final hasAnswer = answer?.isNotEmpty ?? false;
  final hasNote = note?.isNotEmpty ?? false;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 16),
      // 解析部分
      _buildSection(
        icon: Icons.analytics_outlined,
        title: '题目解析',
        content: answer,
        defaultText: '等待老师添加解析中...',
        context: context,
      ),

      if (hasNote) ...[
        const SizedBox(height: 20),
        Divider(color: Colors.grey.shade300, height: 1),
        const SizedBox(height: 20),
        _buildSection(
          icon: Icons.note_alt_outlined,
          title: '学习笔记',
          content: note,
          defaultText: '暂无学习笔记',
          context: context,
        ),
      ],
    ],
  );
}

Widget _buildSection({
  required IconData icon,
  required String title,
  required String? content,
  required String defaultText,
  required BuildContext context,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // 标题行
      Row(
        children: [
          Icon(icon, size: 18, color: Theme.of(context).primaryColor),
          const SizedBox(width: 8),
          Text(title,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade800,
                fontWeight: FontWeight.w600,
              )),
        ],
      ),
      const SizedBox(height: 12),
      // 内容容器
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blueGrey.withOpacity(0.03),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blueGrey.withOpacity(0.1)),
        ),
        child: (content?.isNotEmpty ?? false)
            ? LaTexT(
                laTeXCode: ExtendedText(
                  content!,
                  specialTextSpanBuilder: MathIncludeTextSpanBuilder(),
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: Colors.grey.shade800,
                  ),
                ),
              )
            : Text(defaultText,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                )),
      ),
    ],
  );
}

class _InnerState extends State<QuestionScreen> {
  List<String> idList = [];

  final CardSwiperController controller = CardSwiperController();

  final List<SingleQuestionData> allQuestions = [];
  final List<bool> questionRemoved = [];
  final List<SingleQuestionData> leftQuestions = [];
  final List<SingleQuestionData> rightQuestions = [];
  int questionRemain = 0;

  //这修改页面2的内容
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TDNavBar(
        title: '刷题界面',
        onBack: () {},
        backgroundColor: Theme.of(context).cardColor,
      ),
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
                  List<Card> cards = [];

                  if (StudyData.instance.getStudyType() == StudyType.testMode) {
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
                    for (var i = 0;
                        i < StudyData.instance.getStudyQuestionNum();
                        i++) {
                      var rQdb = snapshot.data!;
                      var k = (List<String>.from(
                          dtype.keys))[Random().nextInt(dtype.keys.length)];
                      var d = rQdb[int.parse(k)];
                      var rSec = d.data![
                          (dtype[k])![Random().nextInt(dtype[k]!.length)]];
                      SingleQuestionData q = rSec
                          .randomSectionQuestion([], [], d.id!, d.displayName!);

                      allQuestions.add(q);
                      questionRemoved.add(false);
                      questionRemain++;
                      cards.add(buildQuestionCard(
                          context,
                          q.getKonwledgePoint(),
                          q.question['q']!,
                          q.question['w'],
                          WrongQuestionBook.instance
                              .getQuestion(q.question['id']!)
                              .note));
                    }
                  } else if (StudyData.instance.getStudyType() ==
                      StudyType.studyMode) {
                    String? secList = StudyData.instance.getStudySection();
                    if (secList == null) {
                      throw Exception("study mode but no section");
                    }
                    Section sec = Section("", "")
                      ..children = snapshot.data!.single.data;

                    List<String> fromKonwledgeIndex = [];
                    List<String> fromKonwledgePoint = [];

                    for (var index in secList.split("/")) {
                      sec = sec.children!.where((e) => e.index == index).single;
                      fromKonwledgeIndex.add(sec.index);
                      fromKonwledgePoint.add(sec.title);
                    }
                    void buildSection(Section s) {
                      cards.add(buildKnowledgeCard(
                          context, s.index, s.title, s.note ?? "暂无知识点"));
                      questionRemoved.add(false);
                      allQuestions.add(SingleQuestionData([], [], {}, "", ""));
                      questionRemain++;
                      if (s.children != null) {
                        for (var i = 0; i < s.children!.length; i++) {
                          buildSection(s.children![i]);
                        }
                      }
                    }

                    buildSection(sec);

                    if (sec.children != null) {}
                    for (var q in sec.sectionQuestion(
                        fromKonwledgePoint,
                        fromKonwledgeIndex,
                        snapshot.data!.single.id!,
                        snapshot.data!.single.displayName!)) {
                      questionRemoved.add(false);
                      allQuestions.add(q);
                      questionRemain++;

                      cards.add(buildQuestionCard(
                          context,
                          q.getKonwledgePoint(),
                          q.question['q']!,
                          q.question['w'],
                          WrongQuestionBook.instance
                              .getQuestion(q.question['id']!)
                              .note));
                    }
                  }
                  return CardSwiper(
                    controller: controller,
                    onSwipe: (previousIndex, currentIndex, direction) {
                      if (questionRemain > 0) {
                        if (direction == CardSwiperDirection.right) {
                          String idWrong =
                              allQuestions[previousIndex].question['id'] ??
                                  const Uuid().v4();
                          idList.add(idWrong);
                          if (allQuestions[previousIndex]
                              .fromKonwledgeIndex
                              .isNotEmpty) {
                            if (WrongQuestionBook.instance
                                .hasWrongQuestion(idWrong)) {
                              TDToast.showWarning("已在错题本中", context: context);
                              //随机改id防止‘重做’操作后错题被删
                              idList.last = const Uuid().v4();
                            } else {
                              WrongQuestionBook.instance.addWrongQuestion(
                                  idWrong, allQuestions[previousIndex]);
                              TDToast.showSuccess("已加入错题本", context: context);
                            }
                            String questionId =
                                allQuestions[previousIndex].question['id']!;
                            if (WrongQuestionBook.instance
                                .hasQuestion(questionId)) {
                              WrongQuestionBook.instance
                                  .getQuestion(questionId)
                                  .happenedTimes++;
                            } else {
                              WrongQuestionBook.instance
                                  .addQuestion(questionId, QuestionUserData(1));
                            }
                          }
                          rightQuestions.add(allQuestions[previousIndex]);
                          questionRemoved[previousIndex] = true;
                          questionRemain--;
                        } else if (direction == CardSwiperDirection.left) {
                          leftQuestions.add(allQuestions[previousIndex]);
                          questionRemoved[previousIndex] = true;
                          questionRemain--;
                          if (allQuestions[previousIndex]
                              .fromKonwledgeIndex
                              .isNotEmpty) {
                            String questionId =
                                allQuestions[previousIndex].question['id']!;
                            if (WrongQuestionBook.instance
                                .hasQuestion(questionId)) {
                              WrongQuestionBook.instance
                                  .getQuestion(questionId)
                                  .happenedTimes++;
                            } else {
                              WrongQuestionBook.instance
                                  .addQuestion(questionId, QuestionUserData(1));
                            }

                            print(WrongQuestionBook.instance
                                .getQuestion(questionId)
                                .happenedTimes);
                          }
                        }

                        return true;
                      } else {
                        return false;
                      }
                    },
                    onUndo: (
                      int? previousIndex,
                      int currentIndex,
                      CardSwiperDirection direction,
                    ) {
                      if (direction == CardSwiperDirection.left) {
                        questionRemoved[currentIndex] = false;
                        questionRemain++;
                        leftQuestions.removeLast();
                        if (allQuestions[currentIndex]
                            .fromKonwledgeIndex
                            .isNotEmpty) {
                          String questionId =
                              allQuestions[currentIndex].question['id']!;
                          if (WrongQuestionBook.instance
                              .hasQuestion(questionId)) {
                            WrongQuestionBook.instance
                                .getQuestion(questionId)
                                .happenedTimes--;
                          }
                        }
                      }
                      if (direction == CardSwiperDirection.right) {
                        questionRemoved[currentIndex] = false;
                        questionRemain++;
                        rightQuestions.removeLast();
                        WrongQuestionBook.instance
                            .removeWrongQuestion(idList.removeLast());
                        if (allQuestions[currentIndex]
                            .fromKonwledgeIndex
                            .isNotEmpty) {
                          String questionId =
                              allQuestions[currentIndex].question['id']!;
                          if (WrongQuestionBook.instance
                              .hasQuestion(questionId)) {
                            WrongQuestionBook.instance
                                .getQuestion(questionId)
                                .happenedTimes--;
                          }
                        }
                      }
                      return true;
                    },
                    cardsCount: cards.length,
                    numberOfCardsDisplayed: 2,
                    cardBuilder:
                        (context, index, percentThresholdX, percentThresholdY) {
                      if (questionRemain == 0) {
                        return Card(
                          color: Theme.of(context).cardColor,
                          elevation: 4,
                          child: SingleChildScrollView(
                            child: SizedBox(
                              width: double.infinity,
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
                                              Image.asset(
                                                'assets/come_on.jpg',
                                                height: 150,
                                              ),
                                              const Text(
                                                '''
                                           提示：退出or继续''',
                                                style: TextStyle(
                                                    fontStyle:
                                                        FontStyle.italic),
                                              ),
                                              InkWell(
                                                  onTap: () {
                                                    Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                            builder: (context) =>
                                                                const LoadingScreen(
                                                                    title:
                                                                        '')));
                                                  },
                                                  child: TDButton(
                                                    text: '继续刷题',
                                                    size: TDButtonSize.large,
                                                    type: TDButtonType.ghost,
                                                    shape:
                                                        TDButtonShape.rectangle,
                                                    theme:
                                                        TDButtonTheme.primary,
                                                    onTap: () {
                                                      Navigator.pushAndRemoveUntil(
                                                          context,
                                                          MaterialPageRoute(
                                                              builder: (context) =>
                                                                  const ModeScreen(
                                                                      title:
                                                                          '')),
                                                          (route) =>
                                                              route.isFirst);
                                                    },
                                                  ))
                                            ],
                                          ),
                                        )),
                                  ],
                                ),
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
            color: Theme.of(context).cardColor,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        TDSlidePopupRoute(
                          modalBarrierColor: TDTheme.of(context).fontGyColor2,
                          slideTransitionFrom: SlideTransitionFrom.bottom,
                          builder: (context) {
                            return TDPopupBottomDisplayPanel(
                              closeClick: () {
                                Navigator.maybePop(context);
                              },
                              child: const SizedBox(
                                height: 400,
                                width: double.infinity,
                                child: Scaffold(
                                  body: Column(
                                    children: [
                                      Expanded(child: WrongQuestionWidth()),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                    child: const Padding(
                      padding: EdgeInsets.only(bottom: 15, top: 15),
                      child: Icon(Icons.class_outlined),
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
                                child: Padding(
                                  padding: const EdgeInsets.all(15),
                                  child: SizedBox(
                                    height: 300,
                                    child: GridView.builder(
                                      gridDelegate:
                                          const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 6,
                                        crossAxisSpacing: 10.0,
                                        mainAxisSpacing: 10.0,
                                      ),
                                      itemCount: allQuestions.length,
                                      itemBuilder: (context, index) {
                                        var questionId =
                                            allQuestions[index].question['id'];
                                        return Scaffold(
                                          body: InkWell(
                                            onTap: () {
                                              controller.moveTo(index);
                                            },
                                            child: Card(
                                              margin: const EdgeInsets.all(2),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              color: (allQuestions[index]
                                                          .fromKonwledgeIndex
                                                          .isEmpty) ||
                                                      questionId == null
                                                  ? (Colors.blueAccent)
                                                  : (WrongQuestionBook.instance
                                                              .getQuestion(
                                                                  questionId)
                                                              .happenedTimes >
                                                          0
                                                      ? (WrongQuestionBook
                                                              .instance
                                                              .hasWrongQuestion(
                                                                  questionId)
                                                          ? Colors.redAccent
                                                          : Colors.greenAccent)
                                                      : Theme.of(context)
                                                          .cardColor),
                                              child: Center(
                                                child: Text('${index + 1}'),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ));
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
                      showGeneralDialog(
                        context: context,
                        pageBuilder: (BuildContext buildContext,
                            Animation<double> animation,
                            Animation<double> secondaryAnimation) {
                          return const TDConfirmDialog(
                            title: "帮助",
                            content: '''右滑加入错题本，左滑表示已掌握。上下滑稍后再看''',
                          );
                        },
                      );
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
