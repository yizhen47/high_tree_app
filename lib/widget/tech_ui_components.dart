import 'package:flutter/material.dart';

// 科技风背景
BoxDecoration buildTechBackground() {
  return const BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF0A0A0F), // 深蓝黑
        Color(0xFF1A1A2E), // 深蓝紫
        Color(0xFF16213E), // 深蓝
        Color(0xFF0F0F23), // 深紫黑
        Color(0xFF0A0A0F), // 深蓝黑
      ],
      stops: [0.0, 0.25, 0.5, 0.75, 1.0],
    ),
  );
}

// 科技风应用栏
class TechAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget title;
  final Widget? trailing;

  const TechAppBar({
    super.key,
    required this.title,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF0A0A0F).withOpacity(0.95),
            const Color(0xFF1A1A2E).withOpacity(0.95),
            const Color(0xFF16213E).withOpacity(0.95),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFF00F5FF).withOpacity(0.3),
            width: 2,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00F5FF).withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              // 返回按钮
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF00F5FF).withOpacity(0.3),
                      const Color(0xFF1E90FF).withOpacity(0.3),
                    ],
                  ),
                  border: Border.all(
                    color: const Color(0xFF00FFFF).withOpacity(0.6),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00F5FF).withOpacity(0.4),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Color(0xFF00F5FF),
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              // 标题
              Expanded(
                child: title,
              ),
              // 装饰元素
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(80);
}

// 科技风提示信息
void showTechToast(BuildContext context, String message) {
  final overlay = Overlay.of(context);
  late OverlayEntry overlayEntry;
  
  overlayEntry = OverlayEntry(
    builder: (context) => Positioned(
      top: 100,
      left: 20,
      right: 20,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF00F5FF).withOpacity(0.9),
                const Color(0xFF1E90FF).withOpacity(0.9),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF00FFFF),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00F5FF).withOpacity(0.6),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.2),
                ),
                child: const Icon(
                  Icons.check_circle_outline,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  
  overlay.insert(overlayEntry);
  
  // 3秒后移除
  Future.delayed(const Duration(seconds: 3), () {
    overlayEntry.remove();
  });
}

class ChapterMindMapNavBar extends StatelessWidget {
  const ChapterMindMapNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF0A0A0F).withOpacity(0.95),
            const Color(0xFF1A1A2E).withOpacity(0.98),
          ],
        ),
        border: Border(
          top: BorderSide(
            color: const Color(0xFF00F5FF).withOpacity(0.3),
            width: 2,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00F5FF).withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF00F5FF).withOpacity(0.2),
                      const Color(0xFF1E90FF).withOpacity(0.2),
                      const Color(0xFF00FFFF).withOpacity(0.2),
                    ],
                  ),
                  border: Border.all(
                    color: const Color(0xFF00F5FF).withOpacity(0.6),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00F5FF).withOpacity(0.4),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(25),
                  onTap: () {
                    Navigator.of(context).pop(); // 返回主知识图谱
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                const Color(0xFF00F5FF).withOpacity(0.8),
                                const Color(0xFF00F5FF).withOpacity(0.3),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF00F5FF).withOpacity(0.6),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.map_outlined,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                                                 Text(
                           '返回图谱',
                           style: TextStyle(
                             color: const Color(0xFF00F5FF),
                             fontSize: 18,
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
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MainMindMapNavBar extends StatelessWidget {
  final Animation<double> backgroundAnimation;
  final VoidCallback onRefresh;

  const MainMindMapNavBar({
    super.key,
    required this.backgroundAnimation,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF0A0A0F).withOpacity(0.95),
            const Color(0xFF1A1A2E).withOpacity(0.98),
          ],
        ),
        border: Border(
          top: BorderSide(
            color: const Color(0xFF00F5FF).withOpacity(0.3),
            width: 2,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00F5FF).withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: AnimatedBuilder(
                animation: backgroundAnimation,
                builder: (context, child) {
                  return Container(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF00F5FF).withOpacity(0.2),
                          const Color(0xFF1E90FF).withOpacity(0.2),
                          const Color(0xFF00FFFF).withOpacity(0.2),
                        ],
                      ),
                      border: Border.all(
                        color: const Color(0xFF00F5FF).withOpacity(0.6),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00F5FF).withOpacity(0.4),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(25),
                      onTap: onRefresh,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    const Color(0xFF00F5FF).withOpacity(0.8),
                                    const Color(0xFF00F5FF).withOpacity(0.3),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        const Color(0xFF00F5FF).withOpacity(0.6),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.refresh_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              '刷新图谱计划',
                              style: TextStyle(
                                color: const Color(0xFF00F5FF),
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.0,
                                shadows: [
                                  Shadow(
                                    offset: const Offset(0, 0),
                                    blurRadius: 8.0,
                                    color: const Color(0xFF00F5FF)
                                        .withOpacity(0.8),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
} 