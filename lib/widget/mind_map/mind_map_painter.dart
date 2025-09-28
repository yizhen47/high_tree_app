import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:latext/latext.dart';

import 'mind_map_node.dart';

// 粒子类 - 用于背景动画效果
class Particle {
  Offset position;
  Offset velocity;
  double opacity;
  double maxOpacity;
  double radius;
  Color color;
  
  Particle({
    required this.position,
    required this.velocity,
    required this.opacity,
    required this.maxOpacity,
    required this.radius,
    required this.color,
  });
  
  void update(Size canvasSize) {
    position += velocity;
    
    // 边界检测和反弹
    if (position.dx <= 0 || position.dx >= canvasSize.width) {
      velocity = Offset(-velocity.dx, velocity.dy);
    }
    if (position.dy <= 0 || position.dy >= canvasSize.height) {
      velocity = Offset(velocity.dx, -velocity.dy);
    }
    
    // 保持在边界内
    position = Offset(
      position.dx.clamp(0, canvasSize.width),
      position.dy.clamp(0, canvasSize.height),
    );
  }
}

// 科技风背景绘制器
class TechBackgroundPainter extends CustomPainter {
  final double animation;
  final List<Particle> particles;

  TechBackgroundPainter({
    required this.animation,
    required this.particles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 绘制网格背景
    _drawGrid(canvas, size);
    
    // 绘制粒子
    _drawParticles(canvas, size);
    
    // 绘制边框发光效果
    _drawGlowBorder(canvas, size);
  }
  
  void _drawGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00F5FF).withOpacity(0.1)
      ..strokeWidth = 0.5;
    
    const spacing = 50.0;
    
    // 垂直线
    for (double x = 0; x <= size.width; x += spacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }
    
    // 水平线
    for (double y = 0; y <= size.height; y += spacing) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }
  
  void _drawParticles(Canvas canvas, Size size) {
    for (final particle in particles) {
      final paint = Paint()
        ..color = particle.color.withOpacity(particle.opacity)
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(particle.position, particle.radius, paint);
      
      // 粒子光晕
      final glowPaint = Paint()
        ..color = particle.color.withOpacity(particle.opacity * 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      
      canvas.drawCircle(particle.position, particle.radius * 2, glowPaint);
    }
  }
  
  void _drawGlowBorder(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    
    final glowPaint = Paint()
      ..color = const Color(0xFF00F5FF).withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    
    canvas.drawRect(rect, glowPaint);
  }

  @override
  bool shouldRepaint(covariant TechBackgroundPainter old) =>
      old.animation != animation;
}

class MindMapPainter extends CustomPainter {
  final MindMapNode rootNode;
  final Color lineColor;
  final double lineWidth;
  final double scale;
  final double highlightProgress;
  final double pulseProgress;
  final double techProgress;
  final Map<String, ui.Image> latexCache;
  final Map<String, ui.Image> imageCache;
  final Map<String, String> questionBankCacheDirs;
  final VoidCallback? onImageLoaded;

  MindMapPainter({
    required this.rootNode,
    required this.lineColor,
    required this.lineWidth,
    required this.scale,
    required this.highlightProgress,
    required this.pulseProgress,
    required this.techProgress,
    required this.latexCache,
    required this.imageCache,
    required this.questionBankCacheDirs,
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

  // 科技风折叠指示器
  void _drawCollapseIndicator(Canvas canvas, MindMapNode node) {
    final indicatorCenter = Offset(
      node.position.dx + node.size.width / 2 + 25,
      node.position.dy,
    );
    
    const indicatorRadius = 12.0;
    
    // 外圈光晕
    final glowPaint = Paint()
      ..color = const Color(0xFF00F5FF).withOpacity(0.6 * node.glowIntensity)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(indicatorCenter, indicatorRadius + 5, glowPaint);
    
    // 主体圆环
    final circlePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF00F5FF).withOpacity(0.8),
          const Color(0xFF1E90FF).withOpacity(0.6),
        ],
      ).createShader(Rect.fromCircle(center: indicatorCenter, radius: indicatorRadius))
      ..style = PaintingStyle.fill;
    canvas.drawCircle(indicatorCenter, indicatorRadius, circlePaint);
    
    // 边框
    final borderPaint = Paint()
      ..color = const Color(0xFF00FFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(indicatorCenter, indicatorRadius, borderPaint);
    
    // 绘制 +/- 符号（霓虹灯效果）
    final linePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    
    // 横线（总是显示）
    canvas.drawLine(
      Offset(indicatorCenter.dx - 6, indicatorCenter.dy),
      Offset(indicatorCenter.dx + 6, indicatorCenter.dy),
      linePaint,
    );
    
    // 竖线（只在折叠时显示）
    if (node.isCollapsed) {
      canvas.drawLine(
        Offset(indicatorCenter.dx, indicatorCenter.dy - 6),
        Offset(indicatorCenter.dx, indicatorCenter.dy + 6),
        linePaint,
      );
    }
  }

  // 科技风图片节点
  void _drawImageNode(Canvas canvas, MindMapNode node) {
    final image = node.cachedImage;
    if (image == null) {
      _loadImageForNode(node);
      _drawTextNode(canvas, node);
      return;
    }

    // 绘制节点背景 - 科技风卡片
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: node.position,
        width: node.size.width,
        height: node.size.height,
      ),
      const Radius.circular(20),
    );

    // 外发光
    final glowPaint = Paint()
      ..color = node.color.withOpacity(0.4 * node.glowIntensity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
    canvas.drawRRect(rect.inflate(10), glowPaint);

    // 渐变背景
    final backgroundPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFF1A1A2E).withOpacity(0.9),
          const Color(0xFF16213E).withOpacity(0.9),
        ],
      ).createShader(rect.outerRect);
    canvas.drawRRect(rect, backgroundPaint);

    // 高亮边框
    if (node.isHighlighted) {
      final highlightPaint = Paint()
        ..color = const Color(0xFF00F5FF).withOpacity(0.8 * highlightProgress)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
      canvas.drawRRect(rect.inflate(2), highlightPaint);
    }

    // 计算图片的显示尺寸
    const double textAreaHeight = 50.0;
    const double padding = 15.0;
    
    final maxImageWidth = node.size.width - (padding * 2);
    final maxImageHeight = node.size.height - textAreaHeight - (padding * 2);
    
    final imageAspectRatio = image.width / image.height;
    double imageWidth = maxImageWidth;
    double imageHeight = imageWidth / imageAspectRatio;
    
    if (imageHeight > maxImageHeight) {
      imageHeight = maxImageHeight;
      imageWidth = imageHeight * imageAspectRatio;
    }

    // 绘制图片
    final imageRect = Rect.fromCenter(
      center: Offset(
        node.position.dx, 
        node.position.dy - (textAreaHeight / 2)
      ),
      width: imageWidth,
      height: imageHeight,
    );
    
    final imageRRect = RRect.fromRectAndRadius(imageRect, const Radius.circular(12));
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

    // 绘制文本标签（科技风样式）
    if (node.text.isNotEmpty) {
      if (node.isLatex) {
        final latexImage = latexCache[node.latexContent];
        if (latexImage != null) {
          // 绘制渲染好的 LaTeX 图片
          const double textAreaHeight = 30.0;
          final double textYCenter =
              node.position.dy + (node.size.height / 2) - (textAreaHeight / 2);

          const double padding = 10.0;
          final double maxWidth = node.size.width - (padding * 2);
          final double maxHeight = textAreaHeight - padding;

          final imageAspectRatio = latexImage.width / latexImage.height;
          double renderWidth = maxWidth;
          double renderHeight = renderWidth / imageAspectRatio;

          if (renderHeight > maxHeight) {
            renderHeight = maxHeight;
            renderWidth = renderHeight * imageAspectRatio;
          }

          final latexRect = Rect.fromCenter(
            center: Offset(node.position.dx, textYCenter),
            width: renderWidth,
            height: renderHeight,
          );

          canvas.drawImageRect(
            latexImage,
            Rect.fromLTWH(
                0, 0, latexImage.width.toDouble(), latexImage.height.toDouble()),
            latexRect,
            Paint(),
          );
        } else {
          // LaTeX 缓存不存在时，回退到绘制原始文本
          final textPainter = TextPainter(
            text: TextSpan(
              text: node.text,
              style: TextStyle(
                color: const Color(0xFF00F5FF),
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
                fontStyle: FontStyle.italic, // 保留斜体以示区别
                shadows: [
                  Shadow(
                    offset: const Offset(0, 0),
                    blurRadius: 8.0,
                    color: const Color(0xFF00F5FF).withOpacity(0.8),
                  ),
                  Shadow(
                    offset: const Offset(0, 0),
                    blurRadius: 16.0,
                    color: const Color(0xFF00F5FF).withOpacity(0.4),
                  ),
                ],
              ),
            ),
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.center,
          )..layout(maxWidth: node.size.width - 20);

          final textPos = Offset(
            node.position.dx - textPainter.width / 2,
            node.position.dy + (node.size.height / 2) - 35,
          );
          textPainter.paint(canvas, textPos);
        }
      } else {
        // 绘制普通文本
      final textPainter = TextPainter(
        text: TextSpan(
          text: node.text,
          style: TextStyle(
            color: const Color(0xFF00F5FF),
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
            shadows: [
              Shadow(
                offset: const Offset(0, 0),
                blurRadius: 8.0,
                color: const Color(0xFF00F5FF).withOpacity(0.8),
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout(maxWidth: node.size.width - 20);

      final textPos = Offset(
        node.position.dx - textPainter.width / 2,
        node.position.dy + (node.size.height / 2) - 35,
      );
      textPainter.paint(canvas, textPos);
      }
    }
  }

  // 科技风文本节点
  void _drawTextNode(Canvas canvas, MindMapNode node) {
    final isRootNode = node.parent == null || (node.parent != null && node.parent!.size == const Size(0, 0));
    
    final borderRadius = isRootNode ? 25.0 : 15.0;
    final pulseScale = 1.0 + (node.pulseAnimation * 0.05); // 脉冲缩放

    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(
          center: node.position,
        width: node.size.width * pulseScale,
        height: node.size.height * pulseScale,
      ),
      Radius.circular(borderRadius),
    );

    // 外发光效果
    final glowPaint = Paint()
      ..color = node.color.withOpacity(0.6 * node.glowIntensity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    canvas.drawRRect(rect.inflate(15), glowPaint);

    // 科技风渐变背景
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        const Color(0xFF0A0A0F).withOpacity(0.95),
        node.color.withOpacity(0.3),
        const Color(0xFF1A1A2E).withOpacity(0.95),
      ],
      stops: const [0.0, 0.5, 1.0],
    );
    
    final fillPaint = Paint()
      ..shader = gradient.createShader(rect.outerRect)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(rect, fillPaint);

    // 高亮效果
    if (node.isHighlighted) {
      // 主高亮
      final highlightPaint = Paint()
        ..color = const Color(0xFF00F5FF).withOpacity(0.8 * highlightProgress)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
      canvas.drawRRect(rect.inflate(8), highlightPaint);

      // 高亮边框
      final highlightBorderPaint = Paint()
        ..color = const Color(0xFF00F5FF).withOpacity(0.9)
        ..strokeWidth = 3.0
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
      canvas.drawRRect(rect, highlightBorderPaint);
    }

    // 绘制文本（霓虹灯效果）
    final textPainter = TextPainter(
      text: TextSpan(
        text: node.text,
        style: TextStyle(
          color: isRootNode ? const Color(0xFF00F5FF) : Colors.white,
          fontSize: isRootNode ? 20 : 16,
          fontWeight: isRootNode ? FontWeight.w800 : FontWeight.w700,
          letterSpacing: isRootNode ? 1.5 : 1.0,
          shadows: [
            Shadow(
              offset: const Offset(0, 0),
              blurRadius: isRootNode ? 12.0 : 8.0,
              color: (isRootNode ? const Color(0xFF00F5FF) : node.color).withOpacity(0.8),
            ),
            Shadow(
              offset: const Offset(0, 0),
              blurRadius: isRootNode ? 24.0 : 16.0,
              color: (isRootNode ? const Color(0xFF00F5FF) : node.color).withOpacity(0.4),
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout(maxWidth: node.size.width - 30);

    final textPos = node.position - Offset(textPainter.width / 2, textPainter.height / 2);
    textPainter.paint(canvas, textPos);

    // 霓虹边框
    final neonBorderPaint = Paint()
      ..color = const Color(0xFF00FFFF).withOpacity(0.8)
      ..strokeWidth = isRootNode ? 3.0 : 2.0
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawRRect(rect, neonBorderPaint);
    
    // 内部装饰线
    final decorPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(rect.deflate(3), decorPaint);
  }

  // 科技风 LaTeX 节点
  void _drawLatexNode(Canvas canvas, MindMapNode node) {
    final image = latexCache[node.latexContent];
    if (image == null) {
      _drawTextNode(canvas, node);
      return;
    }

    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: node.position,
        width: node.size.width,
        height: node.size.height,
      ),
      const Radius.circular(15),
    );

    // 外发光
    final glowPaint = Paint()
      ..color = const Color(0xFF00F5FF).withOpacity(0.4 * node.glowIntensity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
    canvas.drawRRect(rect.inflate(10), glowPaint);

    // 科技风背景
    final backgroundPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFF0A0A0F).withOpacity(0.95),
          const Color(0xFF1A1A2E).withOpacity(0.95),
        ],
      ).createShader(rect.outerRect);
    canvas.drawRRect(rect, backgroundPaint);

    // 高亮效果
    if (node.isHighlighted) {
      final highlightPaint = Paint()
        ..color = const Color(0xFF00F5FF).withOpacity(0.6 * highlightProgress)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawRRect(rect, highlightPaint);
    }

    // 绘制 LaTeX 图像
    final aspectRatio = image.width / image.height;
    final maxWidth = node.size.width - 30;
    final maxHeight = node.size.height - 30;

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

    // 添加光晕效果
    final glowPaintImage = Paint()
      ..color = const Color(0xFF00F5FF).withOpacity(0.8 * node.glowIntensity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
    canvas.drawImage(image, Offset.zero, glowPaintImage);

    canvas.restore();

    // 霓虹边框
    final neonBorderPaint = Paint()
      ..color = const Color(0xFF00FFFF).withOpacity(0.8)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawRRect(rect, neonBorderPaint);
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

    // 创建科技风贝塞尔曲线
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

    // 外发光连接线
    final glowPath = Path()
      ..moveTo(start.dx, start.dy)
      ..cubicTo(
        controlPoint1.dx, controlPoint1.dy,
        controlPoint2.dx, controlPoint2.dy,
        end.dx, end.dy,
      );

    canvas.drawPath(
      glowPath,
      Paint()
        ..color = const Color(0xFF00F5FF).withOpacity(0.6)
        ..strokeWidth = 8.0
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    // 主连接线（霓虹效果）
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          colors: [
            const Color(0xFF00F5FF).withOpacity(0.9),
            const Color(0xFF1E90FF).withOpacity(0.9),
            const Color(0xFF00FFFF).withOpacity(0.9),
          ],
        ).createShader(Rect.fromPoints(start, end))
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );

    // 连接点（科技风圆点）
    final connectionPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF00F5FF),
          const Color(0xFF1E90FF).withOpacity(0.8),
        ],
      ).createShader(Rect.fromCircle(center: end, radius: 6))
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(end, 6.0, connectionPaint);
    
    // 连接点光晕
    final connectionGlowPaint = Paint()
      ..color = const Color(0xFF00F5FF).withOpacity(0.6)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    
    canvas.drawCircle(end, 8.0, connectionGlowPaint);
    
    // 连接点边框
    final connectionBorderPaint = Paint()
      ..color = const Color(0xFF00FFFF)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    
    canvas.drawCircle(end, 6.0, connectionBorderPaint);
  }

  @override
  bool shouldRepaint(covariant MindMapPainter old) =>
      old.rootNode != rootNode ||
      old.highlightProgress != highlightProgress ||
      old.pulseProgress != pulseProgress ||
      old.techProgress != techProgress ||
      old.scale != scale;
} 