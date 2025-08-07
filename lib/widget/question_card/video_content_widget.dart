import 'package:flutter/material.dart';
import 'package:flutter_application_1/tool/question/question_bank.dart';
import 'video_player_widget.dart';

class VideoContentWidget extends StatelessWidget {
  final Color primaryColor;
  final SingleQuestionData? currentQuestionData;

  const VideoContentWidget({
    Key? key,
    required this.primaryColor,
    this.currentQuestionData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 获取题目中的视频路径
    String? videoPath = currentQuestionData?.question['video']?.toString();
    
    if (videoPath == null || videoPath.isEmpty) {
      // 如果没有视频，显示占位符
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
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

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: VideoPlayerWidget(
        videoPath: videoPath,
        primaryColor: primaryColor,
      ),
    );
  }
} 