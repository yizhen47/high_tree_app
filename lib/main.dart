import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'screen/home.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import 'package:flutter/widgets.dart';

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
        useMaterial3: true,
      ),
      home: const _MainEnterScreen(title: ' '),
    );
  }
}

//这里也是一个标准的动态页面
class _MainEnterScreen extends StatefulWidget {
  const _MainEnterScreen({super.key, required this.title});
  final String title;

  @override
  State<_MainEnterScreen> createState() => _MainEnterScreenState();
}

//这个应该是折叠控件的数据
class CollapseDataItem {
  var isExpanded = false;
  var randomString = "知识点";
  var headerValue = "章节名称";

  CollapseDataItem();
}

class _MainEnterScreenState extends State<_MainEnterScreen> {
  //tdCollapse好像有点问题，我也不知道这里怎么跑起来的，反正跑起来了
  final _basicData = [CollapseDataItem()];

//init: 在页面初始化的时候执行
  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      fetchAll();
    });
    //future.delay xxxxx格式：延时执行一串代码
    Future.delayed(const Duration(milliseconds: 500), () {
      // ignore: use_build_context_synchronously
      Navigator.push(context,
          CupertinoPageRoute(builder: (context) => const HomeScreen(title: '')));
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
      //定义假面内容
      body:
          Column(mainAxisAlignment: MainAxisAlignment.start, children: <Widget>[
        const Padding(padding: EdgeInsets.fromLTRB(50, 100, 0, 70)),
        Text(
          '加入你不熟悉的知识点就开始练习吧！',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        TDButton(
          text: '测试按钮（题库设置）',
          size: TDButtonSize.large,
          type: TDButtonType.ghost,
          shape: TDButtonShape.rectangle,
          theme: TDButtonTheme.primary,
          onTap: () async {
            FilePickerResult? result = await FilePicker.platform.pickFiles();
            if (result != null) {
              // QuestionBank(result.files.single.path!).load();
              QuestionBank.create(result.files.single.path!);
            } else {
              // User canceled the picker
            }
          },
        ),
        TDButton(
          text: '测试按钮（刷题主页）',
          size: TDButtonSize.large,
          type: TDButtonType.ghost,
          shape: TDButtonShape.rectangle,
          theme: TDButtonTheme.primary,
          onTap: () {
            //前往另外一个页面（需要import）
            Navigator.push(
              context,
              CupertinoPageRoute(
                  builder: (context) => const HomeScreen(
                        title: '',
                      )),
            );
          },
        ),
      ]),
    );
  }
}
