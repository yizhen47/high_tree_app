import 'package:flutter/material.dart';
import 'package:extended_text/extended_text.dart';
import 'package:flutter_application_1/widget/latex.dart';
import 'package:latext/latext.dart';
import 'dart:math' show min, Random;
import 'package:flutter_application_1/tool/question/question_bank.dart';
import 'package:flutter_application_1/tool/question/question_controller.dart';
import 'package:flutter_application_1/tool/question/wrong_question_book.dart';
import 'package:flutter_application_1/widget/left_toast.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_markdown_latex/flutter_markdown_latex.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:flutter_application_1/services/ai_service.dart';

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
     final QuestionBank? questionBank,
     final bool showBottomButtons = true,
     final bool useFixedHeight = true]) {
  final ValueNotifier<bool> isExpanded = ValueNotifier(false);
  final ValueNotifier<String> activeFeature = ValueNotifier('none');
  
  // AI相关状态管理 - 移到外层避免重建时丢失
  final TextEditingController questionController = TextEditingController();
  final ValueNotifier<String> aiResponseNotifier = ValueNotifier<String>('');
  final ValueNotifier<bool> isLoadingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> hasQuestionedNotifier = ValueNotifier<bool>(false);
  
  final options = currentQuestionData?.question['options'] as List<dynamic>?;
  final difficulty = currentQuestionData?.question['difficulty']?.toString();
  
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
        return useFixedHeight 
          ? SizedBox(
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
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            _buildKnowledgePointTag(context, knowledgepoint),
                            _buildDifficultyIndicator(context, difficulty),
                          ],
                        ),
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
                  return _buildFeaturePanel(
                    context, 
                    feature, 
                    question, 
                    knowledgepoint, 
                    currentQuestionData, 
                    activeFeature, 
                    questionBank,
                    questionController,
                    aiResponseNotifier,
                    isLoadingNotifier,
                    hasQuestionedNotifier,
                  );
                },
              ),
              
              // 底部功能按钮
              if (showBottomButtons)
              _buildBottomFeatureButtons(context, activeFeature, currentQuestionData, questionBank),
            ],
          )
        ) : Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 内容区域（非固定高度）
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 知识点标签
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _buildKnowledgePointTag(context, knowledgepoint),
                      _buildDifficultyIndicator(context, difficulty),
                    ],
                  ),
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
            
            // 功能内容区域
            ValueListenableBuilder<String>(
              valueListenable: activeFeature,
              builder: (context, feature, _) {
                if (feature == 'none') return const SizedBox.shrink();
                return _buildFeaturePanel(
                  context, 
                  feature, 
                  question, 
                  knowledgepoint, 
                  currentQuestionData, 
                  activeFeature, 
                  questionBank,
                  questionController,
                  aiResponseNotifier,
                  isLoadingNotifier,
                  hasQuestionedNotifier,
                );
              },
            ),
            
            // 底部功能按钮
            if (showBottomButtons)
              _buildBottomFeatureButtons(context, activeFeature, currentQuestionData, questionBank),
          ],
        );
      },
    ),
  );
}

Widget _buildDifficultyIndicator(BuildContext context, String? difficultyString) {
  if (difficultyString == null || difficultyString.isEmpty) {
    return const SizedBox.shrink();
  }

  Color difficultyColor;
  String difficultyText;

  switch (difficultyString) {
    case '简单':
      difficultyColor = Colors.green;
      difficultyText = '基础';
      break;
    case '中等':
      difficultyColor = Colors.orange;
      difficultyText = '提高';
      break;
    case '困难':
      difficultyColor = Colors.red;
      difficultyText = '探究';
      break;
    default:
      difficultyColor = Colors.grey;
      difficultyText = difficultyString;
      break;
  }

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: difficultyColor.withOpacity(0.1),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(
      difficultyText,
      style: TextStyle(
        fontSize: 12,
        color: difficultyColor,
        fontWeight: FontWeight.w500,
      ),
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

Widget _buildFeaturePanel(
  BuildContext context, 
  String feature, 
  String question, 
  String knowledgepoint, 
  SingleQuestionData? currentQuestionData, 
  ValueNotifier<String> activeFeature, 
  QuestionBank? questionBank,
  TextEditingController questionController,
  ValueNotifier<String> aiResponseNotifier,
  ValueNotifier<bool> isLoadingNotifier,
  ValueNotifier<bool> hasQuestionedNotifier,
) {
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
                child: _buildFeatureContent(
                  feature, 
                  question, 
                  knowledgepoint, 
                  context,
                  questionController,
                  aiResponseNotifier,
                  isLoadingNotifier,
                  hasQuestionedNotifier,
                  currentQuestionData, 
                  questionBank
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _buildBottomFeatureButtons(BuildContext context, ValueNotifier<String> activeFeature, SingleQuestionData? currentQuestionData, [QuestionBank? questionBank]) {
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
    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
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
          questionBank: questionBank,
        ),
        _buildBottomFeatureButton(
          icon: Icons.chat_outlined,
          label: '问AI',
          feature: 'ai',
          activeFeature: activeFeature,
          context: context,
          currentQuestionData: currentQuestionData,
          questionBank: questionBank,
        ),
        _buildBottomFeatureButton(
          icon: Icons.apps,
          label: '同源题',
          feature: 'similar',
          activeFeature: activeFeature,
          context: context,
          currentQuestionData: currentQuestionData,
          questionBank: questionBank,
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
  QuestionBank? questionBank,
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
                  // 优先使用传入的questionBank参数，如果没有则使用第一个可用的
                  final targetQuestionBank = questionBank ?? LearningPlanManager.instance.questionBanks.firstOrNull;
                  print('HighTree-Debug: questionBank = $targetQuestionBank');
                  if (targetQuestionBank != null) {
                    print('HighTree-Debug: currentQuestionData.fromKonwledgeIndex = ${currentQuestionData.fromKonwledgeIndex}');
                    print('HighTree-Debug: currentQuestionData.fromKonwledgePoint = ${currentQuestionData.fromKonwledgePoint}');
                    final knowledgeSection = targetQuestionBank.findSectionByQuestion(currentQuestionData);
                    print('HighTree-Debug: knowledgeSection = $knowledgeSection');
                    showKnowledgeCard(context, knowledgeSection, questionBank: targetQuestionBank);
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
            
            // 同源题按钮特殊处理：直接跳转到随机同源题
            if (feature == 'similar') {
              _showRandomSimilarQuestion(context, currentQuestionData, questionBank);
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
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
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

Widget _buildFeatureContent(
  String feature, 
  String question, 
  String knowledgepoint, 
  BuildContext context,
  TextEditingController questionController,
  ValueNotifier<String> aiResponseNotifier,
  ValueNotifier<bool> isLoadingNotifier,
  ValueNotifier<bool> hasQuestionedNotifier,
  [SingleQuestionData? currentQuestionData, 
   QuestionBank? questionBank]
) {
  final Color primaryColor = Theme.of(context).primaryColor;
  
  switch (feature) {
    case 'ai':
      return _buildSimpleAIContent(
        question, 
        context, 
        primaryColor,
        questionController,
        aiResponseNotifier,
        isLoadingNotifier,
        hasQuestionedNotifier,
      );
    case 'similar':
      return _buildSimpleSimilarQuestionsContent(context, primaryColor, currentQuestionData, questionBank);
    default:
      return const SizedBox.shrink();
  }
}

// AI解答内容
Widget _buildSimpleAIContent(
  String question, 
  BuildContext context, 
  Color primaryColor,
  TextEditingController questionController,
  ValueNotifier<String> aiResponseNotifier,
  ValueNotifier<bool> isLoadingNotifier,
  ValueNotifier<bool> hasQuestionedNotifier,
) {
  
  Future<void> askAI() async {
    final userQuestion = questionController.text.trim();
    if (userQuestion.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入您的问题')),
      );
      return;
    }
    
    // 检查API密钥是否已配置
    if (!AIService().isApiKeyConfigured()) {
      aiResponseNotifier.value = '错误：AI服务暂不可用，请检查网络连接或联系开发者。';
      hasQuestionedNotifier.value = true;
      return;
    }
    
    isLoadingNotifier.value = true;
    hasQuestionedNotifier.value = true;
    aiResponseNotifier.value = '';
    
    try {
      final response = await AIService().askQuestionStream(
        userQuestion, 
        context: '题目内容：$question',
        onStream: (chunk) {
          // 实时更新UI显示流式输出
          aiResponseNotifier.value += chunk;
        },
      );
      // 确保最终结果完整
      if (response.isNotEmpty) {
        aiResponseNotifier.value = response;
      }
    } catch (e) {
      aiResponseNotifier.value = '获取AI回答时出现错误：$e';
    } finally {
      isLoadingNotifier.value = false;
    }
  }
  
  return Container(
    margin: const EdgeInsets.symmetric(vertical: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: questionController,
                decoration: InputDecoration(
                  hintText: '请输入您想向AI询问的问题...',
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
                maxLines: 2,
                onSubmitted: (_) => askAI(),
              ),
            ),
            const SizedBox(width: 8),
            ValueListenableBuilder<bool>(
              valueListenable: isLoadingNotifier,
              builder: (context, isLoading, _) {
                return Container(
              decoration: BoxDecoration(
                    color: isLoading ? Colors.grey.shade400 : primaryColor,
                borderRadius: BorderRadius.circular(6),
              ),
              child: IconButton(
                    icon: isLoading 
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.send, color: Colors.white, size: 16),
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
                    onPressed: isLoading ? null : askAI,
              ),
                );
              },
            ),
          ],
        ),
        
        ValueListenableBuilder<bool>(
          valueListenable: hasQuestionedNotifier,
          builder: (context, hasQuestioned, _) {
            if (!hasQuestioned) {
              return Container(
          margin: const EdgeInsets.only(top: 8),
          width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.blue.shade200, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb_outline, size: 16, color: Colors.blue.shade600),
                        const SizedBox(width: 6),
                        Text(
                          '智能提问建议',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _buildQuickQuestionChip('这道题的解题思路是什么？', questionController, askAI, primaryColor),
                        _buildQuickQuestionChip('这道题涉及哪些知识点？', questionController, askAI, primaryColor),
                        _buildQuickQuestionChip('有没有更简单的解法？', questionController, askAI, primaryColor),
                        _buildQuickQuestionChip('类似的题目怎么做？', questionController, askAI, primaryColor),
                      ],
                    ),
                  ],
                ),
              );
            }
            
            return ValueListenableBuilder<String>(
              valueListenable: aiResponseNotifier,
              builder: (context, aiResponse, _) {
                return Container(
                  margin: const EdgeInsets.only(top: 8),
                  width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.grey.shade200, width: 1),
          ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 标题栏
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                        child: Row(
                          children: [
                            Icon(Icons.smart_toy, size: 16, color: primaryColor),
                            const SizedBox(width: 6),
                            Text(
                              'AI回答',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: primaryColor,
                              ),
                            ),
                            const Spacer(),
                            if (aiResponse.isNotEmpty && !aiResponse.startsWith('AI正在思考'))
                              IconButton(
                                icon: Icon(Icons.refresh, size: 16, color: Colors.grey.shade600),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () {
                                  hasQuestionedNotifier.value = false;
                                  aiResponseNotifier.value = '';
                                  questionController.clear();
                                },
                              ),
                          ],
                        ),
                      ),
                      // 可滚动的回答内容
                      Container(
                        constraints: const BoxConstraints(
                          maxHeight: 150, // 降低最大高度，让回答更紧凑
                        ),
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        child: SingleChildScrollView(
                          child: aiResponse.isNotEmpty 
                            ? Builder(
                                builder: (context) {
                                  try {
                                    final convertedResponse = convertLatexDelimiters(aiResponse);
                                    return LaTeX(
                                      laTeXCode: ExtendedText(
                                        convertedResponse,
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
                                    print("HighTree-Debug: LaTeX rendering failed for AI response: $aiResponse");
                                    print("HighTree-Debug: Error: $e");
                                    print("HighTree-Debug: StackTrace: $stackTrace");
                                    // 降级到纯文本显示
                                    return SelectableText(
                                      aiResponse,
                                      style: TextStyle(
                                        fontSize: 13,
                                        height: 1.5,
                                        color: Colors.grey.shade800,
                                      ),
                                    );
                                  }
                                },
                              )
                            : Text(
                                '等待您的提问...',
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.5,
                                  color: Colors.grey.shade500,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
            ),
          ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    ),
  );
}

Widget _buildQuickQuestionChip(String question, TextEditingController controller, VoidCallback onTap, Color primaryColor) {
  return GestureDetector(
    onTap: () {
      controller.text = question;
      onTap();
    },
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryColor.withOpacity(0.3), width: 1),
      ),
      child: Text(
        question,
        style: TextStyle(
          fontSize: 11,
          color: primaryColor,
          fontWeight: FontWeight.w500,
        ),
      ),
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
                  color: Colors.green.shade400,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check, color: Colors.white, size: 24),
                    SizedBox(height: 8),
                    Text('答对了',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              secondaryBackground: Container(
                decoration: BoxDecoration(
                  color: Colors.red.shade400,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.close, color: Colors.white, size: 24),
                    SizedBox(height: 8),
                    Text('答错了',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              onDismissed: (direction) {
                if (direction == DismissDirection.startToEnd) {
                  // 左滑：答对了
                  showVerticalToast(
                    context: context,
                    title: '答题结果',
                    message: '答对了！',
                    color: Colors.green.shade400,
                    icon: Icons.check,
                  );
                } else {
                  // 右滑：答错了，加入错题本
                  showVerticalToast(
                    context: context,
                    title: '错题本',
                    message: '答错了，已添加到错题本',
                    color: Colors.red.shade400,
                    icon: Icons.bookmark_added,
                  );
                }
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
            child: GestureDetector(
              onTap: () {
                // 显示所有同源题的对话框
                showDialog(
                  context: context,
                  builder: (dialogContext) {
                    return Dialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Container(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.8,
                          maxWidth: MediaQuery.of(context).size.width * 0.9,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // 标题栏
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.1),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                  topRight: Radius.circular(16),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.quiz, color: primaryColor, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
            child: Text(
                                      '所有同源题 (${similarQuestions.length}题)',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: primaryColor,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () => Navigator.of(dialogContext).pop(),
                                    icon: const Icon(Icons.close, size: 20),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                            ),
                            // 题目列表
                            Expanded(
                              child: ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: similarQuestions.length,
                                itemBuilder: (context, index) {
                                  final question = similarQuestions[index];
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: InkWell(
                                      onTap: () {
                                        Navigator.of(dialogContext).pop();
                                        showQuestion(question);
                                      },
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade50,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: Colors.grey.shade200,
                                            width: 0.5,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 24,
                                              height: 24,
                                              alignment: Alignment.center,
                                              decoration: BoxDecoration(
                                                color: primaryColor.withOpacity(0.1),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Text(
                                                '${index + 1}',
                                                style: TextStyle(
                                                  color: primaryColor,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Builder(
                                                builder: (context) {
                                                  try {
                                                    final questionText = _formatQuestionPreview(question.question['q'] ?? '');
                                                    final convertedQuestion = convertLatexDelimiters(questionText);
                                                    return LaTeX(
                                                      laTeXCode: ExtendedText(
                                                        convertedQuestion,
                                                        style: const TextStyle(
                                                          fontSize: 14,
                                                          height: 1.3,
                                                        ),
                                                        maxLines: 2,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                      equationStyle: TextStyle(
                                                        fontSize: 14.0,
                                                        fontWeight: latexStyleConfig.fontWeight,
                                                        fontFamily: latexStyleConfig.mathFontFamily,
                                                        fontStyle: FontStyle.italic,
                                                      ),
                                                    );
                                                  } catch (e) {
                                                    // 如果LaTeX渲染失败，降级到纯文本显示
                                                    return ExtendedText(
                                                      _formatQuestionPreview(question.question['q'] ?? ''),
                                                      style: const TextStyle(fontSize: 14),
                                                      maxLines: 2,
                                                      overflow: TextOverflow.ellipsis,
                                                    );
                                                  }
                                                },
                                              ),
                                            ),
                                            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              child: Text(
                '点击查看更多同源题 (${similarQuestions.length - maxDisplayCount})',
              style: TextStyle(
                fontSize: 12,
                color: primaryColor,
                  decoration: TextDecoration.underline,
                ),
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
                      answer,
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

// 显示随机同源题
void _showRandomSimilarQuestion(BuildContext context, SingleQuestionData? currentQuestionData, QuestionBank? questionBank) {
  if (currentQuestionData == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('无法获取当前题目信息')),
    );
    return;
  }

  try {
    final targetQuestionBank = questionBank ?? LearningPlanManager.instance.questionBanks.firstOrNull;
    
    if (targetQuestionBank == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('无法获取题库信息')),
      );
      return;
    }

    final section = targetQuestionBank.findSectionByQuestion(currentQuestionData);
    final questions = section.sectionQuestionOnly(
      targetQuestionBank.id ?? '',
      targetQuestionBank.displayName ?? ''
    );
    
    // 过滤掉当前题目
    final similarQuestions = questions.where((q) => q.question['id'] != currentQuestionData.question['id']).toList();
    
    if (similarQuestions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('本章节没有其他同源题')),
      );
      return;
    }
    
    // 随机选择一个题目
    final random = Random();
    final randomQuestion = similarQuestions[random.nextInt(similarQuestions.length)];
    
    // 显示随机选择的题目
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
              key: Key(randomQuestion.question['id'] ?? 'unknown'),
              direction: DismissDirection.horizontal,
              background: Container(
                decoration: BoxDecoration(
                  color: Colors.green.shade400,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check, color: Colors.white, size: 24),
                    SizedBox(height: 8),
                    Text('答对了',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              secondaryBackground: Container(
                decoration: BoxDecoration(
                  color: Colors.red.shade400,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.close, color: Colors.white, size: 24),
                    SizedBox(height: 8),
                    Text('答错了',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              onDismissed: (direction) {
                if (direction == DismissDirection.startToEnd) {
                  // 左滑：答对了
                  showVerticalToast(
                    context: context,
                    title: '答题结果',
                    message: '答对了！',
                    color: Colors.green.shade400,
                    icon: Icons.check,
                  );
                } else {
                  // 右滑：答错了，加入错题本
                  showVerticalToast(
                    context: context,
                    title: '错题本',
                    message: '答错了，已添加到错题本',
                    color: Colors.red.shade400,
                    icon: Icons.bookmark_added,
                  );
                }
                Navigator.of(dialogContext).pop();
              },
              confirmDismiss: (direction) async {
                return true;
              },
              child: buildQuestionCard(
                    dialogContext,
                    randomQuestion.getKonwledgePoint(),
                    randomQuestion.question['q']!,
                    randomQuestion.question['w'],
                    null,
                    randomQuestion,
                    questionBank,
              ),
            ),
          ),
        );
      },
    );
    
  } catch (e) {
    print('Error showing random similar question: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('获取同源题失败')),
    );
  }
} 