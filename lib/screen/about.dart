import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import 'package:flutter_tilt/flutter_tilt.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});
  @override
  State<AboutScreen> createState() => _InnerState();
}

//这里是在一个页面中加了PageView，PageView可以载入更多的StatefulWidget或者StatelessWidget（也就是页面中加载其他页面作为子控件）
class _InnerState extends State<AboutScreen> {
  String version = '0.0.0';
  @override
  Widget build(BuildContext context) {
    PackageInfo.fromPlatform().then((PackageInfo packageInfo) {
      version = packageInfo.version;
      setState(() {});
    });
    return Scaffold(
      appBar: TDNavBar(
          backgroundColor: Theme.of(context).primaryColor,
          title: '',
          onBack: () {}),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).primaryColor,
                        Colors.white,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  height: 200),
              Center(
                child: Tilt(
                  tiltConfig: const TiltConfig(
                    leaveCurve: Curves.easeInOutCubicEmphasized,
                    leaveDuration: Duration(milliseconds: 200),
                  ),
                  lightConfig: const LightConfig(disable: true),
                  shadowConfig: const ShadowConfig(disable: true),
                  childLayout: ChildLayout(
                    outer: [
                      const Positioned.fill(
                        child: TiltParallax(
                          size: Offset(10, 10),
                          child: Text(
                            '我们！',
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      TiltParallax(
                        size: const Offset(20, 20),
                        child: Image.asset(
                          'assets/chu.png',
                          width: 200,
                          height: 200,
                        ),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(25.0),
                    child: Image.asset(
                      'assets/logo.png',
                      width: 200,
                      height: 200,
                      colorBlendMode: BlendMode.multiply,
                      color: Color.fromARGB(109, 96, 115, 161),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Column(
            children: <Widget>[
              TDCellGroup(
                theme: TDCellGroupTheme.cardTheme,
                cells: [
                  TDCell(
                      leftIcon: Icons.verified_user_outlined,
                      title: "当前版本",
                      note: version,
                      onClick: (_) {}),
                  TDCell(
                      leftIcon: Icons.arrow_circle_up_rounded,
                      title: "版本更新",
                      arrow: true,
                      onClick: (_) {}),
                  TDCell(
                      leftIcon: Icons.groups_2_sharp,
                      title: "联系我们",
                      arrow: true,
                      onClick: (_) {}),
                ],
              )
            ],
          ),
        ],
      ),
    );
  }
}
