import 'package:flutter/material.dart';
import 'mind_map_node.dart';

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
    
    // 计算节点层级深度
    final nodeDepth = _calculateNodeDepth(parent) + 1;
    
    // 根据层级设置默认折叠状态：二级目录（depth=2）默认折叠，其他展开
    final defaultCollapsed = (nodeDepth == 2);
    
    var node = MindMapNode<T>(
        id: id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        text: text,
        position: newPosition,
        parent: parent,
        color: color ?? defaultColor,
        image: image, // 添加图片参数
        data: data,
        size: nodeSize); // 使用计算出的大小
    
    // 设置默认折叠状态
    node.isCollapsed = defaultCollapsed;
    
    parent.children.add(node);

    final isRootNode = parent.parent == null || (parent.parent != null && parent.parent!.size == const Size(0, 0));
    if (isRootNode) {
      // 对于根节点的子节点，每次添加后都重新平衡所有兄弟节点。
      // 这样可以确保始终根据最新的总数进行连续、平衡的分配。
      final totalNodes = parent.children.length;
      final expectedLeftCount = (totalNodes + 1) ~/ 2; // 左侧应有的节点数
      for (int i = 0; i < totalNodes; i++) {
        parent.children[i].side = i < expectedLeftCount ? NodeSide.left : NodeSide.right;
      }
    } else {
      // 非根节点的子节点继承父节点的side
      node.side = parent.side;
    }

    return node;
  }

  /// 计算子节点位置
  static Offset _calculateChildPosition<T>(MindMapNode<T> parent, bool left) {
    final isRootNode = parent.parent == null || (parent.parent != null && parent.parent!.size == const Size(0, 0));

    // 对于根节点，我们只决定左右方向，具体位置由organizeTree调整
    // 这里使用默认间距，具体位置会在organizeTree中用动态间距重新计算
    if (isRootNode) {
        // 连续分配策略：前面的节点连续放左边，后面的连续放右边
        final currentIndex = parent.children.length; // 当前节点是第几个（从0开始）
        
        // 动态计算分割点，确保左右尽量平衡
        final totalNodes = parent.children.length + 1; // 包括即将添加的这个节点
        final expectedLeftCount = (totalNodes + 1) ~/ 2; // 向上取整
        
        final isLeftSide = currentIndex < expectedLeftCount;
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

  // 计算节点的层级深度
  static int _calculateNodeDepth<T>(MindMapNode<T> node) {
    int depth = 0;
    MindMapNode? current = node;
    
    while (current != null) {
      // 如果是隐藏的根节点（尺寸为0），不计入深度
      if (current.size.width == 0 && current.size.height == 0) {
        current = current.parent;
        continue;
      }
      
      // 如果到达真正的根节点（没有父节点），停止计算
      if (current.parent == null) {
        break;
      }
      
      depth++;
      current = current.parent;
    }
    
    return depth;
  }
} 