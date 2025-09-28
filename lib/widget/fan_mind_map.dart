import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:latext/latext.dart';


import 'fan_mind_map/fan_mind_map_controller.dart';
import 'fan_mind_map/fan_mind_map_helper.dart';
import 'fan_mind_map/fan_mind_map_node.dart';
import 'fan_mind_map/fan_mind_map_painter.dart';

export 'fan_mind_map/fan_mind_map_controller.dart';
export 'fan_mind_map/fan_mind_map_helper.dart';
export 'fan_mind_map/fan_mind_map_node.dart';

class FanMindMap<T> extends StatefulWidget {
  final FanMindMapNode<T> rootNode;
  final double width;
  final double height;
  final Color lineColor;
  final double lineWidth;
  final VoidCallback? onUpdated;
  final Function(FanMindMapNode<T>)? onNodeTap;
  final FanMindMapController? controller;
  final Map<String, String>? questionBankCacheDirs;

  const FanMindMap({
    super.key,
    required this.rootNode,
    required this.width,
    required this.height,
    this.lineColor = Colors.grey,
    this.lineWidth = 1.5,
    this.onUpdated,
    this.onNodeTap,
    this.controller,
    this.questionBankCacheDirs,
  });

  @override
  State<FanMindMap<T>> createState() => FanMindMapState<T>();
}

class FanMindMapState<T> extends State<FanMindMap<T>> with TickerProviderStateMixin implements FanMindMapControllable {
  double _scale = 1.0;
  Offset _offset = Offset.zero;
  late Offset _initialFocalPoint;
  late Offset _initialOffset;
  late double _initialScale;
  late AnimationController _highlightController;
  late Animation<double> _highlightAnimation;
  
  // 科技风动画控制器
  late AnimationController _techAnimationController;
  late Animation<double> _techAnimation;
  late AnimationController _particleController;
  late Animation<double> _particleAnimation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _rotationController;
  late Animation<double> _rotationAnimation;

  final Map<String, ui.Image> _imageCache = {};
  final Map<String, ui.Image> _latexCache = {};
  
  // 粒子系统
  List<FanParticle> _particles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    widget.controller?.attach(this);
    
    _highlightController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _highlightAnimation = CurvedAnimation(
      parent: _highlightController,
      curve: Curves.easeInOut,
    );
    
    // 科技风动画控制器
    _techAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat();
    _techAnimation = CurvedAnimation(
      parent: _techAnimationController,
      curve: Curves.linear,
    );
    
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    )..repeat();
    _particleAnimation = CurvedAnimation(
      parent: _particleController,
      curve: Curves.linear,
    );
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();
    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    );
    
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 20000),
    )..repeat();
    _rotationAnimation = CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    );
    
    _initializeParticles();
    _precacheLatex(widget.rootNode);
    _precacheImages(widget.rootNode);

    // Organize tree after a short delay to ensure canvas size is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _organizeTree();
      }
    });
  }
  
  // 初始化粒子系统
  void _initializeParticles() {
    _particles = List.generate(50, (index) {
      final angle = _random.nextDouble() * 2 * math.pi;
      final radius = _random.nextDouble() * math.min(widget.width, widget.height) * 0.4;
      final center = Offset(widget.width / 2, widget.height / 2);
      
      return FanParticle(
        position: center + Offset(math.cos(angle) * radius, math.sin(angle) * radius),
        angle: angle,
        radius: radius,
        angularVelocity: (_random.nextDouble() - 0.5) * 0.01,
        radialVelocity: (_random.nextDouble() - 0.5) * 0.2,
        opacity: _random.nextDouble() * 0.4 + 0.1,
        maxOpacity: _random.nextDouble() * 0.6 + 0.3,
        size: _random.nextDouble() * 3 + 1,
        color: [
          const Color(0xFF00F5FF),
          const Color(0xFF1E90FF),
          const Color(0xFF00FFFF),
          const Color(0xFF4169E1),
          const Color(0xFF6495ED),
        ][_random.nextInt(5)],
        center: center,
      );
    });
  }

  @override
  void dispose() {
    _highlightController.dispose();
    _techAnimationController.dispose();
    _particleController.dispose();
    _pulseController.dispose();
    _rotationController.dispose();
    widget.controller?.detach();
    super.dispose();
  }

  @override
  void didUpdateWidget(FanMindMap<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.detach();
      widget.controller?.attach(this);
    }
  }

  // LaTeX渲染
  Future<ui.Image?> _renderLatex(String latex, FanMindMapNode node) async {
    final completer = Completer<ui.Image?>();
    final key = GlobalKey();
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: -5000, // Off-screen
        child: RepaintBoundary(
          key: key,
          child: LaTexT(
            laTeXCode: Text(
              latex,
              style: TextStyle(
                color: Colors.white,
                fontSize: node.getLevelFontSize(),
                fontWeight: FontWeight.normal,
                letterSpacing: 0.5,
                shadows: [
                  Shadow(
                    color: node.getLevelColor().withOpacity(0.8),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        completer.complete(null);
        return;
      }
      try {
        Overlay.of(context).insert(overlayEntry);
        await Future.delayed(const Duration(milliseconds: 50));
        final boundary = key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
        if (boundary == null || !boundary.hasSize) {
          completer.complete(null);
          return;
        }
        final image = await boundary.toImage(pixelRatio: 1.5);
        completer.complete(image);
      } catch (e) {
        debugPrint('Render latex error: $e');
        completer.complete(null);
      } finally {
        overlayEntry.remove();
      }
    });

    return completer.future;
  }

  // LaTeX预缓存
  void _precacheLatex(FanMindMapNode node) {
    if (node.isLatex) {
      final cacheKey = '${node.latexContent}_${node.level}';
      if (!_latexCache.containsKey(cacheKey)) {
        _renderLatex(node.latexContent, node).then((image) {
          if (image != null && mounted) {
            setState(() => _latexCache[cacheKey] = image);
          }
        });
      }
    }
    node.children.forEach(_precacheLatex);
  }

  void _precacheImages(FanMindMapNode node) {
    if (node.hasImage && !_imageCache.containsKey(node.image!)) {
      _loadImage(node.image!).then((image) {
        if (image != null && mounted) {
          setState(() {
            _imageCache[node.image!] = image;
            node.setCachedImage(image);
          });
        }
      });
    }
    node.children.forEach(_precacheImages);
  }

  Future<ui.Image?> _loadImage(String imagePath) async {
    try {
      if (imagePath.startsWith('assets/')) {
        final data = await DefaultAssetBundle.of(context).load(imagePath);
        final bytes = data.buffer.asUint8List();
        return await decodeImageFromList(bytes);
      } else if (imagePath.startsWith('http')) {
        final ImageProvider provider = NetworkImage(imagePath);
        final ImageStream stream = provider.resolve(ImageConfiguration.empty);
        final Completer<ui.Image> completer = Completer<ui.Image>();
        late ImageStreamListener listener;
        listener = ImageStreamListener((ImageInfo info, bool _) {
          completer.complete(info.image);
          stream.removeListener(listener);
        });
        stream.addListener(listener);
        return completer.future;
      } else if (widget.questionBankCacheDirs != null) {
        for (var entry in widget.questionBankCacheDirs!.entries) {
          final cacheDir = entry.value;
          final possiblePaths = [
            '$cacheDir/assets/$imagePath',
            '$cacheDir/assets/images/$imagePath',
            '$cacheDir/$imagePath',
          ];
          
          for (var fullPath in possiblePaths) {
            final file = File(fullPath);
            if (await file.exists()) {
              final bytes = await file.readAsBytes();
              return await decodeImageFromList(bytes);
            }
          }
        }
        return null;
      } else {
        final data = await DefaultAssetBundle.of(context).load('assets/$imagePath');
        final bytes = data.buffer.asUint8List();
        return await decodeImageFromList(bytes);
      }
    } catch (e) {
      print('Error loading image $imagePath: $e');
      return null;
    }
  }

  @override
  void highlightNode(List<String> nodeId) {
    setState(() {
      widget.rootNode.updateHighlight(nodeId);
      _highlightController.reset();
      _highlightController.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerSignal: (pointerSignal) {
        if (pointerSignal is PointerScrollEvent) {
          final scaleFactor = pointerSignal.scrollDelta.dy > 0 ? 0.9 : 1.1;
          setState(() {
            _scale = (_scale * scaleFactor).clamp(0.3, 3.0);
          });
        }
      },
      child: GestureDetector(
        onScaleStart: (details) {
          _initialScale = _scale;
          _initialOffset = _offset;
          _initialFocalPoint = details.localFocalPoint;
        },
        onScaleUpdate: (details) {
          final newScale = (_initialScale * details.scale).clamp(0.3, 3.0);
          final currentFocalPoint = details.localFocalPoint;
          final newOffset = currentFocalPoint -
              ((_initialFocalPoint - _initialOffset) / _initialScale) * newScale;
          setState(() {
            _scale = newScale;
            _offset = newOffset;
          });
          widget.onUpdated?.call();
        },
        onTapDown: (details) => _handleTap(details.localPosition),
        child: Container(
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0A0A0F),
                Color(0xFF1A1A2E),
                Color(0xFF16213E),
                Color(0xFF0F0F23),
              ],
              stops: [0.0, 0.3, 0.7, 1.0],
            ),
            border: Border.all(
              color: const Color(0xFF00F5FF).withOpacity(0.3),
              width: 2,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00F5FF).withOpacity(0.2),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          width: widget.width,
          height: widget.height,
          child: Stack(
            children: [
              // 扇形背景动画层
              AnimatedBuilder(
                animation: _techAnimation,
                builder: (context, child) {
                  for (var particle in _particles) {
                    particle.update(Size(widget.width, widget.height));
                  }
                  
                  return CustomPaint(
                    painter: FanTechBackgroundPainter(
                      animation: _techAnimation.value,
                      rotationAnimation: _rotationAnimation.value,
                      particles: _particles,
                    ),
                    size: Size.infinite,
                  );
                },
              ),
              // 扇形知识图谱层
              AnimatedBuilder(
                animation: Listenable.merge([
                  _highlightAnimation,
                  _pulseAnimation,
                  _techAnimation,
                  _rotationAnimation,
                ]),
                builder: (context, child) {
                  _updateNodeAnimations(widget.rootNode);
                  
                  return Transform.translate(
                    offset: _offset,
                    child: CustomPaint(
                      painter: FanMindMapPainter(
                        imageCache: _imageCache,
                        latexCache: _latexCache,
                        questionBankCacheDirs: widget.questionBankCacheDirs ?? {},
                        rootNode: widget.rootNode,
                        lineColor: widget.lineColor,
                        lineWidth: widget.lineWidth,
                        scale: _scale,
                        highlightProgress: _highlightAnimation.value,
                        pulseProgress: _pulseAnimation.value,
                        techProgress: _techAnimation.value,
                        rotationProgress: _rotationAnimation.value,
                        onImageLoaded: () {
                          setState(() {});
                        },
                      ),
                      size: Size.infinite,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _updateNodeAnimations(FanMindMapNode<T> node) {
    node.pulseAnimation = math.sin(_pulseAnimation.value * 2 * math.pi) * 0.5 + 0.5;
    
    if (node.isHighlighted) {
      node.glowIntensity = math.sin(_highlightAnimation.value * 2 * math.pi) * 0.5 + 0.5;
    } else {
      node.glowIntensity = 0.2;
    }
    
    for (final child in node.children) {
      _updateNodeAnimations(child);
    }
  }

  void _handleTap(Offset localPosition) {
    final tapPos = (localPosition - _offset) / _scale;
    final node = _findNodeAtPosition(widget.rootNode, tapPos);
    if (node != null) widget.onNodeTap?.call(node);
  }

  FanMindMapNode<T>? _findNodeAtPosition(FanMindMapNode<T> node, Offset position) {
    // 根节点不参与点击检测
    if (node.level == 0) {
      for (final child in node.children) {
        final result = _findNodeAtPosition(child, position);
        if (result != null) return result;
      }
      return null;
    }

    final distance = (position - node.position).distance;
    if (distance <= node.nodeRadius) {
      return node;
    }
    
    for (final child in node.children) {
      final result = _findNodeAtPosition(child, position);
      if (result != null) return result;
    }
    
    return null;
  }

  void _organizeTree() {
    final size = Size(widget.width, widget.height);
    FanMindMapHelper.organizeFanTree<T>(widget.rootNode, size);
    if (mounted) {
      setState(() {});
    }
  }
}

// 扇形粒子类
class FanParticle {
  Offset position;
  double angle;
  double radius;
  double angularVelocity;
  double radialVelocity;
  double opacity;
  double maxOpacity;
  double size;
  Color color;
  Offset center;
  
  FanParticle({
    required this.position,
    required this.angle,
    required this.radius,
    required this.angularVelocity,
    required this.radialVelocity,
    required this.opacity,
    required this.maxOpacity,
    required this.size,
    required this.color,
    required this.center,
  });
  
  void update(Size screenSize) {
    angle += angularVelocity;
    radius += radialVelocity;
    
    // 保持在合理范围内
    if (radius < 50) radius = 50;
    if (radius > math.min(screenSize.width, screenSize.height) * 0.4) {
      radius = math.min(screenSize.width, screenSize.height) * 0.4;
    }
    
    // 更新位置
    position = center + Offset(math.cos(angle) * radius, math.sin(angle) * radius);
    
    // 更新透明度
    opacity = (math.sin(angle * 3) * 0.5 + 0.5) * maxOpacity;
  }
} 