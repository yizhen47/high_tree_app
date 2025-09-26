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

import 'mind_map/mind_map_controller.dart';
import 'mind_map/mind_map_helper.dart';
import 'mind_map/mind_map_node.dart';
import 'mind_map/mind_map_painter.dart';

export 'mind_map/mind_map_controller.dart';
export 'mind_map/mind_map_helper.dart';
export 'mind_map/mind_map_node.dart';


class MindMap<T> extends StatefulWidget {
  final MindMapNode<T> rootNode;
  final double width;
  final double height;
  final Color lineColor;
  final double lineWidth;
  final VoidCallback? onUpdated;
  final Function(MindMapNode<T>)? onNodeTap;
  final MindMapController? controller;
  final Map<String, String>? questionBankCacheDirs; // 题库ID到缓存目录的映射

  const MindMap({
    super.key,
    required this.rootNode,
    required this.width,
    required this.height,
    this.lineColor = Colors.grey,
    this.lineWidth = 1.5,
    this.onUpdated,
    this.onNodeTap,
    this.controller,
    this.questionBankCacheDirs, // 题库ID到缓存目录的映射
  });

  @override
  State<MindMap<T>> createState() => MindMapState<T>();
}

class MindMapState<T> extends State<MindMap<T>> with TickerProviderStateMixin implements MindMapControllable {
  double _scale = 1.0;
  Offset _offset = Offset.zero;
  late Offset _initialFocalPoint;
  late Offset _initialOffset;
  late double _initialScale;
  late AnimationController _highlightController;
  late Animation<double> _highlightAnimation;
  late AnimationController _layoutController;
  late Animation<double> _layoutAnimation;
  
  // 科技风动画控制器
  late AnimationController _techAnimationController;
  late Animation<double> _techAnimation;
  late AnimationController _particleController;
  late Animation<double> _particleAnimation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  
  final Map<String, ui.Image> _latexCache = {};
  final Map<String, ui.Image> _imageCache = {}; // 添加图片缓存
  final GlobalKey _repaintBoundaryKey = GlobalKey();
  
  // 存储节点的动画起始和结束位置
  final Map<String, Offset> _nodeStartPositions = {};
  final Map<String, Offset> _nodeEndPositions = {};
  
  // 粒子系统
  List<Particle> _particles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    widget.controller?.attach(this);
    
    // 原有动画控制器
    _highlightController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _highlightAnimation = CurvedAnimation(
      parent: _highlightController,
      curve: Curves.easeInOut,
    );
    
    _layoutController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _layoutAnimation = CurvedAnimation(
      parent: _layoutController,
      curve: Curves.easeInOutCubic,
    );
    
    // 科技风动画控制器
    _techAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
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
      duration: const Duration(milliseconds: 2000),
    )..repeat();
    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    );
    
    _initializeParticles();
    _precacheLatex(widget.rootNode);
    _precacheImages(widget.rootNode); // 添加图片预缓存
  }
  
  // 初始化粒子系统
  void _initializeParticles() {
    _particles = List.generate(30, (index) {
      return Particle(
        position: Offset(
          _random.nextDouble() * widget.width,
          _random.nextDouble() * widget.height,
        ),
        velocity: Offset(
          (_random.nextDouble() - 0.5) * 0.5,
          (_random.nextDouble() - 0.5) * 0.5,
        ),
        opacity: _random.nextDouble() * 0.3 + 0.1,
        maxOpacity: _random.nextDouble() * 0.5 + 0.2,
        radius: _random.nextDouble() * 2 + 1,
        color: [
          const Color(0xFF00F5FF), // 青色
          const Color(0xFF1E90FF), // 深天蓝
          const Color(0xFF00FFFF), // 青绿色
          const Color(0xFF4169E1), // 皇家蓝
          const Color(0xFF6495ED), // 矢车菊蓝
        ][_random.nextInt(5)],
      );
    });
  }

  @override
  void dispose() {
    _highlightController.dispose();
    _layoutController.dispose();
    _techAnimationController.dispose();
    _particleController.dispose();
    _pulseController.dispose();
    widget.controller?.detach();
    super.dispose();
  }

  @override
  void didUpdateWidget(MindMap<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.detach();
      widget.controller?.attach(this);
    }
  }

// 修改后的_renderLatex方法
  Future<ui.Image?> _renderLatex(String latex) async {
    final completer = Completer<ui.Image?>();
    final key = GlobalKey();
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: -5000, // 移出可视区域
        child: RepaintBoundary(
          key: key,
          child: LaTexT(
            laTeXCode: Text(
              latex,
              style: const TextStyle(
                color: Color(0xFF00F5FF), // 统一为科技蓝色
                fontSize: 48, // 提高分辨率
                fontWeight: FontWeight.w500,
                decoration: null,
                decorationStyle: null,
                decorationColor: null,
                decorationThickness: 0.0,
              ),
            ),
          ),
        ),
      ),
    );

    // 延迟到帧渲染完成后执行
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        // 检查组件是否仍挂载
        completer.complete(null);
        return;
      }

      try {
        // 插入Overlay
        Overlay.of(context).insert(overlayEntry);

        // 等待两帧确保布局完成
        await Future.delayed(const Duration(milliseconds: 50));

        final boundary =
            key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
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
        // 立即移除OverlayEntry
        overlayEntry.remove();
      }
    });

    return completer.future;
  }

// 修改预缓存调用
  void _precacheLatex(MindMapNode node) {
    if (node.isLatex && !_latexCache.containsKey(node.latexContent)) {
      _renderLatex(node.latexContent).then((image) {
        if (image != null && mounted) {
          // 增加mounted检查
          setState(() => _latexCache[node.latexContent] = image);
        }
      });
    }
    node.children.forEach(_precacheLatex);
  }

  void _precacheImages(MindMapNode node) {
    if (node.hasImage && !_imageCache.containsKey(node.image!)) {
      _loadImage(node.image!).then((image) {
        if (image != null && mounted) {
          setState(() {
            _imageCache[node.image!] = image;
            // 设置图片到节点并自动调整大小
            node.setCachedImage(image);
            // 重新布局树以适应新的节点大小
            _relayoutTree();
          });
        }
      });
    }
    node.children.forEach(_precacheImages);
  }

  // 重新布局树
  void _relayoutTree() {
    // 使用 MindMapHelper 重新组织树
    try {
      MindMapHelper.organizeTree(widget.rootNode);
    } catch (e) {
      print('Error relayouting tree: $e');
    }
  }

  Future<ui.Image?> _loadImage(String imagePath) async {
    try {
      // 支持本地资源图片
      if (imagePath.startsWith('assets/')) {
        final data = await DefaultAssetBundle.of(context).load(imagePath);
        final bytes = data.buffer.asUint8List();
        return await decodeImageFromList(bytes);
      }
      // 支持网络图片
      else if (imagePath.startsWith('http')) {
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
      }
      // 支持题库缓存目录中的图片
      else if (widget.questionBankCacheDirs != null) {
        // 尝试从所有题库缓存目录中查找图片
        for (var entry in widget.questionBankCacheDirs!.entries) {
          final bankId = entry.key;
          final cacheDir = entry.value;
          
          // 尝试多种路径格式
          final possiblePaths = [
            '$cacheDir/assets/$imagePath',        // 原始路径
            '$cacheDir/assets/images/$imagePath', // 图片在images子目录下
            '$cacheDir/$imagePath',               // 直接在缓存目录下
          ];
          
          for (var fullPath in possiblePaths) {
            final file = File(fullPath);
            if (await file.exists()) {
              final bytes = await file.readAsBytes();
              return await decodeImageFromList(bytes);
            }
          }
        }
        print('Image file not found in any cache directory: $imagePath');
        return null;
      }
      // 支持相对路径文件（假设在assets目录下）
      else {
        final data = await DefaultAssetBundle.of(context).load('assets/$imagePath');
        final bytes = data.buffer.asUint8List();
        return await decodeImageFromList(bytes);
      }
    } catch (e) {
      print('Error loading image $imagePath: $e');
      return null;
    }
  }

  void centerNodeById(String nodeId,
      {Duration duration = const Duration(milliseconds: 500)}) {
    final node = _findNodeById(nodeId);
    if (node == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final screenSize = Offset(widget.width, widget.height);
      final targetOffset = Offset(
        screenSize.dx / 2 - node.position.dx * _scale,
        screenSize.dy / 2 - node.position.dy * _scale,
      );

      final controller = AnimationController(
        vsync: this,
        duration: duration,
      );

      final animation = Tween<Offset>(
        begin: _offset,
        end: targetOffset,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeInOut,
      ));

      animation.addListener(() => setState(() => _offset = animation.value));
      controller.forward().whenComplete(controller.dispose);
    });
  }

  @override
  void highlightNode(List<String> nodeId) {
    setState(() {
      widget.rootNode.updateHighlight(nodeId);
      _highlightController.reset();
      _highlightController.forward();
    });
  }

  MindMapNode<T>? _findNodeById(String id) =>
      _findNodeRecursive(widget.rootNode, id);

  MindMapNode<T>? _findNodeRecursive(MindMapNode<T> node, String id) {
    if (node.id == id) return node;
    for (final child in node.children) {
      final found = _findNodeRecursive(child, id);
      if (found != null) return found;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerSignal: (pointerSignal) {
        if (pointerSignal is PointerScrollEvent) {
          final scaleFactor = pointerSignal.scrollDelta.dy > 0 ? 0.9 : 1.1;
          setState(() {
            _scale = (_scale * scaleFactor).clamp(0.1, 5.0);
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
          final newScale = (_initialScale * details.scale).clamp(0.1, 5.0);
          final currentFocalPoint = details.localFocalPoint;
          final newOffset = currentFocalPoint -
              ((_initialFocalPoint - _initialOffset) / _initialScale) *
                  newScale;
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
            // 科技风深色背景渐变
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0A0A0F), // 深蓝黑
                Color(0xFF1A1A2E), // 深蓝紫
                Color(0xFF16213E), // 深蓝
                Color(0xFF0F0F23), // 深紫黑
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
              // 背景动画层
              AnimatedBuilder(
                animation: _techAnimation,
            builder: (context, child) {
                  // 更新粒子位置
                  for (var particle in _particles) {
                    particle.update(Size(widget.width, widget.height));
                  }
                  
                  return CustomPaint(
                    painter: TechBackgroundPainter(
                      animation: _techAnimation.value,
                      particles: _particles,
                    ),
                    size: Size.infinite,
                  );
                },
              ),
              // 知识图谱层
              AnimatedBuilder(
                animation: Listenable.merge([
                  _highlightAnimation,
                  _pulseAnimation,
                  _techAnimation,
                ]),
                builder: (context, child) {
                  // 更新节点动画属性
                  _updateNodeAnimations(widget.rootNode);
                  
              return Transform.translate(
                offset: _offset,
                child: CustomPaint(
                  painter: MindMapPainter(
                    latexCache: _latexCache,
                        imageCache: _imageCache,
                        questionBankCacheDirs: widget.questionBankCacheDirs ?? {},
                    rootNode: widget.rootNode,
                    lineColor: widget.lineColor,
                    lineWidth: widget.lineWidth,
                    scale: _scale,
                    highlightProgress: _highlightAnimation.value,
                        pulseProgress: _pulseAnimation.value,
                        techProgress: _techAnimation.value,
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
  
  // 更新节点动画属性
  void _updateNodeAnimations(MindMapNode<T> node) {
    // 脉冲动画
    node.pulseAnimation = math.sin(_pulseAnimation.value * 2 * math.pi) * 0.5 + 0.5;
    
    // 光晕强度
    if (node.isHighlighted) {
      node.glowIntensity = math.sin(_highlightAnimation.value * 2 * math.pi) * 0.5 + 0.5;
    } else {
      node.glowIntensity = 0.2;
    }
    
    // 递归更新子节点
    if (!node.isCollapsed) {
      for (final child in node.children) {
        _updateNodeAnimations(child);
      }
    }
  }

  void _handleTap(Offset localPosition) {
    final tapPos = (localPosition - _offset) / _scale;
    
    // 先检查是否点击了折叠指示器
    final collapseNode = _findCollapseIndicatorAtPosition(widget.rootNode, tapPos);
    if (collapseNode != null) {
      _animateLayoutChange(() {
        collapseNode.toggleCollapse();
      });
      return;
    }
    
    // 如果没有点击折叠指示器，则检查是否点击了节点
    final node = _findNodeAtPosition(widget.rootNode, tapPos);
    if (node != null) widget.onNodeTap?.call(node);
  }

  // 执行布局动画
  void _animateLayoutChange(VoidCallback stateChange) {
    // 记录当前所有节点的位置
    _recordNodePositions(widget.rootNode, _nodeStartPositions);
    
    // 执行状态改变
    stateChange();
    
    // 重新计算布局
    MindMapHelper.organizeTree(widget.rootNode);
    
    // 记录新的位置
    _recordNodePositions(widget.rootNode, _nodeEndPositions);
    
    // 设置起始位置到节点
    _applyNodePositions(widget.rootNode, _nodeStartPositions);
    
    // 添加动画监听器
    late void Function() listener;
    listener = () {
      _interpolateNodePositions(widget.rootNode, _layoutAnimation.value);
      setState(() {});
    };
    
    _layoutAnimation.addListener(listener);
    
    // 重置动画并开始
    _layoutController.reset();
    _layoutController.forward().then((_) {
      // 动画完成后设置最终位置并清理
      _applyNodePositions(widget.rootNode, _nodeEndPositions);
      _layoutAnimation.removeListener(listener);
      _nodeStartPositions.clear();
      _nodeEndPositions.clear();
      setState(() {});
    });
  }

  // 记录节点位置
  void _recordNodePositions(MindMapNode<T> node, Map<String, Offset> positions) {
    positions[node.id] = node.position;
    if (!node.isCollapsed) {
      for (final child in node.children) {
        _recordNodePositions(child, positions);
      }
    }
  }

  // 将位置映射应用到节点
  void _applyNodePositions(MindMapNode<T> node, Map<String, Offset> positions) {
    final pos = positions[node.id];
    if (pos != null) {
      node.position = pos;
    }
    
    if (!node.isCollapsed) {
      for (final child in node.children) {
        _applyNodePositions(child, positions);
      }
    }
  }

  // 在动画期间插值节点位置
  void _interpolateNodePositions(MindMapNode<T> node, double progress) {
    final startPos = _nodeStartPositions[node.id];
    final endPos = _nodeEndPositions[node.id];
    
    if (startPos != null && endPos != null) {
      node.position = Offset.lerp(startPos, endPos, progress) ?? node.position;
    }
    
    if (!node.isCollapsed) {
      for (final child in node.children) {
        _interpolateNodePositions(child, progress);
      }
    }
  }

  // 查找点击位置是否在折叠指示器上
  MindMapNode<T>? _findCollapseIndicatorAtPosition(MindMapNode<T> node, Offset position) {
    // 检查当前节点的折叠指示器
    if (node.canCollapse) {
      final indicatorCenter = Offset(
        node.position.dx + node.size.width / 2 + 20,
        node.position.dy,
      );
      final distance = (position - indicatorCenter).distance;
      if (distance <= 12.0) { // 增大点击区域
        return node;
      }
    }
    
    // 只在节点未折叠时检查子节点
    if (!node.isCollapsed) {
      for (final child in node.children) {
        final result = _findCollapseIndicatorAtPosition(child, position);
        if (result != null) return result;
      }
    }
    
    return null;
  }

  MindMapNode<T>? _findNodeAtPosition(MindMapNode<T> node, Offset position) {
    final rect = Rect.fromCenter(
      center: node.position,
      width: node.size.width,
      height: node.size.height,
    );
    
    if (rect.contains(position)) {
      return node;
    }
    
    // 只在节点未折叠时检查子节点
    if (!node.isCollapsed) {
      for (final child in node.children) {
        final result = _findNodeAtPosition(child, position);
        if (result != null) return result;
      }
    }
    
    return null;
  }
}
