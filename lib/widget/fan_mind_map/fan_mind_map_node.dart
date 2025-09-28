import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/material.dart';

class FanMindMapNode<T> {
  String id;
  String text;
  Offset position; // 屏幕坐标位置
  double angle; // 节点角度（弧度）
  double radius; // 距离中心的半径
  double nodeRadius; // 节点自身的半径
  int level; // 节点层级 (0=根节点, 1-4=展开层级)
  Color color;
  T? data;
  String? image;
  ui.Image? cachedImage;
  
  // 新增：节点权重，用于动态布局
  int weight = 1;
  
  // 扇形布局属性
  double startAngle; // 扇形起始角度
  double sweepAngle; // 扇形扫描角度
  double innerRadius; // 内半径
  double outerRadius; // 外半径
  
  // 动画属性
  double pulseAnimation = 0.0;
  double glowIntensity = 0.2;
  
  // 高亮属性
  bool isHighlighted = false;
  
  // 移除LaTeX支持，只保留图片检查（虽然图片也已移除）
  bool get hasImage => image != null && image!.isNotEmpty;
  
  bool get isLatex => text.contains(r'$$') || text.contains(r'$');
  String get latexContent => isLatex ? text : '';

  List<FanMindMapNode<T>> children = [];
  FanMindMapNode<T>? parent;

  FanMindMapNode({
    required this.id,
    required this.text,
    required this.position,
    required this.angle,
    required this.radius,
    required this.level,
    this.nodeRadius = 25.0,
    this.color = const Color(0xFF00F5FF),
    this.data,
    this.image,
    this.startAngle = 0.0,
    this.sweepAngle = 0.0,
    this.innerRadius = 0.0,
    this.outerRadius = 0.0,
  });

  void addChild(FanMindMapNode<T> child) {
    children.add(child);
    child.parent = this;
  }

  void removeChild(FanMindMapNode<T> child) {
    children.remove(child);
    child.parent = null;
  }

  void setCachedImage(ui.Image image) {
    cachedImage = image;
    // 根据图片尺寸调整节点大小
    final aspectRatio = image.width / image.height;
    if (aspectRatio > 1) {
      nodeRadius = math.max(25.0, math.min(40.0, 30.0 * aspectRatio));
    } else {
      nodeRadius = math.max(25.0, math.min(40.0, 30.0 / aspectRatio));
    }
  }

  void updateHighlight(List<String> highlightIds) {
    isHighlighted = highlightIds.contains(id);
    for (final child in children) {
      child.updateHighlight(highlightIds);
    }
  }

  // 获取节点的显示文本（清理后的）
  String get displayText {
    // 清理章节标题
    final regex = RegExp(r'^第[\d一二三四五六七八九十百千万]+章\s*');
    return text.replaceFirst(regex, '').trim();
  }

  // 计算节点在扇形中的位置
  void calculateFanPosition(Offset centerPosition, double baseRadius, double levelSpacing) {
    final actualRadius = baseRadius + level * levelSpacing;
    position = centerPosition + Offset(
      math.cos(angle) * actualRadius,
      math.sin(angle) * actualRadius,
    );
    radius = actualRadius;
  }

  // 设置扇形区域
  void setFanSector(double startAngle, double sweepAngle, double innerRadius, double outerRadius) {
    this.startAngle = startAngle;
    this.sweepAngle = sweepAngle;
    this.innerRadius = innerRadius;
    this.outerRadius = outerRadius;
  }

  // 获取适合层级的颜色
  Color getLevelColor() {
    switch (level) {
      case 0: return const Color(0xFF00F5FF); // 根节点 - 亮青色
      case 1: return const Color(0xFF1E90FF); // 第一层 - 深天蓝
      case 2: return const Color(0xFF4169E1); // 第二层 - 皇家蓝
      case 3: return const Color(0xFF6495ED); // 第三层 - 矢车菊蓝
      case 4: return const Color(0xFF87CEEB); // 第四层 - 天蓝色
      default: return const Color(0xFF00FFFF);
    }
  }

  // 获取适合层级的节点大小
  double getLevelRadius() {
    switch (level) {
      case 0: return 35.0; // 根节点最大
      case 1: return 28.0;
      case 2: return 22.0;
      case 3: return 18.0;
      case 4: return 15.0;
      default: return 12.0;
    }
  }

  // 获取适合层级的文字大小
  double getLevelFontSize() {
    switch (level) {
      case 0: return 16.0;
      case 1: return 14.0;
      case 2: return 12.0;
      case 3: return 10.0;
      case 4: return 9.0;
      default: return 8.0;
    }
  }

  @override
  String toString() {
    return 'FanMindMapNode{id: $id, text: $text, level: $level, angle: ${angle * 180 / math.pi}°}';
  }
} 