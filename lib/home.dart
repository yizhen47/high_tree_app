import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/left.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import 'package:flutter_application_1/setting.dart';
import 'package:flutter_application_1/achievement.dart';
import 'dart:io';

//动态页面：按照下面的方法创建。特点：每一次setState都会刷新控件，比如下面的按一下加次数，文本会被重新构建。
class MyApp3 extends StatefulWidget {
  const MyApp3({super.key, required this.title});
  final String title;
  @override
  State<MyApp3> createState() => _MyHomePageState();
}

//这里是在一个页面中加了PageView，PageView可以载入更多的StatefulWidget或者StatelessWidget（也就是页面中加载其他页面作为子控件）
class _MyHomePageState extends State<MyApp3> {
  int _currentIndex = 1;
  final PageController _pageController = PageController(initialPage: 1);

  Future<void> fetchAll() async {}

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TDNavBar(
        title: ' ',
      ),
      resizeToAvoidBottomInset: false, // 设置为 false 避免底部溢出
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: const [
          CommunityPage(
            title: ' ',
          ),
          MainHomePage(
            title: ' ',
          ),
          ProfilePage(
            title: ' ',
          ),
        ],
      ),
      bottomNavigationBar: TDBottomTabBar(
        TDBottomTabBarBasicType.iconText, // 确保使用正确的属性名
        useVerticalDivider: false,
        barHeight: 60,
        currentIndex: _currentIndex, // 确保绑定 currentIndex
        navigationTabs: [
          TDBottomTabBarTabConfig(
              unselectedIcon: const Icon(CupertinoIcons.text_justify),
              selectedIcon: const Icon(CupertinoIcons.text_quote),
              tabText: '题库',
              onTap: () => _onTabTapped(0)),
          TDBottomTabBarTabConfig(
              selectedIcon: const Icon(CupertinoIcons.pencil_outline),
              unselectedIcon: const Icon(CupertinoIcons.pencil),
              tabText: '刷题',
              onTap: () => _onTabTapped(1)),
          TDBottomTabBarTabConfig(
              unselectedIcon: const Icon(CupertinoIcons.person),
              selectedIcon: const Icon(CupertinoIcons.person_fill),
              tabText: '我',
              onTap: () => _onTabTapped(2)),
        ],
      ),
    );
  }
}

//我们希望子页面也是动态的，所以模仿上面进行动态页面的构造
class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key, required this.title});
  final String title;
  @override
  State<CommunityPage> createState() => CommunityPageState();
}

class CommunityPageState extends State<CommunityPage> {
  @override
  Widget build(BuildContext context) {
    return TDButton(
      text: '基础抽屉',
      isBlock: true,
      type: TDButtonType.outline,
      theme: TDButtonTheme.primary,
      size: TDButtonSize.large,
      onTap: () {
        var tdDrawer = TDDrawer(
          context,
          visible: true,
          drawerTop: 40,
          items: List.empty(growable: true),
          onItemClick: (index, item) {
            print('drawer item被点击，index：$index，title：${item.title}');
          },
        );
      },
    );
  }
}

//第二个子页面
class MainHomePage extends StatefulWidget {
  const MainHomePage({super.key, required this.title});
  final String title;
  @override
  State<MainHomePage> createState() => MainHomePageState();
}

int clickNum = 1;

class MainHomePageState extends State<MainHomePage> {
  @override
  Widget build(BuildContext context) {
    return Center(
      //InkWell：可以给任意控件外面套，然后可以监听点击之类的事件
      child: InkWell(
        onTap: () {
          setState(() {
            clickNum += 1;
          });
          Navigator.push(
            context,
            CupertinoPageRoute(builder: (context) => const MyApp2()),
          );
        },
        child: Container(
          width: 200,
          height: 200,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color.fromARGB(255, 74, 126, 123),
          ),
          child: Column(
            verticalDirection: VerticalDirection.up,
            children: [
              const Text(
                ' ',
                style: TextStyle(
                  color: Color.fromARGB(255, 236, 236, 236),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                '点击继续',
                style: TextStyle(
                  color: Color.fromARGB(255, 236, 236, 236),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '$clickNum次',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text('您已刷题',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

//第三个页面
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, required this.title});
  final String title;
  @override
  State<ProfilePage> createState() => ProfilePageState();
}

class ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    var screenWidth = MediaQuery.of(context).size.width;
    TDSwipeCell(
      groupTag: 'test',
      left: TDSwipeCellPanel(
        extentRatio: 60 / screenWidth,
        children: [],
      ),
      cell: const TDCell(
        title: '左右滑操作',
        note: '辅助信息',
      ),
    );

    return Column(
      children: [
        Row(
          children: [
            Padding(
              padding: EdgeInsets.all(50),
              child: Container(
                width: 100,
                height: 100,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color.fromARGB(255, 74, 126, 123),
                ),
              ),
            ),
            Column(
              children: const [
                Text(
                  '姓名',
                  textScaler: TextScaler.linear(2),
                  style: TextStyle(),
                ),
                Text(
                  '签名',
                  textScaler: TextScaler.linear(1.2),
                  style: TextStyle(),
                ),
              ],
            ),
          ],
        ),
        SizedBox(
          height: 20,
          child: Container(
            alignment: Alignment.center,
            child: const TDDivider(),
          ),
        ),
        Padding(
          padding: EdgeInsets.all(5),
          child: TDButton(
            text: '成就',
            size: TDButtonSize.large,
            type: TDButtonType.fill,
            shape: TDButtonShape.filled,
            theme: TDButtonTheme.defaultTheme,
            onTap: () {
              //前往另外一个页面（需要import）
              Navigator.push(
                context,
                CupertinoPageRoute(
                    builder: (context) => const MyApp5(
                          title: '',
                        )),
              );
            },
          ),
        ),
        Padding(
          padding: EdgeInsets.all(5),
          child: TDButton(
            text: '设置',
            size: TDButtonSize.large,
            type: TDButtonType.fill,
            shape: TDButtonShape.filled,
            theme: TDButtonTheme.defaultTheme,
            onTap: () {
              //前往另外一个页面（需要import）
              Navigator.push(
                context,
                CupertinoPageRoute(
                    builder: (context) => const MyApp4(
                          title: '',
                        )),
              );
            },
          ),
        ),
        Padding(
          padding: EdgeInsets.all(5),
          child: const TDButton(
            text: '关于',
            size: TDButtonSize.large,
            type: TDButtonType.fill,
            shape: TDButtonShape.filled,
            theme: TDButtonTheme.defaultTheme,
          ),
        ), //点进去可以看团队信息
      ],
    );
  }
}
