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
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_markdown_latex/flutter_markdown_latex.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:latext/latext.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:markdown/markdown.dart' as md;
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
          crossAxisAlignment: CrossAxisAlignment.stretch, // 关键修改1：撑满横向空间
          children: [
            // 修复章节标题显示问题
            _buildHeader(context, index, title), // 提取标题组件

            const SizedBox(height: 20),

            // 内容滚动区域
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.stretch, // 关键修改2：内容横向撑满
                  children: [
                    _buildMarkdownContent(knowledge), // Markdown内容
                    if (images != null) _buildImageSection(images), // 图片部分
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _buildHeader(BuildContext context, String index, String title) {
  return Row(
    children: [
      // 左侧 index 容器
      Container(
        constraints: const BoxConstraints(
          minWidth: 32, // 最小保持正方形
          // maxWidth: 56,  // 限制最大扩展宽度
        ),
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 4), // 左右留白
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          borderRadius: BorderRadius.circular(4), // 圆角更美观
        ),
        alignment: Alignment.center,
        child: _buildAdaptiveIndexText(index), // 智能文本组件
      ),
      const SizedBox(width: 12), // 缩小间距
      // 右侧标题部分
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
  );
}

// 智能文本适配组件
Widget _buildAdaptiveIndexText(String text) {
  return LayoutBuilder(
    builder: (context, constraints) {
      // 计算文本宽度是否超出容器
      final textSpan = TextSpan(
          text: text, style: const TextStyle(fontWeight: FontWeight.bold));
      final painter = TextPainter(
        text: textSpan,
        maxLines: 1,
        textDirection: TextDirection.ltr,
      )..layout();

      // 根据宽度动态选择布局
      if (painter.width > constraints.maxWidth) {
        return FittedBox(
          // 超长文本缩放
          fit: BoxFit.scaleDown,
          child: Text(text, style: const TextStyle(color: Colors.white)),
        );
      } else {
        return Text(
          // 正常显示
          text,
          style: const TextStyle(color: Colors.white),
          overflow: TextOverflow.clip,
        );
      }
    },
  );
}

// Markdown内容组件
Widget _buildMarkdownContent(String knowledge) {
  return Container(
    width: double.infinity,
    child: MarkdownBody(
      data: knowledge,
      styleSheet: MarkdownStyleSheet(
        p: const TextStyle(fontSize: 16, color: Colors.black87), // 统一正文字号
        h1: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        h2: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        // 其他元素样式...
      ),
      builders: {
        'latex': LatexElementBuilder(
          textStyle: const TextStyle(
            fontWeight: FontWeight.w100,
            fontSize: 16, // 与普通文本一致
          ),
          textScaleFactor: 1.2,
        ),
      },
      extensionSet: md.ExtensionSet(
        [LatexBlockSyntax()],
        [LatexInlineSyntax()],
      ),
    ),
  );
}

// 图片组件
Widget _buildImageSection(String images) {
  return Padding(
    padding: const EdgeInsets.only(top: 24),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity, // 关键修改4：图片横向撑满
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
          constraints: const BoxConstraints(
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
                    child: Builder(
                      builder: (context) => LaTexT(
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
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.blueGrey.withOpacity(0.03),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blueGrey.withOpacity(0.1)),
        ),
        child: (content?.isNotEmpty ?? false)
            ? Builder(
                builder: (context) => LaTexT(
                  laTeXCode: ExtendedText(
                    content!,
                    specialTextSpanBuilder: MathIncludeTextSpanBuilder(),
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      color: Colors.grey.shade800,
                    ),
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

// 弹跳动画组件示例
class BounceTransition extends StatelessWidget {
  final Widget child;

  final AnimationController controller;

  const BounceTransition(
      {super.key, required this.child, required this.controller});

  @override
  Widget build(BuildContext context) {
    final animation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(
        parent: controller,
        curve: Curves.elasticOut,
      ),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, animation.value),
          child: child,
        );
      },
      child: child,
    );
  }
}

class _InnerState extends State<QuestionScreen> with TickerProviderStateMixin {
  List<String> idList = [];

  final CardSwiperController controller = CardSwiperController();

  final List<SingleQuestionData> allQuestions = [];
  final List<bool> questionRemoved = [];
  final List<SingleQuestionData> leftQuestions = [];
  final List<SingleQuestionData> rightQuestions = [];
  int questionRemain = 0;

// 构建带动画的图标组件
  Widget _buildAnimatedIcons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const ScaleTransition(
          scale: AlwaysStoppedAnimation(1.2),
          child: Icon(
            Icons.emoji_flags,
            size: 100,
            color: Colors.orange,
          ),
        ),
        BounceTransition(
          // 自定义弹跳动画
          child: const Icon(
            Icons.emoji_people,
            size: 80,
            color: Colors.lightBlue,
          ),
          controller: _controller,
        ),
      ],
    );
  }

  // 在State类中添加
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

// 构建统一风格的按钮组件
  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
            ],
          ),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  _buildCompleteCard(BuildContext context) {
    return Card(
      color: Theme.of(context).cardColor,
      elevation: 8, // 增加阴影高度
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0), // 更圆润的边框
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 图标部分添加动画
              _buildAnimatedIcons(),
              const SizedBox(height: 25),

              // 标题文字样式优化
              Text(
                '🎉 任务完成！',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              const SizedBox(height: 15),

              // 提示文字样式优化
              Text(
                '您已经完成了所有题目',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.secondary,
                    ),
              ),
              const SizedBox(height: 30),

              // 图片容器优化
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    const BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    )
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.asset(
                    'assets/come_on.jpg',
                    height: 180,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // 按钮组布局
              Column(
                children: [
                  Text(
                    '请选择下一步操作',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 25),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 继续按钮美化
                      _buildActionButton(
                        context,
                        icon: Icons.refresh,
                        label: '继续刷题',
                        onTap: () => Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const ModeScreen(title: '刷题界面'),
                          ),
                          (route) => route.isFirst,
                        ),
                      ),
                      const SizedBox(width: 20),
                      // 退出按钮美化
                      _buildActionButton(
                        context,
                        icon: Icons.exit_to_app,
                        label: '退出',
                        onTap: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

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
                    final studyType = StudyData.instance.getStudyType();
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
                        WrongQuestionBook.instance
                            .getQuestion(q.question['id']!)
                            .note,
                      ));
                    }

                    // 测试模式处理
                    if (isTestMode) {
                      final secList = StudyData.instance.getStudySection();
                      Map<String, List<int>> dtype = {};

                      if (secList != null) {
                        final decoded =
                            json.decode(secList) as Map<String, dynamic>;
                        dtype = decoded.map(
                            (k, v) => MapEntry(k, List<int>.from(v as List)));
                      }

                      final rQdb = snapshot.data!;
                      final sectionKeys = List<String>.from(dtype.keys);

                      for (int i = 0;
                          i < StudyData.instance.getStudyQuestionNum();
                          i++) {
                        final randomKey =
                            sectionKeys[Random().nextInt(sectionKeys.length)];
                        final sectionData = rQdb[int.parse(randomKey)];
                        final questionIndexes = dtype[randomKey]!;
                        final randomIndex = questionIndexes[
                            Random().nextInt(questionIndexes.length)];

                        final question = sectionData.data![randomIndex];
                        final qData = question.randomSectionQuestion(
                            [], [], sectionData.id!, sectionData.displayName!);

                        addQuestionCard(qData);
                      }
                    }

// 学习模式处理
                    else if (isStudyMode) {
                      final secList = StudyData.instance.getStudySection() ??
                          (throw Exception("需要指定学习章节"));
                      Section currentSection = Section("", "")
                        ..children = snapshot.data!.single.data;
                      final knowledgePath = secList.split("/");

                      // 递归构建知识卡片
                      void buildSectionTree(Section section) {
                        cards.add(buildKnowledgeCard(context, section.index,
                            section.title, section.note ?? "暂无知识点"));
                        questionRemoved.add(false);
                        allQuestions
                            .add(SingleQuestionData([], [], {}, "", ""));
                        questionRemain++;

                        section.children
                            ?.forEach((child) => buildSectionTree(child));
                      }

                      // 定位目标章节
                      for (final index in knowledgePath) {
                        currentSection = currentSection.children!
                            .firstWhere((e) => e.index == index);
                      }

                      buildSectionTree(currentSection);
                      currentSection
                          .sectionQuestion(
                            knowledgePath
                                .map((e) => currentSection.title)
                                .toList(),
                            knowledgePath,
                            snapshot.data!.single.id!,
                            snapshot.data!.single.displayName!,
                          )
                          .forEach(addQuestionCard);
                    }

// 滑动处理统一逻辑
                    void handleQuestionSwipe(
                        int index, CardSwiperDirection direction) {
                      final question = allQuestions[index];
                      questionRemoved[index] = true;
                      questionRemain--;

                      if (question.fromKonwledgeIndex.isNotEmpty) {
                        final questionId =
                            question.question['id'] ?? const Uuid().v4();
                        final questionData =
                            WrongQuestionBook.instance.getQuestion(questionId);

                        if (direction == CardSwiperDirection.right) {
                          idList.add(questionId);
                          if (!WrongQuestionBook.instance
                              .hasWrongQuestion(questionId)) {
                            WrongQuestionBook.instance
                                .addWrongQuestion(questionId, question);
                          }
                        }

                        questionData.happenedTimes =
                            (questionData.happenedTimes ?? 0) + 1;
                      }
                    }

                    // 卡片滑动组件
                    return CardSwiper(
                      controller: controller,
                      onSwipe: (previousIndex, currentIndex, direction) {
                        if (questionRemain > 0) {
                          final index = previousIndex!;
                          final question = allQuestions[index];

                          // 生成持久化ID（重要修复）
                          final String questionId =
                              question.question['id'] ?? '';

                          // 记录发生次数（无论是否知识点题目）
                          final userData = WrongQuestionBook.instance
                              .getQuestion(questionId);
                          userData.happenedTimes++;
                          print(userData.happenedTimes);

                          // 仅知识点题目需要记录错题本
                          if (question.fromKonwledgeIndex.isNotEmpty) {
                            if (direction == CardSwiperDirection.right) {
                              if (!WrongQuestionBook.instance
                                  .hasWrongQuestion(questionId)) {
                                WrongQuestionBook.instance
                                    .addWrongQuestion(questionId, question);
                                idList.add(questionId); // 记录可撤销的错题ID
                                TDToast.showSuccess("已加入错题本", context: context);
                              } else {
                                TDToast.showWarning("已在错题本中", context: context);
                                idList.add(const Uuid().v4()); // 生成伪ID防止误删
                              }
                            }
                          }

                          // 状态更新（统一处理）
                          questionRemoved[index] = true;
                          questionRemain--;
                          direction == CardSwiperDirection.right
                              ? rightQuestions.add(question)
                              : leftQuestions.add(question);

                          return true;
                        }
                        return false;
                      },
                      cardsCount: cards.length,
                      cardBuilder: (context, index, percentThresholdX,
                          percentThresholdY) {
                        if (questionRemain == 0) {
                          return _buildCompleteCard(context);
                        } else {
                          // 记录原始索引和尝试次数防止死循环
                          int originalIndex = index;
                          int attempts = 0;

                          // 查找下一个未移除的卡片，最多尝试cards.length次
                          while (questionRemoved[index] &&
                              attempts < cards.length) {
                            index = (index + 1) % cards.length;
                            attempts++;
                          }

                          // 所有卡片都被移除了但questionRemain未及时更新，强制显示完成
                          if (attempts >= cards.length ||
                              questionRemoved[index]) {
                            return _buildCompleteCard(context);
                          }

                          return cards[index];
                        }
                      },
                      // 在 CardSwiper 的 onUndo 回调中直接实现撤销逻辑（原简写方案中缺失的部分）
                      onUndo: (previousIndex, currentIndex, direction) {
                        final question = allQuestions[currentIndex];
                        final String questionId =
                            question.question['id'] ?? '';

                        // 还原发生次数
                        final userData =
                            WrongQuestionBook.instance.getQuestion(questionId);
                        userData.happenedTimes--;

                        if (direction == CardSwiperDirection.right) {
                          // 错题本撤销处理
                          if (question.fromKonwledgeIndex.isNotEmpty) {
                            final removedId = idList.removeLast();
                            if (removedId == questionId) {
                              // 验证ID一致性
                              WrongQuestionBook.instance
                                  .removeWrongQuestion(removedId);
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
            ),
          ),
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
