import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:flick_video_player/flick_video_player.dart';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:async';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';

import '../../widget/custom_flick_portrait_controls.dart';

// 专门为全屏模式设计的控制器，不会干扰垂直滑动手势
class FullscreenFlickControls extends StatefulWidget {
  const FullscreenFlickControls({
    super.key,
    this.iconSize = 20,
    this.fontSize = 12,
    this.progressBarSettings,
    this.onRotate,
    this.flickManager,
  });

  final double iconSize;
  final double fontSize;
  final FlickProgressBarSettings? progressBarSettings;
  final VoidCallback? onRotate;
  final FlickManager? flickManager;

  @override
  State<FullscreenFlickControls> createState() => _FullscreenFlickControlsState();
}

class _FullscreenFlickControlsState extends State<FullscreenFlickControls> {
  double _currentSpeed = 1.0;
  
  final List<double> _speedOptions = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

  @override
  void initState() {
    super.initState();
    _initializeSpeed();
  }

  @override
  void didUpdateWidget(FullscreenFlickControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.flickManager != oldWidget.flickManager) {
      _initializeSpeed();
    }
  }

  void _initializeSpeed() {
    final flickManager = widget.flickManager;
    if (flickManager != null && flickManager.flickVideoManager?.videoPlayerController != null) {
      final currentSpeed = flickManager.flickVideoManager!.videoPlayerController!.value.playbackSpeed;
      setState(() {
        _currentSpeed = currentSpeed;
      });
      developer.log('[FullscreenFlickControls] Initialized speed to: ${currentSpeed}x', 
                    name: 'FullscreenFlickControls');
    } else {
      developer.log('[FullscreenFlickControls] Cannot initialize speed - FlickManager or controller is null', 
                    name: 'FullscreenFlickControls');
    }
  }

  void _showSpeedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('播放速度'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: _speedOptions.map((speed) {
              return ListTile(
                title: Text('${speed}x'),
                leading: Radio<double>(
                  value: speed,
                  groupValue: _currentSpeed,
                  onChanged: (value) {
                    if (value != null) {
                      _setPlaybackSpeed(value);
                      Navigator.of(context).pop();
                    }
                  },
                ),
                onTap: () {
                  _setPlaybackSpeed(speed);
                  Navigator.of(context).pop();
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _setPlaybackSpeed(double speed) {
    final flickManager = widget.flickManager;
    if (flickManager != null) {
      flickManager.flickVideoManager?.videoPlayerController?.setPlaybackSpeed(speed);
      setState(() {
        _currentSpeed = speed;
      });
      developer.log('[FullscreenFlickControls] Set playback speed to: ${speed}x', 
                    name: 'FullscreenFlickControls');
    } else {
      developer.log('[FullscreenFlickControls] FlickManager is null, cannot set speed', 
                    name: 'FullscreenFlickControls');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        // 只处理点击显示/隐藏控制栏，不处理滑动手势
        Positioned.fill(
          child: FlickShowControlsAction(
            child: Container(
              color: Colors.transparent,
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
                  flickProgressBarSettings: widget.progressBarSettings,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[
                    FlickPlayToggle(
                      size: widget.iconSize,
                    ),
                    FlickSoundToggle(
                      size: widget.iconSize,
                    ),
                    Row(
                      children: <Widget>[
                        FlickCurrentPosition(
                          fontSize: widget.fontSize,
                        ),
                        const Text(' / ', style: TextStyle(color: Colors.white)),
                        FlickTotalDuration(
                          fontSize: widget.fontSize,
                        ),
                      ],
                    ),
                    // 倍速按钮
                    GestureDetector(
                      onTap: _showSpeedDialog,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${_currentSpeed}x',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: widget.fontSize,
                          ),
                        ),
                      ),
                    ),
                    // 旋转按钮
                    if (widget.onRotate != null)
                      GestureDetector(
                        onTap: widget.onRotate,
                        child: Icon(
                          Icons.rotate_90_degrees_ccw,
                          color: Colors.white,
                          size: widget.iconSize,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class FullscreenVideoPage extends StatefulWidget {
  final List<String> videoPaths;
  final int initialIndex;
  final Color primaryColor;
  final bool enableTapToClose;

  const FullscreenVideoPage({
    super.key,
    required this.videoPaths,
    this.initialIndex = 0,
    this.primaryColor = Colors.blue,
    this.enableTapToClose = false,
  });

  @override
  State<FullscreenVideoPage> createState() => _FullscreenVideoPageState();
}

class _FullscreenVideoPageState extends State<FullscreenVideoPage> {
  late PageController _pageController;
  int _currentIndex = 0;
  final List<GlobalKey<_VideoPlayerItemState>> _videoKeys = [];
  final List<VideoPlayerItem> _videoItems = [];
  bool _showNextVideoPreview = false;
  Timer? _autoPlayTimer;
  VideoPlayerController? _previewController;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    
    // 设置全屏但默认竖屏，支持旋转
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    // 初始化视频项和对应的key
    for (int i = 0; i < widget.videoPaths.length; i++) {
      final key = GlobalKey<_VideoPlayerItemState>();
      _videoKeys.add(key);
      _videoItems.add(VideoPlayerItem(
        key: key,
        videoPath: widget.videoPaths[i],
        primaryColor: widget.primaryColor,
        isActive: i == _currentIndex,
        onVideoCompleted: () {
          _onVideoCompleted(i);
        },
      ));
    }
  }

  void _onVideoCompleted(int index) {
    if (mounted && index < widget.videoPaths.length - 1) {
      // 显示下一个视频预览
      setState(() {
        _showNextVideoPreview = true;
      });
      
      // 5秒后自动播放下一个视频
      _autoPlayTimer = Timer(const Duration(seconds: 5), () {
        if (mounted) {
          setState(() {
            _showNextVideoPreview = false;
          });
          _pageController.nextPage(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  void _playNextVideo() {
    _autoPlayTimer?.cancel();
    _previewController?.dispose();
    _previewController = null;
    setState(() {
      _showNextVideoPreview = false;
    });
    _pageController.nextPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  void _cancelAutoPlay() {
    _autoPlayTimer?.cancel();
    _previewController?.dispose();
    _previewController = null;
    setState(() {
      _showNextVideoPreview = false;
    });
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _previewController?.dispose();
    // 恢复系统UI和方向
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    
    // 停止所有视频
    for (var key in _videoKeys) {
      key.currentState?._pause();
      key.currentState?._dispose();
    }
    
    super.dispose();
  }

  void _onPageChanged(int index) {
    if (_currentIndex != index) {
      // 取消自动播放和预览
      _autoPlayTimer?.cancel();
      
      // 暂停之前的视频
      if (_currentIndex < _videoKeys.length) {
        _videoKeys[_currentIndex].currentState?._pause();
        _videoKeys[_currentIndex].currentState?._setActive(false);
      }
      
      // 播放当前视频
      setState(() {
        _currentIndex = index;
        _showNextVideoPreview = false;
      });
      
      if (index < _videoKeys.length) {
        _videoKeys[index].currentState?._setActive(true);
        _videoKeys[index].currentState?._play();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          _autoPlayTimer?.cancel();
          // 暂停当前播放的视频
          if (_currentIndex < _videoKeys.length) {
            _videoKeys[_currentIndex].currentState?._pause();
          }
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            GestureDetector(
              onTap: widget.enableTapToClose ? () {
                _autoPlayTimer?.cancel();
                // 暂停当前播放的视频
                if (_currentIndex < _videoKeys.length) {
                  _videoKeys[_currentIndex].currentState?._pause();
                }
                Navigator.of(context).pop();
              } : null,
              child: NotificationListener<OverscrollNotification>(
                onNotification: (notification) {
                  if (notification.depth == 0 && notification.metrics.axis == Axis.vertical) {
                    // Reached the end of the list
                    if (notification.overscroll > 0 && _currentIndex == widget.videoPaths.length - 1) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('已经是最后一个视频了'),
                          duration: Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                    // Reached the beginning of the list
                    else if (notification.overscroll < 0 && _currentIndex == 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('已经是第一个视频了'),
                          duration: Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                  return true;
                },
                child: PageView.builder(
                  controller: _pageController,
                  scrollDirection: Axis.vertical,
                  onPageChanged: _onPageChanged,
                  itemCount: widget.videoPaths.length,
                  itemBuilder: (context, index) {
                    return _videoItems[index];
                  },
                ),
              ),
            ),
            
            // 下一个视频预览
            if (_showNextVideoPreview && _currentIndex < widget.videoPaths.length - 1)
              _buildNextVideoPreview(),
            
            // 返回按钮
            Positioned(
              top: 16,
              left: 16,
              child: SafeArea(
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 28,
                  ),
                  onPressed: () {
                    _autoPlayTimer?.cancel();
                    // 暂停当前播放的视频
                    if (_currentIndex < _videoKeys.length) {
                      _videoKeys[_currentIndex].currentState?._pause();
                    }
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ),
            
            // 视频指示器
            Positioned(
              top: 16,
              right: 16,
              child: SafeArea(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_currentIndex + 1}/${widget.videoPaths.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNextVideoPreview() {
    final nextVideoPath = widget.videoPaths[_currentIndex + 1];
    
    return Container(
      color: Colors.black87,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 视频预览缩略图，保持原始比例
              Container(
                constraints: const BoxConstraints(
                  maxWidth: 280,
                  maxHeight: 200,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: 16 / 9, // 默认视频比例，实际会根据视频调整
                    child: FutureBuilder<VideoPlayerController>(
                      future: _createPreviewController(nextVideoPath),
                      builder: (context, snapshot) {
                        if (snapshot.hasData && snapshot.data!.value.isInitialized) {
                          final controller = snapshot.data!;
                          final videoAspectRatio = controller.value.aspectRatio;
                          
                          return AspectRatio(
                            aspectRatio: videoAspectRatio,
                            child: Stack(
                              children: [
                                VideoPlayer(controller),
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withOpacity(0.3),
                                      ],
                                    ),
                                  ),
                                ),
                                const Center(
                                  child: Icon(
                                    Icons.play_circle_filled,
                                    size: 48,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          );
                        } else {
                          return Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: Icon(
                                Icons.play_circle_filled,
                                size: 48,
                                color: Colors.blue,
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '下一个视频',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _getVideoDisplayName(nextVideoPath),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              StreamBuilder<int>(
                stream: Stream.periodic(
                  const Duration(seconds: 1),
                  (i) => 5 - i,
                ).take(6),
                builder: (context, snapshot) {
                  final countdown = snapshot.data ?? 5;
                  return Text(
                    countdown > 0 ? '${countdown}秒后自动播放' : '正在播放...',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _cancelAutoPlay,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.grey),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      child: const Text(
                        '取消',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _playNextVideo,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      child: const Text(
                        '立即播放',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 创建预览控制器来获取视频缩略图
  Future<VideoPlayerController> _createPreviewController(String videoPath) async {
    // 清理之前的预览控制器
    _previewController?.dispose();
    
    VideoPlayerController controller;
    
    if (videoPath.startsWith('http://') || videoPath.startsWith('https://')) {
      controller = VideoPlayerController.networkUrl(Uri.parse(videoPath));
    } else {
      controller = VideoPlayerController.file(File(videoPath));
    }
    
    _previewController = controller;
    
    await controller.initialize();
    // 跳转到视频的第一秒来获取更好的预览画面
    await controller.seekTo(const Duration(seconds: 1));
    
    return controller;
  }

  // 获取视频文件的显示名称
  String _getVideoDisplayName(String videoPath) {
    final filename = path.basenameWithoutExtension(videoPath);
    return filename.isNotEmpty ? filename : videoPath;
  }
}

class VideoPlayerItem extends StatefulWidget {
  final String videoPath;
  final Color primaryColor;
  final bool isActive;
  final VoidCallback? onVideoCompleted;

  const VideoPlayerItem({
    super.key,
    required this.videoPath,
    required this.primaryColor,
    this.isActive = false,
    this.onVideoCompleted,
  });

  @override
  State<VideoPlayerItem> createState() => _VideoPlayerItemState();
}

class _VideoPlayerItemState extends State<VideoPlayerItem> {
  FlickManager? _flickManager;
  VideoPlayerController? _videoPlayerController;
  bool _isInitialized = false;
  bool _isActive = false;
  late TransformationController _transformationController;
  String? _error;
  int _rotationAngle = 0; // 添加旋转角度状态

  @override
  void initState() {
    super.initState();
    _isActive = widget.isActive;
    _transformationController = TransformationController();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      developer.log('[VideoPlayerItem] Initializing video: ${widget.videoPath}', 
                    name: 'VideoPlayerItem');

      if (widget.videoPath.startsWith('http://') || widget.videoPath.startsWith('https://')) {
        _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(widget.videoPath));
      } else {
        _videoPlayerController = VideoPlayerController.file(File(widget.videoPath));
      }

      _videoPlayerController?.addListener(_onVideoPlayerUpdate);
      
      _flickManager = FlickManager(
        videoPlayerController: _videoPlayerController!,
        autoPlay: _isActive, // 直接根据是否活跃来决定是否自动播放
        autoInitialize: true,
      );

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      developer.log('[VideoPlayerItem] Error initializing: $e', 
                    name: 'VideoPlayerItem', error: e);
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    }
  }

  void _onVideoPlayerUpdate() {
    if (_videoPlayerController == null || !_videoPlayerController!.value.isInitialized) {
      return;
    }
    
    // When video completes, trigger the callback
    if (_videoPlayerController!.value.position >= _videoPlayerController!.value.duration) {
      // Prevent multiple calls
      if (widget.onVideoCompleted != null) {
        // Remove listener to avoid calling again
        _videoPlayerController?.removeListener(_onVideoPlayerUpdate);
        widget.onVideoCompleted!();
      }
    }
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _videoPlayerController?.removeListener(_onVideoPlayerUpdate);
    _dispose();
    super.dispose();
  }

  void _dispose() {
    _flickManager?.dispose();
    _flickManager = null; // 防止重复访问
  }

  void _play() {
    if (_flickManager != null && _isInitialized) {
      _flickManager?.flickControlManager?.play();
    }
  }

  void _pause() {
    if (_flickManager != null) {
      _flickManager?.flickControlManager?.pause();
    }
  }

  void _setActive(bool active) {
    if (mounted) {
      setState(() {
        _isActive = active;
      });
      
      if (active && _isInitialized) {
        _flickManager?.flickControlManager?.play();
      } else {
        _flickManager?.flickControlManager?.pause();
      }
    }
  }

  void _rotateVideo() {
    setState(() {
      _rotationAngle = (_rotationAngle + 90) % 360;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return _buildErrorWidget();
    }

    if (!_isInitialized || _flickManager == null) {
      return _buildLoadingWidget();
    }

    return GestureDetector(
      onDoubleTap: () {
        // 双击重置缩放
        if (_transformationController.value != Matrix4.identity()) {
          _transformationController.value = Matrix4.identity();
        } else {
          // 如果已经在默认状态，双击放大到2倍
          _transformationController.value = Matrix4.identity()..scale(2.0);
        }
      },
      child: InteractiveViewer(
        transformationController: _transformationController,
        minScale: 0.8,
        maxScale: 5.0,
        panEnabled: true,
        scaleEnabled: true,
        child: Transform.rotate(
          angle: _rotationAngle * 3.14159 / 180, // 将角度转换为弧度
          child: FlickVideoPlayer(
            flickManager: _flickManager!,
            flickVideoWithControls: FlickVideoWithControls(
              controls: FullscreenFlickControls(
                progressBarSettings: FlickProgressBarSettings(
                  playedColor: widget.primaryColor,
                ),
                onRotate: _rotateVideo, // 传入旋转回调
                flickManager: _flickManager, // 传入FlickManager实例
              ),
              playerLoadingFallback: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(widget.primaryColor),
                ),
              ),
              videoFit: BoxFit.contain, // 添加视频适应模式，保持比例并完全显示
            ),
          ),
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
            size: 64,
            color: Colors.red.shade400,
          ),
          const SizedBox(height: 16),
          const Text(
            '视频加载失败',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? '',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
      setState(() {
                _error = null;
                _isInitialized = false;
              });
              _initializePlayer();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.primaryColor,
            ),
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }

  void _openFullscreenPlayer() {
    if (_flickManager?.flickVideoManager?.videoPlayerController?.value.isInitialized == true) {
      final currentPosition = _flickManager!.flickVideoManager!.videoPlayerController!.value.position;
      
      // 暂停当前播放
      _flickManager?.flickControlManager?.pause();
      
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => FullscreenVideoPlayer(
            videoPath: widget.videoPath,
            primaryColor: widget.primaryColor,
            startPosition: currentPosition,
          ),
          fullscreenDialog: true,
        ),
      ).then((_) {
        // 返回后恢复播放状态
        if (_isActive && mounted) {
          _flickManager?.flickControlManager?.play();
        }
      });
    }
  }
}

// 独立的全屏播放器（横屏模式）
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
  int _rotationAngle = 0; // 添加旋转角度状态

  @override
  void initState() {
    super.initState();
    _initializePlayer();
    // 设置横屏但保持可以退出
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    SystemChrome.setPreferredOrientations([
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

  void _rotateVideo() {
    setState(() {
      _rotationAngle = (_rotationAngle + 90) % 360;
    });
  }

  @override
  void dispose() {
    _videoPlayerController?.removeListener(_onControllerUpdated);
    _flickManager?.dispose();
    // 恢复竖屏
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
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
                      Transform.rotate(
                        angle: _rotationAngle * 3.14159 / 180, // 将角度转换为弧度
                        child: FlickVideoPlayer(
                          flickManager: _flickManager!,
                          flickVideoWithControls: FlickVideoWithControls(
                            controls: FullscreenFlickControls(
                              progressBarSettings: FlickProgressBarSettings(
                                playedColor: widget.primaryColor,
                              ),
                              onRotate: _rotateVideo, // 传入旋转回调
                            ),
                            playerLoadingFallback: _buildLoadingWidget(),
                            videoFit: BoxFit.contain, // 添加视频适应模式，保持比例并完全显示
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
            color: Colors.red.shade400,
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
            child: const Text('返回'),
          ),
        ],
      ),
    );
  }
} 