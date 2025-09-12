import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/screen/fullscreen_video_page.dart';
import 'package:flutter_application_1/widget/latex.dart';
import 'package:flutter_application_1/widget/question_card/question_card_widget.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_markdown_latex/flutter_markdown_latex.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:tdesign_flutter/tdesign_flutter.dart';
import 'package:flutter_application_1/tool/question/question_bank.dart';
import 'latex_config.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path/path.dart' as path;
import 'dart:developer' as developer;
import 'package:video_player/video_player.dart';
import 'dart:async';

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
              Icon(Icons.error, color: Colors.blue, size: 48),
              SizedBox(height: 8),
              Text('图片加载失败', style: TextStyle(color: Colors.blue)),
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
              Icon(Icons.error, color: Colors.blue, size: 48),
              SizedBox(height: 8),
              Text('图片加载失败', style: TextStyle(color: Colors.blue)),
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
                    Icon(Icons.error, color: Colors.blue, size: 48),
                    SizedBox(height: 8),
                    Text('图片加载失败', style: TextStyle(color: Colors.blue)),
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
            Icon(Icons.video_library, color: Colors.blue[600], size: 20),
            const SizedBox(width: 8),
          ],
        ),
        const SizedBox(height: 12),
        ...videos.asMap().entries.map((entry) {
          final index = entry.key;
          final video = entry.value;
          return _VideoListItem(
            video: video,
            index: index,
            videos: videos,
            questionBank: questionBank,
          );
        }),
      ],
    ),
  );
}

class _VideoListItem extends StatefulWidget {
  final String video;
  final int index;
  final List<String> videos;
  final QuestionBank? questionBank;

  const _VideoListItem({
    required this.video,
    required this.index,
    required this.videos,
    this.questionBank,
  });

  @override
  State<_VideoListItem> createState() => _VideoListItemState();
}

class _VideoListItemState extends State<_VideoListItem> with TickerProviderStateMixin {
  String? _thumbnailPath;
  bool _isGeneratingThumbnail = false;
  String? _resolvedVideoPath;
  
  // 预览相关状态
  VideoPlayerController? _previewController;

  Duration? _videoDuration;
  bool _isPreviewInitialized = false;
  bool _isPlaying = false; // 播放状态
  Timer? _previewTimer;
  
  @override
  void initState() {
    super.initState();
    _resolveVideoPathAndGenerateThumbnail().then((_) {
      if (mounted && _resolvedVideoPath != null) {
        _initPreview(); // 只初始化，不自动播放
      }
    });
  }
  


  Future<void> _resolveVideoPathAndGenerateThumbnail() async {
    try {
      // 首先解析视频路径
      final resolvedPath = await _findAssetInQuestionBank(
        widget.video, 
        widget.questionBank, 
        isVideo: true
      );
      
      if (resolvedPath != null && mounted) {
        setState(() {
          _resolvedVideoPath = resolvedPath;
        });
        
        // 生成缩略图
        await _generateThumbnail(resolvedPath);
        // 获取视频时长
        await _getVideoDuration(resolvedPath);
      }
    } catch (e) {
      developer.log('[VideoListItem] Error resolving video path: $e', name: 'VideoListItem');
    }
  }
  
  Future<void> _getVideoDuration(String videoPath) async {
    try {
      VideoPlayerController tempController;
      
      if (videoPath.startsWith('http://') || videoPath.startsWith('https://')) {
        tempController = VideoPlayerController.networkUrl(Uri.parse(videoPath));
      } else {
        tempController = VideoPlayerController.file(File(videoPath));
      }
      
      await tempController.initialize();
      
      if (mounted) {
        setState(() {
          _videoDuration = tempController.value.duration;
        });
      }
      
      await tempController.dispose();
    } catch (e) {
      developer.log('[VideoListItem] Error getting video duration: $e', name: 'VideoListItem');
    }
  }

  Future<void> _generateThumbnail(String videoPath) async {
    if (_isGeneratingThumbnail) return;
    
    setState(() {
      _isGeneratingThumbnail = true;
    });

    try {
      String? thumbnailPath;
      
      if (videoPath.startsWith('http://') || videoPath.startsWith('https://')) {
        // 网络视频
        thumbnailPath = await VideoThumbnail.thumbnailFile(
          video: videoPath,
          thumbnailPath: (await Directory.systemTemp.createTemp()).path,
          imageFormat: ImageFormat.JPEG,
          maxHeight: 120,
          quality: 75,
        );
      } else {
        // 本地视频
        final file = File(videoPath);
        if (await file.exists()) {
          thumbnailPath = await VideoThumbnail.thumbnailFile(
            video: videoPath,
            thumbnailPath: (await Directory.systemTemp.createTemp()).path,
            imageFormat: ImageFormat.JPEG,
            maxHeight: 120,
            quality: 75,
          );
        }
      }

      if (thumbnailPath != null && mounted) {
        setState(() {
          _thumbnailPath = thumbnailPath;
        });
      }
    } catch (e) {
      developer.log('[VideoListItem] Error generating thumbnail: $e', name: 'VideoListItem');
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingThumbnail = false;
        });
      }
    }
  }
  
  Future<void> _initPreview() async {
    if (_resolvedVideoPath == null || _isPreviewInitialized) return;
    
    try {
      if (_resolvedVideoPath!.startsWith('http://') || _resolvedVideoPath!.startsWith('https://')) {
        _previewController = VideoPlayerController.networkUrl(Uri.parse(_resolvedVideoPath!));
      } else {
        _previewController = VideoPlayerController.file(File(_resolvedVideoPath!));
      }
      
      await _previewController!.initialize();
      _previewController!.setLooping(false);
      
      if (mounted) {
        setState(() {
          _isPreviewInitialized = true;
          _videoDuration = _previewController!.value.duration;
        });
      }
    } catch (e) {
      developer.log('[VideoListItem] Error initializing preview: $e', name: 'VideoListItem');
    }
  }
  
  void _startPreview() async {
    if (!_isPreviewInitialized) {
      await _initPreview();
    }
    
    if (_previewController != null && _isPreviewInitialized) {
      setState(() {
        _isPlaying = true;
      });

      _previewController!.play();
      
      // 移除自动停止功能，改为手动控制
      _previewTimer?.cancel();
    }
  }
  
  void _togglePlayPause() {
    if (_previewController != null && _isPreviewInitialized) {
      setState(() {
        _isPlaying = !_isPlaying;
      });
      
      if (_isPlaying) {
        _previewController!.play();
      } else {
        _previewController!.pause();
      }
    }
  }
  
  void _stopPreview() {
    _previewTimer?.cancel();
    setState(() {
      _isPlaying = false;
    });

    _previewController?.pause();
    _previewController?.seekTo(Duration.zero); // 回到开始位置
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () {
          // 单击切换播放/暂停
          _togglePlayPause();
        },
        onDoubleTap: _openVideoPlayer, // 双击进入全屏
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.blue[200]!,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 视频区域 - 占据卡片全宽
              _buildFullWidthVideo(),
              const SizedBox(height: 12),
              const SizedBox(height: 4),
              // 视频简介
              Text(
                _getVideoDisplayName(),
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              // 播放状态和时长信息
              Row(
                children: [
                  Icon(
                    _isPlaying ? Icons.pause_circle_outline : Icons.play_circle_outline,
                    size: 16,
                    color: Colors.blue[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _isPlaying ? '播放中' : '已暂停',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (_videoDuration != null) ...[
                    const Spacer(),
                    Text(
                      _buildTimeText(),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey[400],
                  ),
                ],
              ),
              // 进度条
              if (_previewController != null && _isPreviewInitialized) 
                _buildProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFullWidthVideo() {
    return GestureDetector(
      onTap: _openVideoPlayer,
      child: Container(
        width: double.infinity, // 占据卡片全宽
        height: 200, // 设置固定高度
        decoration: BoxDecoration(
          color: Colors.black12,
          borderRadius: BorderRadius.circular(8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
        child: _previewController != null && _isPreviewInitialized
            ? Stack(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: double.infinity,
                    child: VideoPlayer(_previewController!),
                  ),
                  // 播放状态指示器
                  if (!_isPlaying)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withOpacity(0.3),
                        child: Center(
                          child: Icon(
                            Icons.play_arrow,
                            color: Colors.white,
                            size: 48, // 增大播放按钮
                          ),
                        ),
                      ),
                    ),
                  // 全屏按钮
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: _openVideoPlayer,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.fullscreen,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : _thumbnailPath != null
                ? Stack(
                    children: [
                      Image.file(
                        File(_thumbnailPath!),
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildDefaultThumbnail();
                        },
                      ),
                      // 全屏按钮
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: _openVideoPlayer,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              Icons.fullscreen,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : _isGeneratingThumbnail
                    ? Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
                          ),
                        ),
                      )
                    : Stack(
                        children: [
                          _buildDefaultThumbnail(),
                          // 全屏按钮
                          Positioned(
                            top: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: _openVideoPlayer,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(
                                  Icons.fullscreen,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: ValueListenableBuilder<VideoPlayerValue>(
        valueListenable: _previewController!,
        builder: (context, value, child) {
          if (!value.isInitialized) return const SizedBox.shrink();
          
          final position = value.position;
          final duration = value.duration;
          
          if (duration == Duration.zero) return const SizedBox.shrink();
          
          final progress = position.inMilliseconds / duration.inMilliseconds;
          
          return Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDuration(position),
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    _formatDuration(duration),
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: Colors.blue[600],
                  inactiveTrackColor: Colors.grey[300],
                  thumbColor: Colors.blue[600],
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                  trackHeight: 3,
                ),
                child: Slider(
                  value: progress.clamp(0.0, 1.0),
                  onChanged: (newValue) {
                    final newPosition = Duration(
                      milliseconds: (newValue * duration.inMilliseconds).round(),
                    );
                    _previewController!.seekTo(newPosition);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
  
  String _buildTimeText() {
    if (_previewController != null && _isPreviewInitialized) {
      final position = _previewController!.value.position;
      final duration = _previewController!.value.duration;
      return '${_formatDuration(position)} / ${_formatDuration(duration)}';
    } else if (_videoDuration != null) {
      return _formatDuration(_videoDuration!);
    }
    return '';
  }
  
  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Widget _buildDefaultThumbnail() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue[400]!,
            Colors.blue[600]!,
          ],
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.video_library,
          color: Colors.white,
          size: 32,
        ),
      ),
    );
  }

  String _getVideoDisplayName() {
    final filename = path.basenameWithoutExtension(widget.video);
    return filename.isNotEmpty ? filename : widget.video;
  }

  Future<void> _openVideoPlayer() async {
    try {
      // 收集所有视频路径，确保正确解析
      final allVideoPaths = <String>[];
      for (final video in widget.videos) {
        final resolvedPath = await _findAssetInQuestionBank(
          video, 
          widget.questionBank, 
          isVideo: true
        );
        if (resolvedPath != null && resolvedPath.isNotEmpty) {
          allVideoPaths.add(resolvedPath);
        }
      }

      if (allVideoPaths.isNotEmpty && mounted) {
        // 暂停预览
        _stopPreview();
        
        // 找到当前视频在解析后列表中的索引
        int actualIndex = 0;
        if (_resolvedVideoPath != null) {
          final foundIndex = allVideoPaths.indexOf(_resolvedVideoPath!);
          if (foundIndex != -1) {
            actualIndex = foundIndex;
          }
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FullscreenVideoPage(
              videoPaths: allVideoPaths,
              initialIndex: actualIndex,
              enableTapToClose: true, // 启用点击空白处关闭
            ),
          ),
        );
      } else {
        // 显示错误提示
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('视频文件未找到: ${widget.video}'),
              backgroundColor: Colors.red[600],
            ),
          );
        }
      }
    } catch (e) {
      developer.log('[VideoListItem] Error opening video player: $e', name: 'VideoListItem');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('播放视频时出错: $e'),
            backgroundColor: Colors.red[600],
          ),
        );
      }
    }
  }
  
  @override
  void dispose() {
    _previewTimer?.cancel();

    _previewController?.dispose();
    super.dispose();
  }
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