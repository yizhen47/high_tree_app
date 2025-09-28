import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'fan_mind_map_node.dart';

class FanMindMapHelper {
  // 创建智能扇形根节点
  static FanMindMapNode<T> createSmartFanRoot<T>({
    required T data,
    required int questionBankCount,
    required Offset position,
    String text = '知识图谱',
  }) {
    return FanMindMapNode<T>(
      id: 'root',
      text: text,
      position: position,
      angle: 0,
      radius: 0,
      level: 0,
      nodeRadius: 40.0,
      color: const Color(0xFF00F5FF),
      data: data,
    );
  }

  // 添加扇形子节点
  static FanMindMapNode<T> addFanChildNode<T>(
    FanMindMapNode<T> parent,
    String text, {
    String? id,
    T? data,
  }) {
    final child = FanMindMapNode<T>(
      id: id ?? '${parent.id}_${parent.children.length}',
      text: text,
      position: parent.position,
      angle: 0,
      radius: 0,
      level: parent.level + 1,
      data: data,
    );
    
    parent.addChild(child);
    return child;
  }

  // 扩散式树结构组织
  static void organizeFanTree<T>(FanMindMapNode<T> rootNode, Size canvasSize) {
    _calculateNodeWeights(rootNode);
    final center = Offset(canvasSize.width / 2, canvasSize.height / 2);
    
    // 设置根节点
    rootNode.position = center;
    rootNode.angle = -math.pi / 2; // 指向上方，更符合树形结构
    rootNode.radius = 0;
    rootNode.level = 0;
    rootNode.nodeRadius = rootNode.getLevelRadius();
    rootNode.color = rootNode.getLevelColor();
    
    // 计算实际的最大深度
    final actualMaxDepth = getMaxDepth(rootNode);
    
    // 使用扩散式布局，确保布局所有层级
    _layoutRadialDispersion(rootNode, canvasSize, 0, actualMaxDepth + 1);
  }

  // 递归计算每个节点的权重（包括自身和所有子孙节点）
  static int _calculateNodeWeights<T>(FanMindMapNode<T> node) {
    if (node.children.isEmpty) {
      node.weight = 1;
      return 1;
    }
    int weight = 1;
    for (var child in node.children) {
      weight += _calculateNodeWeights(child);
    }
    node.weight = weight;
    return weight;
  }
  
  // 扩散式布局 - 全新圆形随机物理排斥算法
  static void _layoutRadialDispersion<T>(
    FanMindMapNode<T> parentNode,
    Size canvasSize,
    int currentLevel,
    int maxLevels,
  ) {
    if (currentLevel >= maxLevels || parentNode.children.isEmpty) return;

    final childLevel = currentLevel + 1;
    final childCount = parentNode.children.length;
    final random = math.Random(parentNode.id.hashCode);

    // 1. 根据层级设置合适的距离参数
    double dispersionRadius;
    if (currentLevel == 0) {
      // 第一层：主干分支
      dispersionRadius = math.min(canvasSize.width, canvasSize.height) * 0.84375; // 0.675 * 1.25
    } else if (currentLevel == 1) {
      // 第二层：次级分支
      dispersionRadius = math.max(400.0, 187.5 + childCount * 50.875); // 300.0 * 1.25, 150.0 * 1.25, 37.5 * 1.25
    } else if (currentLevel == 2) {
      // 第三层：三级分支
      dispersionRadius = math.max(187.5, 93.75 + childCount * 38.5); // 150.0 * 1.25, 75.0 * 1.25, 18.0 * 1.25
    } else if (currentLevel == 3) {
      // 第四层：细分分支
      dispersionRadius = math.max(112.5, 56.25 + childCount * 12.5); // 90.0 * 1.25, 45.0 * 1.25, 10.0 * 1.25
    } else {
      // 第五层及以上：末梢节点，距离更小
      dispersionRadius = math.max(75.0, 37.5 + childCount * 7.5); // 60.0 * 1.25, 30.0 * 1.25, 6.0 * 1.25
    }

    // 2. 将子节点均匀分布在圆形边框上
    if (childCount > 0) {
      final angleStep = 2 * math.pi / childCount;
      // 随机化初始角度，避免布局僵硬
      final startAngle = random.nextDouble() * 2 * math.pi;

      for (int i = 0; i < childCount; i++) {
        final child = parentNode.children[i];
        final angle = startAngle + i * angleStep;

        // 半径轻微浮动，使其围绕圆形边框分布
        final radius = dispersionRadius * (0.95 + random.nextDouble() * 0.1);
        
        child.position = parentNode.position + Offset.fromDirection(angle, radius);
        child.angle = angle;
        child.radius = radius;
        child.level = childLevel;
        child.nodeRadius = child.getLevelRadius();
        child.color = child.getLevelColor();
      }
    }

    // 3. 简单的物理排斥模拟，避免节点重叠（安全距离根据层级调整）
    const iterations = 120;
    const repulsionStrength = 3.5;

    // 根据层级调整安全间距
    double minDistanceGap;
    if (currentLevel == 0) {
      minDistanceGap = 112.5; // 主干分支间距 (90.0 * 1.25)
    } else if (currentLevel == 1) {
      minDistanceGap = 62.5; // 次级分支间距 (50.0 * 1.25)
    } else if (currentLevel == 2) {
      minDistanceGap = 37.5; // 三级分支间距 (30.0 * 1.25)
    } else if (currentLevel == 3) {
      minDistanceGap = 25.0; // 四级分支间距 (20.0 * 1.25)
    } else {
      minDistanceGap = 18.75; // 末梢节点间距 (15.0 * 1.25)
    }
    
    for (int i = 0; i < iterations; i++) {
      for (int j = 0; j < childCount; j++) {
        for (int k = j + 1; k < childCount; k++) {
          final child1 = parentNode.children[j];
          final child2 = parentNode.children[k];

          final vector = child1.position - child2.position;
          final distance = vector.distance;
          // 安全间距根据层级变化
          final minDistance = child1.nodeRadius + child2.nodeRadius + minDistanceGap;

          if (distance < minDistance && distance > 0) {
            final overlap = minDistance - distance;
            final repulsionVector = (vector / distance) * (overlap / 2) * repulsionStrength;
            child1.position += repulsionVector;
            child2.position -= repulsionVector;
          }
        }
      }
    }

    // 4. 递归为子节点进行布局
    for (final child in parentNode.children) {
      // 移除边界限制，让节点自由分布
      _layoutRadialDispersion(child, canvasSize, childLevel, maxLevels);
    }
  }

  /// 根据数据构建扇形节点树
  static void buildFanNodesFromData<T>(
    FanMindMapNode<T> parentNode,
    List<T> dataList,
    String Function(T) getTitle,
    String Function(T) getId,
    List<T> Function(T)? getChildren,
    String? Function(T)? getImage,
    int maxDepth,
  ) {
    if (maxDepth <= 0) return;

    for (final data in dataList) {
      final child = addFanChildNode(
        parentNode,
        getTitle(data),
        id: getId(data),
        data: data,
      );

      // 递归添加子节点
      final childData = getChildren?.call(data);
      if (childData != null && childData.isNotEmpty && maxDepth > 1) {
        buildFanNodesFromData(
          child,
          childData,
          getTitle,
          getId,
          getChildren,
          getImage,
          maxDepth - 1,
        );
      }
    }
  }

  /// 查找节点通过ID
  static FanMindMapNode<T>? findNodeById<T>(FanMindMapNode<T> root, String id) {
    if (root.id == id) return root;
    
    for (final child in root.children) {
      final found = findNodeById(child, id);
      if (found != null) return found;
    }
    
    return null;
  }

  /// 获取节点路径（从根到目标节点）
  static List<FanMindMapNode<T>> getNodePath<T>(FanMindMapNode<T> targetNode) {
    final path = <FanMindMapNode<T>>[];
    FanMindMapNode<T>? current = targetNode;
    
    while (current != null) {
      path.insert(0, current);
      current = current.parent;
    }
    
    return path;
  }

  /// 计算两个角度之间的最短角度差
  static double angleDifference(double a1, double a2) {
    double diff = (a2 - a1) % (2 * math.pi);
    if (diff > math.pi) diff -= 2 * math.pi;
    if (diff < -math.pi) diff += 2 * math.pi;
    return diff;
  }

  /// 标准化角度到 [0, 2π) 范围
  static double normalizeAngle(double angle) {
    angle = angle % (2 * math.pi);
    if (angle < 0) angle += 2 * math.pi;
    return angle;
  }

  /// 获取节点在指定层级的数量
  static int getNodeCountAtLevel<T>(FanMindMapNode<T> root, int level) {
    if (level == 0) return 1;
    
    int count = 0;
    void countNodes(FanMindMapNode<T> node, int currentLevel) {
      if (currentLevel == level) {
        count++;
        return;
      }
      for (final child in node.children) {
        countNodes(child, currentLevel + 1);
      }
    }
    
    for (final child in root.children) {
      countNodes(child, 1);
    }
    
    return count;
  }

  /// 获取扇形图的最大深度
  static int getMaxDepth<T>(FanMindMapNode<T> root) {
    int maxDepth = 0;
    
    void findDepth(FanMindMapNode<T> node, int depth) {
      maxDepth = math.max(maxDepth, depth);
      for (final child in node.children) {
        findDepth(child, depth + 1);
      }
    }
    
    findDepth(root, 0);
    return maxDepth;
  }
} 