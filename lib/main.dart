import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/tool/question/question_controller.dart';
import 'package:flutter_application_1/tool/study_data.dart';
import 'package:flutter_application_1/tool/question/wrong_question_book.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rebirth/rebirth.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import 'screen/home/home.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'tool/question/question_bank.dart';
import 'package:window_manager/window_manager.dart';

//整个软件入口（测试用）
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows) {
    await windowManager.ensureInitialized();

    WindowOptions windowOptions = const WindowOptions(
      size: Size(400, 700),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      alwaysOnTop: true,
      titleBarStyle: TitleBarStyle.normal,
      windowButtonVisibility: false,
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  } else if (Platform.isAndroid) {
    // 逐个申请权限，避免批量请求导致的插件错误
    try {
      // 存储权限
      await Permission.storage.request();
      
      // 位置权限（WiFi扫描需要）
      await Permission.location.request();
      
      // 相机权限
      await Permission.camera.request();
      
      // 蓝牙权限
      try {
        await Permission.bluetooth.request();
        await Permission.bluetoothScan.request();
        await Permission.bluetoothConnect.request();
        await Permission.bluetoothAdvertise.request();
      } catch (e) {
        // 蓝牙权限可能在较低版本不可用，忽略错误
        print('Bluetooth permissions not available: $e');
      }
      
      // WiFi相关权限（Android 13+）
      try {
        await Permission.nearbyWifiDevices.request();
      } catch (e) {
        // Permission.nearbyWifiDevices可能在较低版本不可用，忽略错误
        print('NEARBY_WIFI_DEVICES permission not available: $e');
      }
      
      print('All permissions requested successfully');
    } catch (e) {
      print('Error requesting permissions: $e');
      // 即使权限请求失败，应用也应该继续运行
    }
    try {
      await FlutterDisplayMode.setHighRefreshRate();
    } on PlatformException catch (e) {
      print(e);
    }
  }
  await StudyData.instance.init();

  runApp(const WidgetRebirth(materialApp: MainEnterScreen()));
}

//这里是入口代码，不用改
class MainEnterScreen extends StatelessWidget {
  const MainEnterScreen({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    //入口，一般不用改
    return MaterialApp(
      title: '高数',
      theme: ThemeData(
        fontFamily: Platform.isWindows ? "微软雅黑" : null,
        primaryColor: StudyData.instance.themeColor,
        extensions: [
          TDTheme.defaultData()
            ..colorMap['brandColor7'] = StudyData.instance.themeColor
        ],
        scaffoldBackgroundColor: const Color.fromRGBO(250, 250, 250, 1),
        cardColor: Colors.white,
        useMaterial3: true,
      ),
      home: const _MainEnterScreen(title: ' '),
    );
  }
}

var isStarted = false;

//这里也是一个标准的动态页面
class _MainEnterScreen extends StatefulWidget {
  const _MainEnterScreen({required this.title});
  final String title;

  @override
  State<_MainEnterScreen> createState() => _MainEnterScreenState();
}

class _MainEnterScreenState extends State<_MainEnterScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  final double _opacity = 1.0;
  bool _initCompleted = false;

  @override
  void initState() {
    super.initState();

    Future(
      () async {
        await QuestionBank.init();
        await QuestionBankBuilder.init();
        await WrongQuestionBook.init();

        if (StudyData.instance.todayUpdater()) {
          LearningPlanManager.instance.resetDailyProgress();
        }

        await LearningPlanManager.instance.updateLearningPlan();

        if (mounted) {
          setState(() => _initCompleted = true);
          _navigateToHome();
        }
      },
    );

    // 5秒超时机制
    Future.delayed(const Duration(seconds: 5), _navigateToHome);

    // 渐隐动画控制器
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
  }

  void _navigateToHome() {
    if (!mounted) return;

    _fadeController.forward().then((_) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 800),
          pageBuilder: (_, __, ___) => const HomeScreen(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = StudyData.instance.themeColor;

    return Scaffold(
      body: AnimatedBuilder(
        animation: _fadeController,
        builder: (context, child) {
          return Opacity(
            opacity: 1 - _fadeController.value,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo容器（修复空白框问题）
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: LinearGradient(
                        colors: [
                          themeColor,
                          themeColor.withOpacity(0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Image.asset(
                        'assets/logo.png',
                        filterQuality: FilterQuality.high,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // 加载状态提示
                  _initCompleted
                      ? Text("加载完成", style: TextStyle(color: themeColor))
                      : const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),

                  const SizedBox(height: 20),

                  // 轻触跳过提示（保留原有交互）
                  GestureDetector(
                    onTap: _navigateToHome,
                    child: AnimatedOpacity(
                      opacity: _initCompleted ? 0.0 : 1.0,
                      duration: const Duration(milliseconds: 300),
                      child: Text("轻触跳过",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          )),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }
}
