import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'dart:developer' as developer;
import 'package:flutter_application_1/tool/text_string_handle.dart';

class FullscreenVideoPage extends StatefulWidget {
  final List<String> videoPaths;
  final int initialIndex;

  const FullscreenVideoPage({
    super.key,
    required this.videoPaths,
    this.initialIndex = 0,
  });

  @override
  State<FullscreenVideoPage> createState() => _FullscreenVideoPageState();
}

class _FullscreenVideoPageState extends State<FullscreenVideoPage> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        itemCount: widget.videoPaths.length,
        itemBuilder: (context, index) {
          return VideoPlayerItem(
            key: ValueKey(widget.videoPaths[index]),
            videoPath: widget.videoPaths[index],
          );
        },
      ),
    );
  }
}

class VideoPlayerItem extends StatefulWidget {
  final String videoPath;

  const VideoPlayerItem({super.key, required this.videoPath});

  @override
  _VideoPlayerItemState createState() => _VideoPlayerItemState();
}

class _VideoPlayerItemState extends State<VideoPlayerItem> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayer();
  }

  Future<void> _initializeVideoPlayer() async {
    try {
      if (widget.videoPath.startsWith('http')) {
        _videoPlayerController =
            VideoPlayerController.networkUrl(Uri.parse(widget.videoPath));
      } else {
        _videoPlayerController =
            VideoPlayerController.file(File(widget.videoPath));
      }
      await _videoPlayerController.initialize();
      setState(() {
        _chewieController = ChewieController(
          videoPlayerController: _videoPlayerController,
          autoPlay: true,
          looping: true,
          showControls: false, // Hide controls for a cleaner look
          aspectRatio: _videoPlayerController.value.aspectRatio,
        );
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
      developer.log(
        'Error initializing video player for: ${widget.videoPath}',
        name: 'VideoPlayerItem',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }
    if (_hasError) {
      return const Center(
          child:
              Text('视频加载失败', style: TextStyle(color: Colors.white)));
    }
    return Center(
      child: Chewie(
        controller: _chewieController!,
      ),
    );
  }
} 