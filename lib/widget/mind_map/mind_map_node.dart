import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../tool/question/question_bank.dart';

enum NodeSide { left, right, none }

/// 知识图谱节点数据类
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
  
  // 科技风动画属性
  double pulseAnimation = 0.0;
  double glowIntensity = 0.0;
  double hoverProgress = 0.0;

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
      return const Size(120, 50); // 增大基础尺寸适配科技风
    } else if (textLength <= 12) {
      return const Size(160, 60);
    } else if (textLength <= 20) {
      return const Size(200, 70);
    } else {
      return const Size(240, 80);
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

  void updateHighlight(List<String> targetId) {
    isHighlighted = (targetId.contains(id));
    for (final child in children) {
      child.updateHighlight(targetId);
    }
  }

  static MindMapNode<Section> fromSection(Section section) {
    return MindMapNode<Section>(
      id: section.id,
      text: section.title,
      position: Offset.zero, // 初始位置，会在布局时重新计算
      data: section,
      image: section.image, // 如果 Section 有图片属性
      color: const Color(0xFF4F46E5), // 默认颜色
    );
  }
} 