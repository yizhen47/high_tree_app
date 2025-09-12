import 'package:flutter/material.dart';
import 'package:flutter_application_1/tool/question/question_bank.dart';
import 'video_player_widget.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'dart:developer' as developer;

class VideoContentWidget extends StatelessWidget {
  final Color primaryColor;
  final SingleQuestionData? currentQuestionData;
  final QuestionBank? questionBank;

  const VideoContentWidget({
    super.key,
    required this.primaryColor,
    this.currentQuestionData,
    this.questionBank,
  });

  @override
  Widget build(BuildContext context) {
    // 获取题目中的视频路径
    String? videoPath = currentQuestionData?.question['video']?.toString();
    
    if (videoPath == null || videoPath.isEmpty) {
      // 如果没有视频，显示占位符
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

    return FutureBuilder<String?>(
      future: _findVideoPath(videoPath),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          developer.log('[VideoContentWidget] Error finding video path: ${snapshot.error}', 
                      name: 'VideoContentWidget', error: snapshot.error);
          return _buildErrorWidget('加载视频出错: ${snapshot.error}');
        }

        final foundPath = snapshot.data;
        if (foundPath != null) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: VideoPlayerWidget(
              videoPath: foundPath,
              primaryColor: primaryColor,
            ),
          );
        } else {
          return _buildErrorWidget('视频文件未找到: $videoPath');
        }
      },
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
    if (questionBank?.cacheDir == null) {
      developer.log('[VideoContentWidget] No question bank cache directory provided.', name: 'VideoContentWidget');
      return null;
    }
    
    // 4. 在题库缓存目录中尝试多种路径组合
    final cacheDirPath = questionBank!.cacheDir!;
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

    developer.log('[VideoContentWidget] Possible paths to check:\n${possiblePaths.map((p) => "                $p").join('\n')}', name: 'VideoContentWidget');
    
    for (var fullPath in possiblePaths) {
      final file = File(fullPath);
      if (await file.exists()) {
        developer.log('[VideoContentWidget] Found video at: $fullPath', name: 'VideoContentWidget');
        return fullPath;
      }
    }
    
    developer.log('[VideoContentWidget] Video not found in any possible path: $assetPath', name: 'VideoContentWidget');
    // 5. 如果都找不到，返回null
    return null;
  }
} 