import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// 思维导图节点数据类
class MindMapNode {
  final String id;
  String text;
  Offset position;
  final List<MindMapNode> children;
  Size size;
  MindMapNode? parent;
  Color color;
  double childHeight = 0.0;
  bool isHighlighted = false;

  MindMapNode({
    required this.id,
    required this.text,
    required this.position,
    Iterable<MindMapNode> children = const [],
    this.size = const Size(120, 48),
    this.color = Colors.blue,
    this.parent,
  }) : children = List.of(children);

  void _updateHighlight(String targetId) {
    isHighlighted = id == targetId;
    for (final child in children) {
      child._updateHighlight(targetId);
    }
  }
}

class MindMapController {
  _MindMapState? _state;

  void _attach(_MindMapState state) {
    _state = state;
  }

  void _detach() {
    _state = null;
  }

  void centerNode(MindMapNode node,
      {Duration duration = const Duration(milliseconds: 500)}) {
    _state?.centerNode(node, duration: duration);
  }

  void highlightNode(String nodeId) {
    _state?.highlightNode(nodeId);
  }
}

/// 封装好的思维导图组件
class MindMap extends StatefulWidget {
  final MindMapNode rootNode;
  final Color lineColor;
  final double lineWidth;
  final VoidCallback? onUpdated;
  final Function(MindMapNode)? onNodeTap;
  final String? highlightedNodeId;
  final MindMapController? controller;

  final double height;

  final double width;

  const MindMap({
    super.key,
    required this.rootNode,
    required this.width,
    required this.height,
    this.lineColor = Colors.grey,
    this.lineWidth = 1.5,
    this.onUpdated,
    this.onNodeTap,
    this.highlightedNodeId,
    this.controller,
  });

  @override
  State<MindMap> createState() => _MindMapState();

  void centerNodeById(String nodeId) {
    final node = _findNodeById(rootNode, nodeId);
    if (node != null) _MindMapState().centerNode(node);
  }

  MindMapNode? _findNodeById(MindMapNode root, String id) {
    if (root.id == id) return root;
    for (final child in root.children) {
      final found = _findNodeById(child, id);
      if (found != null) return found;
    }
    return null;
  }
}

class _MindMapState extends State<MindMap> with TickerProviderStateMixin {
  double _scale = 1.0;
  Offset _offset = Offset.zero;
  late Offset _initialFocalPoint;
  late Offset _initialOffset;
  late double _initialScale;
  late AnimationController _highlightController;
  late Animation<double> _highlightAnimation;

  @override
  void dispose() {
    widget.controller?._detach();
    _highlightController.dispose();
    super.dispose();
  }

  // 新增高亮节点方法
  void highlightNode(String nodeId) {
    setState(() {
      _highlightController.reset();
      _highlightController.forward();
      widget.rootNode._updateHighlight(nodeId);
    });
  }

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
  }

  void _handleTap(Offset localPosition) {
    // 调整坐标转换顺序：先减偏移，再除缩放因子
    final tapPosition = (localPosition / _scale) - _offset;
    final node = _findNodeAtPosition(widget.rootNode, tapPosition);
    if (node != null) widget.onNodeTap?.call(node);
  }

  MindMapNode? _findNodeAtPosition(MindMapNode node, Offset position) {
    final rect = Rect.fromCenter(
      center: node.position,
      width: node.size.width,
      height: node.size.height,
    );
    if (rect.contains(position)) return node;
    for (final child in node.children) {
      final found = _findNodeAtPosition(child, position);
      if (found != null) return found;
    }
    return null;
  }

  void centerNode(MindMapNode node,
      {Duration duration = const Duration(milliseconds: 500)}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final screenSize = context.size!;
      final targetOffset = Offset(
        screenSize.width / 2 - node.position.dx * _scale,
        screenSize.height / 2 - node.position.dy * _scale,
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
      controller.forward();
    });
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
              return Transform.scale(
                scale: _scale,
                alignment: Alignment.center,
                child: Transform.translate(
                  offset: _offset,
                  child: CustomPaint(
                    painter: _MindMapPainter(
                      rootNode: widget.rootNode,
                      lineColor: widget.lineColor,
                      lineWidth: widget.lineWidth,
                      scale: _scale,
                      highlightProgress: _highlightAnimation.value,
                    ),
                    size: Size.infinite,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// 思维导图绘制器
class _MindMapPainter extends CustomPainter {
  final MindMapNode rootNode;
  final Color lineColor;
  final double lineWidth;
  final double scale;
  final double highlightProgress;

  _MindMapPainter({
    required this.rootNode,
    required this.lineColor,
    required this.lineWidth,
    required this.scale,
    required this.highlightProgress,
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

    final isHighlighted = node.isHighlighted; // 修正判断逻辑
    final highlightColor = Color.lerp(
      node.color.withOpacity(0),
      node.color.withOpacity(0.3),
      highlightProgress,
    )!;

    // 绘制背景
    final fillColor = node.color.withOpacity(0.15);
    final borderColor = node.color.withOpacity(0.3);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: node.position,
          width: node.size.width,
          height: node.size.height,
        ),
        const Radius.circular(6),
      ),
      Paint()
        ..color = fillColor
        ..style = PaintingStyle.fill,
    );

    // 绘制高亮效果
    if (isHighlighted) {
      final highlightPaint = Paint()
        ..color = highlightColor
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: node.position,
            width: node.size.width + 16,
            height: node.size.height + 16,
          ),
          const Radius.circular(8),
        ),
        highlightPaint,
      );
    }

    // 绘制边框
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: node.position,
          width: node.size.width,
          height: node.size.height,
        ),
        const Radius.circular(6),
      ),
      Paint()
        ..color = borderColor
        ..strokeWidth = 0.8
        ..style = PaintingStyle.stroke,
    );

    // 绘制文字
    final textStyle = TextStyle(
      color: Colors.grey[800]!.withOpacity(0.9),
      fontSize: 13,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
    );

    final textPainter = TextPainter(
      text: TextSpan(text: node.text, style: textStyle),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    textPainter.layout(maxWidth: node.size.width - 20);
    textPainter.paint(
      canvas,
      node.position - Offset(textPainter.width / 2, textPainter.height / 2),
    );
  }

  void _drawConnection(Canvas canvas, MindMapNode parent, MindMapNode child) {
    final parentCenter = parent.position;
    final childCenter = child.position;

    final isRight = childCenter.dx > parentCenter.dx;
    final curveDirection = isRight ? 1.0 : -1.0;

    final start = Offset(
      parentCenter.dx +
          (isRight ? parent.size.width / 2 : -parent.size.width / 2),
      parentCenter.dy,
    );

    final end = Offset(
      childCenter.dx + (isRight ? -child.size.width / 2 : child.size.width / 2),
      childCenter.dy,
    );

    final linePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          parent.color.withOpacity(0.6),
          child.color.withOpacity(0.6),
        ],
      ).createShader(Rect.fromPoints(start, end))
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..quadraticBezierTo(
        (start.dx + end.dx) / 2,
        (start.dy + end.dy) / 2 + 40 * curveDirection,
        end.dx,
        end.dy,
      );

    canvas.drawPath(path, linePaint);
    // 绘制箭头
    canvas.drawCircle(
      end,
      3.0,
      Paint()..color = child.color.withOpacity(0.8),
    );
  }

  @override
  bool shouldRepaint(covariant _MindMapPainter oldDelegate) =>
      oldDelegate.rootNode != rootNode ||
      oldDelegate.lineColor != lineColor ||
      oldDelegate.lineWidth != lineWidth ||
      oldDelegate.scale != scale ||
      oldDelegate.highlightProgress != highlightProgress;
}

class MindMapHelper {
  static const int _defaultHorizontalSpacing = 200; // 水平间距
  static const int _defaultVerticalSpacing = 80; // 垂直间距
  static const int _horizontalSpacing = 200;
  static const int _verticalSpacing = 10;

  /// 创建根节点
  static MindMapNode createRoot({
    String? id,
    String text = 'Root',
    Offset position = Offset.zero,
  }) {
    return MindMapNode(
      id: id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      text: text,
      position: position,
    );
  }

  /// 添加子节点到指定父节点，自动计算位置
  static MindMapNode addChildNode(MindMapNode parent, String text,
      {bool left = false,String? id}) {
    final newPosition = _calculateChildPosition(parent, left);
    var node = MindMapNode(
      id: id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      text: text,
      position: newPosition,
      parent: parent,
    );
    parent.children.add(node);
    return node;
  }

  /// 计算子节点位置
  static Offset _calculateChildPosition(MindMapNode parent, bool left) {
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

  static MindMapNode addAutoChild(MindMapNode parent, String text) {
    final node = MindMapNode(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      text: text,
      position: _calculateChildPosition(parent, false),
    );
    parent.children.add(node);
    return node;
  } // 垂直基础间距

  static const double _minNodeHeight = 30.0; // 节点最小高度

  static void organizeTree(MindMapNode root) {
    _calculateTreeHeight(root);
    _layoutSubtree(root, root.position);
  }

  // 计算树深度（后序遍历）
  static double _calculateTreeHeight(MindMapNode node) {
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
  static void _layoutSubtree(MindMapNode node, Offset parentPosition) {
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
