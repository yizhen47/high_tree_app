import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/screen/question.dart';
import 'package:simple_ripple_animation/simple_ripple_animation.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import 'package:flutter_application_1/screen/setting.dart';
import 'package:flutter_application_1/screen/achievement.dart';

//动态页面：按照下面的方法创建。特点：每一次setState都会刷新控件，比如下面的按一下加次数，文本会被重新构建。
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.title});
  final String title;
  @override
  State<HomeScreen> createState() => _MyHomePageState();
}

//这里是在一个页面中加了PageView，PageView可以载入更多的StatefulWidget或者StatelessWidget（也就是页面中加载其他页面作为子控件）
class _MyHomePageState extends State<HomeScreen> {
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
      appBar: TDNavBar(
        title: ' ',
        height: 45,
        useDefaultBack: false,
        backgroundColor: Colors.blueAccent,
        leftBarItems: [
          TDNavBarItem(
              iconColor: Colors.white, icon: Icons.people, action: () {})
        ],
      ),
      resizeToAvoidBottomInset: false, // 设置为 false 避免底部溢出
      
      body: Container(
        color: Colors.white,
        child: PageView(
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
      ),
      bottomNavigationBar: CurvedNavigationBar(
        backgroundColor: Colors.white,
        index: _currentIndex,
        height: 56,
        color: Colors.blueAccent,
        items: const <Widget>[
          Icon(
            CupertinoIcons.text_justify,
            color: Colors.white,
          ),
          Icon(
            CupertinoIcons.pencil_outline,
            color: Colors.white,
          ),
          Icon(
            CupertinoIcons.person,
            color: Colors.white,
          ),
        ],
        onTap: (index) {
          _onTabTapped(index);
        },
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
          items: [
            TDDrawerItem(title: "test", icon: const Icon(Icons.add_box_sharp))
          ],
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
    return Stack(children: [
      Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.blueAccent,
                Color.fromARGB(137, 235, 235, 235)
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          height: 150),
      Column(
        //InkWell：可以给任意控件外面套，然后可以监听点击之类的事件
        children: [
          Container(
            height: 50,
          ),
          Center(
            child: InkWell(
              onTap: () {
                setState(() {
                  clickNum += 1;
                });
                Navigator.push(
                  context,
                  CupertinoPageRoute(
                      builder: (context) => const QuestionScreen()),
                );
              },
              child: RippleAnimation(
                color: Colors.blueAccent,
                // delay: const Duration(milliseconds: -1000),
                repeat: true,
                minRadius: 50,
                maxRadius: 80,
                ripplesCount: 10,
                duration: const Duration(milliseconds: 6000),
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: const BoxDecoration(
                      shape: BoxShape.circle, color: Colors.blueAccent),
                  child: const Center(
                    child: Text(
                      '开始刷题',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const Row(
            children: [
              Expanded(
                child: Card(
                  margin: EdgeInsets.all(20),
                  color: Colors.blueAccent,
                  child: Text("data"),
                ),
              ),
              Expanded(
                child: Card(
                  child: Text("data"),
                ),
              ),
            ],
          )
        ],
      )
    ]);
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
              padding: const EdgeInsets.all(50),
              child: Container(
                width: 100,
                height: 100,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color.fromARGB(255, 74, 126, 123),
                ),
              ),
            ),
            const Column(
              children: [
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
          padding: const EdgeInsets.all(5),
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
                    builder: (context) => const AchievementScreen(
                          title: '',
                        )),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(5),
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
                    builder: (context) => const SettingScreen(
                          title: '',
                        )),
              );
            },
          ),
        ),
        const Padding(
          padding: EdgeInsets.all(5),
          child: TDButton(
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
