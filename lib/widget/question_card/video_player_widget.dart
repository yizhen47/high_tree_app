import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:flick_video_player/flick_video_player.dart';
import 'dart:developer' as developer;
import 'dart:io';

import '../custom_flick_portrait_controls.dart';

class VideoPlayerWidget extends StatefulWidget {
  final String videoPath;
  final Color primaryColor;

  const VideoPlayerWidget({
    super.key,
    required this.videoPath,
    required this.primaryColor,
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  FlickManager? _flickManager;
  bool _isInitialized = false;
  bool _isDisposed = false; // 添加disposed标志
  String? _error;
  int _rotationAngle = 0; // 旋转角度 (0, 90, 180, 270)

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  @override
  void didUpdateWidget(VideoPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 如果视频路径改变了，重新初始化
    if (widget.videoPath != oldWidget.videoPath) {
      _reinitializePlayer();
    }
  }

  Future<void> _reinitializePlayer() async {
    // 先清理旧的播放器
    await _disposePlayer();
    // 重新初始化
    await _initializePlayer();
  }

  Future<void> _disposePlayer() async {
    if (_flickManager != null) {
      try {
        _flickManager!.dispose();
      } catch (e) {
        developer.log('[VideoPlayerWidget] Error disposing flick manager: $e', 
                      name: 'VideoPlayerWidget');
      }
      _flickManager = null;
    }
    
    if (mounted) {
      setState(() {
        _isInitialized = false;
        _error = null;
      });
    }
  }

  Future<void> _initializePlayer() async {
    if (_isDisposed) return; // 如果已经被disposed，不要初始化
    
    try {
      developer.log('[VideoPlayerWidget] Initializing video player for: ${widget.videoPath}', 
                    name: 'VideoPlayerWidget');

      VideoPlayerController videoPlayerController;
      
      // 判断是网络URL还是本地文件
      if (widget.videoPath.startsWith('http://') || widget.videoPath.startsWith('https://')) {
        videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(widget.videoPath));
      } else {
        // 检查本地文件是否存在
        final file = File(widget.videoPath);
        if (!await file.exists()) {
          throw Exception('视频文件不存在: ${widget.videoPath}');
        }
        videoPlayerController = VideoPlayerController.file(file);
      }

      // 等待初始化完成
      await videoPlayerController.initialize();
      
      if (_isDisposed || !mounted) {
        // 如果在初始化过程中组件被disposed，清理资源
        videoPlayerController.dispose();
        return;
      }

      // 创建 FlickManager
      _flickManager = FlickManager(
        videoPlayerController: videoPlayerController,
        autoPlay: false, // 不自动播放，等待滚动到视野中央时再播放
        autoInitialize: false, // 我们已经初始化了，不需要重复初始化
      );

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        developer.log('[VideoPlayerWidget] Video player initialized successfully', 
                      name: 'VideoPlayerWidget');
      }
    } catch (e) {
      developer.log('[VideoPlayerWidget] Error initializing video player: $e', 
                    name: 'VideoPlayerWidget', error: e);
      if (mounted && !_isDisposed) {
        setState(() {
          _error = e.toString();
        });
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true; // 标记为已disposed
    _disposePlayer(); // 异步清理，但不等待
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return _buildErrorWidget(_error!);
    }

    if (!_isInitialized || _flickManager == null) {
      return _buildLoadingWidget();
    }

    // 获取屏幕宽度
    final screenWidth = MediaQuery.of(context).size.width;
    final videoAspectRatio = _flickManager?.flickVideoManager?.videoPlayerController?.value.aspectRatio ?? 16/9;
    
    // 计算视频容器的尺寸
    double containerWidth = screenWidth;
    double containerHeight;
    
    // 根据旋转角度调整容器尺寸
    if (_rotationAngle == 90 || _rotationAngle == 270) {
      // 旋转90°或270°时，需要交换宽高比
      containerHeight = screenWidth * videoAspectRatio;
    } else {
      // 0°或180°时，使用标准比例
      containerHeight = screenWidth / videoAspectRatio;
    }

    return Stack(
      children: [
        GestureDetector(
          onTap: () => _openFullscreen(),
          child: Container(
            width: containerWidth,
            height: containerHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.black,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Center(
                child: Transform.rotate(
                  angle: _rotationAngle * 3.14159 / 180, // 转换为弧度
                  child: SizedBox(
                    width: _rotationAngle == 90 || _rotationAngle == 270 
                        ? containerHeight 
                        : containerWidth,
                    height: _rotationAngle == 90 || _rotationAngle == 270 
                        ? containerWidth 
                        : containerHeight,
                    child: FlickVideoPlayer(
                      flickManager: _flickManager!,
                      flickVideoWithControls: FlickVideoWithControls(
                        controls: FlickPortraitControls(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        // 旋转按钮
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black87, // 更不透明
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white, width: 1), // 添加白色边框
            ),
            child: IconButton(
              icon: const Icon(
                Icons.rotate_90_degrees_ccw,
                color: Colors.white,
                size: 22, // 稍微大一点
              ),
              onPressed: _rotateVideo,
              constraints: const BoxConstraints(
                minWidth: 40, // 稍微大一点
                minHeight: 40,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingWidget() {
    final screenWidth = MediaQuery.of(context).size.width;
    final containerHeight = screenWidth / (16/9); // 默认16:9比例
    
    return Container(
      width: screenWidth,
      height: containerHeight,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(widget.primaryColor),
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    final screenWidth = MediaQuery.of(context).size.width;
    final containerHeight = screenWidth / (16/9); // 默认16:9比例
    
    return Container(
      width: screenWidth,
      height: containerHeight,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 32,
            color: Colors.red.shade400,
          ),
          const SizedBox(height: 8),
          Text(
            '视频加载失败: $error',
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

  void _openFullscreen() {
    if (_flickManager?.flickVideoManager?.videoPlayerController?.value.isInitialized == true) {
      final currentPosition = _flickManager!.flickVideoManager!.videoPlayerController!.value.position;
      
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => FullscreenVideoPlayer(
            videoPath: widget.videoPath,
            primaryColor: widget.primaryColor,
            startPosition: currentPosition,
          ),
          fullscreenDialog: true,
        ),
      );
    }
  }

  // 旋转视频方法
  void _rotateVideo() {
    setState(() {
      _rotationAngle = (_rotationAngle + 90) % 360;
    });
  }

  // 公共方法：用于外部控制播放/暂停
  void play() {
    _flickManager?.flickControlManager?.play();
  }

  void pause() {
    _flickManager?.flickControlManager?.pause();
  }

  bool get isPlaying {
    return _flickManager?.flickVideoManager?.isPlaying ?? false;
  }
}

// 独立的全屏播放器（支持旋转模式）
class FullscreenVideoPlayer extends StatefulWidget {
  final String videoPath;
  final Color primaryColor;
  final Duration startPosition;

  const FullscreenVideoPlayer({
    super.key,
    required this.videoPath,
    required this.primaryColor,
    this.startPosition = Duration.zero,
  });

  @override
  State<FullscreenVideoPlayer> createState() => _FullscreenVideoPlayerState();
}

class _FullscreenVideoPlayerState extends State<FullscreenVideoPlayer> {
  FlickManager? _flickManager;
  VideoPlayerController? _videoPlayerController;
  bool _isInitialized = false;
  String? _error;
  late TransformationController _transformationController;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    _initializePlayer();
    // 设置全屏但默认竖屏，支持旋转
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  Future<void> _initializePlayer() async {
    try {
      if (widget.videoPath.startsWith('http://') || widget.videoPath.startsWith('https://')) {
        _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(widget.videoPath));
      } else {
        _videoPlayerController = VideoPlayerController.file(File(widget.videoPath));
      }

      // Add a listener to handle post-initialization logic
      _videoPlayerController!.addListener(_onControllerUpdated);

      _flickManager = FlickManager(
        videoPlayerController: _videoPlayerController!,
        autoPlay: true,
        autoInitialize: true,
      );

      if (mounted) {
        setState(() {
          // Manager is created, build method will now create the Flick player
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    }
  }

  void _onControllerUpdated() {
    if (!mounted || _videoPlayerController == null) return;
    
    // Once initialized, seek to the start position and update the state
    if (_videoPlayerController!.value.isInitialized && !_isInitialized) {
      if (widget.startPosition != Duration.zero) {
        _videoPlayerController!.seekTo(widget.startPosition);
      }
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }

      // Remove the listener after it has done its job
      _videoPlayerController!.removeListener(_onControllerUpdated);
    }
    // Handle errors during initialization
    else if (_videoPlayerController!.value.hasError && _error == null) {
      if (mounted) {
        setState(() {
          _error = _videoPlayerController!.value.errorDescription;
        });
      }
      _videoPlayerController!.removeListener(_onControllerUpdated);
    }
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _videoPlayerController?.removeListener(_onControllerUpdated);
    _flickManager?.dispose();
    // 恢复系统UI和所有方向
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          _flickManager?.flickControlManager?.pause();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: _error != null
            ? _buildErrorWidget()
            : _flickManager == null
                ? _buildLoadingWidget()
                : Stack(
                    children: [
                      GestureDetector(
                        onDoubleTap: () {
                          // 双击重置缩放
                          if (_transformationController.value != Matrix4.identity()) {
                            _transformationController.value = Matrix4.identity();
                          }
                        },
                        child: InteractiveViewer(
                          transformationController: _transformationController,
                          minScale: 1.0,
                          maxScale: 4.0,
                          child: FlickVideoPlayer(
                            flickManager: _flickManager!,
                            flickVideoWithControls: FlickVideoWithControls(
                              controls: OrientationBuilder(
                                builder: (context, orientation) {
                                  return orientation == Orientation.landscape
                                      ? const FlickLandscapeControls()
                                      : CustomFlickPortraitControls(
                                          progressBarSettings: FlickProgressBarSettings(
                                            playedColor: widget.primaryColor,
                                          ),
                                        );
                                },
                              ),
                              playerLoadingFallback: _buildLoadingWidget(),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 16,
                        left: 16,
                        child: SafeArea(
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(widget.primaryColor),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: Colors.blue.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            '视频加载失败: $_error',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.primaryColor,
            ),
            child: const Text('返回'),
          ),
        ],
      ),
    );
  }
} 