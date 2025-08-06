import 'package:flutter/material.dart';
import 'package:flutter_application_1/tool/question/question_bank.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import 'dart:math' show min;

import 'package:extended_text/extended_text.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_markdown_latex/flutter_markdown_latex.dart';
import 'package:latext/latext.dart';
import 'package:flutter_application_1/tool/question/question_controller.dart';
import 'package:flutter_application_1/widget/left_toast.dart';
import 'package:flutter_application_1/tool/question/options_matcher.dart'; // 导入新的选项匹配工具

import 'package:markdown/markdown.dart' as md;

// 确保所有数学符号使用一致的数学模式渲染配置
final latexStyleConfig = LatexStyleConfiguration(
  fontSize: 16,
  fontWeight: FontWeight.w400,
  textStyle: const TextStyle(
    fontWeight: FontWeight.w100,
    fontSize: 16,
    fontFamily: 'CMU', // 直接在textStyle中指定数学字体
    fontStyle: FontStyle.italic, // 确保使用斜体
  ),
  textScaleFactor: 1.2,
  displayMode: true, // 改为true试试看是否能影响公式渲染
  mathFontFamily: 'CMU', // 使用Computer Modern字体家族，这是LaTeX标准数学字体
  forceItalics: true, // 确保数学模式中的变量使用斜体
);

Card buildKnowledgeCard(BuildContext context, final String index,
    final String title, final String knowledge,
    {final String? images}) {
  return Card(
    elevation: 4, // 降低卡片阴影，原值6
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
        padding: const EdgeInsets.all(16), // 减小内边距，原值20
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 修复章节标题显示问题
            _buildHeader(context, index, title), // 提取标题组件

            const SizedBox(height: 16), // 减少间距，原值20

            // 内容滚动区域
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
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
          minWidth: 28, // 减小尺寸，原值32
          // maxWidth: 56,  // 限制最大扩展宽度
        ),
        height: 28, // 减小高度，原值32
        padding: const EdgeInsets.symmetric(horizontal: 4), // 左右留白
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          borderRadius: BorderRadius.circular(4), // 圆角更美观
        ),
        alignment: Alignment.center,
        child: _buildAdaptiveIndexText(index), // 智能文本组件
      ),
      const SizedBox(width: 10), // 缩小间距，原值12
      // 右侧标题部分
      Expanded(
          child: LaTexT(
        laTeXCode: Text(
          title,
          style: TextStyle(
            fontSize: 17, // 减小字体大小，原值20
            fontWeight: FontWeight.w600, // 减小字重，原值w700
            color: Colors.grey.shade800,
            height: 1.2,
            // 恢复原样式，移除数学字体
          ),
        ),
        equationStyle: TextStyle(
          fontSize: 15, // 减小数学公式字体大小
          fontWeight: latexStyleConfig.fontWeight,
          fontFamily: latexStyleConfig.mathFontFamily,
          fontStyle: FontStyle.italic, // 强制使用斜体
        ),
        delimiter: r'$', // 确保使用正确的分隔符
        displayDelimiter: r'$$', // 确保使用正确的分隔符
      )),
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
  return SizedBox(
    width: double.infinity,
    child: MarkdownBody(
      data: knowledge,
      styleSheet: MarkdownStyleSheet(
        p: const TextStyle(fontSize: 14, color: Colors.black87), // 减小正文字号，原值16
        h1: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold), // 减小标题字号，原值16
        h2: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold), // 减小标题字号，原值16
        h3: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        blockquote: const TextStyle(fontSize: 13.5, fontStyle: FontStyle.italic),
        code: const TextStyle(fontSize: 13),
        // 其他元素样式...
      ),
      builders: {
        'latex': LatexElementBuilder(
          textStyle: const TextStyle(
            fontWeight: FontWeight.w100,
            fontSize: 14, // 减小字体大小
            fontFamily: 'CMU',
            fontStyle: FontStyle.italic,
          ),
          textScaleFactor: 1.1, // 减小缩放因子，原值1.2
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

Card buildQuestionCard(
    BuildContext context, 
    final String knowledgepoint,
    final String question, 
    final String? answer, 
    final String? note,
    [final SingleQuestionData? currentQuestionData]) {
  final ValueNotifier<bool> isExpanded = ValueNotifier(false);
  // 添加额外的状态来管理各功能的展开状态
  final ValueNotifier<String> activeFeature = ValueNotifier('none');
  
  // 识别并处理选项 - 使用新的工具类
  final ChoiceOptionsResult optionsResult = OptionsMatcher.extractChoiceOptions(question, answer);
  final List<ChoiceOption> options = optionsResult.options;
  final String cleanedQuestion = optionsResult.cleanedQuestion;
  
  return Card(
    color: Theme.of(context).cardColor,
    elevation: 2,  // 降低卡片阴影
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
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0), // 移除底部填充
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 知识点标签 - 更紧凑的设计
                        Container(
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
                              Expanded(
                                  child: Builder(
                                      builder: (context) => LaTexT(
                                            laTeXCode: ExtendedText(
                                              knowledgepoint,
                                              style: TextStyle(
                                                fontSize: 12, // 更小的字体
                                                color: Theme.of(context).primaryColor,
                                                fontWeight: FontWeight.w500,
                                                // 恢复原样式，移除数学字体
                                              ),
                                            ),
                                            equationStyle: TextStyle(
                                              fontSize: latexStyleConfig.fontSize,
                                              fontWeight: latexStyleConfig.fontWeight,
                                              fontFamily: latexStyleConfig.mathFontFamily,
                                              fontStyle: FontStyle.italic, // 强制使用斜体
                                            ),
                                            delimiter: r'$',
                                            displayDelimiter: r'$$',
                                          ))),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12), // 减少间距

                        // 题目内容 - 加大字体提高可读性
                        Container(
                          padding: const EdgeInsets.only(left: 8),
                          decoration: BoxDecoration(
                            border: Border(
                              left: BorderSide(
                                color: Colors.blueGrey.withOpacity(0.25),
                                width: 2,  // 更细的边框
                              ),
                            ),
                          ),
                          child: Builder(
                            builder: (context) => LaTexT(
                              laTeXCode: ExtendedText(
                                cleanedQuestion, // 使用去除了选项的题目文本
                                style: TextStyle(
                                  fontSize: 14.0, // 减小题目字体大小，原值15.5
                                  height: 1.4, // 减小行高，原值1.5
                                  color: Colors.grey.shade800,
                                  fontWeight: FontWeight.w500,
                                  // 恢复原样式，移除数学字体
                                ),
                              ),
                              equationStyle: TextStyle(
                                fontSize: 14.0, // 减小数学公式字体大小，匹配题目文本
                                fontWeight: latexStyleConfig.fontWeight,
                                fontFamily: latexStyleConfig.mathFontFamily,
                                fontStyle: FontStyle.italic, // 强制使用斜体
                              ),
                              delimiter: r'$',
                              displayDelimiter: r'$$',
                            ),
                          ),
                        ),

                        // 显示选项UI (如果题目包含选项) - 使用新的工具类
                        OptionsMatcher.buildChoiceOptionsUI(
                          options, 
                          context,
                          TextStyle(
                            fontSize: 13,
                            fontWeight: latexStyleConfig.fontWeight,
                            fontFamily: latexStyleConfig.mathFontFamily,
                            fontStyle: FontStyle.italic,
                          ),
                        ),

                        // 解析切换按钮 - 更小更紧凑
                        GestureDetector(
                          onTap: () => isExpanded.value = !expanded,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10), // 减少垂直间距
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  expanded ? Icons.expand_less : Icons.expand_more,
                                  color: Colors.blueGrey.shade600,
                                  size: 18, // 更小的图标
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
                        ),
                            
                        // 解析内容
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
                        
                        // 添加底部间距，防止内容被底部按钮覆盖
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
              
              // 功能内容区域 - 移到底部功能按钮上方
                        ValueListenableBuilder<String>(
                          valueListenable: activeFeature,
                          builder: (context, feature, _) {
                            if (feature == 'none') return const SizedBox.shrink();
                  return Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 统一的功能面板（带收起箭头）
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
                              // 收起箭头指示器（作为面板的一部分）
                              Container(
                                width: double.infinity,
                                height: 40, // 增加高度以容纳标签
                                alignment: Alignment.center,
                                decoration: const BoxDecoration(
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(12),
                                    topRight: Radius.circular(12),
                                  ),
                                  color: Colors.white,
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // 双向下箭头指示器（可点击）
                                    GestureDetector(
                                      onTap: () => activeFeature.value = 'none',
                                      child: Transform.scale(
                                        scaleX: 3.0, // 进一步增加水平拉伸比例
                                        child: Icon(
                                          Icons.keyboard_double_arrow_down,
                                          size: 22,
                                          color: Colors.grey.shade400,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              // 功能内容
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                                child: _buildFeatureContent(feature, question, knowledgepoint, context, currentQuestionData),
                              ),
                      ],
                    ),
                  ),
                      ],
                ),
                  );
                },
              ),
              
              // 底部功能按钮 - 固定在底部
              _buildBottomFeatureButtons(context, activeFeature),
            ],
          ),
        );
      },
    ),
  );
}

// 底部固定的功能按钮组
Widget _buildBottomFeatureButtons(BuildContext context, ValueNotifier<String> activeFeature) {
  final Color primaryColor = Theme.of(context).primaryColor;
  
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
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildBottomFeatureButton(
          icon: Icons.video_library_outlined,
          label: '视频',
          feature: 'video',
          activeFeature: activeFeature,
          context: context,
        ),
        _buildBottomFeatureButton(
          icon: Icons.chat_outlined,
          label: '问AI',
          feature: 'ai',
          activeFeature: activeFeature,
          context: context,
        ),
        _buildBottomFeatureButton(
          icon: Icons.book_outlined,
          label: '同源题',
          feature: 'similar',
          activeFeature: activeFeature,
          context: context,
        ),
        _buildBottomFeatureButton(
          icon: Icons.lightbulb_outline,
          label: '知识点',
          feature: 'knowledge',
          activeFeature: activeFeature,
          context: context,
        ),
      ],
    ),
  );
}

// 底部功能按钮
Widget _buildBottomFeatureButton({
  required IconData icon,
  required String label,
  required String feature,
  required ValueNotifier<String> activeFeature,
  required BuildContext context,
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

// 功能内容显示函数 - 让内容区域更紧凑
Widget _buildFeatureContent(String feature, String question, String knowledgepoint, BuildContext context, [SingleQuestionData? currentQuestionData]) {
  final Color primaryColor = Theme.of(context).primaryColor;
  
  // 为每个功能创建适当的内容展示
  switch (feature) {
    case 'video':
      return _buildSimpleVideoContent(context, primaryColor);
    case 'ai':
      return _buildSimpleAIContent(question, context, primaryColor);
    case 'similar':
      return _buildSimpleSimilarQuestionsContent(context, primaryColor, currentQuestionData);
    case 'knowledge':
      return _buildSimpleKnowledgeContent(knowledgepoint, context, primaryColor, currentQuestionData);
    default:
      return const SizedBox.shrink();
  }
}

// 视频解析内容 - 简化版
Widget _buildSimpleVideoContent(BuildContext context, Color primaryColor) {
  return Container(
    margin: const EdgeInsets.symmetric(vertical: 10), // 减少外边距
    decoration: BoxDecoration(
      color: Colors.grey.shade50,
      borderRadius: BorderRadius.circular(8),
    ),
    child: AspectRatio(
      aspectRatio: 16/9, // 标准视频比例
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 视频播放按钮
          Icon(
            Icons.play_circle_fill,
            size: 48,
            color: primaryColor.withOpacity(0.9),
          ),
          // 右下方提示文字
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                '视频解析',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

// AI解答内容 - 简化版
Widget _buildSimpleAIContent(String question, BuildContext context, Color primaryColor) {
  return Container(
    margin: const EdgeInsets.symmetric(vertical: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 简单输入框
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
        // AI回答显示区域
        Container(
          margin: const EdgeInsets.only(top: 8),
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Builder(
            builder: (context) => LaTexT(
              laTeXCode: ExtendedText(
                '等待AI回答...',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: Colors.grey.shade500,
                  fontStyle: FontStyle.italic,
                  // 恢复原样式，移除数学字体
                ),
              ),
              equationStyle: TextStyle(
                fontSize: latexStyleConfig.fontSize,
                fontWeight: latexStyleConfig.fontWeight,
                fontFamily: latexStyleConfig.mathFontFamily,
                fontStyle: FontStyle.italic, // 强制使用斜体
              ),
              delimiter: r'$',
              displayDelimiter: r'$$',
            ),
          ),
        ),
      ],
    ),
  );
}

// 同源题内容 - 简化版
Widget _buildSimpleSimilarQuestionsContent(BuildContext context, Color primaryColor, [SingleQuestionData? currentQuestionData]) {
  // 显示的最大问题数量
  const int maxDisplayCount = 5;
  final similarQuestions = <SingleQuestionData>[];
  
  // 显示所选问题的处理函数
  void showQuestion(SingleQuestionData question) {
    // 创建一个弹窗显示题目详情
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
                // 在这里添加加入错题本的逻辑
                
                // 使用竖直方向的toast通知
                showVerticalToast(
                  context: context,
                  title: '错题本',
                  message: '已添加题目',
                  color: direction == DismissDirection.startToEnd 
                      ? Colors.red.shade400 
                      : primaryColor,
                  icon: Icons.bookmark_added,
                );
                
                // 关闭弹窗
                Navigator.of(dialogContext).pop();
              },
              confirmDismiss: (direction) async {
                // 可以在这里添加确认对话框
                return true; // 直接确认滑动操作
              },
              child: buildQuestionCard(
                dialogContext,
                question.getKonwledgePoint(),
                question.question['q']!,
                question.question['w'],
                null, // 不带笔记
                question, // 传递题目数据
              ),
            ),
          ),
        );
      },
    );
  }
  
  // 如果提供了特定的问题数据，直接使用它
  if (currentQuestionData != null) {
    try {
      final questionBank = LearningPlanManager.instance.questionBanks.firstOrNull;
      
      if (questionBank != null) {
        // 获取当前问题所属的Section
        final section = questionBank.findSectionByQuestion(currentQuestionData);
        
        // 获取该章节的所有问题
        final questions = section.sectionQuestionOnly(
          questionBank.id ?? '',
          questionBank.displayName ?? ''
        );
        
        // 过滤掉当前问题
        similarQuestions.addAll(
          questions.where((q) => q.question['id'] != currentQuestionData.question['id'])
        );
      }
    } catch (e) {
      // 处理可能的错误
      print('Error getting similar questions: $e');
    }
  } else {
    // 备用方案：尝试从全局状态获取问题
    final currentQuestions = LearningPlanManager.instance.learningPlanItems
        .expand((item) => item.questionList)
        .toList();
    
    if (currentQuestions.isNotEmpty) {
      try {
        final currentQuestion = currentQuestions.last;
        final questionBank = LearningPlanManager.instance.questionBanks.firstOrNull;
        
        if (questionBank != null) {
          // 获取当前问题所属的Section
          final section = questionBank.findSectionByQuestion(currentQuestion);
          
          // 获取该章节的所有问题
          final questions = section.sectionQuestionOnly(
            questionBank.id ?? '',
            questionBank.displayName ?? ''
          );
          
          // 过滤掉当前问题
          similarQuestions.addAll(
            questions.where((q) => q.question['id'] != currentQuestion.question['id'])
          );
        }
      } catch (e) {
        // 处理可能的错误
        print('Error getting similar questions from global state: $e');
      }
    }
  }
  
  return Container(
    margin: const EdgeInsets.symmetric(vertical: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 如果有同源题
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
                        // 截取题目前面的一部分作为预览
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
          
        // 显示更多的提示 (只有当问题数量超过显示数量时才显示)
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

// 辅助方法：格式化问题预览
String _formatQuestionPreview(String question) {
  // 去除Markdown和LaTeX标记
  final cleanText = question
      .replaceAll(RegExp(r'\$\$(.*?)\$\$', dotAll: true), '[数学公式]')
      .replaceAll(RegExp(r'\$(.*?)\$', dotAll: true), '[数学公式]')
      .replaceAll(RegExp(r'\[image:.*?\]'), '[图片]')
      .trim();
      
  // 限制长度
  if (cleanText.length > 40) {
    return '${cleanText.substring(0, 40)}...';
  }
  return cleanText;
}

// 知识点内容 - 简化版
Widget _buildSimpleKnowledgeContent(String knowledgepoint, BuildContext context, Color primaryColor, [SingleQuestionData? currentQuestionData]) {
  // 知识点内容和章节
  String knowledgePointContent = '';
  Section? knowledgeSection;
  
  // 如果直接提供了当前问题数据
  if (currentQuestionData != null && knowledgepoint.isNotEmpty) {
    try {
      final questionBank = LearningPlanManager.instance.questionBanks.firstOrNull;
      
      if (questionBank != null) {
        // 获取当前问题所在的章节
        knowledgeSection = questionBank.findSectionByQuestion(currentQuestionData);
        
        // 使用章节的note作为知识点内容
        knowledgePointContent = knowledgeSection.note ?? '暂无相关知识点解析';
      }
    } catch (e) {
      print('Error getting knowledge point: $e');
      knowledgePointContent = '获取知识点信息失败';
    }
  } else {
    // 备用方案：尝试从全局状态获取
    final currentQuestions = LearningPlanManager.instance.learningPlanItems
        .expand((item) => item.questionList)
        .toList();
    
    if (currentQuestions.isNotEmpty && knowledgepoint.isNotEmpty) {
      try {
        final currentQuestion = currentQuestions.last;
        final questionBank = LearningPlanManager.instance.questionBanks.firstOrNull;
        
        if (questionBank != null) {
          // 获取当前问题所在的章节
          knowledgeSection = questionBank.findSectionByQuestion(currentQuestion);
          
          // 使用章节的note作为知识点内容
          knowledgePointContent = knowledgeSection.note ?? '暂无相关知识点解析';
        }
      } catch (e) {
        print('Error getting knowledge point from global state: $e');
        knowledgePointContent = '获取知识点信息失败';
      }
    } else {
      knowledgePointContent = '暂无相关知识点';
    }
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
            // 显示知识点名称
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
        
        // 显示知识点内容
        Padding(
          padding: const EdgeInsets.only(left: 20),
          child: knowledgePointContent.isNotEmpty
              ? Builder(
                  builder: (context) => MarkdownBody(
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
        
        // 如果有知识点章节，添加一个查看完整章节按钮
        if (knowledgeSection != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 20),
            child: GestureDetector(
              onTap: () {
                // 显示完整知识点章节
                showKnowledgeCard(context, knowledgeSection!);
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

// 重新设计解析区域，让它更紧凑
Widget _buildAnswerSection(String? answer, String? note, BuildContext context) {
  final hasNote = note?.isNotEmpty ?? false;
  final Color primaryColor = Theme.of(context).primaryColor;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 8), // 减少间距
      
      // 解析部分
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
            // 标题
            Row(
              children: [
                Icon(Icons.analytics_outlined, 
                  size: 14, 
                  color: primaryColor
                ),
                const SizedBox(width: 6),
                Text(
                  '题目解析',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // 内容
            (answer?.isNotEmpty ?? false)
              ? Builder(
                  builder: (context) => LaTexT(
                    laTeXCode: ExtendedText(
                      answer!,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: Colors.grey.shade800,
                        // 恢复原样式，移除数学字体
                      ),
                    ),
                    equationStyle: TextStyle(
                      fontSize: latexStyleConfig.fontSize,
                      fontWeight: latexStyleConfig.fontWeight,
                      fontFamily: latexStyleConfig.mathFontFamily,
                      fontStyle: FontStyle.italic, // 强制使用斜体
                    ),
                    delimiter: r'$',
                    displayDelimiter: r'$$',
                  ),
                )
              : Text(
                  '等待老师添加解析中...',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                    fontSize: 12,
                  ),
                ),
                
            // 笔记部分 (如果有)
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
              
              Builder(
                builder: (context) => LaTexT(
                  laTeXCode: ExtendedText(
                    note!,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: Colors.grey.shade800,
                      // 恢复原样式，移除数学字体
                    ),
                  ),
                  equationStyle: TextStyle(
                    fontSize: latexStyleConfig.fontSize,
                    fontWeight: latexStyleConfig.fontWeight,
                    fontFamily: latexStyleConfig.mathFontFamily,
                    fontStyle: FontStyle.italic, // 强制使用斜体
                  ),
                  delimiter: r'$',
                  displayDelimiter: r'$$',
                ),
              ),
            ],
          ],
        ),
      ),
    ],
  );
}

void showKnowledgeCard(BuildContext context, Section section) {
  var screenWidth = MediaQuery.of(context).size.width;
  var screenHeight = MediaQuery.of(context).size.height;

  Navigator.of(context).push(
    TDSlidePopupRoute(
      // modalBarrierColor:
      //     TDTheme.of(context).fontGyColor2,
      slideTransitionFrom: SlideTransitionFrom.center,
      builder: (_) {
        return TDPopupCenterPanel(
          radius: 16, // 增加圆角半径与Card一致
          backgroundColor: Colors.transparent,
          closeClick: () {
            Navigator.maybePop(context);
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16), // 裁剪内容区域，确保内容也是圆角
          child: SizedBox(
            width: screenWidth - 80,
            height: screenHeight - 150,
            child: buildKnowledgeCard(
                context, section.index, section.title, section.note ?? "暂无知识点"),
            ),
          ),
        );
      },
    ),
  );
}

// 获取功能标题
String _getFeatureTitle(String feature) {
  switch (feature) {
    case 'video':
      return '视频解析';
    case 'ai':
      return 'AI助手';
    case 'similar':
      return '同源题';
    case 'knowledge':
      return '知识点';
    default:
      return '功能';
  }
}

// 样式配置类
class LatexStyleConfiguration {
  final double fontSize;
  final FontWeight fontWeight;
  final TextStyle textStyle;
  final double textScaleFactor;
  final bool displayMode;
  final String mathFontFamily;
  final bool forceItalics;

  LatexStyleConfiguration({
    required this.fontSize,
    required this.fontWeight,
    required this.textStyle,
    required this.textScaleFactor,
    required this.displayMode,
    required this.mathFontFamily,
    required this.forceItalics,
  });
}
