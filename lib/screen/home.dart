import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/screen/Wrong.dart';
import 'package:flutter_application_1/screen/question.dart';
import 'package:flutter_swiper_view/flutter_swiper_view.dart';
import 'package:simple_ripple_animation/simple_ripple_animation.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import 'package:flutter_application_1/screen/setting.dart';
import 'package:flutter_application_1/screen/achievement.dart';
import 'bank.dart';
import 'skip.dart';
import 'note.dart';

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

      bottomNavigationBar: CurvedNavigationBar(
        backgroundColor: Colors.white,
        index: _currentIndex,
        animationDuration: const Duration(milliseconds: 300),
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
      text: '查看章节',
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
  List<Map> imgList = [
    {"url": "http://img5.mtime.cn/mg/2021/08/24/141454.81651527_285X160X4.jpg"},
    {"url": "http://img5.mtime.cn/mg/2021/08/24/134535.67957178_285X160X4.jpg"},
    {"url": "http://img5.mtime.cn/mg/2021/08/24/112722.60735295_285X160X4.jpg"},
    {"url": "http://img5.mtime.cn/mg/2021/08/24/110937.63038065_285X160X4.jpg"},
  ];
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(
                height: 120,
              ),
              const Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Expanded(
                    child: Card(
                      margin: EdgeInsets.all(8),
                      color: Colors.lightGreen,
                      borderOnForeground: false,
                      elevation: 3,
                      shape: BeveledRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(40)),
                        side: BorderSide(color: Colors.white),
                      ),
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(10, 60, 10, 40),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text(
                              "难度-",
                              style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      offset: Offset(1, 1),
                                      blurRadius: 1.0,
                                      color: Colors.black54,
                                    )
                                  ]),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Card(
                      margin: EdgeInsets.all(8),
                      color: Colors.deepOrange,
                      borderOnForeground: false,
                      elevation: 3,
                      shape: BeveledRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(40)),
                        side: BorderSide(color: Colors.white),
                      ),
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(10, 60, 10, 40),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              "难度+",
                              style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      offset: Offset(1, 1),
                                      blurRadius: 1.0,
                                      color: Colors.black54,
                                    )
                                  ]),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => SkipScreen()));
                          },
                          child: const Column(
                            children: [
                              Icon(
                                Icons.playlist_add_check,
                                size: 45,
                                color: Colors.blueAccent,
                              ),
                              Text(
                                "跳过的题",
                                style: TextStyle(
                                    fontSize: 12, color: Colors.black),
                              )
                            ],
                          ),
                        )),
                  ),
                  Expanded(
                      child: InkWell(
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => NoteScreen()));
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(10),
                      child: Column(
                        children: [
                          Icon(
                            Icons.mode_outlined,
                            size: 40,
                            color: Colors.blueAccent,
                          ),
                          Text(
                            "添加笔记",
                            style: TextStyle(fontSize: 12, color: Colors.black),
                          )
                        ],
                      ),
                    ),
                  )),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => BankScreen()));
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(10),
                        child: Column(
                          children: [
                            Icon(
                              Icons.notes,
                              size: 40,
                              color: Colors.blueAccent,
                            ),
                            Text(
                              "题库选择",
                              style:
                                  TextStyle(fontSize: 12, color: Colors.black),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const WrongScreen(
                                      title: '',
                                    )));
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(10),
                        child: Column(
                          children: [
                            Icon(
                              Icons.quiz_outlined,
                              size: 35,
                              color: Colors.blueAccent,
                            ),
                            Text(
                              "疑难题集",
                              style:
                                  TextStyle(fontSize: 12, color: Colors.black),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(10, 5, 5, 5),
                child: Text(
                  '公告',
                  style: TextStyle(
                      fontSize: 18,
                      color: Colors.black,
                      fontWeight: FontWeight.w400),
                ),
              ),
              Column(
                children: [
                  const SizedBox(
                    width: double.infinity,
                  ),
                  Card(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Row(
                          children: [
                            const SizedBox(
                              width: 4,
                            ),
                            Image.asset(
                              'assets/logo.png',
                              width: 50,
                              height: 50,
                            ),
                            const SizedBox(
                              width: 10,
                            ),
                            const Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '长安大学高数练习软件',
                                  style: TextStyle(
                                      color: Colors.black, fontSize: 16),
                                ),
                                Text(
                                  '上高树，学高数',
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 14),
                                ),
                              ],
                            )
                          ],
                        )),
                  ),
                  Card(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Row(
                          children: [
                            const SizedBox(
                              width: 4,
                            ),
                            Image.asset(
                              'assets/chu.png',
                              width: 50,
                              height: 50,
                            ),
                            const SizedBox(
                              width: 10,
                            ),
                            const Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '弘毅明德，笃学创新',
                                  style: TextStyle(
                                      color: Colors.black, fontSize: 16),
                                ),
                                Text(
                                  '为党育人，为国育才',
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 14),
                                ),
                              ],
                            )
                          ],
                        ),
                      )),
                ],
              ),
            ],
          ),
          Column(
            //InkWell：可以给任意控件外面套，然后可以监听点击之类的事件
            children: [
              Container(
                height: 50,
              ),
              Center(
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: const BoxDecoration(
                      shape: BoxShape.circle, color: Colors.white),
                ),
              ),
            ],
          ),
          Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blueAccent, Color.fromARGB(0, 68, 138, 255)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              height: 150),
          Column(
            //InkWell：可以给任意控件外面套，然后可以监听点击之类的事件
            children: [
              Container(
                height: 80,
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
                          builder: (context) => QuestionScreen()),
                    );
                  },
                  child: RippleAnimation(
                    color: Colors.blueAccent,
                    // delay: const Duration(milliseconds: -1000),
                    repeat: true,
                    minRadius: 30,
                    maxRadius: 50,
                    ripplesCount: 10,
                    duration: const Duration(milliseconds: 6000),
                    child: Container(
                      width: 140,
                      height: 140,
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
            ],
          )
        ],
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
    return Column(
      children: [
        Card(
          color: Colors.white,
          child: Column(
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
            ],
          ),
        ),

        Card(
          color: Colors.white,
          child: Column(
            children: [
              Container(
                color: Colors.white,
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                        context,
                        CupertinoPageRoute(
                            builder: (context) => const SettingScreen(
                                  title: '',
                                )));
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(14),
                    child: Stack(
                      children: [
                        Row(
                          verticalDirection: VerticalDirection.down,
                          children: [
                            Icon(
                              Icons.settings,
                              size: 20,
                              color: Colors.blueAccent,
                            ),
                            SizedBox(
                              width: 15,
                            ),
                            Text(
                              "设置",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black,
                                fontWeight: FontWeight.w600,
                              ),
                            )
                          ],
                        ),
                        Row(
                          verticalDirection: VerticalDirection.up,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(
                              Icons.chevron_right,
                              color: Colors.grey,
                              size: 22,
                            )
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ),
              const TDDivider(),
              Container(
                color: Colors.white,
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                        context,
                        CupertinoPageRoute(
                            builder: (context) => const AchievementScreen(
                                  title: '',
                                )));
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(14),
                    child: Stack(
                      children: [
                        Row(
                          verticalDirection: VerticalDirection.down,
                          children: [
                            Icon(
                              Icons.star_border,
                              size: 20,
                              color: Colors.blueAccent,
                            ),
                            SizedBox(
                              width: 15,
                            ),
                            Text(
                              "收藏",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black,
                                fontWeight: FontWeight.w600,
                              ),
                            )
                          ],
                        ),
                        Row(
                          verticalDirection: VerticalDirection.up,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(
                              Icons.chevron_right,
                              color: Colors.grey,
                              size: 22,
                            )
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ),
              const TDDivider(),
            ],
          ),
        )

        //点进去可以看团队信息
      ],
    );
  }
}
