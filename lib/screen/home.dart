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
    // 在 Scaffold 中统一增加背景渐变
    return Scaffold(
      extendBodyBehindAppBar: true,
        appBar: AppBar(
          toolbarHeight: 0,
        ),
      resizeToAvoidBottomInset: false, // 设置为 false 避免底部溢出

      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.grey.shade100],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
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
        index: _currentIndex,
        animationDuration: const Duration(milliseconds: 300),
        height: 56,
        backgroundColor: Colors.grey.shade100, // 调整为背景色系
        color: Colors.blue.shade700,
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
        animationCurve: Curves.ease,
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

  // 新增统一的功能按钮构建方法
  Widget _buildFeatureButton(BuildContext context,
      {required IconData icon,
      required String label,
      required Color color,
      required VoidCallback onTap}) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.all(6),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6), // 增加边框
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 28, color: Colors.black54),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 新增进度标签样式
  Widget _buildProgressChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text,
          style: TextStyle(
              color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  // 新增设置卡片组件
  Widget _buildSelectionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color startColor,
    required Color endColor,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [startColor, endColor],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: startColor.withOpacity(0.3),
                  blurRadius: 12,
                  offset: Offset(0, 6),
                )
              ],
            ),
            child: Stack(
              children: [
                // 背景装饰元素
                Positioned(
                  right: 10,
                  top: 10,
                  child: Icon(
                    icon,
                    size: 60,
                    color: Colors.white.withOpacity(0.15),
                  ),
                ),

                // 内容布局
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 2,
                                  offset: Offset(1, 1),
                                )
                              ])),
                      SizedBox(height: 4),
                      Text(subtitle,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 12,
                          )),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  double studyProgress = 0.75;
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return SingleChildScrollView(
        child: Column(
      children: [
        // 上半部分背景
        Stack(
          children: [
            Container(
              height: screenHeight * 0.45,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.blue.shade700,
                    Colors.purple.shade400,
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  // 标题
                  Row(
                    children: [
                      Icon(Icons.school, color: Colors.white, size: 28),
                      const SizedBox(width: 10),
                      Text("高等数学练习平台",
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 开始刷题卡片
                  InkWell(
                    onTap: () {/* 原点击逻辑 */},
                    borderRadius: BorderRadius.circular(0),
                    child: Container(
                      height: 140,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.3), width: 2),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: Offset(0, 10))
                        ],
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            right: -50,
                            top: -50,
                            child: Icon(Icons.fingerprint,
                                color: Colors.white.withOpacity(0.1),
                                size: 180),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.auto_awesome,
                                        color: Colors.amber, size: 28),
                                    const SizedBox(width: 10),
                                    Text("每日练习",
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                const SizedBox(height: 15),
                                // 进度条
                                LinearProgressIndicator(
                                  value: studyProgress,
                                  backgroundColor:
                                      Colors.white.withOpacity(0.2),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.lightGreenAccent),
                                  minHeight: 8,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                    "当前进度：${(studyProgress * 100).toStringAsFixed(1)}%",
                                    style: TextStyle(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: 14)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 题库和模式选择
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Row(
                      children: [
                        _buildSelectionButton(
                          icon: Icons.library_books,
                          title: "题库选择",
                          subtitle: "已选3个题库",
                          startColor: Colors.blueAccent.shade400,
                          endColor: Colors.indigoAccent,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => BankChooseScreen()),
                          ),
                        ),
                        _buildSelectionButton(
                          icon: Icons.tune,
                          title: "模式选择",
                          subtitle: "当前：智能刷题",
                          startColor: Colors.purple.shade400,
                          endColor: Colors.pinkAccent.shade200,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => ModeScreen(
                                      title: "",
                                    )),
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            )
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Column(
            children: [
              // 保留原有的功能按钮布局
              Row(
                children: [
                  _buildFeatureButton(
                    context,
                    icon: Icons.class_outlined,
                    label: "错题查看",
                    color: Colors.purple,
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const WrongQuestionScreen())),
                  ),
                  _buildFeatureButton(
                    context,
                    icon: Icons.note_add_outlined,
                    label: "查看笔记",
                    color: Colors.orange,
                    onTap: () {},
                  ),
                  _buildFeatureButton(
                    context,
                    icon: Icons.search_rounded,
                    label: "题库浏览",
                    color: Colors.blue,
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const SearchScreen())),
                  ),
                  _buildFeatureButton(
                    context,
                    icon: Icons.help_outline_rounded,
                    label: "使用手册",
                    color: Colors.green,
                    onTap: () {},
                  ),
                ],
              ),
              const SizedBox(
                height: 0,
              ),

              Column(
                children: [
                  Container(
                    margin: const EdgeInsets.all(4.0), // 四周外边距
                    child: Card(
                      color: Theme.of(context).cardColor,
                      elevation: 0.3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Row(
                            children: [
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
                                        fontWeight: FontWeight.w800,
                                        color: Colors.black,
                                        fontSize: 14),
                                  ),
                                  Text(
                                    '上高树，学高数',
                                    style: TextStyle(
                                        color: Colors.grey, fontSize: 14),
                                  ),
                                ],
                              ),
                              Image.asset(
                                'assets/logo.png',
                                width: 50,
                                height: 50,
                              ),
                            ],
                          )),
                    ),
                  )
                ],
              ),

              // 其他内容...
            ],
          ),
        ),
        // 修改底部四个功能图标的布局，增加图标多样性和视觉层次
      ],
    ));
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
