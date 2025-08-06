
// 封装左侧Toast组件
import 'package:flutter/material.dart';

class LeftToast extends StatelessWidget {
  final String message;

  const LeftToast({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(left: 16),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[850],
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(4, 4),
                  ),
                ],
              ),
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Toast显示方法封装
void showLeftToast(BuildContext context, String message) {
  final entry = OverlayEntry(
    builder: (context) => LeftToast(message: message),
  );

  Overlay.of(context).insert(entry);
  
  Future.delayed(const Duration(seconds: 2), () {
    entry.remove();
  });
}



// Windows风格垂直通知
class WindowsLeftToast extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final Color color;

  const WindowsLeftToast({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.notifications_none,
    this.color = Colors.blueAccent,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(left: 24),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 280,
              margin: const EdgeInsets.only(top: 80),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor.withOpacity(0.96),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.grey.withOpacity(0.2),
                  width: 0.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 16,
                    offset: const Offset(4, 4),
                  )
                ],
              ),
              child: IntrinsicHeight(
                child: Row(
                  children: [
                    // 彩色指示条
                    Container(
                      width: 6,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // 内容区域
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(icon, size: 18, color: color),
                                const SizedBox(width: 8),
                                Text(
                                  title,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: color,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              message,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.color,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// 带动画的显示方法
void showWindowsToast({
  required BuildContext context,
  required String title,
  required String message,
}) {
  final overlay = Overlay.of(context);
  final entry = OverlayEntry(
    builder: (context) => _ToastWrapper(
      child: WindowsLeftToast(title: title, message: message),
    ),
  );

  overlay.insert(entry);
  Future.delayed(const Duration(seconds: 3), () {
    entry.remove();
  });
}

// 动画包装器
class _ToastWrapper extends StatefulWidget {
  final Widget child;

  const _ToastWrapper({required this.child});

  @override
  _ToastWrapperState createState() => _ToastWrapperState();
}

class _ToastWrapperState extends State<_ToastWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(-1, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      )),
      child: FadeTransition(
        opacity: _controller,
        child: widget.child,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class VerticalTextToast extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final Color color;

  const VerticalTextToast({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.notifications_none,
    this.color = Colors.blueAccent,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.only(top: 80),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor.withOpacity(0.96),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.grey.withOpacity(0.2),
                  width: 0.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 16,
                    offset: const Offset(4, 4),
                  )
                ],
              ),
              child: IntrinsicHeight(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 彩色状态条
                    Container(
                      width: 4,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(8),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // 图标（保持正常方向）
                          Icon(icon, size: 20, color: color),
                          const SizedBox(height: 16),
                          // 垂直文本容器
                          _buildVerticalText(title, context, isTitle: true),
                          const SizedBox(height: 8),
                          _buildVerticalText(message, context),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVerticalText(String text, BuildContext context, {bool isTitle = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: _splitTextToVertical(text, context, isTitle: isTitle),
    );
  }

  List<Widget> _splitTextToVertical(String text, BuildContext context, {bool isTitle = false}) {
    return text.split('').map((char) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Text(
          char,
          style: isTitle
              ? Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  )
              : Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    height: 1.2,
                  ),
        ),
      );
    }).toList();
  }
}

// 动画包装器修改
class _VerticalToastWrapper extends StatefulWidget {
  final Widget child;

  const _VerticalToastWrapper({required this.child});

  @override
  _VerticalToastWrapperState createState() => _VerticalToastWrapperState();
}

class _VerticalToastWrapperState extends State<_VerticalToastWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(-1, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      )),
      child: FadeTransition(
        opacity: _controller,
        child: widget.child,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}



// 封装调用方法
void showVerticalToast({
  required BuildContext context,
  required String title,
  required String message,
  Color? color,
  IconData? icon,
  Duration duration = const Duration(seconds: 3),
}) {
  final entry = OverlayEntry(
    builder: (context) => _VerticalToastWrapper(
      child: VerticalTextToast(
        title: title,
        message: message,
        color: color ?? Theme.of(context).primaryColor,
        icon: icon ?? Icons.info_outline,
      ),
    ),
  );

  Overlay.of(context).insert(entry);
  
  Future.delayed(duration, () {
    entry.remove();
  });
}