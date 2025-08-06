import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/screen/home/home.dart';
import 'package:flutter_application_1/screen/mode.dart';
import 'package:flutter_application_1/screen/question_card.dart';
import 'package:flutter_application_1/screen/wrong_question.dart';
import 'package:flutter_application_1/tool/question/question_bank.dart';
import 'package:flutter_application_1/tool/question/question_controller.dart';
import 'package:flutter_application_1/tool/study_data.dart';
import 'package:flutter_application_1/tool/question/wrong_question_book.dart';
import 'package:flutter_application_1/widget/left_toast.dart';
import 'package:flutter_application_1/widget/mind_map.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:uuid/uuid.dart';

class QuestionScreen extends StatefulWidget {
  const QuestionScreen({super.key, required this.title});
  final String title;

  @override
  State<QuestionScreen> createState() => _InnerState();
}

class _InnerState extends State<QuestionScreen> with TickerProviderStateMixin {
  List<String> idList = [];

  final CardSwiperController controller = CardSwiperController();

  final List<SingleQuestionData> allQuestions = [];
  final List<bool> questionRemoved = [];
  final List<SingleQuestionData> leftQuestions = [];
  final List<SingleQuestionData> rightQuestions = [];

  int questionRemain = 0;
  int unlockedQuestionNum = StudyData.instance.needCompleteQuestionNum;

  var progress = 0.0;
  var retryCount = 0;
  BuildContext? buildContext;

  @override
  void initState() {
    super.initState();
    // 开始学习会话计时
    StudyData.instance.startStudySession();
  }

  @override
  void dispose() {
    // 结束学习会话并记录时间
    StudyData.instance.endStudySession();
    // Reset currentPlanId when leaving the question screen
    StudyData.instance.currentPlanId = -1;
    super.dispose();
  }

// 构建统一风格的按钮组件
  _buildCompleteCard(BuildContext context) {
    return Card(
      color: Colors.white, // 使用主色作为底色
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppTheme.primaryColor.withOpacity(0.2)), // 主色边框
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 图标使用主色
            Container(
              decoration: const BoxDecoration(
                color: AppTheme.primaryColor,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(16),
              child: const Icon(
                Icons.check_rounded,
                size: 36,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 28),

            // 标题使用文本主色
            const Text(
              '任务完成',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary, // 使用定义的文本主色
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),

            // 副标题使用文本次要色
            const Text(
              '已完成所有题目练习',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondary, // 使用定义的文本次要色
              ),
            ),
            const SizedBox(height: 32),

            // 在显示完成卡片时结束学习会话
            StatefulBuilder(
              builder: (context, setState) {
                // 确保只调用一次endStudySession
                Future.microtask(() => StudyData.instance.endStudySession());
                return Container();
              },
            ),

            // 按钮使用次要色系
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.blue[50], // 浅色背景
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ModeScreen(
                            title: '',
                          ),
                        ),
                        (layer) => layer.isFirst,
                      );
                    },
                    child: Text('继续做题',
                        style: TextStyle(
                            color: Colors.blue[800],
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1.2)),
                  ),
                ),
                const SizedBox(height: 12),
                // 添加查看错题按钮
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.red[50], // 浅红色背景
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
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
                                      Expanded(child: WrongQuestionWidget()),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                    child: Text('查看错题',
                        style: TextStyle(
                            color: Colors.red[800],
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1.2)),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.textSecondary, // 使用文本次要色
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('暂时离开'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  _buildCardData(BuildContext context) {
    return FutureBuilder(
      future: QuestionBank.getAllLoadedQuestionBanks(),
      builder: (context, snapshot) {
        // 请求已结束
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            // 请求失败，显示错误
            return Text("Error: ${snapshot.error}" '${snapshot.stackTrace}');
          } else {
            List<Card> cards = [];
            final studyType = StudyData.instance.studyType;
            final isTestMode = studyType == StudyType.testMode;
            final isStudyMode = studyType == StudyType.studyMode;

            // 公共处理逻辑
            void addQuestionCard(SingleQuestionData q) {
              allQuestions.add(q);
              questionRemoved.add(false);
              questionRemain++;
              cards.add(buildQuestionCard(
                context,
                q.getKonwledgePoint(),
                q.question['q']!,
                q.question['w'],
                WrongQuestionBook.instance.getQuestion(q.question['id']!).note,
                q, // Pass the current question data
              ));
            }

            replaceQuestion(SingleQuestionData q, int pos) {
              allQuestions[pos] = q;
              questionRemoved[pos] = false;
              questionRemain++;

              cards[pos] = buildQuestionCard(
                context,
                q.getKonwledgePoint(),
                q.question['q']!,
                q.question['w'],
                WrongQuestionBook.instance.getQuestion(q.question['id']!).note,
                q, // Pass the current question data
              );
            }

            insertQuestion(SingleQuestionData q, int pos) {
              allQuestions.insert(pos, q);
              questionRemoved.insert(pos, false);
              questionRemain++;

              cards.insert(
                pos,
                buildQuestionCard(
                  context,
                  q.getKonwledgePoint(),
                  q.question['q']!,
                  q.question['w'],
                  WrongQuestionBook.instance
                      .getQuestion(q.question['id']!)
                      .note,
                  q, // Pass the current question data
                ),
              );
            }

            isQuestionRemoved(SingleQuestionData q) {
              return questionRemoved[allQuestions.indexOf(q)];
            }

            questionAnsWasWrong(SingleQuestionData q) {
              return rightQuestions.contains(q);
            }

            // 测试模式处理
            if (isTestMode) {
              final secList = StudyData.instance.studySection;
              Map<String, List<int>> dtype = {};

              if (secList != null) {
                final decoded = json.decode(secList) as Map<String, dynamic>;
                dtype = decoded
                    .map((k, v) => MapEntry(k, List<int>.from(v as List)));
              }

              final rQdb = snapshot.data!;
              final sectionKeys = List<String>.from(dtype.keys);

              for (int i = 0;
                  i < StudyData.instance.studyQuestionNum;
                  i++) {
                final randomKey =
                    sectionKeys[Random().nextInt(sectionKeys.length)];
                final sectionData = rQdb[int.parse(randomKey)];
                final questionIndexes = dtype[randomKey]!;
                final randomIndex =
                    questionIndexes[Random().nextInt(questionIndexes.length)];

                final question = sectionData.data![randomIndex];
                final qData = question.randomSectionQuestion(
                    sectionData.id!, sectionData.displayName!);

                addQuestionCard(qData);
              }
            } else if (isStudyMode) {
              final secList = StudyData.instance.studySection ??
                  (throw Exception("需要指定学习章节"));
              Section currentSection = Section("", "")
                ..children = snapshot.data!.single.data;
              final knowledgePath = secList.split("/");

              // 递归构建知识卡片
              void buildSectionTree(Section section) {
                cards.add(buildKnowledgeCard(context, section.index,
                    section.title, section.note ?? "暂无知识点"));
                questionRemoved.add(false);
                allQuestions.add(SingleQuestionData({}, "", ""));
                questionRemain++;

                section.children?.forEach((child) => buildSectionTree(child));
              }

              // 定位目标章节
              for (final index in knowledgePath) {
                currentSection = currentSection.children!
                    .firstWhere((e) => e.index == index);
              }

              buildSectionTree(currentSection);
              currentSection
                  .sectionQuestion(
                    snapshot.data!.single.id!,
                    snapshot.data!.single.displayName!,
                  )
                  .forEach(addQuestionCard);
            } else if (StudyData.instance.studyType ==
                StudyType.recommandMode) {
              // Check if a specific plan is selected
              final currentPlanId = StudyData.instance.currentPlanId;
              if (currentPlanId >= 0 && currentPlanId < LearningPlanManager.instance.learningPlanItems.length) {
                // Study only the selected plan
                final selectedPlan = LearningPlanManager.instance.learningPlanItems[currentPlanId];
                for (var q in selectedPlan.questionList) {
                  addQuestionCard(q);
                }
              } else {
                // Fallback to studying all plans (original behavior)
                for (var c in LearningPlanManager.instance.learningPlanItems) {
                  for (var q in c.questionList) {
                    addQuestionCard(q);
                  }
                }
              }
            }
            // 卡片滑动组件
            return CardSwiper(
              controller: controller,
              onSwipe: (previousIndex, currentIndex, direction) {
                if (questionRemain > 0) {
                  final index = previousIndex;
                  final question = allQuestions[index];

                  // 生成持久化ID（重要修复）
                  final String questionId = question.question['id'] ?? '';

                  // 记录发生次数（无论是否知识点题目）
                  final userData =
                      WrongQuestionBook.instance.getQuestion(questionId);
                  userData.tryCompleteTimes++;
                  if (!WrongQuestionBook.instance.hasQuestion(questionId)) {
                    WrongQuestionBook.instance
                        .addQuestion(questionId, userData); // 更新发生次数
                  }
                  // 仅知识点题目需要记录错题本
                  if (question.fromKonwledgeIndex.isNotEmpty) {
                    if (direction == CardSwiperDirection.right) {
                      if (!WrongQuestionBook.instance
                          .hasWrongQuestion(questionId)) {
                        WrongQuestionBook.instance
                            .addWrongQuestion(questionId, question);
                        idList.add(questionId); // 记录可撤销的错题ID
                        // 移除错题本提示弹窗
                        // showVerticalToast(
                        //   context: context,
                        //   title: "提示",
                        //   message: "已加入错题本",
                        // );
                      } else {
                        // 移除已在错题本中提示弹窗
                        // showVerticalToast(
                        //   context: context,
                        //   title: "提示",
                        //   message: "已在错题本中",
                        // );
                        idList.add(const Uuid().v4()); // 生成伪ID防止误删
                      }
                    } else {
                      if (WrongQuestionBook.instance
                          .hasWrongQuestion(questionId)) {
                        WrongQuestionBook.instance
                            .removeWrongQuestion(questionId);
                        // showVerticalToast(
                        //   context: context,
                        //   title: "提示",
                        //   message: "已从错题本移除",
                        // );
                      }
                    }
                  }

                  // 状态更新（统一处理）
                  questionRemoved[index] = true;
                  questionRemain--;
                  direction == CardSwiperDirection.right
                      ? rightQuestions.add(question)
                      : leftQuestions.add(question);

                  //推荐模式下的判断
                  if (StudyData.instance.studyType ==
                      StudyType.recommandMode) {
                    // Check if a specific plan is selected
                    final currentPlanId = StudyData.instance.currentPlanId;
                    final planItems = currentPlanId >= 0 && currentPlanId < LearningPlanManager.instance.learningPlanItems.length
                        ? [LearningPlanManager.instance.learningPlanItems[currentPlanId]]
                        : LearningPlanManager.instance.learningPlanItems;
                        
                    for (var c in planItems) {
                      var notNeedRefresh = true;
                      var pass = true;
                      var progress = 0;
                      for (var q in c.questionList) {
                        if (questionAnsWasWrong(q)) {
                          notNeedRefresh = false;
                        }

                        //没做完
                        if (!isQuestionRemoved(q)) {
                          notNeedRefresh = true;
                          pass = false;
                          break;
                        } else {
                          progress++;
                        }
                      }
                      if (!notNeedRefresh) {
                        // 移除重做提示弹窗
                        // showVerticalToast(
                        //     title: "重做", message: "题目已经刷新", context: context);
                        retryCount++;
                        List<int> indexRecord = [];
                        for (var q in c.questionList) {
                          leftQuestions.remove(q);
                          rightQuestions.remove(q);
                          indexRecord.add(allQuestions.indexOf(q));
                        }
                        c.failSection();
                        for (var i = 0; i < c.questionList.length; i++) {
                          replaceQuestion(
                              c.questionList[i], indexRecord[i]);
                        }
                        // Remove the mind map popup on plan failure
                        // _showMindMap(context, c.targetSection!.id);
                        Future.delayed(const Duration(milliseconds: 800))
                            .whenComplete(() {
                          showKnowledgeCard(context, c.targetSection!);
                          controller
                              .moveTo(indexRecord.reduce((v, e) => min(v, e)));
                        });

                        break;
                      } else if (pass) {
                        if (c.needsToLearn(c.targetSection!)) {
                          retryCount = 0;
                          // 移除完成提示弹窗
                          // showVerticalToast(
                          //     title: '完成',
                          //     message: c.targetSection!.title,
                          //     context: context);
                          c.completeSection();

                          unlockedQuestionNum +=
                              StudyData.instance.needCompleteQuestionNum;
                        }
                      }

                      var sectionData = c.getSectionLearningData(c.targetSection!);
                      sectionData.alreadyCompleteQuestion = progress;
                      c.saveSectionLearningData(c.targetSection!, sectionData);
                    }
                  }
                  restartUpdater.value = !restartUpdater.value;

                  return true;
                }
                return false;
              },
              cardsCount: cards.length,
              cardBuilder:
                  (context, index, percentThresholdX, percentThresholdY) {
                if (questionRemain == 0) {
                  return _buildCompleteCard(context);
                } else {
                  // 记录原始索引和尝试次数防止死循环
                  int attempts = 0;
                  int oIndex = index;

                  // 查找下一个未移除的卡片，最多尝试cards.length次
                  while (questionRemoved[index] && attempts < cards.length) {
                    index = (index + 1) % cards.length;
                    attempts++;
                  }

                  // 所有卡片都被移除了但questionRemain未及时更新，强制显示完成
                  if (attempts >= cards.length || questionRemoved[index]) {
                    return _buildCompleteCard(context);
                  }

                  return cards[oIndex];
                }
              },
              // 在 CardSwiper 的 onUndo 回调中直接实现撤销逻辑（原简写方案中缺失的部分）
              onUndo: (previousIndex, currentIndex, direction) {
                final question = allQuestions[currentIndex];
                final String questionId = question.question['id'] ?? '';

                // 还原发生次数
                final userData =
                    WrongQuestionBook.instance.getQuestion(questionId);
                userData.tryCompleteTimes--;

                if (direction == CardSwiperDirection.right) {
                  // 错题本撤销处理
                  if (question.fromKonwledgeIndex.isNotEmpty) {
                    final removedId = idList.removeLast();
                    if (removedId == questionId) {
                      WrongQuestionBook.instance.removeWrongQuestion(removedId);
                    }
                  }
                  rightQuestions.removeLast();
                } else {
                  leftQuestions.removeLast();
                }

                questionRemoved[currentIndex] = false;
                questionRemain++;
                return true;
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
    );
  }

// 统一的小型浮动按钮
  Widget _buildMiniFab({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return FloatingActionButton(
      heroTag: 'fab_${icon.codePoint}',
      mini: true,
      backgroundColor: color.withOpacity(0.9),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: color.withOpacity(0.3), width: 1),
      ),
      onPressed: onPressed,
      child: Icon(icon, size: 20, color: Colors.white),
    );
  }

  MindMap _buildMindMap(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    var height = 400.0;
    var mindMap = MindMap<Section>(
        rootNode: MindMapHelper.createRoot(data: Section("", "")),
        width: width,
        controller: MindMapController(),
        onNodeTap: (MindMapNode<Section> node) {
          if (node.data == null) {
            return;
          }
          showKnowledgeCard(buildContext!, node.data!);
        },
        height: height);
    for (var c in LearningPlanManager.instance.questionBanks
        .map((toElement) => LearningPlanItem(toElement))) {
      c.buildMindMapNodes(
          MindMapHelper.addChildNode(mindMap.rootNode, c.bank.displayName!));
    }
    MindMapHelper.organizeTree(mindMap.rootNode);
    return mindMap;
  }

  void _showMindMap(BuildContext context, String? nodeId) {
    final mindMap = _buildMindMap(context); // 创建实例并保存到局部变量
    Navigator.of(context).push(
      TDSlidePopupRoute(
        modalBarrierColor: TDTheme.of(context).fontGyColor2,
        slideTransitionFrom: SlideTransitionFrom.bottom,
        builder: (context) {
          return TDPopupBottomDisplayPanel(
            closeClick: () {
              Navigator.maybePop(context);
            },
            child: SizedBox(
              height: 400,
              width: double.infinity,
              child: Scaffold(
                body: Column(
                  children: [
                    Expanded(child: mindMap),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
    Future.delayed(const Duration(milliseconds: 100)).then((_) {
      if (nodeId != null) {
        // 确保在页面打开后执行定位
        mindMap.controller!.centerNodeById(nodeId);
        mindMap.controller!.highlightNodeById([nodeId]);
      }
    });
  }

  ValueNotifier<bool> restartUpdater = ValueNotifier(true);
  //这修改页面2的内容
  @override
  Widget build(BuildContext context) {
    buildContext = context;

    return Scaffold(
      appBar: TDNavBar(
        title: '学习界面',
        onBack: () {},
        backgroundColor: Theme.of(context).cardColor,
      ),
      // Remove floating action button from the side and place at bottom
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Container(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
        color: Theme.of(context).cardColor,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildMiniFab(
              icon: Icons.check,
              color: Colors.green.shade200,
              onPressed: () {
                controller.swipe(CardSwiperDirection.left);
              },
            ),
            FloatingActionButton(
              heroTag: 'undo_btn',
              mini: true,
              backgroundColor: Colors.grey[200],
              elevation: 2,
              onPressed: controller.undo,
              child: Icon(Icons.reply, color: Colors.grey[700]),
            ),
            // 添加题号选择按钮（仅在学习模式显示）
            if (StudyData.instance.studyType == StudyType.studyMode)
              FloatingActionButton(
                heroTag: 'question_number_btn',
                mini: true,
                backgroundColor: Colors.grey[200],
                elevation: 2,
                child: Icon(Icons.format_list_numbered, color: Colors.grey[700]),
                onPressed: () {
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
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 6,
                                crossAxisSpacing: 10.0,
                                mainAxisSpacing: 10.0,
                              ),
                              itemCount: allQuestions.length,
                              itemBuilder: (context, index) {
                                var questionId = allQuestions[index].question['id'];
                                return Scaffold(
                                  body: InkWell(
                                    onTap: () {
                                      if (index < unlockedQuestionNum || 
                                          StudyData.instance.studyType != StudyType.recommandMode) {
                                        controller.moveTo(index);
                                      }
                                    },
                                    child: Card(
                                      margin: const EdgeInsets.all(2),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      color: (index >= unlockedQuestionNum &&
                                              StudyData.instance.studyType == StudyType.recommandMode)
                                          ? Colors.grey.shade300
                                          : (allQuestions[index].fromKonwledgeIndex.isEmpty) ||
                                                  questionId == null
                                              ? (Colors.blueAccent)
                                              : WrongQuestionBook.instance.hasWrongQuestion(questionId)
                                                  ? Colors.redAccent
                                                  : (WrongQuestionBook.instance.getQuestion(questionId)
                                                              .tryCompleteTimes > 0
                                                          ? (Colors.greenAccent)
                                                          : Theme.of(context).cardColor),
                                      child: Center(
                                        child: Text('${index + 1}'),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ));
                },
              ),
            _buildMiniFab(
              icon: Icons.close,
              color: Colors.red.shade200,
              onPressed: () {
                controller.swipe(CardSwiperDirection.right);
              },
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Flexible(
                child: Padding(
                    padding: const EdgeInsets.only(left: 6), // 右侧留出空间
                    child: _buildCardData(context)),
              ),
              // Remove the bottom navigation bar with icons
              // Leaving a small space for the new floating action button area
              const SizedBox(height: 60),
            ],
          ),
          // Windows风格左侧状态栏
          Positioned(
            left: 6,
            top: 32,
            bottom: 16,
            child: SizedBox(
              width: 16,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 进度系统
                  ValueListenableBuilder(
                    valueListenable: restartUpdater,
                    builder: (context, _, __) => Column(
                      children: [
                        _buildProgressIndicator(LearningPlanManager.instance.getDailyProgress()),
                        const SizedBox(height: 16),
                        _buildRetryCounter(retryCount, context),
                      ],
                    ),
                  ),

                  // 通知区域占位
                  Container(),
                ],
              ),
            ),
          ),
          
          // 删除顶部的题号选择按钮，移动到底部
        ],
      ),
    );
  }
}

// 现代简约进度条
Widget _buildProgressIndicator(double progress) {
  return Container(
    width: 8,
    height: 120,
    decoration: BoxDecoration(
      color: Colors.grey.withOpacity(0.15),
      borderRadius: BorderRadius.circular(3),
    ),
    child: Stack(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOutQuart,
          height: 120 * progress,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blueAccent.shade100, Colors.lightBlue.shade200],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(3),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              )
            ],
          ),
        ),
      ],
    ),
  );
}

// 立体感计数器
Widget _buildRetryCounter(int count, BuildContext context) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.blue.shade50,
      borderRadius: BorderRadius.circular(6),
      border: Border.all(
        color: Colors.blue.shade200.withOpacity(0.6),
        width: 0.6,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.blue.shade100.withOpacity(0.2),
          blurRadius: 8,
          offset: const Offset(0, 2),
        )
      ],
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.replay, size: 14, color: Colors.blue.shade600),
        const SizedBox(height: 4),
        Text(
          '$count',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Colors.blue.shade900,
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    ),
  );
}
