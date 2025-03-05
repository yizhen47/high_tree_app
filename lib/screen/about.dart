import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import 'package:flutter_tilt/flutter_tilt.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});
  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  String _version = '0.0.0';

  final _decorationItems = [
    _DecorationItem(Icons.star, Colors.white30, Alignment(-0.8, -0.6)),
    _DecorationItem(
        Icons.wb_sunny, Colors.amber.withOpacity(0.2), Alignment(0.7, -0.4)),
    _DecorationItem(
        Icons.circle, Colors.blueAccent.withOpacity(0.1), Alignment(0.3, 0.8)),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    PackageInfo.fromPlatform()
        .then((info) => setState(() => _version = info.version));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildHeader() => SizedBox(
        height: 200,
        child: Stack(
          children: [
            _AnimatedGradientBackground(controller: _controller),
            Center(child: _LogoSection(controller: _controller)),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  child: Text(
                    'Version $_version',
                    key: ValueKey(_version),
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.8),
                      shadows: [
                        Shadow(
                            color: Colors.black38,
                            blurRadius: 4,
                            offset: Offset(1, 1))
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TDNavBar(/* 保持原有参数 */),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Theme.of(context).scaffoldBackgroundColor,
                    Colors.white.withOpacity(0.9)
                  ],
                ),
              ),
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(30)),
                child: ListView.separated(
                  padding: const EdgeInsets.only(top: 24),
                  itemCount: _menuItems.length,
                  separatorBuilder: (_, __) =>
                      const Divider(indent: 64, height: 0.5),
                  itemBuilder: (_, i) => _SettingCard(item: _menuItems[i]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoSection extends StatelessWidget {
  final AnimationController controller;

  const _LogoSection({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Tilt(
      fps: 120,
      tiltConfig: TiltConfig(angle: 60, direction: [TiltDirection.left,TiltDirection.right]),
      // tilt: 0.02,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: controller,
            builder: (_, __) => Transform.scale(
              // Fixed: Use controller.value directly
              scale: 1 + 0.1 * (controller.value - 0.5).abs(),
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    Theme.of(context).primaryColor.withOpacity(0.2),
                    Colors.transparent,
                  ]),
                ),
              ),
            ),
          ),
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                    color: Colors.black26, blurRadius: 20, spreadRadius: 5)
              ],
              image: const DecorationImage(
                image: AssetImage('assets/logo.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedGradientBackground extends StatelessWidget {
  final AnimationController controller;

  const _AnimatedGradientBackground({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) => Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(
                controller.value * 0.2 - 0.1, controller.value * 0.2 - 0.1),
            radius: 1.2,
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.8),
              Theme.of(context).primaryColor.withOpacity(0.3),
              Theme.of(context).scaffoldBackgroundColor,
            ],
          ),
        ),
      ),
    );
  }
}
// 优化后的菜单项组件
class _SettingCard extends StatelessWidget {
  final _MenuItem item;

  const _SettingCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        splashColor: Theme.of(context).primaryColor.withOpacity(0.08),
        highlightColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.4),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: item.color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(item.icon, size: 20, color: item.color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  item.title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[800],
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
              if (item.showArrow)
                Icon(Icons.chevron_right, size: 20, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}

// 调整后的数据配置
final _menuItems = [
  _MenuItem(
    icon: Icons.verified_user,
    color: Colors.indigo,
    title: "当前版本",
    onTap: () {},
  ),
  _MenuItem(
    icon: Icons.system_update,
    color: Colors.green,
    title: "版本更新",
    showArrow: true,
    onTap: () {},
  ),
  _MenuItem(
    icon: Icons.contact_support,
    color: Colors.blue,
    title: "联系我们",
    showArrow: true,
    onTap: () {},
  ),
];

// Data Classes
class _DecorationItem {
  final IconData icon;
  final Color color;
  final Alignment alignment;
  final double size;

  const _DecorationItem(this.icon, this.color, this.alignment,
      [this.size = 40]);
}

class _MenuItem {
  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;
  final bool showArrow;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.color,
    required this.title,
    this.subtitle,
    this.showArrow = false,
    required this.onTap,
  });
}
