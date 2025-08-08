import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'dart:io';
import 'dart:developer' as developer;

class VideoPlayerWidget extends StatefulWidget {
  final String videoPath;
  final Color primaryColor;

  const VideoPlayerWidget({
    Key? key,
    required this.videoPath,
    required this.primaryColor,
  }) : super(key: key);

  @override
  _VideoPlayerWidgetState createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    developer.log('[VideoPlayer] Initializing for video path: ${widget.videoPath}', name: 'VideoPlayer');
    _initializeVideoPlayer();
  }

  Future<void> _initializeVideoPlayer() async {
    try {
      if (widget.videoPath.startsWith('http')) {
        _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(widget.videoPath));
      } else {
        _videoPlayerController = VideoPlayerController.file(File(widget.videoPath));
      }

      await _videoPlayerController.initialize();
      
        setState(() {
        _chewieController = ChewieController(
          videoPlayerController: _videoPlayerController,
          autoPlay: true,
          looping: true,
          allowFullScreen: true,
          allowMuting: true,
          showControlsOnInitialize: false,
        );
        _isLoading = false;
        developer.log('[VideoPlayer] Initialization successful for: ${widget.videoPath}', name: 'VideoPlayer');
        });
    } catch (e, stackTrace) {
        setState(() {
          _hasError = true;
        _isLoading = false;
      });
      developer.log(
        '[VideoPlayer] Error initializing video player for: ${widget.videoPath}',
        name: 'VideoPlayer',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  void dispose() {
    developer.log('[VideoPlayer] Disposing video player for: ${widget.videoPath}', name: 'VideoPlayer');
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: AspectRatio(
        aspectRatio: _chewieController?.videoPlayerController.value.aspectRatio ?? 16 / 9,
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(widget.primaryColor),
                ),
              )
            : _hasError
                ? Center(
                    child: SingleChildScrollView( // 解决溢出问题
                  child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                          Icon(Icons.error_outline, color: Colors.red.shade300, size: 48),
                          const SizedBox(height: 16),
                          const Text(
                            '视频加载失败',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Text(
                              '路径: ${widget.videoPath}',
                              style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                              textAlign: TextAlign.center,
                            ),
                                ),
                              ],
                            ),
                        ),
                  )
                : ClipRect(
                    child: Chewie(controller: _chewieController!),
        ),
      ),
    );
  }
}

// 全屏视频播放器
class FullscreenVideoPlayer extends StatefulWidget {
  final VideoPlayerController controller;
  final Color primaryColor;

  const FullscreenVideoPlayer({
    Key? key,
    required this.controller,
    required this.primaryColor,
  }) : super(key: key);

  @override
  State<FullscreenVideoPlayer> createState() => _FullscreenVideoPlayerState();
}

class _FullscreenVideoPlayerState extends State<FullscreenVideoPlayer> {
  bool _showControls = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () {
          setState(() {
            _showControls = !_showControls;
          });
        },
        child: Stack(
          children: [
            Center(
              child: AspectRatio(
                aspectRatio: widget.controller.value.aspectRatio,
                child: VideoPlayer(widget.controller),
              ),
            ),
            
            if (_showControls)
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const Spacer(),
                      const Text(
                        '视频解析',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(width: 48), // 平衡布局
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
} 