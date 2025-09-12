import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/tool/question/question_bank.dart';
import 'package:flutter_application_1/widget/latex.dart';
import 'package:latext/latext.dart';

enum NodeSide { left, right, none }

/// 思维导图节点数据类
class MindMapNode<T> {
  final String id;
  String text;
  String? image; // 添加图片属性
  Offset position;
  final List<MindMapNode<T>> children;
  Size size;
  MindMapNode? parent;
  Color color;
  double childHeight = 0.0;
  double leftChildHeight = 0.0; // 新增：左侧子树总高度
  double rightChildHeight = 0.0; // 新增：右侧子树总高度
  NodeSide side = NodeSide.none; // 新增：节点所在方向
  bool isHighlighted = false;
  bool isCollapsed = false; // 新增：折叠状态
  T? data;
  ui.Image? _cachedImage; // 缓存加载的图片
  Size? _originalImageSize; // 原始图片尺寸

  MindMapNode({
    required this.id,
    required this.text,
    this.image, // 添加图片参数
    required this.position,
    Iterable<MindMapNode<T>> children = const [],
    Size? size, // 改为可选参数
    this.color = const Color(0xFF4F46E5), // 更现代的默认颜色
    this.parent,
    this.data,
  }) : children = List.of(children),
       size = size ?? _calculateDefaultSize(text, image);

  bool get isLatex => text.contains(r'$$') || text.contains(r'$');
  String get latexContent => isLatex ? text : '';
  bool get hasImage => image != null && image!.isNotEmpty; // 添加图片检查方法
  bool get hasChildren => children.isNotEmpty; // 检查是否有子节点
  bool get canCollapse => hasChildren; // 是否可以折叠

  // 计算默认节点大小
  static Size _calculateDefaultSize(String text, String? image) {
    // 如果有图片，使用默认尺寸，后续会根据实际图片大小调整
    if (image != null && image.isNotEmpty) {
      return const Size(200, 150); // 默认图片节点大小，会被动态调整
    }
    
    // 根据文本长度动态调整
    final textLength = text.length;
    if (textLength <= 6) {
      return const Size(100, 40);
    } else if (textLength <= 12) {
      return const Size(140, 50);
    } else if (textLength <= 20) {
      return const Size(180, 60);
    } else {
      return const Size(220, 70);
    }
  }

  // 动态更新节点大小
  void updateSize({Size? newSize}) {
    if (newSize != null) {
      size = newSize;
    } else {
      size = _calculateDefaultSize(text, image);
    }
  }

  // 根据实际图片尺寸计算节点大小
  Size calculateImageNodeSize() {
    if (!hasImage || _originalImageSize == null) {
      return _calculateDefaultSize(text, image);
    }
    
    final originalSize = _originalImageSize!;
    const double textHeight = 40.0; // 为文本预留的高度（统一大小）
    
    // 设置合理的显示尺寸范围
    const double maxDisplayWidth = 400.0;
    const double maxDisplayHeight = 300.0;
    const double minDisplayWidth = 150.0;
    const double minDisplayHeight = 100.0;
    
    // 对于低像素图片，限制最大显示尺寸，避免过度放大
    double targetWidth = originalSize.width.toDouble();
    double targetHeight = originalSize.height.toDouble();
    
    // 如果图片太小，适当放大但不超过合理范围
    if (targetWidth < 150) {
      targetWidth = targetWidth * 1.5; // 轻微放大
    } else if (targetWidth > 400) {
      targetWidth = 400; // 限制最大宽度
    }
    
    if (targetHeight < 100) {
      targetHeight = targetHeight * 1.5; // 轻微放大
    } else if (targetHeight > 300) {
      targetHeight = 300; // 限制最大高度
    }
    
    // 保持宽高比
    final aspectRatio = originalSize.width / originalSize.height;
    if (targetWidth / aspectRatio > targetHeight) {
      targetWidth = targetHeight * aspectRatio;
    } else {
      targetHeight = targetWidth / aspectRatio;
    }
    
    // 确保在合理范围内
    targetWidth = targetWidth.clamp(minDisplayWidth, maxDisplayWidth);
    targetHeight = targetHeight.clamp(minDisplayHeight, maxDisplayHeight);
    
    return Size(targetWidth, targetHeight + textHeight);
  }

  // 切换折叠状态
  void toggleCollapse() {
    if (canCollapse) {
      isCollapsed = !isCollapsed;
    }
  }

  // 展开节点
  void expand() {
    isCollapsed = false;
  }

  // 折叠节点
  void collapse() {
    if (canCollapse) {
      isCollapsed = true;
    }
  }

  // 设置原始图片尺寸并更新节点大小
  void setImageSize(Size imageSize) {
    _originalImageSize = imageSize;
    if (hasImage) {
      size = calculateImageNodeSize();
    }
  }

  // 设置缓存的图片
  void setCachedImage(ui.Image image) {
    _cachedImage = image;
    setImageSize(Size(image.width.toDouble(), image.height.toDouble()));
  }

  // 获取缓存的图片
  ui.Image? get cachedImage => _cachedImage;

  void _updateHighlight(List<String> targetId) {
    isHighlighted = (targetId.contains(id));
    for (final child in children) {
      child._updateHighlight(targetId);
    }
  }

  static MindMapNode<Section> fromSection(Section section) {
    throw UnimplementedError();
  }
}

class MindMapController {
  WeakReference<_MindMapState>? _stateRef;

  void _attach(_MindMapState state) => _stateRef = WeakReference(state);
  void _detach() => _stateRef = null;

  void centerNodeById(String nodeId,
      {Duration duration = const Duration(milliseconds: 500)}) {
    final state = _stateRef?.target;
    state?.centerNodeById(nodeId, duration: duration);
  }

  void highlightNodeById(List<String> nodeId) {
    final state = _stateRef?.target;
    print(state);
    state?.highlightNode(nodeId);
  }
}

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
  State<MindMap<T>> createState() => _MindMapState<T>();
}

class _MindMapState<T> extends State<MindMap<T>> with TickerProviderStateMixin {
  double _scale = 1.0;
  Offset _offset = Offset.zero;
  late Offset _initialFocalPoint;
  late Offset _initialOffset;
  late double _initialScale;
  late AnimationController _highlightController;
  late Animation<double> _highlightAnimation;
  late AnimationController _layoutController;
  late Animation<double> _layoutAnimation;
  final Map<String, ui.Image> _latexCache = {};
  final Map<String, ui.Image> _imageCache = {}; // 添加图片缓存
  final GlobalKey _repaintBoundaryKey = GlobalKey();
  
  // 存储节点的动画起始和结束位置
  final Map<String, Offset> _nodeStartPositions = {};
  final Map<String, Offset> _nodeEndPositions = {};

  @override
  void initState() {
    super.initState();
    widget.controller?._attach(this);
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
    _precacheLatex(widget.rootNode);
    _precacheImages(widget.rootNode); // 添加图片预缓存
  }

  @override
  void dispose() {
    _highlightController.dispose();
    _layoutController.dispose();
    widget.controller?._detach();
    super.dispose();
  }

  @override
  void didUpdateWidget(MindMap<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._detach();
      widget.controller?._attach(this);
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
          child: LaTeX(
            laTeXCode: Text(
              latex,
              style: TextStyle(
                color: Colors.grey[800]!.withOpacity(0.9),
                fontSize: 13,
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

  void highlightNode(List<String> nodeId) {
    setState(() {
      widget.rootNode._updateHighlight(nodeId);
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
            border: Border.all(color: Colors.grey[200]!),
            borderRadius: BorderRadius.circular(8),
          ),
          // color: Colors.orange,
          width: widget.width,
          height: widget.height,
          child: AnimatedBuilder(
            animation: _highlightAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: _offset,
                child: CustomPaint(
                  painter: _MindMapPainter(
                    latexCache: _latexCache,
                    imageCache: _imageCache, // 添加图片缓存
                    questionBankCacheDirs: widget.questionBankCacheDirs ?? {}, // 添加题库缓存目录
                    rootNode: widget.rootNode,
                    lineColor: widget.lineColor,
                    lineWidth: widget.lineWidth,
                    scale: _scale,
                    highlightProgress: _highlightAnimation.value,
                    onImageLoaded: () {
                      // 图片加载完成后重绘
                      setState(() {});
                    },
                  ),
                  size: Size.infinite,
                ),
              );
            },
          ),
        ),
      ),
    );
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
        node.position.dx + node.size.width / 2 + 15,
        node.position.dy,
      );
      final distance = (position - indicatorCenter).distance;
      if (distance <= 8.0) { // 指示器半径
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

class _MindMapPainter extends CustomPainter {
  final MindMapNode rootNode;
  final Color lineColor;
  final double lineWidth;
  final double scale;
  final double highlightProgress;
  final Map<String, ui.Image> latexCache;
  final Map<String, ui.Image> imageCache; // 添加图片缓存
  final Map<String, String> questionBankCacheDirs; // 题库缓存目录映射
  final VoidCallback? onImageLoaded; // 图片加载完成回调

  _MindMapPainter({
    required this.rootNode,
    required this.lineColor,
    required this.lineWidth,
    required this.scale,
    required this.highlightProgress,
    required this.latexCache,
    required this.imageCache, // 添加图片缓存参数
    required this.questionBankCacheDirs, // 添加题库缓存目录参数
    this.onImageLoaded,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(scale);
    _drawNode(canvas, rootNode);
    canvas.restore();
  }

  // 异步加载图片
  void _loadImageForNode(MindMapNode node) {
    if (node.image == null || node.cachedImage != null) return;
    
    // 检查是否已经在全局缓存中
    final cachedImage = imageCache[node.image!];
    if (cachedImage != null) {
      node.setCachedImage(cachedImage);
      // 使用 WidgetsBinding.instance.addPostFrameCallback 来避免在绘制期间调用 setState
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onImageLoaded?.call(); // 触发重绘
      });
      return;
    }
    
    // 异步加载图片
    _loadImageAsync(node.image!).then((image) {
      if (image != null) {
        imageCache[node.image!] = image; // 添加到全局缓存
        node.setCachedImage(image); // 设置到节点
        // 使用 WidgetsBinding.instance.addPostFrameCallback 来避免在绘制期间调用 setState
        WidgetsBinding.instance.addPostFrameCallback((_) {
          onImageLoaded?.call(); // 触发重绘
        });
      }
    }).catchError((error) {
      print('Error loading image ${node.image}: $error');
    });
  }

  // 异步加载图片文件
  Future<ui.Image?> _loadImageAsync(String imagePath) async {
    try {
      late File imageFile;
      
      // 根据路径类型处理
      if (imagePath.startsWith('http')) {
        // 网络图片 - 暂时不支持，可以后续扩展
        return null;
      } else if (imagePath.startsWith('/') || imagePath.contains(':')) {
        // 绝对路径
        imageFile = File(imagePath);
      } else {
        // 相对路径，需要在题库缓存目录中查找
        String? foundPath;
        for (final cacheDir in questionBankCacheDirs.values) {
          final fullPath = '$cacheDir/$imagePath';
          if (File(fullPath).existsSync()) {
            foundPath = fullPath;
            break;
          }
        }
        if (foundPath == null) return null;
        imageFile = File(foundPath);
      }
      
      if (!imageFile.existsSync()) return null;
      
      final bytes = await imageFile.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      return frame.image;
    } catch (e) {
      print('Error loading image: $e');
      return null;
    }
  }

  void _drawNode(Canvas canvas, MindMapNode node) {
    // 只有在节点未折叠时才绘制子节点
    if (!node.isCollapsed) {
      for (final child in node.children) {
        _drawConnection(canvas, node, child);
        _drawNode(canvas, child);
      }
    }

    // 如果是隐藏的根节点（尺寸为0），不绘制节点本身
    if (node.size.width == 0 && node.size.height == 0) {
      return;
    }

    // 根据内容类型选择不同的绘制样式
    if (node.hasImage) {
      _drawImageNode(canvas, node);
    } else if (node.isLatex) {
      _drawLatexNode(canvas, node);
    } else {
      _drawTextNode(canvas, node);
    }

    // 如果节点有子节点，绘制折叠/展开指示器
    if (node.canCollapse) {
      _drawCollapseIndicator(canvas, node);
    }
  }

  // 绘制折叠/展开指示器
  void _drawCollapseIndicator(Canvas canvas, MindMapNode node) {
    // 指示器位置在节点右侧
    final indicatorCenter = Offset(
      node.position.dx + node.size.width / 2 + 15,
      node.position.dy,
    );
    
    const indicatorRadius = 8.0;
    
    // 绘制圆形背景
    final circlePaint = Paint()
      ..color = node.isCollapsed ? Colors.grey[300]! : Colors.blue[300]!
      ..style = PaintingStyle.fill;
    canvas.drawCircle(indicatorCenter, indicatorRadius, circlePaint);
    
    // 绘制边框
    final borderPaint = Paint()
      ..color = node.isCollapsed ? Colors.grey[500]! : Colors.blue[500]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(indicatorCenter, indicatorRadius, borderPaint);
    
    // 绘制 +/- 符号
    final linePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    
    // 横线（总是显示）
    canvas.drawLine(
      Offset(indicatorCenter.dx - 4, indicatorCenter.dy),
      Offset(indicatorCenter.dx + 4, indicatorCenter.dy),
      linePaint,
    );
    
    // 竖线（只在折叠时显示，形成 + 号）
    if (node.isCollapsed) {
      canvas.drawLine(
        Offset(indicatorCenter.dx, indicatorCenter.dy - 4),
        Offset(indicatorCenter.dx, indicatorCenter.dy + 4),
        linePaint,
      );
    }
  }

  // 绘制图片节点 - XMind 风格
  void _drawImageNode(Canvas canvas, MindMapNode node) {
    final image = node.cachedImage; // 使用缓存的图片
    if (image == null) {
      // 如果图片还没有加载，尝试从缓存加载或异步加载
      _loadImageForNode(node);
      _drawTextNode(canvas, node);
      return;
    }

    // 绘制节点背景 - 更像卡片的样式
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: node.position,
        width: node.size.width,
        height: node.size.height,
      ),
      const Radius.circular(16),
    );

    // 阴影
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawRRect(rect.shift(const Offset(0, 4)), shadowPaint);

    // 背景
    final backgroundPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawRRect(rect, backgroundPaint);

    // 高亮效果
    if (node.isHighlighted) {
      final highlightPaint = Paint()
        ..color = Color.lerp(
          Colors.amber.withOpacity(0.3),
          Colors.amber.withOpacity(0.6),
          highlightProgress,
        )!
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;
      canvas.drawRRect(rect.inflate(2), highlightPaint);
    }

    // 计算图片的显示尺寸 - 占用除文字区域外的所有空间
    const double textAreaHeight = 40.0; // 为文本预留的高度
    const double padding = 10.0; // 图片四周的内边距
    
    final maxImageWidth = node.size.width - (padding * 2);
    final maxImageHeight = node.size.height - textAreaHeight - (padding * 2);
    
    final imageAspectRatio = image.width / image.height;
    double imageWidth = maxImageWidth;
    double imageHeight = imageWidth / imageAspectRatio;
    
    if (imageHeight > maxImageHeight) {
      imageHeight = maxImageHeight;
      imageWidth = imageHeight * imageAspectRatio;
    }

    // 绘制图片 - 位置在节点上半部分居中
    final imageRect = Rect.fromCenter(
      center: Offset(
        node.position.dx, 
        node.position.dy - (textAreaHeight / 2) // 向上偏移，为文字留出空间
      ),
      width: imageWidth,
      height: imageHeight,
    );
    
    // 图片圆角裁剪
    final imageRRect = RRect.fromRectAndRadius(imageRect, const Radius.circular(8));
    canvas.clipRRect(imageRRect);
    canvas.drawImageRect(
      image, 
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()), 
      imageRect, 
      Paint()
    );
    canvas.restore();
    canvas.save();
    canvas.scale(scale);

    // 绘制文本标签（统一大小和样式）
    if (node.text.isNotEmpty) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: node.text,
          style: TextStyle(
            color: Colors.grey[800],
            fontSize: 14, // 统一文字大小
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout(maxWidth: node.size.width - 20);

      // 文本位置：固定在节点底部
      final textPos = Offset(
        node.position.dx - textPainter.width / 2,
        node.position.dy + (node.size.height / 2) - 25, // 固定距底部25px
      );
      textPainter.paint(canvas, textPos);
    }

    // 边框
    final borderPaint = Paint()
      ..color = node.color.withOpacity(0.3)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(rect, borderPaint);
  }

  // 绘制文本节点 - 更现代的样式
  void _drawTextNode(Canvas canvas, MindMapNode node) {
    final isRootNode = node.parent == null || (node.parent != null && node.parent!.size == const Size(0, 0));
    
    // 计算圆角半径
    final borderRadius = isRootNode ? 20.0 : 12.0;

    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(
          center: node.position,
          width: node.size.width,
        height: node.size.height,
      ),
      Radius.circular(borderRadius),
    );

    // 阴影效果
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.1)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawRRect(rect.shift(const Offset(0, 2)), shadowPaint);

    // 渐变背景
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        node.color.withOpacity(0.9),
        node.color.withOpacity(0.7),
      ],
    );
    
    final fillPaint = Paint()
      ..shader = gradient.createShader(rect.outerRect)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(rect, fillPaint);

    // 高亮效果
    if (node.isHighlighted) {
      final highlightPaint = Paint()
        ..color = Color.lerp(
          Colors.amber.withOpacity(0.4),
          Colors.amber.withOpacity(0.8),
          highlightProgress,
        )!
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
      canvas.drawRRect(rect.inflate(8), highlightPaint);

      // 高亮边框
      final highlightBorderPaint = Paint()
        ..color = Colors.amber.withOpacity(0.9)
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke;
      canvas.drawRRect(rect, highlightBorderPaint);
    }

    // 绘制文本
    final textPainter = TextPainter(
      text: TextSpan(
        text: node.text,
        style: TextStyle(
          color: Colors.white,
          fontSize: isRootNode ? 16 : 13,
          fontWeight: isRootNode ? FontWeight.bold : FontWeight.w600,
          shadows: [
            Shadow(
              offset: const Offset(0.5, 0.5),
              blurRadius: 1.0,
              color: Colors.black.withOpacity(0.3),
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout(maxWidth: node.size.width - 20);

    final textPos = node.position - Offset(textPainter.width / 2, textPainter.height / 2);
    textPainter.paint(canvas, textPos);

    // 细边框装饰
    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(rect, borderPaint);
  }

  // 绘制 LaTeX 节点
  void _drawLatexNode(Canvas canvas, MindMapNode node) {
    final image = latexCache[node.latexContent];
    if (image == null) {
      _drawTextNode(canvas, node);
      return;
    }

    // 计算白色背景框
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: node.position,
        width: node.size.width,
        height: node.size.height,
      ),
      const Radius.circular(12),
    );

    // 阴影
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.1)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawRRect(rect.shift(const Offset(0, 2)), shadowPaint);

    // 白色背景
    final backgroundPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawRRect(rect, backgroundPaint);

    // 高亮效果
    if (node.isHighlighted) {
      final highlightPaint = Paint()
        ..color = Color.lerp(
          Colors.amber.withOpacity(0.3),
          Colors.amber.withOpacity(0.6),
          highlightProgress,
        )!
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawRRect(rect, highlightPaint);
    }

    // 绘制 LaTeX 图像
    final aspectRatio = image.width / image.height;
    final maxWidth = node.size.width - 20;
    final maxHeight = node.size.height - 20;

    double width = maxWidth;
    double height = width / aspectRatio;
    if (height > maxHeight) {
      height = maxHeight;
      width = height * aspectRatio;
    }

    final offset = node.position - Offset(width / 2, height / 2);
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.scale(width / image.width);
    canvas.drawImage(image, Offset.zero, Paint());
    canvas.restore();

    // 边框
    final borderPaint = Paint()
      ..color = node.color.withOpacity(0.4)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(rect, borderPaint);
  }

  void _drawConnection(Canvas canvas, MindMapNode parent, MindMapNode child) {
    // 如果父节点是隐藏的根节点（尺寸为0），不绘制连接线
    if (parent.size.width == 0 && parent.size.height == 0) {
      return;
    }
    
    final start = Offset(
      parent.position.dx +
          (child.position.dx > parent.position.dx ? 1 : -1) *
              parent.size.width /
              2,
      parent.position.dy,
    );
    final end = Offset(
      child.position.dx +
          (child.position.dx > parent.position.dx ? -1 : 1) *
              child.size.width /
              2,
      child.position.dy,
    );

    // 创建更优雅的贝塞尔曲线
    final controlPoint1 = Offset(
      start.dx + (end.dx - start.dx) * 0.5,
      start.dy,
    );
    final controlPoint2 = Offset(
      start.dx + (end.dx - start.dx) * 0.5,
      end.dy,
    );

    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..cubicTo(
        controlPoint1.dx, controlPoint1.dy,
        controlPoint2.dx, controlPoint2.dy,
        end.dx, end.dy,
      );

    // 绘制连接线阴影
    final shadowPath = Path()
      ..moveTo(start.dx + 1, start.dy + 1)
      ..cubicTo(
        controlPoint1.dx + 1, controlPoint1.dy + 1,
        controlPoint2.dx + 1, controlPoint2.dy + 1,
        end.dx + 1, end.dy + 1,
      );

    canvas.drawPath(
      shadowPath,
      Paint()
        ..color = Colors.black.withOpacity(0.1)
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );

    // 绘制主连接线
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          colors: [
            parent.color.withOpacity(0.9),
            child.color.withOpacity(0.9),
          ],
        ).createShader(Rect.fromPoints(start, end))
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );

    // 绘制连接点
    canvas.drawCircle(
      end, 
      4.0, 
      Paint()
        ..color = child.color.withOpacity(0.9)
        ..style = PaintingStyle.fill,
    );
    
    // 连接点的高光效果
    canvas.drawCircle(
      end, 
      4.0, 
      Paint()
        ..color = Colors.white.withOpacity(0.3)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant _MindMapPainter old) =>
      old.rootNode != rootNode ||
      old.highlightProgress != highlightProgress ||
      old.scale != scale;
}

class MindMapHelper {
  static const int _defaultHorizontalSpacing = 200; // 水平间距
  static const int _defaultVerticalSpacing = 80; // 垂直间距
  static const int _horizontalSpacing = 200;
  static const int _verticalSpacing = 10;

  /// 创建根节点
  static MindMapNode<T> createRoot<T>(
      {String? id,
      String text = 'Root',
      Offset position = Offset.zero,
      T? data}) {
    return MindMapNode<T>(
        id: id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        text: text,
        position: position,
        data: data);
  }
  
  /// 创建智能根节点 - 根据题库数量决定是否显示根节点
  static MindMapNode<T> createSmartRoot<T>(
      {String? id,
      String text = 'Root',
      Offset position = Offset.zero,
      T? data,
      required int questionBankCount}) {
    
    // 如果只有一个题库，创建一个隐藏的根节点
    if (questionBankCount == 1) {
      return MindMapNode<T>(
          id: id ?? DateTime.now().microsecondsSinceEpoch.toString(),
          text: '', // 空文本，实际不会显示
          position: position,
          data: data,
          size: const Size(0, 0)); // 零尺寸，不占用空间
    }
    
    // 多个题库时显示正常的根节点
    return MindMapNode<T>(
        id: id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        text: text,
        position: position,
        data: data);
  }

  /// 添加子节点到指定父节点，自动计算位置
  static MindMapNode<T> addChildNode<T>(MindMapNode<T> parent, String text,
      {bool left = false, String? id, T? data, Color? color, String? image}) {
    final newPosition = _calculateChildPosition(parent, left);
    
    // 使用更现代的颜色方案
    final defaultColors = [
      const Color(0xFF6366F1), // 紫色
      const Color(0xFF8B5CF6), // 紫罗兰
      const Color(0xFF06B6D4), // 青色
      const Color(0xFF10B981), // 绿色
      const Color(0xFFF59E0B), // 橙色
      const Color(0xFFEF4444), // 红色
      const Color(0xFF8B5A2B), // 棕色
      const Color(0xFF6B7280), // 灰色
    ];
    
    final defaultColor = defaultColors[parent.children.length % defaultColors.length];
    
    // 为图片节点使用更大的默认尺寸
    Size? nodeSize;
    if (image != null && image.isNotEmpty) {
      nodeSize = const Size(200, 150); // 图片节点的默认大小
    }
    
    var node = MindMapNode<T>(
        id: id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        text: text,
        position: newPosition,
        parent: parent,
        color: color ?? defaultColor,
        image: image, // 添加图片参数
        data: data,
        size: nodeSize); // 使用计算出的大小
    
    // 如果父节点是根节点，设置子节点的side
    final isRootNode = parent.parent == null || (parent.parent != null && parent.parent!.size == const Size(0, 0));
    if (isRootNode) {
      node.side = parent.children.length % 2 == 1 ? NodeSide.left : NodeSide.right;
    } else {
      node.side = parent.side; // 继承父节点的side
    }

    parent.children.add(node);
    return node;
  }

  /// 计算子节点位置
  static Offset _calculateChildPosition<T>(MindMapNode<T> parent, bool left) {
    final isRootNode = parent.parent == null || (parent.parent != null && parent.parent!.size == const Size(0, 0));

    // 对于根节点，我们只决定左右方向，具体位置由organizeTree调整
    // 这里使用默认间距，具体位置会在organizeTree中用动态间距重新计算
    if (isRootNode) {
        final isLeftSide = parent.children.length % 2 == 1;
        final dx = isLeftSide ? -_defaultHorizontalSpacing : _defaultHorizontalSpacing;
        return Offset(parent.position.dx + dx, parent.position.dy);
    }
    
    // 对于非根节点，根据其自身的side属性决定方向
    // 这里使用默认间距，具体位置会在organizeTree中用动态间距重新计算
    final dx = parent.side == NodeSide.left ? -_defaultHorizontalSpacing : _defaultHorizontalSpacing;
    return Offset(parent.position.dx + dx, parent.position.dy);
  }

  static MindMapNode<T> addAutoChild<T>(MindMapNode<T> parent, String text) {
    final node = MindMapNode<T>(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      text: text,
      position: _calculateChildPosition(parent, false),
    );
    parent.children.add(node);
    return node;
  } // 垂直基础间距

  static const double _minNodeHeight = 30.0; // 节点最小高度

  static void organizeTree<T>(MindMapNode<T> root) {
    _calculateTreeHeight(root);
    _layoutSubtree(root, root.position);
  }

  // 计算树深度（后序遍历）
  static double _calculateTreeHeight<T>(MindMapNode<T> node) {
    final isRootNode = node.parent == null || (node.parent != null && node.parent!.size == const Size(0, 0));
    
    if (isRootNode) {
      // 对根节点，分别计算左右子树的高度
      final leftChildren = node.children.where((c) => c.side == NodeSide.left);
      final rightChildren = node.children.where((c) => c.side == NodeSide.right);

      node.leftChildHeight = leftChildren.fold(0.0, (sum, child) {
        final childHeight = _calculateTreeHeight(child);
        return sum + childHeight + _verticalSpacing;
      }) - (leftChildren.isNotEmpty ? _verticalSpacing : 0);
      
      node.rightChildHeight = rightChildren.fold(0.0, (sum, child) {
        final childHeight = _calculateTreeHeight(child);
        return sum + childHeight + _verticalSpacing;
      }) - (rightChildren.isNotEmpty ? _verticalSpacing : 0);
      
      node.childHeight = (node.leftChildHeight > node.rightChildHeight ? node.leftChildHeight : node.rightChildHeight);
      return node.childHeight;

    } else {
      // 如果节点被折叠或没有子节点，只返回节点自身的高度
      if (node.isCollapsed || node.children.isEmpty) {
        node.childHeight = node.size.height;
        return node.childHeight;
      }
      
      // 只有在节点展开时才计算子节点高度
      node.childHeight = node.children.fold(0.0, (sum, child) {
        return sum + _calculateTreeHeight(child) + _verticalSpacing;
      }) - _verticalSpacing;
      return node.childHeight;
    }
  }

  // 递归布局子树
  static void _layoutSubtree<T>(MindMapNode<T> node, Offset parentPosition) {
    // 如果节点被折叠或没有子节点，不布局子树
    if (node.isCollapsed || node.children.isEmpty) return;

    final isRootNode = node.parent == null || (node.parent != null && node.parent!.size == const Size(0, 0));

    if (isRootNode) {
      // 根节点的子节点左右分布
      double leftStartY = node.position.dy - node.leftChildHeight / 2;
      double rightStartY = node.position.dy - node.rightChildHeight / 2;

    for (final child in node.children) {
        // 计算动态水平间距，考虑节点和父节点的宽度
        final dynamicSpacing = _calculateDynamicSpacing(node, child);
        
        if (child.side == NodeSide.left) {
          final childX = node.position.dx - dynamicSpacing;
          final childY = leftStartY + child.childHeight / 2;
      child.position = Offset(childX, childY);
      _layoutSubtree(child, child.position);
          leftStartY += child.childHeight + _verticalSpacing;
        } else { // Right side
          final childX = node.position.dx + dynamicSpacing;
          final childY = rightStartY + child.childHeight / 2;
          child.position = Offset(childX, childY);
          _layoutSubtree(child, child.position);
          rightStartY += child.childHeight + _verticalSpacing;
        }
      }
    } else {
      // 非根节点布局
      double totalHeight = node.childHeight;
      double startY = node.position.dy - totalHeight / 2;
      
      final isLeft = node.side == NodeSide.left;

      for (final child in node.children) {
        // 计算动态水平间距，考虑节点和父节点的宽度
        final dynamicSpacing = _calculateDynamicSpacing(node, child);
        final childX = node.position.dx + (isLeft ? -dynamicSpacing : dynamicSpacing);
        final childY = startY + child.childHeight / 2;
        child.position = Offset(childX, childY);
        _layoutSubtree(child, child.position);
        startY += child.childHeight + _verticalSpacing;
    }
    }
  }

  // 计算动态水平间距，考虑父节点和子节点的宽度
  static double _calculateDynamicSpacing<T>(MindMapNode<T> parent, MindMapNode<T> child) {
    // 基础间距
    double baseSpacing = _horizontalSpacing.toDouble();
    
    // 计算父节点和子节点的半宽
    double parentHalfWidth = parent.size.width / 2;
    double childHalfWidth = child.size.width / 2;
    
    // 确保间距足够大，避免重叠，并添加额外的缓冲区
    double minSpacing = parentHalfWidth + childHalfWidth + 50; // 50是额外的缓冲区
    
    // 返回基础间距和最小间距中的较大值
    return minSpacing > baseSpacing ? minSpacing : baseSpacing;
  }
}
