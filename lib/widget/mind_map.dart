import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:latext/latext.dart';

/// 思维导图节点数据类
class MindMapNode<T> {
  final String id;
  String text;
  Offset position;
  final List<MindMapNode<T>> children;
  Size size;
  MindMapNode? parent;
  Color color;
  double childHeight = 0.0;
  bool isHighlighted = false;
  T? data;

  MindMapNode({
    required this.id,
    required this.text,
    required this.position,
    Iterable<MindMapNode<T>> children = const [],
    this.size = const Size(120, 48),
    this.color = Colors.blue,
    this.parent,
    this.data,
  }) : children = List.of(children);

  bool get isLatex => text.contains(r'$$') || text.contains(r'$');
  String get latexContent => isLatex ? text : '';

  void _updateHighlight(List<String> targetId) {
    isHighlighted = (targetId.contains(id));
    for (final child in children) {
      child._updateHighlight(targetId);
    }
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
  final Map<String, ui.Image> _latexCache = {};
  final GlobalKey _repaintBoundaryKey = GlobalKey();

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
    _precacheLatex(widget.rootNode);
  }

  @override
  void dispose() {
    _highlightController.dispose();
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
          child: LaTexT(
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
            _scale = (_scale * scaleFactor).clamp(0.5, 5.0);
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
          final newScale = (_initialScale * details.scale).clamp(0.5, 5.0);
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
                    rootNode: widget.rootNode,
                    lineColor: widget.lineColor,
                    lineWidth: widget.lineWidth,
                    scale: _scale,
                    highlightProgress: _highlightAnimation.value,
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
    final node = _findNodeAtPosition(widget.rootNode, tapPos);
    if (node != null) widget.onNodeTap?.call(node);
  }

  MindMapNode<T>? _findNodeAtPosition(MindMapNode<T> node, Offset position) {
    final rect = Rect.fromCenter(
      center: node.position,
      width: node.size.width,
      height: node.size.height,
    );
    return rect.contains(position)
        ? node
        : node.children
            .expand((c) => [_findNodeAtPosition(c, position)])
            .firstWhere(
              (n) => n != null,
              orElse: () => null,
            );
  }
}

class _MindMapPainter extends CustomPainter {
  final MindMapNode rootNode;
  final Color lineColor;
  final double lineWidth;
  final double scale;
  final double highlightProgress;
  final Map<String, ui.Image> latexCache;

  _MindMapPainter({
    required this.rootNode,
    required this.lineColor,
    required this.lineWidth,
    required this.scale,
    required this.highlightProgress,
    required this.latexCache,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(scale);
    _drawNode(canvas, rootNode);
    canvas.restore();
  }

  void _drawNode(Canvas canvas, MindMapNode node) {
    for (final child in node.children) {
      _drawConnection(canvas, node, child);
      _drawNode(canvas, child);
    }

    final fillPaint = Paint()
      ..color = node.color.withOpacity(0.15)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = node.color.withOpacity(0.3)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(
          center: node.position,
          width: node.size.width,
          height: node.size.height),
      const Radius.circular(6),
    );

    // 绘制背景
    canvas.drawRRect(rect, fillPaint);

    // 高亮效果
    if (node.isHighlighted) {
      final highlightPaint = Paint()
        ..color = Color.lerp(
          node.color.withOpacity(0),
          node.color.withOpacity(0.3),
          highlightProgress,
        )!
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawRRect(
        rect.inflate(8),
        highlightPaint,
      );
    }

    // 绘制边框
    canvas.drawRRect(rect, borderPaint);

    // 内容绘制
    if (node.isLatex) {
      _drawLatex(canvas, node);
    } else {
      _drawText(canvas, node);
    }
  }

// 修改后的_drawLatex方法
  void _drawLatex(Canvas canvas, MindMapNode node) {
    final image = latexCache[node.latexContent];
    if (image == null) return;

    final aspectRatio = image.width / image.height;
    final maxWidth = node.size.width - 10;
    final maxHeight = node.size.height - 10;

    // 计算最佳尺寸
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
  }

  void _drawText(Canvas canvas, MindMapNode node) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: node.text,
        style: TextStyle(
          color: Colors.grey[800]!.withOpacity(0.9),
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout(maxWidth: node.size.width - 20);

    final pos =
        node.position - Offset(textPainter.width / 2, textPainter.height / 2);
    textPainter.paint(canvas, pos);
  }

  void _drawConnection(Canvas canvas, MindMapNode parent, MindMapNode child) {
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

    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..quadraticBezierTo(
        (start.dx + end.dx) / 2,
        (start.dy + end.dy) / 2 +
            40 * (child.position.dx > parent.position.dx ? 1 : -1),
        end.dx,
        end.dy,
      );

    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          colors: [parent.color, child.color],
        ).createShader(Rect.fromPoints(start, end))
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );

    canvas.drawCircle(end, 3.0, Paint()..color = child.color);
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

  /// 添加子节点到指定父节点，自动计算位置
  static MindMapNode<T> addChildNode<T>(MindMapNode<T> parent, String text,
      {bool left = false, String? id, T? data,Color? color}) {
    final newPosition = _calculateChildPosition(parent, left);
    var node = MindMapNode<T>(
        id: id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        text: text,
        position: newPosition,
        parent: parent,
        color: color ?? Colors.blue ,
        data: data);
    parent.children.add(node);
    return node;
  }

  /// 计算子节点位置
  static Offset _calculateChildPosition<T>(MindMapNode<T> parent, bool left) {
    final childCount = parent.children.length;

    // 水平方向：左侧或右侧
    final dx = left ? -_defaultHorizontalSpacing : _defaultHorizontalSpacing;

    // 垂直方向：基于子节点数量居中分布
    final baseY = parent.position.dy +
        (childCount % 2 == 0
            ? -childCount * _defaultVerticalSpacing / 2
            : (childCount - 1) * _defaultVerticalSpacing / 2);

    return Offset(
      parent.position.dx + dx,
      baseY + (childCount.isOdd ? _defaultVerticalSpacing : 0),
    );
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
    if (node.children.isEmpty) {
      node.size = Size(node.size.width, _minNodeHeight);
      node.childHeight = node.size.height;
      return node.childHeight;
    }
    node.childHeight = node.children.fold(0.0, (sum, child) {
          return sum + _calculateTreeHeight(child) + _verticalSpacing;
        }) -
        _verticalSpacing;
    return node.childHeight;
  }

  // 递归布局子树
  static void _layoutSubtree<T>(MindMapNode<T> node, Offset parentPosition) {
    if (node.children.isEmpty) return;

    // 计算子节点总高度（包含动态间距）
    double totalHeight = node.childHeight;

    // 起始Y坐标（垂直居中布局）
    double startY = node.position.dy - totalHeight / 2;
    double currentY = startY;

    for (final child in node.children) {
      // 计算子节点位置
      final childX =
          parentPosition.dx + node.size.width / 2 + _horizontalSpacing;
      final childY = currentY + child.childHeight / 2;
      child.position = Offset(childX, childY);

      // 递归布局子节点
      _layoutSubtree(child, child.position);

      // 更新当前Y坐标（考虑动态间距）
      currentY += child.childHeight + _verticalSpacing;
    }
  }
}
