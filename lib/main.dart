import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'screen/home.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'tool/question_bank.dart';

//整个软件入口（测试用）
void main() {
  runApp(const MainEnterScreen());
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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        scaffoldBackgroundColor: const Color.fromRGBO(250, 250, 250, 1),
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

class _MainEnterScreenState extends State<_MainEnterScreen> {

//init: 在页面初始化的时候执行
  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      fetchAll();
    });
    //future.delay xxxxx格式：延时执行一串代码

    QuestionBank.init();
    Future.delayed(const Duration(milliseconds: 5000), () {
      if(!isStarted) {
        // ignore: use_build_context_synchronously
        Navigator.push(context,
          MaterialPageRoute(builder: (context) => const HomeScreen(title: '')));
      }
    });
  }

  Future<void> fetchAll() async {
    //设置安卓平台的高屏幕刷新率
    if (Platform.isAndroid) {
      try {
        await FlutterDisplayMode.setHighRefreshRate();
      } on PlatformException catch (e) {
        print(e);
      }
    }
  }

  //界面1的界面内容
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          verticalDirection: VerticalDirection.up,
          children: <Widget>[
            Container(
              height: 80,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/logo.png',
                  width: 60,
                  height: 60,
                ),
                const Column(
                  children: [
                    Text(
                      '长安大学高数练习软件',
                      style: TextStyle(color: Colors.black,fontSize: 20),
                    ),
                    Text(
                      '上高树，学高数',
                      style: TextStyle(color: Colors.grey,fontSize: 16),
                    ),
                  ],
                )
              ],
            ),
            Expanded(
              child: Center(
                  child: InkWell(
                onTap: () {
                  isStarted = true;
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const HomeScreen(title: '')));
                },
                child: SizedBox(
                  width: 250.0,
                  child: TextLiquidFill(
                    text: 'CHU',
                    waveColor: Colors.blueAccent,
                    boxBackgroundColor: Colors.redAccent,
                    textStyle: const TextStyle(
                      fontSize: 80.0,
                      fontWeight: FontWeight.bold,
                    ),
                    boxHeight: 250.0,
                  ),
                ),
              )),
            )
          ],
        ),
      ),
    );
  }
}
