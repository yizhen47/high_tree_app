import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:flick_video_player/flick_video_player.dart';
import 'dart:developer' as developer;
import 'dart:io';

import '../custom_flick_portrait_controls.dart';

// 自定义播放控件，包含旋转、倍速和比例控制
class CustomVideoControls extends StatefulWidget {
  final FlickManager flickManager;
  final Color primaryColor;
  final VoidCallback onRotate;
  final Function(double) onSpeedChange;
  final Function(double) onAspectRatioChange;
  final VoidCallback onFullscreen;
  final int rotationAngle;

  const CustomVideoControls({
    super.key,
    required this.flickManager,
    required this.primaryColor,
    required this.onRotate,
    required this.onSpeedChange,
    required this.onAspectRatioChange,
    required this.onFullscreen,
    required this.rotationAngle,
  });

  @override
  State<CustomVideoControls> createState() => _CustomVideoControlsState();
}

class _CustomVideoControlsState extends State<CustomVideoControls> {
  double _currentSpeed = 1.0;
  double _currentAspectRatio = 16 / 9;
  bool _showSpeedMenu = false;
  bool _showAspectMenu = false;

  final List<double> _speedOptions = [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
  final List<MapEntry<String, double>> _aspectRatioOptions = [
    const MapEntry('16:9', 16 / 9),
    const MapEntry('4:3', 4 / 3),
    const MapEntry('1:1', 1.0),
    const MapEntry('9:16', 9 / 16),
    const MapEntry('原始', 0), // 0 表示使用原始比例
  ];

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: FlickShowControlsAction(
            child: FlickSeekVideoAction(
              child: Center(
                child: FlickVideoBuffer(
                  child: FlickAutoHideChild(
                    child: FlickPlayToggle(
                      size: 30,
                      color: Colors.white,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(40),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: FlickAutoHideChild(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                FlickVideoProgressBar(
                  flickProgressBarSettings: FlickProgressBarSettings(
                    playedColor: widget.primaryColor,
                  ),
                ),
                // 主控制行
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[
                    FlickPlayToggle(size: 20),
                    FlickSoundToggle(size: 20),
                    Row(
                      children: <Widget>[
                        FlickCurrentPosition(fontSize: 12),
                        const Text(' / ',
                            style:
                                TextStyle(color: Colors.white, fontSize: 12)),
                        FlickTotalDuration(fontSize: 12),
                      ],
                    ),
                    // 全屏按钮
                    GestureDetector(
                      onTap: widget.onFullscreen,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: const Icon(
                          Icons.fullscreen,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // 扩展控制行（旋转、倍速、比例）
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // 旋转按钮
                    GestureDetector(
                      onTap: widget.onRotate,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.rotate_90_degrees_ccw,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${widget.rotationAngle}°',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // 倍速控制
                    GestureDetector(
                      onTap: () =>
                          setState(() => _showSpeedMenu = !_showSpeedMenu),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.speed,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${_currentSpeed}x',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // 比例控制
                    GestureDetector(
                      onTap: () =>
                          setState(() => _showAspectMenu = !_showAspectMenu),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.aspect_ratio,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _getCurrentAspectRatioLabel(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
        // 倍速菜单
        if (_showSpeedMenu)
          Positioned(
            bottom: 120,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: _speedOptions.map((speed) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _currentSpeed = speed;
                        _showSpeedMenu = false;
                      });
                      widget.onSpeedChange(speed);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      decoration: BoxDecoration(
                        color: _currentSpeed == speed
                            ? widget.primaryColor
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${speed}x',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        // 比例菜单
        if (_showAspectMenu)
          Positioned(
            bottom: 120,
            left: 20,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: _aspectRatioOptions.map((option) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _currentAspectRatio = option.value;
                        _showAspectMenu = false;
                      });
                      widget.onAspectRatioChange(option.value);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      decoration: BoxDecoration(
                        color: _currentAspectRatio == option.value
                            ? widget.primaryColor
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        option.key,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
      ],
    );
  }

  String _getCurrentAspectRatioLabel() {
    for (var option in _aspectRatioOptions) {
      if (option.value == _currentAspectRatio) {
        return option.key;
      }
    }
    return '16:9'; // 默认值
  }
}

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
  double _currentAspectRatio = 16 / 9; // 当前宽高比
  double _playbackSpeed = 1.0; // 播放速度

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
    } else {
      developer.log(
          '[VideoPlayerWidget] Flick manager is already null during dispose',
          name: 'VideoPlayerWidget');
    }
    _isInitialized = false;
    _error = null;
  }

  Future<void> _initializePlayer() async {
    if (_isDisposed) return; // 如果已经被disposed，不要初始化

    try {
      developer.log(
          '[VideoPlayerWidget] Initializing video player for: ${widget.videoPath}',
          name: 'VideoPlayerWidget');

      VideoPlayerController videoPlayerController;

      // 判断是网络URL还是本地文件
      if (widget.videoPath.startsWith('http://') ||
          widget.videoPath.startsWith('https://')) {
        videoPlayerController =
            VideoPlayerController.networkUrl(Uri.parse(widget.videoPath));
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
        developer.log(
            '[VideoPlayerWidget] Video player initialized successfully',
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
    // 使用当前设置的宽高比，如果为0则使用原始视频比例
    final videoAspectRatio = _currentAspectRatio == 0
        ? (_flickManager
                ?.flickVideoManager?.videoPlayerController?.value.aspectRatio ??
            16 / 9)
        : _currentAspectRatio;

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

    return GestureDetector(
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
                    controls: CustomVideoControls(
                      flickManager: _flickManager!,
                      primaryColor: widget.primaryColor,
                      onRotate: _rotateVideo,
                      onSpeedChange: _changePlaybackSpeed,
                      onAspectRatioChange: _changeAspectRatio,
                      onFullscreen: _openFullscreen,
                      rotationAngle: _rotationAngle,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    final screenWidth = MediaQuery.of(context).size.width;
    final containerHeight = screenWidth / (16 / 9); // 默认16:9比例

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
    final containerHeight = screenWidth / (16 / 9); // 默认16:9比例

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
    if (_flickManager
            ?.flickVideoManager?.videoPlayerController?.value.isInitialized ==
        true) {
      final currentPosition = _flickManager!
          .flickVideoManager!.videoPlayerController!.value.position;
      final isPlaying = _flickManager!.flickVideoManager!.isPlaying;

      // 暂停当前播放器
      _flickManager?.flickControlManager?.pause();

      Navigator.of(context)
          .push(
        MaterialPageRoute(
          builder: (context) => FullscreenVideoPlayer(
            videoPath: widget.videoPath,
            primaryColor: widget.primaryColor,
            startPosition: currentPosition,
          ),
          fullscreenDialog: true,
        ),
      )
          .then((_) {
        // 从全屏返回后，如果之前在播放，则继续播放
        if (isPlaying && mounted && !_isDisposed && _flickManager != null) {
          try {
            _flickManager?.flickControlManager?.play();
          } catch (e) {
            print('Error resuming video playback: $e');
          }
        }
      }).catchError((error) {
        print('Error in fullscreen navigation: $error');
      });
    }
  }

  // 旋转视频方法
  void _rotateVideo() {
    setState(() {
      _rotationAngle = (_rotationAngle + 90) % 360;
    });
  }

  // 改变播放速度
  void _changePlaybackSpeed(double speed) {
    setState(() {
      _playbackSpeed = speed;
    });
    _flickManager?.flickVideoManager?.videoPlayerController
        ?.setPlaybackSpeed(speed);
  }

  // 改变宽高比
  void _changeAspectRatio(double aspectRatio) {
    setState(() {
      _currentAspectRatio = aspectRatio;
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
  int _rotationAngle = 0; // 0, 90, 180, 270
  bool _isDisposed = false;

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
      if (widget.videoPath.startsWith('http://') ||
          widget.videoPath.startsWith('https://')) {
        _videoPlayerController =
            VideoPlayerController.networkUrl(Uri.parse(widget.videoPath));
      } else {
        _videoPlayerController =
            VideoPlayerController.file(File(widget.videoPath));
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
    if (!mounted || _isDisposed || _videoPlayerController == null) return;

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
    _isDisposed = true;
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
        if (didPop && mounted && !_isDisposed && _flickManager != null) {
          try {
            _flickManager?.flickControlManager?.pause();
          } catch (e) {
            print('Error pausing video on pop: $e');
          }
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
                          if (_transformationController.value !=
                              Matrix4.identity()) {
                            _transformationController.value =
                                Matrix4.identity();
                          } else {
                            // 如果没有缩放，则旋转
                            _rotateVideo();
                          }
                        },
                        child: InteractiveViewer(
                          transformationController: _transformationController,
                          minScale: 1.0,
                          maxScale: 4.0,
                          child: Transform.rotate(
                            angle: _rotationAngle * 3.14159 / 180,
                            child: FlickVideoPlayer(
                              flickManager: _flickManager!,
                              flickVideoWithControls: FlickVideoWithControls(
                                controls: OrientationBuilder(
                                  builder: (context, orientation) {
                                    // 全屏时，我们总是希望有旋转按钮，所以直接使用 CustomFlickPortraitControls
                                    return CustomFlickPortraitControls(
                                      onRotate: _rotateVideo,
                                      progressBarSettings:
                                          FlickProgressBarSettings(
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
                      ),
                      Positioned(
                        top: 16,
                        left: 16,
                        child: SafeArea(
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back,
                                color: Colors.white, size: 28),
                            onPressed: () {
                              if (mounted) {
                                _flickManager?.flickControlManager?.pause();
                                Navigator.of(context).pop();
                              }
                            },
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
            onPressed: () {
              if (mounted) {
                Navigator.of(context).pop();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.primaryColor,
            ),
            child: const Text('返回'),
          ),
        ],
      ),
    );
  }

  void _rotateVideo() {
    setState(() {
      _rotationAngle = (_rotationAngle + 90) % 360;
    });
  }
}
