import 'package:flutter/material.dart';
import 'package:extended_text/extended_text.dart';
import 'package:flutter_application_1/widget/latex.dart';
import 'package:latext/latext.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_markdown_latex/flutter_markdown_latex.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:tdesign_flutter/tdesign_flutter.dart';
import 'package:flutter_application_1/tool/question/question_bank.dart';
import 'latex_config.dart';

Card buildKnowledgeCard(BuildContext context, final String index,
    final String title, final String knowledge,
    {final String? images}) {
  return Card(
    elevation: 4,
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context, index, title),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildMarkdownContent(knowledge),
                    if (images != null) _buildImageSection(images),
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
      Container(
        constraints: const BoxConstraints(minWidth: 28),
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          borderRadius: BorderRadius.circular(4),
        ),
        alignment: Alignment.center,
        child: _buildAdaptiveIndexText(index),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: LaTeX(
          laTeXCode: Text(
            convertLatexDelimiters(title),
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
              height: 1.2,
            ),
          ),
          equationStyle: TextStyle(
            fontSize: 15,
            fontWeight: latexStyleConfig.fontWeight,
            fontFamily: latexStyleConfig.mathFontFamily,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    ],
  );
}

Widget _buildAdaptiveIndexText(String text) {
  return LayoutBuilder(
    builder: (context, constraints) {
      final textSpan = TextSpan(
        text: text,
        style: const TextStyle(fontWeight: FontWeight.bold),
      );
      final painter = TextPainter(
        text: textSpan,
        maxLines: 1,
        textDirection: TextDirection.ltr,
      )..layout();

      if (painter.width > constraints.maxWidth) {
        return FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(text, style: const TextStyle(color: Colors.white)),
        );
      } else {
        return Text(
          text,
          style: const TextStyle(color: Colors.white),
          overflow: TextOverflow.clip,
        );
      }
    },
  );
}

Widget _buildMarkdownContent(String knowledge) {
  return SizedBox(
    width: double.infinity,
    child: MarkdownBody(
      data: knowledge,
      styleSheet: MarkdownStyleSheet(
        p: const TextStyle(fontSize: 14, color: Colors.black87),
        h1: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        h2: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold),
        h3: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        blockquote: const TextStyle(fontSize: 13.5, fontStyle: FontStyle.italic),
        code: const TextStyle(fontSize: 13),
      ),
      builders: {
        'latex': LatexElementBuilder(
          textStyle: const TextStyle(
            fontWeight: FontWeight.w100,
            fontSize: 14,
            fontFamily: 'CMU',
            fontStyle: FontStyle.italic,
          ),
          textScaleFactor: 1.1,
        ),
      },
      extensionSet: md.ExtensionSet(
        [LatexBlockSyntax()],
        [LatexInlineSyntax()],
      ),
    ),
  );
}

Widget _buildImageSection(String images) {
  return Padding(
    padding: const EdgeInsets.only(top: 24),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
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

void showKnowledgeCard(BuildContext context, Section section) {
  var screenWidth = MediaQuery.of(context).size.width;
  var screenHeight = MediaQuery.of(context).size.height;

  Navigator.of(context).push(
    TDSlidePopupRoute(
      slideTransitionFrom: SlideTransitionFrom.center,
      builder: (_) {
        return TDPopupCenterPanel(
          radius: 16,
          backgroundColor: Colors.transparent,
          closeClick: () {
            Navigator.maybePop(context);
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              width: screenWidth - 80,
              height: screenHeight - 150,
              child: buildKnowledgeCard(
                context,
                section.index,
                section.title,
                section.note ?? "暂无知识点",
              ),
            ),
          ),
        );
      },
    ),
  );
} 