import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'fan_mind_map_node.dart';
import '../fan_mind_map.dart';

class FanMindMapPainter<T> extends CustomPainter {
  final FanMindMapNode<T> rootNode;
  final Color lineColor;
  final double lineWidth;
  final double scale;
  final double highlightProgress;
  final double pulseProgress;
  final double techProgress;
  final double rotationProgress;
  final Map<String, ui.Image> imageCache;
  final Map<String, ui.Image> latexCache;
  final Map<String, String> questionBankCacheDirs;
  final VoidCallback? onImageLoaded;

  FanMindMapPainter({
    required this.rootNode,
    required this.lineColor,
    required this.lineWidth,
    required this.scale,
    required this.highlightProgress,
    required this.pulseProgress,
    required this.techProgress,
    required this.rotationProgress,
    required this.imageCache,
    required this.latexCache,
    required this.questionBankCacheDirs,
    this.onImageLoaded,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(scale);

    // 绘制扇形连接线
    _drawFanConnections(canvas, rootNode);
    
    // 绘制扇形区域
    _drawFanSectors(canvas, rootNode);
    
    // 绘制节点
    _drawFanNodes(canvas, rootNode);

    canvas.restore();
  }

  void _drawFanConnections(Canvas canvas, FanMindMapNode<T> node) {
    if (node.children.isEmpty) return;

    final paint = Paint()
      ..color = const Color(0xFF00F5FF).withOpacity(0.6)
      ..strokeWidth = lineWidth * (1.0 + pulseProgress * 0.3)
      ..style = PaintingStyle.stroke;

    // 为每个子节点绘制连接线
    for (final child in node.children) {
      // 跳过从根节点(level 0)绘制的连接线，因为根节点已被隐藏
      if (node.level > 0) {
        _drawRadialConnection(canvas, node.position, child.position, paint);
      }
      
      // 递归绘制子节点的连接
      _drawFanConnections(canvas, child);
    }
  }

  void _drawRadialConnection(Canvas canvas, Offset start, Offset end, Paint paint) {
    final path = Path();
    
    // 创建轻微弯曲的连接线
    final controlPoint = Offset(
      (start.dx + end.dx) / 2 + math.sin(techProgress * 2 * math.pi) * 5,
      (start.dy + end.dy) / 2 + math.cos(techProgress * 2 * math.pi) * 5,
    );
    
    path.moveTo(start.dx, start.dy);
    path.quadraticBezierTo(controlPoint.dx, controlPoint.dy, end.dx, end.dy);
    
    // 添加发光效果
    final glowPaint = Paint()
      ..color = paint.color.withOpacity(0.3)
      ..strokeWidth = paint.strokeWidth * 3
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    
    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, paint);
  }

  void _drawFanSectors(Canvas canvas, FanMindMapNode<T> node) {
    if (node.level == 0) {
      // 绘制根节点的扇形区域
      for (final child in node.children) {
        _drawSingleFanSector(canvas, child);
        _drawFanSectors(canvas, child);
      }
    } else {
      for (final child in node.children) {
        _drawFanSectors(canvas, child);
      }
    }
  }

  void _drawSingleFanSector(Canvas canvas, FanMindMapNode<T> node) {
    if (node.sweepAngle <= 0) return;

    final center = rootNode.position;
    final paint = Paint()
      ..color = node.getLevelColor().withOpacity(0.1 + pulseProgress * 0.05)
      ..style = PaintingStyle.fill;

    final rect = Rect.fromCircle(center: center, radius: node.outerRadius);
    
    canvas.drawArc(
      rect,
      node.startAngle,
      node.sweepAngle,
      false,
      paint,
    );

    // 绘制扇形边界
    final borderPaint = Paint()
      ..color = node.getLevelColor().withOpacity(0.3)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // 绘制弧线
    canvas.drawArc(rect, node.startAngle, node.sweepAngle, false, borderPaint);
    
    // 绘制放射线
    final startLine = Offset(
      center.dx + math.cos(node.startAngle) * node.innerRadius,
      center.dy + math.sin(node.startAngle) * node.innerRadius,
    );
    final endLine = Offset(
      center.dx + math.cos(node.startAngle) * node.outerRadius,
      center.dy + math.sin(node.startAngle) * node.outerRadius,
    );
    canvas.drawLine(startLine, endLine, borderPaint);
    
    final startLine2 = Offset(
      center.dx + math.cos(node.startAngle + node.sweepAngle) * node.innerRadius,
      center.dy + math.sin(node.startAngle + node.sweepAngle) * node.innerRadius,
    );
    final endLine2 = Offset(
      center.dx + math.cos(node.startAngle + node.sweepAngle) * node.outerRadius,
      center.dy + math.sin(node.startAngle + node.sweepAngle) * node.outerRadius,
    );
    canvas.drawLine(startLine2, endLine2, borderPaint);
  }

  void _drawFanNodes(Canvas canvas, FanMindMapNode<T> node) {
    _drawSingleFanNode(canvas, node);
    
    for (final child in node.children) {
      _drawFanNodes(canvas, child);
    }
  }

  void _drawSingleFanNode(Canvas canvas, FanMindMapNode<T> node) {
    // 隐藏根节点，知识图谱从子节点开始
    if (node.level == 0) return;
    
    final position = node.position;
    final nodeRadius = node.getLevelRadius() * (1.0 + node.pulseAnimation * 0.1);
    final color = node.getLevelColor();

    // 绘制节点发光效果
    if (node.isHighlighted || node.glowIntensity > 0.2) {
      final glowPaint = Paint()
        ..color = color.withOpacity(node.glowIntensity * 0.8)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(position, nodeRadius * 2, glowPaint);
    }

    // 绘制节点主体
    final nodePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withOpacity(0.9),
          color.withOpacity(0.6),
          color.withOpacity(0.3),
        ],
        stops: const [0.0, 0.7, 1.0],
      ).createShader(Rect.fromCircle(center: position, radius: nodeRadius))
      ..style = PaintingStyle.fill;

    canvas.drawCircle(position, nodeRadius, nodePaint);

    // 绘制节点边框
    final borderPaint = Paint()
      ..color = color.withOpacity(0.8)
      ..strokeWidth = 2.0 * (1.0 + node.pulseAnimation * 0.2)
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(position, nodeRadius, borderPaint);

    // 绘制节点内容
    if (node.hasImage && node.cachedImage != null) {
      _drawNodeImage(canvas, node, nodeRadius);
    } else if (node.isLatex) {
      _drawNodeLatex(canvas, node, nodeRadius);
    } else {
      _drawNodeText(canvas, node, nodeRadius);
    }

    // 绘制科技风装饰
    _drawTechDecorations(canvas, node, nodeRadius);
  }

  void _drawNodeImage(Canvas canvas, FanMindMapNode<T> node, double nodeRadius) {
    final image = node.cachedImage!;
    final position = node.position;
    
    final imageSize = nodeRadius * 1.6;
    final srcRect = Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
    final dstRect = Rect.fromCenter(
      center: position,
      width: imageSize,
      height: imageSize,
    );
    
    // 绘制圆形裁剪的图片
    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(dstRect, Radius.circular(imageSize / 2)));
    canvas.drawImageRect(image, srcRect, dstRect, Paint());
    canvas.restore();
  }



  void _drawNodeLatex(Canvas canvas, FanMindMapNode<T> node, double nodeRadius) {
    final cacheKey = '${node.latexContent}_${node.level}';
    final image = latexCache[cacheKey];
    if (image == null) {
      _drawNodeText(canvas, node, nodeRadius);
      return;
    }

    final position = node.position;
    final imageSize = nodeRadius * 1.8;
    final srcRect = Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
    final dstRect = Rect.fromCenter(
      center: position,
      width: imageSize,
      height: imageSize / (image.width / image.height),
    );

    canvas.drawImageRect(image, srcRect, dstRect, Paint());
  }

  void _drawNodeText(Canvas canvas, FanMindMapNode<T> node, double nodeRadius) {
    final text = node.displayText;
    if (text.isEmpty) return;

    final textStyle = TextStyle(
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
    );

    final textSpan = TextSpan(text: text, style: textStyle);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
      maxLines: 2,
    );

    textPainter.layout(maxWidth: nodeRadius * 3);
    
    final textOffset = Offset(
      node.position.dx - textPainter.width / 2,
      node.position.dy - textPainter.height / 2,
    );

    textPainter.paint(canvas, textOffset);
  }

  void _drawTechDecorations(Canvas canvas, FanMindMapNode<T> node, double nodeRadius) {
    final position = node.position;
    final color = node.getLevelColor();
    
    // 绘制旋转的科技环
    final ringPaint = Paint()
      ..color = color.withOpacity(0.4)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final rotationAngle = rotationProgress * 2 * math.pi + node.angle;
    
    // 绘制外环
    for (int i = 0; i < 3; i++) {
      final angle = rotationAngle + i * (2 * math.pi / 3);
      final radius = nodeRadius + 5 + i * 3;
      
      final start = Offset(
        position.dx + math.cos(angle) * radius,
        position.dy + math.sin(angle) * radius,
      );
      final end = Offset(
        position.dx + math.cos(angle + math.pi / 6) * radius,
        position.dy + math.sin(angle + math.pi / 6) * radius,
      );
      
      canvas.drawLine(start, end, ringPaint);
    }

    // 绘制能量点
    if (node.isHighlighted) {
      final energyPaint = Paint()
        ..color = color.withOpacity(node.glowIntensity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      
      for (int i = 0; i < 6; i++) {
        final angle = rotationAngle * 2 + i * (2 * math.pi / 6);
        final energyPos = Offset(
          position.dx + math.cos(angle) * (nodeRadius + 15),
          position.dy + math.sin(angle) * (nodeRadius + 15),
        );
        
        canvas.drawCircle(energyPos, 2, energyPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant FanMindMapPainter<T> oldDelegate) {
    return oldDelegate.highlightProgress != highlightProgress ||
           oldDelegate.pulseProgress != pulseProgress ||
           oldDelegate.techProgress != techProgress ||
           oldDelegate.rotationProgress != rotationProgress ||
           oldDelegate.scale != scale;
  }
}

// 扇形科技背景绘制器
class FanTechBackgroundPainter extends CustomPainter {
  final double animation;
  final double rotationAnimation;
  final List<FanParticle> particles;

  FanTechBackgroundPainter({
    required this.animation,
    required this.rotationAnimation,
    required this.particles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.min(size.width, size.height) * 0.45;

    // 绘制同心圆网格
    _drawConcentricGrid(canvas, center, maxRadius);
    
    // 绘制放射线网格
    _drawRadialGrid(canvas, center, maxRadius);
    
    // 绘制旋转的科技环
    _drawRotatingRings(canvas, center, maxRadius);
    
    // 绘制粒子
    _drawParticles(canvas);
  }

  void _drawConcentricGrid(Canvas canvas, Offset center, double maxRadius) {
    final gridPaint = Paint()
      ..color = const Color(0xFF00F5FF).withOpacity(0.1)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // 绘制同心圆
    for (int i = 1; i <= 4; i++) {
      final radius = maxRadius * (i / 4);
      canvas.drawCircle(center, radius, gridPaint);
    }
  }

  void _drawRadialGrid(Canvas canvas, Offset center, double maxRadius) {
    final gridPaint = Paint()
      ..color = const Color(0xFF00F5FF).withOpacity(0.08)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    // 绘制放射线（12条）
    for (int i = 0; i < 12; i++) {
      final angle = i * (2 * math.pi / 12);
      final start = center;
      final end = Offset(
        center.dx + math.cos(angle) * maxRadius,
        center.dy + math.sin(angle) * maxRadius,
      );
      canvas.drawLine(start, end, gridPaint);
    }
  }

  void _drawRotatingRings(Canvas canvas, Offset center, double maxRadius) {
    final ringPaint = Paint()
      ..color = const Color(0xFF00F5FF).withOpacity(0.3)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // 绘制多个旋转环
    for (int i = 0; i < 3; i++) {
      final radius = maxRadius * (0.3 + i * 0.15);
      final rotation = rotationAnimation * 2 * math.pi + i * (math.pi / 3);
      
      final rect = Rect.fromCircle(center: center, radius: radius);
      
      // 绘制部分弧线，创造旋转效果
      canvas.drawArc(rect, rotation, math.pi / 2, false, ringPaint);
      canvas.drawArc(rect, rotation + math.pi, math.pi / 2, false, ringPaint);
    }
  }

  void _drawParticles(Canvas canvas) {
    for (final particle in particles) {
      final paint = Paint()
        ..color = particle.color.withOpacity(particle.opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1);
      
      canvas.drawCircle(particle.position, particle.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant FanTechBackgroundPainter oldDelegate) {
    return oldDelegate.animation != animation ||
           oldDelegate.rotationAnimation != rotationAnimation;
  }
} 