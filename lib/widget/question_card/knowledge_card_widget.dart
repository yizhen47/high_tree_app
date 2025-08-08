import 'dart:io';
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
import 'video_player_widget.dart';
import 'package:path/path.dart' as path;
import 'dart:developer' as developer;
import 'question_card_widget.dart';

Card buildKnowledgeCard(BuildContext context, final String index,
    final String title, final String knowledge,
    {final String? images, final List<String>? videos, final QuestionBank? questionBank, final Section? section}) {
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
                    if (images != null) _buildImageSection(images, questionBank),
                    if (videos != null && videos.isNotEmpty) _buildVideoSection(videos, questionBank),
                  ],
                ),
              ),
            ),
            if (section != null) _buildPracticeButton(context, section, questionBank),
          ],
        ),
      ),
    ),
  );
}

Widget _buildPracticeButton(BuildContext context, Section section, QuestionBank? questionBank) {
  return Padding(
    padding: const EdgeInsets.only(top: 16.0),
    child: ElevatedButton.icon(
      onPressed: () {
        final questions = section.sectionQuestion(questionBank?.id ?? '', questionBank?.displayName ?? '');
        if (questions.isNotEmpty) {
          final question = questions.first;
          showDialog(
            context: context,
            builder: (dialogContext) {
              final screenHeight = MediaQuery.of(dialogContext).size.height;
              final screenWidth = MediaQuery.of(dialogContext).size.width;
              return Dialog(
                backgroundColor: Colors.transparent,
                child: SizedBox(
                  height: screenHeight * 0.8,
                  width: screenWidth * 0.9,
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
              );
            },
          );
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('该知识点下暂无题目')),
            );
          }
        }
      },
      icon: const Icon(Icons.quiz_outlined),
      label: const Text('来道题试试'),
      style: ElevatedButton.styleFrom(
        foregroundColor: Theme.of(context).primaryColor, backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
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

Widget _buildImageSection(String images, QuestionBank? questionBank) {
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
        child: _buildImageWidget(images, questionBank),
      ),
    ),
  );
}

Widget _buildImageWidget(String imagePath, QuestionBank? questionBank) {
  // 判断图片路径类型并选择合适的加载方式
  if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
    // 网络图片
    return Image.network(
      imagePath,
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
      errorBuilder: (context, error, stackTrace) {
        return Container(
          height: 200,
          alignment: Alignment.center,
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, color: Colors.red, size: 48),
              SizedBox(height: 8),
              Text('图片加载失败', style: TextStyle(color: Colors.red)),
            ],
          ),
        );
      },
    );
  } else if (imagePath.startsWith('assets/')) {
    // Asset图片
    return Image.asset(
      imagePath,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          height: 200,
          alignment: Alignment.center,
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, color: Colors.red, size: 48),
              SizedBox(height: 8),
              Text('图片加载失败', style: TextStyle(color: Colors.red)),
            ],
          ),
        );
      },
    );
  } else {
    // 本地文件图片 - 需要在题库缓存目录中查找
    return FutureBuilder<String?>(
      future: _findAssetInQuestionBank(imagePath, questionBank, isVideo: false),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 200,
            alignment: Alignment.center,
            child: const CircularProgressIndicator(),
          );
        }
        
        final foundPath = snapshot.data;
        if (foundPath != null) {
          return Image.file(
            File(foundPath),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 200,
                alignment: Alignment.center,
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error, color: Colors.red, size: 48),
                    SizedBox(height: 8),
                    Text('图片加载失败', style: TextStyle(color: Colors.red)),
                  ],
                ),
              );
            },
          );
        } else {
          return Container(
            height: 200,
            alignment: Alignment.center,
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.image_not_supported, color: Colors.grey, size: 48),
                SizedBox(height: 8),
                Text('图片文件不存在', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }
      },
    );
  }
}

Future<String?> _findAssetInQuestionBank(String assetPath, QuestionBank? questionBank, {required bool isVideo}) async {
  developer.log('[findAsset] Searching for: $assetPath, isVideo: $isVideo', name: 'KnowledgeCard');
  // 1. 如果是网络路径，直接返回
  if (assetPath.startsWith('http://') || assetPath.startsWith('https://')) {
    developer.log('[findAsset] Path is a URL, returning as is: $assetPath', name: 'KnowledgeCard');
    return assetPath;
  }
  
  // 2. 如果是绝对路径，检查文件是否存在
  final absoluteFile = File(assetPath);
  if (await absoluteFile.exists()) {
    developer.log('[findAsset] Found absolute path: ${absoluteFile.path}', name: 'KnowledgeCard');
    return assetPath;
  }

  // 3. 如果没有题库信息，无法查找缓存，返回null
  if (questionBank?.cacheDir == null) {
    developer.log('[findAsset] No question bank cache directory provided.', name: 'KnowledgeCard');
    return null;
  }
  
  // 4. 在题库缓存目录中尝试多种路径组合
  final cacheDirPath = questionBank!.cacheDir!;
  final assetSubDir = isVideo ? 'videos' : 'images';
  developer.log('[findAsset] Searching in cache directory: $cacheDirPath', name: 'KnowledgeCard');

  // 使用 Set 避免重复检查相同路径
  final possiblePaths = <String>{
    // 路径1: cache/微分方程知识图谱素材/伯努利方程.png (兼容旧格式)
    path.join(cacheDirPath, assetPath),
    // 路径2: cache/assets/微分方程知识图谱素材/伯努利方程.png (兼容旧格式)
    path.join(cacheDirPath, 'assets', assetPath),
    // 路径3: cache/assets/images/微分方程知识图谱素材/伯努利方程.png (正确的目标路径)
    path.join(cacheDirPath, 'assets', assetSubDir, assetPath),
  };

  developer.log('[findAsset] Possible paths to check:\n${possiblePaths.map((p) => "                $p").join('\n')}', name: 'KnowledgeCard');
  
  for (var fullPath in possiblePaths) {
    final file = File(fullPath);
    if (await file.exists()) {
      developer.log('[findAsset] Found asset at: $fullPath', name: 'KnowledgeCard');
      return fullPath;
    }
  }
  
  developer.log('[findAsset] Asset not found in any possible path: $assetPath', name: 'KnowledgeCard');
  // 5. 如果都找不到，返回null
  return null;
}


Widget _buildVideoSection(List<String> videos, QuestionBank? questionBank) {
  return Padding(
    padding: const EdgeInsets.only(top: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.video_library, color: Colors.red[600], size: 20),
            const SizedBox(width: 8),
            Text(
              '视频课程 (${videos.length})',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.red[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...videos.asMap().entries.map((entry) {
          final index = entry.key;
          final video = entry.value;
          return Builder(
            builder: (context) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () {
                  _showVideoDialog(context, video, questionBank);
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.red[600],
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '视频课程 ${index + 1}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              video,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.grey[400],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    ),
  );
}

void _showVideoDialog(BuildContext context, String videoPath, QuestionBank? questionBank) {
  developer.log('[showVideoDialog] Showing video dialog for: $videoPath', name: 'KnowledgeCard');
  showDialog(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.9,
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: FutureBuilder<String?>(
          future: _findAssetInQuestionBank(videoPath, questionBank, isVideo: true),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              );
            }

            if (snapshot.hasError) {
              developer.log('[showVideoDialog] Error finding video path: ${snapshot.error}', name: 'KnowledgeCard', error: snapshot.error);
              return Center(child: Text('加载视频出错: ${snapshot.error}'));
            }

            final foundPath = snapshot.data;
            developer.log('[showVideoDialog] FutureBuilder result for video path: $foundPath', name: 'KnowledgeCard');

            if (foundPath != null) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: VideoPlayerWidget(
                  videoPath: foundPath,
                  primaryColor: Theme.of(context).primaryColor,
                ),
              );
            } else {
              developer.log('[showVideoDialog] Video path not found, showing error.', name: 'KnowledgeCard');
              return Container(
                alignment: Alignment.center,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.video_library_outlined, size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('视频文件不存在', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              );
            }
          },
        ),
      ),
    ),
  );
}

void showKnowledgeCard(BuildContext context, Section section, {QuestionBank? questionBank}) {
  var screenWidth = MediaQuery.of(context).size.width;
  var screenHeight = MediaQuery.of(context).size.height;

  Navigator.of(context).push(
    TDSlidePopupRoute(
      slideTransitionFrom: SlideTransitionFrom.center,
      builder: (popupContext) {
        return TDPopupCenterPanel(
          radius: 16,
          backgroundColor: Colors.transparent,
          closeClick: () {
            Navigator.maybePop(popupContext);
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              width: screenWidth - 80,
              height: screenHeight - 150,
              child: buildKnowledgeCard(
                popupContext,
                section.index,
                section.title,
                section.note ?? "",
                images: section.image,
                videos: section.videos,
                questionBank: questionBank,
                section: section,
              ),
            ),
          ),
        );
      },
    ),
  );
} 