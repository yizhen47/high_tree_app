import 'package:flutter/material.dart';
import 'package:extended_text/extended_text.dart';
import 'package:flutter_application_1/widget/latex.dart';
import 'package:latext/latext.dart';
import 'dart:math' show min;
import 'package:flutter_application_1/tool/question/question_bank.dart';
import 'package:flutter_application_1/tool/question/question_controller.dart';
import 'package:flutter_application_1/widget/left_toast.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_markdown_latex/flutter_markdown_latex.dart';
import 'package:markdown/markdown.dart' as md;

// 导入子组件
import 'latex_config.dart';
import 'choice_options_widget.dart';
import 'video_content_widget.dart';
import 'knowledge_card_widget.dart';

Card buildQuestionCard(
    BuildContext context, 
    final String knowledgepoint,
    final String question, 
    final String? answer, 
    final String? note,
    [final SingleQuestionData? currentQuestionData,
     final QuestionBank? questionBank]) {
  final ValueNotifier<bool> isExpanded = ValueNotifier(false);
  final ValueNotifier<String> activeFeature = ValueNotifier('none');
  
  final options = currentQuestionData?.question['options'] as List<dynamic>?;
  
  return Card(
    color: Theme.of(context).cardColor,
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(color: Colors.grey.shade200),
    ),
    child: ValueListenableBuilder<bool>(
      valueListenable: isExpanded,
      builder: (context, expanded, _) {
        return SizedBox(
          height: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 内容区域（可滚动）
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 知识点标签
                        _buildKnowledgePointTag(context, knowledgepoint),
                        const SizedBox(height: 12),
                        
                        // 题目内容
                        _buildQuestionContent(context, question),
                        
                        // 显示选项UI (如果题目包含选项)
                        if (options != null && options.isNotEmpty)
                          ChoiceOptionsWidget(
                            options: options,
                            questionData: currentQuestionData,
                          ),

                        // 解析切换按钮
                        _buildExpandButton(context, isExpanded, expanded),
                            
                        // 解析内容
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: expanded ? 1 : 0,
                          child: AnimatedSize(
                            duration: const Duration(milliseconds: 300),
                            child: expanded
                                ? _buildAnswerSection(answer, note, context, currentQuestionData, questionBank)
                                : const SizedBox.shrink(),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
              
              // 功能内容区域
              ValueListenableBuilder<String>(
                valueListenable: activeFeature,
                builder: (context, feature, _) {
                  if (feature == 'none') return const SizedBox.shrink();
                  return _buildFeaturePanel(context, feature, question, knowledgepoint, currentQuestionData, activeFeature, questionBank);
                },
              ),
              
              // 底部功能按钮
              _buildBottomFeatureButtons(context, activeFeature, currentQuestionData),
            ],
          ),
        );
      },
    ),
  );
}

Widget _buildKnowledgePointTag(BuildContext context, String knowledgepoint) {
  return Container(
    decoration: BoxDecoration(
      color: Theme.of(context).primaryColor.withOpacity(0.08),
      borderRadius: BorderRadius.circular(4),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.library_books_outlined,
            size: 14, color: Theme.of(context).primaryColor),
        const SizedBox(width: 6),
        Flexible(
          child: LaTeX(
            laTeXCode: ExtendedText(
              convertLatexDelimiters(knowledgepoint),
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            equationStyle: TextStyle(
              fontSize: latexStyleConfig.fontSize,
              fontWeight: latexStyleConfig.fontWeight,
              fontFamily: latexStyleConfig.mathFontFamily,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildQuestionContent(BuildContext context, String question) {
  final convertedQuestion = convertLatexDelimiters(question);
  return Container(
    padding: const EdgeInsets.only(left: 8),
    decoration: BoxDecoration(
      border: Border(
        left: BorderSide(
          color: Colors.blueGrey.withOpacity(0.25),
          width: 2,
        ),
      ),
    ),
    child: Builder(
      builder: (context) {
        try {
          return LaTeX(
            laTeXCode: ExtendedText(
              convertedQuestion,
              style: TextStyle(
                fontSize: 14.0,
                height: 1.4,
                color: Colors.grey.shade800,
                fontWeight: FontWeight.w500,
              ),
            ),
            equationStyle: TextStyle(
              fontSize: 14.0,
              fontWeight: latexStyleConfig.fontWeight,
              fontFamily: latexStyleConfig.mathFontFamily,
              fontStyle: FontStyle.italic,
            ),
          );
        } catch (e, stackTrace) {
          print("HighTree-Debug: LaTeX rendering failed for question: $question");
          print("HighTree-Debug: Error: $e");
          print("HighTree-Debug: StackTrace: $stackTrace");
          // 降级到纯文本显示
          return ExtendedText(
            question,
            style: TextStyle(
              fontSize: 14.0,
              height: 1.4,
              color: Colors.grey.shade800,
              fontWeight: FontWeight.w500,
            ),
          );
        }
      },
    ),
  );
}

Widget _buildExpandButton(BuildContext context, ValueNotifier<bool> isExpanded, bool expanded) {
  return GestureDetector(
    onTap: () => isExpanded.value = !expanded,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            expanded ? Icons.expand_less : Icons.expand_more,
            color: Colors.blueGrey.shade600,
            size: 18,
          ),
          const SizedBox(width: 6),
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
    ),
  );
}

Widget _buildFeaturePanel(BuildContext context, String feature, String question, 
    String knowledgepoint, SingleQuestionData? currentQuestionData, ValueNotifier<String> activeFeature, QuestionBank? questionBank) {
  return Container(
    decoration: const BoxDecoration(
      color: Colors.white,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.15),
                blurRadius: 4,
                spreadRadius: 1,
                offset: const Offset(0, -2),
              ),
            ],
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                height: 40,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  color: Colors.white,
                ),
                child: GestureDetector(
                  onTap: () => activeFeature.value = 'none',
                  child: Transform.scale(
                    scaleX: 3.0,
                    child: Icon(
                      Icons.keyboard_double_arrow_down,
                      size: 22,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: _buildFeatureContent(feature, question, knowledgepoint, context, currentQuestionData, questionBank),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _buildBottomFeatureButtons(BuildContext context, ValueNotifier<String> activeFeature, SingleQuestionData? currentQuestionData) {
  return Container(
    width: double.infinity,
    decoration: BoxDecoration(
      color: Theme.of(context).cardColor,
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(12),
        bottomRight: Radius.circular(12),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.1),
          spreadRadius: 0,
          blurRadius: 1,
          offset: const Offset(0, -1),
        ),
      ],
    ),
    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildBottomFeatureButton(
          icon: Icons.lightbulb_outline,
          label: '知识点',
          feature: 'knowledge',
          activeFeature: activeFeature,
          context: context,
          currentQuestionData: currentQuestionData,
        ),
        _buildBottomFeatureButton(
          icon: Icons.chat_outlined,
          label: '问AI',
          feature: 'ai',
          activeFeature: activeFeature,
          context: context,
          currentQuestionData: currentQuestionData,
        ),
        _buildBottomFeatureButton(
          icon: Icons.book_outlined,
          label: '同源题',
          feature: 'similar',
          activeFeature: activeFeature,
          context: context,
          currentQuestionData: currentQuestionData,
        ),
      ],
    ),
  );
}

Widget _buildBottomFeatureButton({
  required IconData icon,
  required String label,
  required String feature,
  required ValueNotifier<String> activeFeature,
  required BuildContext context,
  SingleQuestionData? currentQuestionData,
}) {
  final Color primaryColor = Theme.of(context).primaryColor;
  
  return ValueListenableBuilder<String>(
    valueListenable: activeFeature,
    builder: (context, currentFeature, _) {
      final isActive = currentFeature == feature;
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // 知识点按钮特殊处理：直接弹出知识卡片
            if (feature == 'knowledge') {
              print('HighTree-Debug: Knowledge button clicked');
              if (currentQuestionData != null) {
                print('HighTree-Debug: currentQuestionData is not null');
                try {
                  final questionBank = LearningPlanManager.instance.questionBanks.firstOrNull;
                  print('HighTree-Debug: questionBank = $questionBank');
                  if (questionBank != null) {
                    print('HighTree-Debug: currentQuestionData.fromKonwledgeIndex = ${currentQuestionData.fromKonwledgeIndex}');
                    print('HighTree-Debug: currentQuestionData.fromKonwledgePoint = ${currentQuestionData.fromKonwledgePoint}');
                    final knowledgeSection = questionBank.findSectionByQuestion(currentQuestionData);
                    print('HighTree-Debug: knowledgeSection = $knowledgeSection');
                    showKnowledgeCard(context, knowledgeSection, questionBank: questionBank);
                  } else {
                    print('HighTree-Debug: questionBank is null');
                  }
                } catch (e) {
                  print('Error showing knowledge card: $e');
                }
              } else {
                print('HighTree-Debug: currentQuestionData is null');
              }
              return;
            }
            
            // 其他按钮的原有逻辑
            if (isActive) {
              activeFeature.value = 'none';
            } else {
              activeFeature.value = feature;
            }
          },
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon, 
                  size: 18,
                  color: isActive ? primaryColor : Colors.grey.shade500
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: isActive ? primaryColor : Colors.grey.shade600,
                    fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

Widget _buildFeatureContent(String feature, String question, String knowledgepoint, BuildContext context, [SingleQuestionData? currentQuestionData, QuestionBank? questionBank]) {
  final Color primaryColor = Theme.of(context).primaryColor;
  
  switch (feature) {
    case 'ai':
      return _buildSimpleAIContent(question, context, primaryColor);
    case 'similar':
      return _buildSimpleSimilarQuestionsContent(context, primaryColor, currentQuestionData, questionBank);
    default:
      return const SizedBox.shrink();
  }
}

// AI解答内容
Widget _buildSimpleAIContent(String question, BuildContext context, Color primaryColor) {
  return Container(
    margin: const EdgeInsets.symmetric(vertical: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: '点此向AI提问...',
                  hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(color: primaryColor.withOpacity(0.5), width: 1),
                  ),
                ),
                style: const TextStyle(fontSize: 13),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(6),
              ),
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white, size: 16),
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
                onPressed: () {},
              ),
            ),
          ],
        ),
        Container(
          margin: const EdgeInsets.only(top: 8),
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(6),
          ),
          child: LaTeX(
            laTeXCode: ExtendedText(
              convertLatexDelimiters('等待AI回答...'),
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: Colors.grey.shade500,
                fontStyle: FontStyle.italic,
              ),
            ),
            equationStyle: TextStyle(
              fontSize: latexStyleConfig.fontSize,
              fontWeight: latexStyleConfig.fontWeight,
              fontFamily: latexStyleConfig.mathFontFamily,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    ),
  );
}

// 同源题内容 - 简化版
Widget _buildSimpleSimilarQuestionsContent(BuildContext context, Color primaryColor, [SingleQuestionData? currentQuestionData, QuestionBank? questionBank]) {
  const int maxDisplayCount = 5;
  final similarQuestions = <SingleQuestionData>[];
  
  void showQuestion(SingleQuestionData question) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: Colors.transparent,
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.8,
            width: MediaQuery.of(context).size.width * 0.9,
            child: Dismissible(
              key: Key(question.question['id'] ?? 'unknown'),
              direction: DismissDirection.horizontal,
              background: Container(
                decoration: BoxDecoration(
                  color: Colors.red.shade400,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bookmark_add, color: Colors.white, size: 24),
                    SizedBox(height: 8),
                    Text('加入错题本',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              secondaryBackground: Container(
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bookmark_add, color: Colors.white, size: 24),
                    SizedBox(height: 8),
                    Text('加入错题本',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              onDismissed: (direction) {
                showVerticalToast(
                  context: context,
                  title: '错题本',
                  message: '已添加题目',
                  color: direction == DismissDirection.startToEnd 
                      ? Colors.red.shade400 
                      : primaryColor,
                  icon: Icons.bookmark_added,
                );
                Navigator.of(dialogContext).pop();
              },
              confirmDismiss: (direction) async {
                return true;
              },
              child: buildQuestionCard(
                dialogContext,
                question.getKonwledgePoint(),
                question.question['q']!,
                question.question['w'],
                null,
                question,
                questionBank,
              ),
            ),
          ),
        );
      },
    );
  }
  
  if (currentQuestionData != null) {
    try {
      final questionBank = LearningPlanManager.instance.questionBanks.firstOrNull;
      
      if (questionBank != null) {
        final section = questionBank.findSectionByQuestion(currentQuestionData);
        final questions = section.sectionQuestionOnly(
          questionBank.id ?? '',
          questionBank.displayName ?? ''
        );
        
        similarQuestions.addAll(
          questions.where((q) => q.question['id'] != currentQuestionData.question['id'])
        );
      }
    } catch (e) {
      print('Error getting similar questions: $e');
    }
  }
  
  return Container(
    margin: const EdgeInsets.symmetric(vertical: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (similarQuestions.isNotEmpty)
          ...similarQuestions.take(maxDisplayCount).map((question) => 
          Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: Colors.grey.shade200,
                width: 0.5,
              ),
            ),
              child: InkWell(
                onTap: () => showQuestion(question),
            child: Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                        '${similarQuestions.indexOf(question) + 1}',
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                        _formatQuestionPreview(question.question['q'] ?? ''),
                    style: const TextStyle(
                      fontSize: 13,
                    ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey.shade400),
              ],
                ),
              ),
            )
          )
        else
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                '本章节没有其他同源题',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ),
          
        if (similarQuestions.length > maxDisplayCount)
        Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '点击查看更多同源题',
              style: TextStyle(
                fontSize: 12,
                color: primaryColor,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

String _formatQuestionPreview(String question) {
  final cleanText = question
      .replaceAll(RegExp(r'\$\$(.*?)\$\$', dotAll: true), '[数学公式]')
      .replaceAll(RegExp(r'\$(.*?)\$', dotAll: true), '[数学公式]')
      .trim();
      
  if (cleanText.length > 40) {
    return '${cleanText.substring(0, 40)}...';
  }
  return cleanText;
}

// 知识点内容
Widget _buildSimpleKnowledgeContent(String knowledgepoint, BuildContext context, Color primaryColor, [SingleQuestionData? currentQuestionData]) {
  String knowledgePointContent = '';
  Section? knowledgeSection;
  QuestionBank? questionBank;
  
  if (currentQuestionData != null && knowledgepoint.isNotEmpty) {
    try {
      questionBank = LearningPlanManager.instance.questionBanks.firstOrNull;
      
      if (questionBank != null) {
        knowledgeSection = questionBank.findSectionByQuestion(currentQuestionData);
        knowledgePointContent = knowledgeSection.note ?? '暂无相关知识点解析';
      }
    } catch (e) {
      print('Error getting knowledge point: $e');
      knowledgePointContent = '获取知识点信息失败';
    }
  } else {
    knowledgePointContent = '暂无相关知识点';
  }
  
  return Container(
    margin: const EdgeInsets.symmetric(vertical: 10),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.grey.shade50,
      borderRadius: BorderRadius.circular(6),
      border: Border.all(
        color: Colors.grey.shade200,
        width: 0.5,
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.info_outline, 
              size: 14, 
              color: primaryColor
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
              knowledgepoint,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: primaryColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        Padding(
          padding: const EdgeInsets.only(left: 20),
          child: knowledgePointContent.isNotEmpty
              ? MarkdownBody(
                  data: knowledgePointContent,
                  styleSheet: MarkdownStyleSheet(
                    p: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                  selectable: true,
                  builders: {
                    'latex': LatexElementBuilder(
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w100,
                        fontSize: 12,
                      ),
                      textScaleFactor: latexStyleConfig.textScaleFactor,
                    ),
                  },
                  extensionSet: md.ExtensionSet(
                    [LatexBlockSyntax()],
                    [LatexInlineSyntax()],
                  ),
                )
              : Text(
                  '暂无相关知识点解析',
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 12,
              height: 1.5,
                    fontStyle: FontStyle.italic,
                  ),
                ),
        ),
        
        if (knowledgeSection != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 20),
            child: GestureDetector(
              onTap: () {
                showKnowledgeCard(context, knowledgeSection!, questionBank: questionBank);
              },
              child: Text(
                '查看完整知识点',
                style: TextStyle(
                  color: primaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildAnswerSection(String? answer, String? note, BuildContext context, [SingleQuestionData? currentQuestionData, QuestionBank? questionBank]) {
  final hasNote = note?.isNotEmpty ?? false;
  final Color primaryColor = Theme.of(context).primaryColor;
  
  // 检查是否有视频解析
  String? videoPath = currentQuestionData?.question['video']?.toString();
  final hasVideo = videoPath != null && videoPath.isNotEmpty;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 8),
      
      Container(
        padding: const EdgeInsets.all(12),
        width: double.infinity,
        decoration: BoxDecoration(
          color: primaryColor.withOpacity(0.04),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(hasVideo ? Icons.video_library_outlined : Icons.analytics_outlined, 
                  size: 14, 
                  color: primaryColor
                ),
                const SizedBox(width: 6),
                Text(
                  hasVideo ? '视频解析' : '题目解析',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // 如果有视频，显示视频解析；否则显示文本解析
            hasVideo
              ? VideoContentWidget(
                  primaryColor: primaryColor,
                  currentQuestionData: currentQuestionData,
                  questionBank: questionBank,
                )
              : (answer?.isNotEmpty ?? false)
                ? Builder(builder: (context) {
                    final convertedAnswer = convertLatexDelimiters(answer!);
                    try {
                      return LaTeX(
                        laTeXCode: ExtendedText(
                          convertedAnswer,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        equationStyle: TextStyle(
                          fontSize: latexStyleConfig.fontSize,
                          fontWeight: latexStyleConfig.fontWeight,
                          fontFamily: latexStyleConfig.mathFontFamily,
                          fontStyle: FontStyle.italic,
                        ),
                      );
                    } catch (e, stackTrace) {
                      print("HighTree-Debug: LaTeX rendering failed for analysis: $convertedAnswer");
                      print("HighTree-Debug: Error: $e");
                      print("HighTree-Debug: StackTrace: $stackTrace");
                      // 降级到纯文本显示
                      return ExtendedText(
                        answer!,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          color: Colors.grey.shade800,
                        ),
                      );
                    }
                  })
                : Text(
                    '等待老师添加解析中...',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                      fontSize: 12,
                    ),
                  ),
                
            if (hasNote) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              
              Row(
                children: [
                  Icon(Icons.note_alt_outlined, 
                    size: 14, 
                    color: primaryColor
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '学习笔记',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              LaTeX(
                laTeXCode: ExtendedText(
                  convertLatexDelimiters(note!),
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: Colors.grey.shade800,
                  ),
                ),
                equationStyle: TextStyle(
                  fontSize: latexStyleConfig.fontSize,
                  fontWeight: latexStyleConfig.fontWeight,
                  fontFamily: latexStyleConfig.mathFontFamily,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    ],
  );
} 