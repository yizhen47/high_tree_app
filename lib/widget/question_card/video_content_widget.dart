import 'package:flutter/material.dart';
import 'package:flutter_application_1/tool/question/question_bank.dart';
import 'video_player_widget.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'dart:developer' as developer;
import 'package:flutter_application_1/tool/study_data.dart';

class VideoContentWidget extends StatefulWidget {
  final Color primaryColor;
  final SingleQuestionData? currentQuestionData;
  final QuestionBank? questionBank;
  final ValueNotifier<bool>? hasAskedAI;
  final ValueNotifier<bool>? hasViewedVideo;
  final ValueNotifier<bool>? hasViewedKnowledge;
  final VoidCallback? onVideoViewed;

  const VideoContentWidget({
    super.key,
    required this.primaryColor,
    this.currentQuestionData,
    this.questionBank,
    this.hasAskedAI,
    this.hasViewedVideo,
    this.hasViewedKnowledge,
    this.onVideoViewed,
  });

  @override
  State<VideoContentWidget> createState() => _VideoContentWidgetState();
}

class _VideoContentWidgetState extends State<VideoContentWidget> {
  VideoPlayerWidget? _videoPlayerWidget;
  bool _isLoading = false;
  String? _error;
  String? _lastRequestedPath; // 追踪最后请求的路径，避免重复加载

  @override
  void initState() {
    super.initState();
    _loadVideo();
  }

  @override
  void didUpdateWidget(VideoContentWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 如果题目数据改变了，重新加载视频
    if (widget.currentQuestionData != oldWidget.currentQuestionData) {
      _loadVideo();
    }
  }

  Future<void> _loadVideo() async {
    // 获取题目中的视频路径
    String? videoPath = widget.currentQuestionData?.question['video']?.toString();
    
    // 如果路径相同，不需要重新加载
    if (videoPath == _lastRequestedPath && _videoPlayerWidget != null) {
      return;
    }
    
    _lastRequestedPath = videoPath;
    
    if (videoPath == null || videoPath.isEmpty) {
          setState(() {
      _videoPlayerWidget = null;
      _error = null;
      _isLoading = false;
    });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _videoPlayerWidget = null; // 清除旧的播放器
    });

    try {
      final foundPath = await _findVideoPath(videoPath);
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (foundPath != null) {
            // 只有找到路径时才创建新的播放器
            _videoPlayerWidget = VideoPlayerWidget(
              key: ValueKey(foundPath), // 使用路径作为key确保唯一性
              videoPath: foundPath,
              primaryColor: widget.primaryColor,
            );
            // 记录查看视频行为
            StudyData.instance.recordViewVideo();
            if (widget.hasViewedVideo != null && !widget.hasViewedVideo!.value) {
              widget.hasViewedVideo!.value = true;
              widget.onVideoViewed?.call();
            }
          } else {
            _error = '视频文件未找到: $videoPath';
          }
        });
      }
    } catch (e) {
      developer.log('[VideoContentWidget] Error loading video: $e', 
                  name: 'VideoContentWidget', error: e);
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = '加载视频出错: $e';
        });
      }
    }
  }

  @override
  void dispose() {
    // VideoPlayerWidget 会自己处理dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 没有视频路径
    if (widget.currentQuestionData?.question['video'] == null || 
        widget.currentQuestionData!.question['video'].toString().isEmpty) {
      return _buildNoVideoWidget();
    }

    // 加载中
    if (_isLoading) {
      return _buildLoadingWidget();
    }

    // 有错误
    if (_error != null) {
      return _buildErrorWidget(_error!);
    }

    // 有视频播放器
    if (_videoPlayerWidget != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: _videoPlayerWidget!,
      );
    }

    // 默认情况（不应该到达这里）
    return _buildNoVideoWidget();
  }

  Widget _buildNoVideoWidget() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(
            Icons.video_library_outlined,
            size: 32,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 8),
          Text(
            '该题目暂无视频解析',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(widget.primaryColor),
            ),
            const SizedBox(height: 8),
            Text(
              '正在加载视频...',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            size: 32,
            color: Colors.red.shade400,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              color: Colors.red.shade600,
              fontSize: 13,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _loadVideo,
            child: Text(
              '重试',
              style: TextStyle(color: widget.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  Future<String?> _findVideoPath(String assetPath) async {
    developer.log('[VideoContentWidget] Finding video path for: $assetPath', name: 'VideoContentWidget');
    
    // 1. 如果是网络URL，直接返回
    if (assetPath.startsWith('http://') || assetPath.startsWith('https://')) {
      developer.log('[VideoContentWidget] Path is a URL, returning as is: $assetPath', name: 'VideoContentWidget');
      return assetPath;
    }
    
    // 2. 如果是绝对路径，检查文件是否存在
    final absoluteFile = File(assetPath);
    if (await absoluteFile.exists()) {
      developer.log('[VideoContentWidget] Found absolute path: ${absoluteFile.path}', name: 'VideoContentWidget');
      return assetPath;
    }

    // 3. 如果没有题库信息，无法查找缓存，返回null
    if (widget.questionBank?.cacheDir == null) {
      developer.log('[VideoContentWidget] No question bank cache directory provided.', name: 'VideoContentWidget');
      return null;
    }
    
    // 4. 在题库缓存目录中尝试多种路径组合
    final cacheDirPath = widget.questionBank!.cacheDir!;
    developer.log('[VideoContentWidget] Searching in cache directory: $cacheDirPath', name: 'VideoContentWidget');

    // 使用 Set 避免重复检查相同路径
    final possiblePaths = <String>{
      // 路径1: cache/作业册讲解视频/作业册讲解视频4.1/4.1.1.1&2.mp4 (兼容旧格式)
      path.join(cacheDirPath, assetPath),
      // 路径2: cache/assets/作业册讲解视频/作业册讲解视频4.1/4.1.1.1&2.mp4 (兼容旧格式)
      path.join(cacheDirPath, 'assets', assetPath),
      // 路径3: cache/assets/videos/作业册讲解视频/作业册讲解视频4.1/4.1.1.1&2.mp4 (正确的目标路径)
      path.join(cacheDirPath, 'assets', 'videos', assetPath),
    };

    developer.log('[VideoContentWidget] Possible paths to check:\n${possiblePaths.map((p) => "  $p").join('\n')}', name: 'VideoContentWidget');
    
    for (var fullPath in possiblePaths) {
      final file = File(fullPath);
      if (await file.exists()) {
        developer.log('[VideoContentWidget] Found video at: $fullPath', name: 'VideoContentWidget');
        return fullPath;
      } else {
        developer.log('[VideoContentWidget] File not found: $fullPath', name: 'VideoContentWidget');
      }
    }
    
    developer.log('[VideoContentWidget] Video not found in any possible path for: $assetPath', name: 'VideoContentWidget');
    // 5. 如果都找不到，返回null
    return null;
  }
} 