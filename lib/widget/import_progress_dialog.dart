import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';

class ImportProgressDialog extends StatefulWidget {
  final String fileName;
  final double fileSizeMB;
  final Stream<Object> progressStream;
  final VoidCallback? onCancel;
  final Function() onDialogClose;

  const ImportProgressDialog({
    super.key,
    required this.fileName,
    required this.fileSizeMB,
    required this.progressStream,
    required this.onDialogClose,
    this.onCancel,
  });

  @override
  State<ImportProgressDialog> createState() => _ImportProgressDialogState();
}

class _ImportProgressDialogState extends State<ImportProgressDialog>
    with TickerProviderStateMixin {
  double _displayedProgress = 0.0;
  String _currentPhase = "准备中...";
  late AnimationController _spinController;
  late AnimationController _pulseController;
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  late AnimationController _slowFillController;
  late Animation<double> _slowFillAnimation;
  late final double _targetProgress;

  bool _isComplete = false;
  String? _errorMessage;
  bool get _isSuccess => _isComplete && _errorMessage == null;

  @override
  void initState() {
    super.initState();
    _targetProgress = 0.95 + Random().nextDouble() * 0.04; // 0.95 to 0.99

    _spinController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 2000), // Slower transition
      vsync: this,
    )..addListener(() {
        if (mounted) {
          setState(() {
            _displayedProgress = _progressAnimation.value;
          });
        }
      });

    _slowFillController = AnimationController(
      duration: const Duration(seconds: 45), // A long duration for a slow, steady fill
      vsync: this,
    )..addListener(() {
      if (mounted) {
        setState(() {
          _displayedProgress = _slowFillAnimation.value;
        });
      }
    });

    widget.progressStream.listen(_handleProgressUpdate, onDone: () {
      if (!mounted) return;
      setState(() {
        _isComplete = true;
        _currentPhase = "导入成功";
      });
    });
  }

  @override
  void dispose() {
    _spinController.dispose();
    _pulseController.dispose();
    _progressController.dispose();
    _slowFillController.dispose();
    super.dispose();
  }

  TickerFuture _animateProgress(double target) {
    _progressAnimation = Tween<double>(
      begin: _displayedProgress,
      end: target,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: const EaseInLater(0.7),
    ));
    return _progressController.forward(from: 0);
  }

  void _handleProgressUpdate(dynamic data) {
    if (!mounted) return;
    _slowFillController.stop(); // Stop any fake progress on a new event

    if (data is double) {
      _animateProgress(data).whenComplete(() {
        if (!mounted) return;

        // After a real progress update, start a slow, steady progress animation
        // towards the final simulated percentage, unless we are already there.
        if (data >= 0.1 && _displayedProgress < _targetProgress) {
          // We'll simulate the progress from 10% to target% over about 80 seconds.
          // This makes the perceived speed consistent even when interrupted by real updates.
          const totalSimulationSeconds = 80.0;
          final totalSimulationRange = _targetProgress - 0.1;
          
          final remainingProgress = _targetProgress - _displayedProgress;
          if (remainingProgress <= 0) return;

          final remainingSeconds = (remainingProgress / totalSimulationRange) * totalSimulationSeconds;
          if (remainingSeconds <= 0) return;

          _slowFillController.duration = Duration(seconds: remainingSeconds.ceil());
          _slowFillAnimation = Tween<double>(
            begin: _displayedProgress,
            end: _targetProgress,
          ).animate(CurvedAnimation(
            parent: _slowFillController,
            curve: Curves.linear,
          ));
          _slowFillController.forward(from: 0);
        }
      });

      setState(() {
        if (data < 0.1) {
            _currentPhase = "准备读取文件...";
          } else if (data < 0.3) {
            _currentPhase = "解压缩文件...";
          } else if (data < 0.7) {
            _currentPhase = "解析XML数据...";
          } else if (data < 0.98) {
            _currentPhase = "验证数据完整性...";
          } else if (data < 1.0) {
            _currentPhase = "保存到题库...";
          }
        });
    } else if (data == 'done') {
      _animateProgress(1.0).whenComplete(() {
        if (!mounted) return;
        setState(() {
          _isComplete = true;
          _currentPhase = "导入成功";
        });
      });
    } else { // Error case
      setState(() {
        _isComplete = true;
        var errorString = data.toString();
        if (errorString.startsWith('Exception: ')) {
           errorString = errorString.substring('Exception: '.length);
        }
        _errorMessage = errorString;
        _currentPhase = "导入失败";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => _isComplete, // 防止用户意外关闭
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: _isComplete
              ? _buildResultView()
              : _buildProgressView(),
        ),
      ),
    );
  }

  Widget _buildProgressView() {
    return Container(
      key: const ValueKey('progress'),
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
          Stack(
            alignment: Alignment.center,
            children: [
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
              SizedBox(
                width: 80,
                height: 80,
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return CircularProgressIndicator(
                      value: _displayedProgress,
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
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "${(_displayedProgress * 100).toStringAsFixed(0)}%",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  if (_displayedProgress < 1.0)
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
          Text(
            _currentPhase,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
            ),
            child: LinearProgressIndicator(
              value: _displayedProgress,
              minHeight: 6,
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
            ),
          ),
          const SizedBox(height: 24),
          if (widget.onCancel != null)
            TextButton(
              onPressed: widget.onCancel,
              style: TextButton.styleFrom(
                foregroundColor: Colors.red.shade400,
              ),
              child: const Text("取消导入"),
            ),
        ],
      ),
    );
  }

  Widget _buildResultView() {
    return Container(
      key: const ValueKey('result'),
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
          Icon(
            _isSuccess ? Icons.check_circle_outline : Icons.error_outline,
            color: _isSuccess ? Colors.green[500] : Colors.red[500],
            size: 56,
          ),
          const SizedBox(height: 16),
          Text(
            _currentPhase,
            style: TextStyle(
              fontSize: 18, 
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.titleLarge?.color,
            ),
          ),
          const SizedBox(height: 12),
          if (_errorMessage != null)
            SizedBox(
              height: 100,
              child: Scrollbar(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 13),
                    ),
                  ),
                ),
              ),
            )
          else
             Text(
              widget.fileName,
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 13),
            ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: widget.onDialogClose,
            style: ElevatedButton.styleFrom(
              backgroundColor: _isSuccess ? Theme.of(context).primaryColor : Colors.grey[700],
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('完成'),
          ),
        ],
      ),
    );
  }
}

/// A custom curve that is mostly linear for the first `linearPortion` of the animation,
/// and then accelerates towards the end.
class EaseInLater extends Curve {
  final double linearPortion;

  const EaseInLater(this.linearPortion);

  @override
  double transformInternal(double t) {
    if (t < linearPortion) {
      // Linear part
      return t * (linearPortion / linearPortion);
    } else {
      // Ease-in part, scaled and shifted
      double t_remaining = (t - linearPortion) / (1 - linearPortion);
      double val_remaining = t_remaining * t_remaining; // simple quadratic ease-in
      return linearPortion + val_remaining * (1 - linearPortion);
    }
  }
} 