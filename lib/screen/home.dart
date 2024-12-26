import 'dart:io';

import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/screen/bank_manager.dart';
import 'package:flutter_application_1/screen/personal.dart';
import 'package:flutter_application_1/screen/mode.dart';
import 'package:flutter_application_1/screen/question.dart';
import 'package:flutter_application_1/screen/search.dart';
import 'package:flutter_application_1/tool/question_bank.dart';
import 'package:flutter_application_1/tool/study_data.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import 'package:flutter_application_1/screen/setting.dart';
import 'package:fl_chart/fl_chart.dart';

import 'bank_choose.dart';
import 'wrong_question.dart';

class MedicalCaseIndexVary {
  final String referenceValueUpper;
  final String referenceValueLower;

  MedicalCaseIndexVary({
    required this.referenceValueUpper,
    required this.referenceValueLower,
  });
}

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
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leftBarItems: [
          TDNavBarItem(
              iconColor: Theme.of(context).primaryColor,
              icon: Icons.people,
              action: () {})
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
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        index: _currentIndex,
        animationDuration: const Duration(milliseconds: 300),
        height: 56,
        color: Theme.of(context).primaryColor,
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
  final medicalCaseIndexVary = MedicalCaseIndexVary(
      referenceValueUpper: '10.0', referenceValueLower: '0.0');
  List<String> weekDays = [];
  bool showCircles = false;
  int touchedValue = -1;
  List<double> yValues = [];

  @override
  void initState() {
    super.initState();
    touchedValue = -1;
    showCircles = true;
    weekDays = [
      "2021-02-01",
      "2021-03-01",
      "2021-04-01",
      "2021-05-01",
      "2021-06-01",
      "2021-07-01",
      "2021-08-01"
    ];
    yValues = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0];
  }

  @override
  Widget build(BuildContext context) {
    final List<int> showIndexes = yValues.asMap().keys.toList();
    final lineBarsData = [
      LineChartBarData(
        isCurved: true,
        color: const Color(0xFF22A3FD),
        barWidth: 2,
        spots: yValues.asMap().entries.map((e) {
          return FlSpot(e.key.toDouble(), e.value);
        }).toList(),
        belowBarData: BarAreaData(show: false),
        dotData: FlDotData(
          show: true,
          getDotPainter: (spot, percent, barData, index) {
            return FlDotCirclePainter(
              radius: index != weekDays.length - 1 && showCircles ? 1 : 3,
              color: index != weekDays.length - 1 && showCircles
                  ? const Color(0xFF22A3FD)
                  : Colors.white,
              strokeWidth: 2,
              strokeColor: const Color(0xFF22A3FD),
            );
          },
        ),
      ),
    ];

    final referenceValueUpper =
        double.parse(medicalCaseIndexVary.referenceValueUpper);
    final referenceValueLower =
        double.parse(medicalCaseIndexVary.referenceValueLower);
    double numMax = [referenceValueUpper, referenceValueLower, ...yValues]
        .reduce((a, b) => a > b ? a : b);
    numMax *= 1.25;

    return weekDays.isNotEmpty
        ? Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              _buildHeader(),
              _buildSubHeader(),
              const SizedBox(height: 15),
              _buildChart(numMax, showIndexes, lineBarsData),
            ],
          )
        : Center(child: Image.asset("assets/logo.png"));
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            '数据趋势',
            style: TextStyle(
                color: Color(0xFF555555),
                fontSize: 18.0,
                fontWeight: FontWeight.bold),
          ),
          GestureDetector(
            child: const Text(
              '详情',
              style: TextStyle(color: Color(0xFF8C8C8C), fontSize: 14.0),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubHeader() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '单位：次',
            style: TextStyle(color: Color(0xFF8C8C8C), fontSize: 12.0),
          ),
          Text(
            '参考值范围：0-10',
            style: TextStyle(color: Color(0xFF8C8C8C), fontSize: 12.0),
          ),
        ],
      ),
    );
  }

  Widget _buildChart(double numMax, List<int> showIndexes,
      List<LineChartBarData> lineBarsData) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 200,
      child: LineChart(
        LineChartData(
          showingTooltipIndicators: showIndexes.map((index) {
            return ShowingTooltipIndicators([
              LineBarSpot(lineBarsData[0], 0, lineBarsData[0].spots[index]),
            ]);
          }).toList(),
          lineTouchData: LineTouchData(
            enabled: false,
            getTouchedSpotIndicator: (barData, spotIndexes) {
              return spotIndexes.map((index) {
                return const TouchedSpotIndicatorData(
                  FlLine(color: Colors.transparent),
                  FlDotData(show: false),
                );
              }).toList();
            },
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (lineBarsSpot) {
                return lineBarsSpot.map((lineBarSpot) {
                  return LineTooltipItem(
                    lineBarSpot.y.toString(),
                    const TextStyle(
                        color: Color(0xFF22A3FD),
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  );
                }).toList();
              },
            ),
          ),
          extraLinesData: ExtraLinesData(horizontalLines: [
            HorizontalLine(
              y: 0.0,
              color: const Color(0xFF64FFE4),
              strokeWidth: 2,
              dashArray: [20, 2],
            ),
            HorizontalLine(
              y: 10.0,
              color: const Color(0xFFF8A70A),
              strokeWidth: 2,
              dashArray: [20, 2],
            ),
          ]),
          lineBarsData: lineBarsData,
          borderData: FlBorderData(
            show: true,
            border: const Border(
              bottom: BorderSide(width: 0.5, color: Color(0xFF8FFFEB)),
            ),
          ),
          minY: 0,
          maxY: numMax,
          gridData: const FlGridData(
            show: true,
            drawHorizontalLine: false,
            drawVerticalLine: false,
          ),
          titlesData: FlTitlesData(
            show: true,
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Text(
                    "${weekDays[value.toInt()].substring(0, 4)}\n${weekDays[value.toInt()].substring(5, 7)}\n${weekDays[value.toInt()].substring(8, 10)}",
                    style: TextStyle(
                      fontSize: 10,
                      color: value == touchedValue
                          ? const Color(0xFF000000)
                          : const Color(0xFF000000).withOpacity(0.5),
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
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
              Column(
                //InkWell：可以给任意控件外面套，然后可以监听点击之类的事件
                children: [
                  Center(
                    child: InkWell(
                      onTap: () {
                        if (sectionIsEmpty() ||
                            QuestionBank.getAllLoadedQuestionBankIds()
                                .isEmpty) {
                          TDToast.showWarning('章节未选择',
                              direction: IconTextDirection.vertical,
                              context: context);
                        } else {
                          Navigator.push(
                            context,
                            CupertinoPageRoute(
                                builder: (context) => const QuestionScreen(
                                      title: '',
                                    )),
                          );
                        }
                      },
                      child: Card(
                        color: Theme.of(context).primaryColor,
                        elevation: 2,
                        margin: const EdgeInsets.all(20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          height: 200,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  CupertinoIcons.square_stack_3d_up_fill,
                                  color: Colors.white,
                                  size: 45,
                                ),
                                const Text(
                                  '开始刷题',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 30,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  StudyData.instance.getStudySection() == null
                                      ? "未选择"
                                      : StudyData.instance
                                              .getStudySection()!
                                              .startsWith("{")
                                          ? "多个题库"
                                          : StudyData.instance
                                              .getStudySection()!,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '${StudyData.instance.getStudyType().getDisplayName()} | ${StudyData.instance.getStudyDifficulty().displayName}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const BankChooseScreen()))
                                .then((onValue) {
                              setState(() {});
                            });
                          },
                          child: Card(
                            color: Colors.deepPurpleAccent,
                            elevation: 2,
                            margin: const EdgeInsets.only(left: 20, right: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const SizedBox(
                              width: double.infinity,
                              height: 80,
                              child: Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      CupertinoIcons.square_list,
                                      color: Colors.white,
                                      size: 35,
                                    ),
                                    SizedBox(
                                      width: 10,
                                    ),
                                    Text('题库选择',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ))
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            if (QuestionBank.getAllLoadedQuestionBankIds()
                                .isEmpty) {
                              TDToast.showWarning('题库未选择',
                                  direction: IconTextDirection.vertical,
                                  context: context);
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ModeScreen(
                                    title: '',
                                  ),
                                ),
                              ).then((onValue) {
                                setState(() {});
                              });
                            }
                          },
                          child: Card(
                            color: Colors.deepOrangeAccent,
                            elevation: 2,
                            margin: const EdgeInsets.only(left: 10, right: 20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const SizedBox(
                              width: double.infinity,
                              height: 80,
                              child: Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      CupertinoIcons.square_on_square,
                                      color: Colors.white,
                                      size: 35,
                                    ),
                                    SizedBox(
                                      width: 10,
                                    ),
                                    Text('模式选择',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ))
                                  ],
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
              const SizedBox(
                height: 15,
              ),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const WrongQuestionScreen()));
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            children: [
                              Icon(
                                Icons.class_outlined,
                                size: 40,
                                color: Theme.of(context).primaryColor,
                              ),
                              const Text(
                                "错题查看",
                                style: TextStyle(
                                    fontSize: 12, color: Colors.black),
                              )
                            ],
                          ),
                        )),
                  ),
                  Expanded(
                      child: InkWell(
                    onTap: () {},
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        children: [
                          Icon(
                            Icons.mode_outlined,
                            size: 40,
                            color: Theme.of(context).primaryColor,
                          ),
                          const Text(
                            "查看笔记",
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
                                builder: (context) => const SearchScreen()));
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          children: [
                            Icon(
                              Icons.search,
                              size: 40,
                              color: Theme.of(context).primaryColor,
                            ),
                            const Text(
                              "题库浏览",
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
                      onTap: () {},
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          children: [
                            Icon(
                              Icons.quiz_outlined,
                              size: 35,
                              color: Theme.of(context).primaryColor,
                            ),
                            const Text(
                              "使用手册",
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
              const SizedBox(
                height: 15,
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
                    color: Theme.of(context).cardColor,
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
                      color: Theme.of(context).cardColor,
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
        InkWell(
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const PersonalScreen(
                          title: '',
                        ))).then((e) => setState(() {}));
          },
          child: Card(
            color: Theme.of(context).cardColor,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(children: [
                Builder(builder: (context) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(25),
                    child: Image(
                      image: StudyData.instance.getAvatar() == null
                          ? const AssetImage("assets/logo.png")
                          : FileImage(File(StudyData.instance.getAvatar()!))
                              as ImageProvider,
                      width: 50,
                      height: 50,
                    ),
                  );
                }),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        StudyData.instance.getUserName(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        StudyData.instance.getSign(),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ),
        Card(
          color: Theme.of(context).cardColor,
          child: TDCellGroup(
            cells: [
              TDCell(
                  leftIcon: Icons.settings,
                  title: "应用设置",
                  onClick: (_) {
                    Navigator.push(
                      context,
                      CupertinoPageRoute(
                        builder: (context) => const SettingScreen(),
                      ),
                    );
                  }),
              TDCell(
                  leftIcon: Icons.library_books,
                  title: "题库管理",
                  onClick: (_) async {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const BankManagerScreen(
                                  title: '',
                                ))).then((e) => setState(() {}));
                  }),
            ],
          ),
        )
      ],
    );
  }
}
