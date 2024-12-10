import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/home.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_application_1/left.dart';


//整个软件入口（测试用）
void main() {
  runApp(const MyApp1());
}

//这里是入口代码，不用改
class MyApp1 extends StatelessWidget {
  const MyApp1({super.key});

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
      home: const MyHomePage(title: ' '),
    );
  }
}

//这里也是一个标准的动态页面
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

//这个应该是折叠控件的数据
class CollapseDataItem {
  var isExpanded = false;
  var randomString = "知识点";
  var headerValue = "章节名称";
  
  CollapseDataItem();
}

class _MyHomePageState extends State<MyHomePage> {
  //tdCollapse好像有点问题，我也不知道这里怎么跑起来的，反正跑起来了
  final _basicData = [CollapseDataItem()];


//init: 在页面初始化的时候执行
  @override
  void initState() {
    super.initState();

    //future.delay xxxxx格式：延时执行一串代码
    Future.delayed(const Duration(milliseconds: 500), () {
       Navigator.push(
              context,
              CupertinoPageRoute(builder: (context) => const MyApp3(title: '',)),
            );
    });
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
          text: '测试按钮（刷题界面）',
          size: TDButtonSize.large,
          type: TDButtonType.ghost,
          shape: TDButtonShape.rectangle,
          theme: TDButtonTheme.primary,
          onTap: () {
            //前往另外一个页面（需要import）
            Navigator.push(
              context,
              CupertinoPageRoute(builder: (context) => const MyApp2()),
            );
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
                  builder: (context) => const MyApp3(
                        title: '',
                      )),
            );
          },
        ),
       
      ]),

     
    );
  }
}