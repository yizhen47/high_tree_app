import 'package:flutter/material.dart';

class ImportProgressDialog extends StatefulWidget {
  final String fileName;
  final double fileSizeMB;
  final Stream<double> progressStream;
  final VoidCallback? onCancel;

  const ImportProgressDialog({
    Key? key,
    required this.fileName,
    required this.fileSizeMB,
    required this.progressStream,
    this.onCancel,
  }) : super(key: key);

  @override
  State<ImportProgressDialog> createState() => _ImportProgressDialogState();
}

class _ImportProgressDialogState extends State<ImportProgressDialog>
    with TickerProviderStateMixin {
  double _progress = 0.0;
  String _currentPhase = "准备中...";
  late AnimationController _spinController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    widget.progressStream.listen((progress) {
      if (mounted) {
        setState(() {
          _progress = progress;
          if (progress < 0.1) {
            _currentPhase = "准备读取文件...";
          } else if (progress < 0.3) {
            _currentPhase = "解压缩文件...";
          } else if (progress < 0.7) {
            _currentPhase = "解析XML数据...";
          } else if (progress < 0.9) {
            _currentPhase = "验证数据完整性...";
          } else if (progress < 1.0) {
            _currentPhase = "保存到题库...";
          } else {
            _currentPhase = "导入完成";
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _spinController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // 防止用户意外关闭
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 顶部标题
              Row(
                children: [
                  Icon(
                    Icons.cloud_upload_outlined,
                    color: Theme.of(context).primaryColor,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "导入题库",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).textTheme.titleLarge?.color,
                          ),
                        ),
                        Text(
                          "${widget.fileSizeMB.toStringAsFixed(1)}MB",
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 文件名
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                  ),
                ),
                child: Text(
                  widget.fileName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 24),

              // 进度指示器
              Stack(
                alignment: Alignment.center,
                children: [
                  // 背景圆环
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: CircularProgressIndicator(
                      value: 1.0,
                      strokeWidth: 8,
                      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).primaryColor.withOpacity(0.1),
                      ),
                    ),
                  ),
                  // 进度圆环
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return CircularProgressIndicator(
                          value: _progress,
                          strokeWidth: 8,
                          backgroundColor: Colors.transparent,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).primaryColor.withOpacity(
                              0.7 + 0.3 * _pulseController.value,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  // 中心文字
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "${(_progress * 100).toStringAsFixed(0)}%",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      if (_progress < 1.0)
                        AnimatedBuilder(
                          animation: _spinController,
                          builder: (context, child) {
                            return Transform.rotate(
                              angle: _spinController.value * 2 * 3.14159,
                              child: Icon(
                                Icons.refresh,
                                size: 12,
                                color: Theme.of(context).primaryColor.withOpacity(0.6),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 当前阶段文本
              Text(
                _currentPhase,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // 进度条
              Container(
                width: double.infinity,
                height: 6,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: MediaQuery.of(context).size.width * 0.6 * _progress,
                  height: 6,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).primaryColor,
                        Theme.of(context).primaryColor.withOpacity(0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(3),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).primaryColor.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 取消按钮 (仅在未完成时显示)
              if (_progress < 1.0 && widget.onCancel != null)
                TextButton(
                  onPressed: widget.onCancel,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red.shade400,
                  ),
                  child: const Text("取消导入"),
                ),
            ],
          ),
        ),
      ),
    );
  }
} 