
import 'package:flutter/material.dart';
import 'package:flutter_application_1/tool/question_bank.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

import 'package:extended_text/extended_text.dart';
import 'package:flutter_application_1/widget/question_text.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_markdown_latex/flutter_markdown_latex.dart';
import 'package:latext/latext.dart';

import 'package:markdown/markdown.dart' as md;

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
        return SizedBox(
          height: double.infinity,
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
                            child: Builder(
                                builder: (context) => LaTexT(
                                      laTeXCode: ExtendedText(
                                        knowledgepoint,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Theme.of(context).primaryColor,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ))),
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
          radius: 15,
          backgroundColor: Colors.transparent,
          closeClick: () {
            Navigator.maybePop(context);
          },
          child: SizedBox(
            width: screenWidth - 80,
            height: screenHeight - 150,
            child: buildKnowledgeCard(
                context, section.index, section.title, section.note ?? "暂无知识点"),
          ),
        );
      },
    ),
  );
}
