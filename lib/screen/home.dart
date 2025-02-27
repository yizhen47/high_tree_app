import 'dart:io';
import 'dart:ui';
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
import 'dart:math';

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

  static const _primaryColor = Color(0xFF6A88E6);
  static const _secondaryColor = Color(0xFF8E49E2);
  static const _warningColor = Color(0xFFFFA726);
  static const _textColor = Color(0xFF4A4A6A);
  static const _iconColor = Color(0xFF5A5A89);

@override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF5F7FF), Color(0xFFE8ECFA)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 紧凑型标题区
              _buildCompactHeader(),
              // 密集统计卡片
              _buildDenseStatsGrid(),
              // 强化图表区
              _buildEnhancedChart(),
              // 辅助信息区
              _buildMetadataSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 40, 20, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [_primaryColor, _secondaryColor]),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.insights, color: Colors.white, size: 24),
              SizedBox(width: 12),
              Text('数据趋势分析',
                  style: TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.w700)),
              Spacer(),
              IconButton(
                icon: Icon(Icons.more_horiz, size: 24, color: Colors.white),
                onPressed: () {},
              ),
            ],
          ),
          SizedBox(height: 16),
          Text('单位：次 · 参考范围：0-10',
              style: TextStyle(color: Colors.white70, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildDenseStatsGrid() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: GridView.count(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.75,
        children: [
          _buildStatCell('平均值', '0', Icons.trending_up),
          _buildStatCell('最高值', '0', Icons.vertical_align_top),
          _buildStatCell('达标率', '${_calculateComplianceRate()}%', Icons.check_circle),
        ],
      ),
    );
  }

  Widget _buildStatCell(String title, String value, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      padding: EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: _primaryColor),
          ),
          SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _textColor)),
          SizedBox(height: 4),
          Text(title,
              style: TextStyle(
                  fontSize: 12,
                  color: _textColor.withOpacity(0.7))),
        ],
      ),
    );
  }

  Widget _buildEnhancedChart() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
          ],
        ),
        padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 图表标签
            Row(
              children: [
                _buildChartLabel(_primaryColor, '数据趋势线'),
                SizedBox(width: 16),
                _buildChartLabel(Color(0xFF64FFE4), '参考下限'),
                SizedBox(width: 16),
                _buildChartLabel(_warningColor, '警戒上限'),
              ],
            ),
            SizedBox(height: 12),
            // 图表主体
            Container(
              height: 220,
              child: LineChart(
                // 保持原有图表配置，调整颜色...
                LineChartData(
                  lineBarsData: [
                    LineChartBarData(
                      gradient: LinearGradient(colors: [_primaryColor, _secondaryColor]),
                      isCurved: true,
                      barWidth: 2.5,
                      shadow: BoxShadow(color: _primaryColor.withOpacity(0.15), blurRadius: 6),
                    ),
                  ],
                ),
              ),
            ),
            // X轴标签
            Padding(
              padding: EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: weekDays.map((date) => _buildDateLabel(date)).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartLabel(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        SizedBox(width: 6),
        Text(text,
            style: TextStyle(
                fontSize: 12,
                color: _textColor,
                fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildDateLabel(String dateStr) {
    final parts = dateStr.split('-');
    return Column(
      children: [
        Text(parts[1],
            style: TextStyle(
                fontSize: 12,
                color: _textColor,
                fontWeight: FontWeight.w600)),
        Text(parts[2],
            style: TextStyle(
                fontSize: 11,
                color: _textColor.withOpacity(0.6))),
      ],
    );
  }

  Widget _buildMetadataSection() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Divider(color: Colors.grey.shade300, height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('数据更新于：2021-08-01',
                  style: TextStyle(fontSize: 12, color: _iconColor)),
              IconButton(
                icon: Icon(Icons.refresh, size: 18, color: _iconColor),
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 新增计算方法
  double _calculateAverage(List<double> values) {
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a + b) / values.length;
  }
  double _calculateComplianceRate() {
    final compliantCount = yValues.where((v) => v <= 10).length;
    return (compliantCount / yValues.length) * 100;
  }

  void _showAnalysisDetail() {
    // 显示详细分析的弹窗
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
                  offset: const Offset(0, 6),
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
                                  offset: const Offset(1, 1),
                                )
                              ])),
                      const SizedBox(height: 4),
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
              height: 300,
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
                      const Icon(Icons.school, color: Colors.white, size: 28),
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
                              offset: const Offset(0, 10))
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
                                const Row(
                                  children: [
                                    Icon(Icons.auto_awesome,
                                        color: Colors.amber, size: 28),
                                    SizedBox(width: 10),
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
                                  valueColor: const AlwaysStoppedAnimation<Color>(
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
                                builder: (_) => const BankChooseScreen()),
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
                                builder: (_) => const ModeScreen(
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
  // 设计系统常量（保持颜色不变）
  static const _accentColor = Color(0xFF6A88E6);
  static const _textPrimary = Color(0xFF2D2D3A);
  static const _textSecondary = Color(0xFF6E6E8A);
  static const _bgGradient = LinearGradient(
    colors: [Color(0xFFF8FAFF), Color(0xFFF2F6FF)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: _bgGradient),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 120, // 缩小标题栏高度
              flexibleSpace: _buildProfileHeader(),
              pinned: true,
              collapsedHeight: 60, // 添加折叠后高度
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16), // 缩小水平间距
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    _buildStatsCard(),
                    const SizedBox(height: 16), // 缩小间距
                    _buildFunctionList(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return FlexibleSpaceBar(
      background: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_accentColor.withOpacity(0.8), _accentColor],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 头像部分
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white24, width: 1.5), // 缩小边框
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 8, // 缩小阴影
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 32, // 缩小头像尺寸
                    backgroundImage: _getAvatarImage(),
                    backgroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 12), // 缩小间距
                Text(
                  StudyData.instance.getUserName(),
                  style: const TextStyle(
                    fontSize: 18, // 缩小字体
                    color: Colors.white,
                    fontWeight: FontWeight.w600, // 调整字重
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16), // 调整圆角
        boxShadow: [
          BoxShadow(
            color: _accentColor.withOpacity(0.1),
            blurRadius: 12, // 缩小阴影
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16), // 调整内边距
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem("练习天数", "28"),
          _buildStatItem("正确率", "92%"),
          _buildStatItem("连续打卡", "7天"),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18, // 缩小数值
            fontWeight: FontWeight.w700,
            color: _accentColor,
          ),
        ),
        const SizedBox(height: 2), // 缩小间距
        Text(
          label,
          style: TextStyle(
            fontSize: 12, // 调整标签大小
            color: _textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildFunctionList() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12), // 缩小圆角
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8), // 减少模糊
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white30),
          ),
          child: Column(
            children: [
              _buildFunctionTile(
                icon: Icons.person_outline_rounded,
                title: "个人资料",
                onTap: _navigateToPersonalScreen,
              ),
              _buildFunctionTile(
                icon: Icons.auto_awesome_mosaic_rounded,
                title: "学习统计",
                onTap: () {},
              ),
              _buildFunctionTile(
                icon: Icons.settings_rounded,
                title: "应用设置",
                onTap: _navigateToSettingScreen,
              ),
              _buildFunctionTile(
                icon: Icons.library_books_rounded,
                title: "题库管理",
                onTap: _navigateToBankManagerScreen,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFunctionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: _accentColor.withOpacity(0.1),
        highlightColor: _accentColor.withOpacity(0.05),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16), // 调整内边距
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8), // 缩小图标容器
                decoration: BoxDecoration(
                  color: _accentColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 20, color: _accentColor), // 缩小图标
              ),
              const SizedBox(width: 12), // 调整间距
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15, // 缩小标题
                    color: _textPrimary,
                    fontWeight: FontWeight.w500, // 调整字重
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: _textSecondary,
                size: 20, // 缩小图标
              ),
            ],
          ),
        ),
      ),
    );
  }
  // 导航方法
  ImageProvider _getAvatarImage() {
    return StudyData.instance.getAvatar() == null
        ? const AssetImage("assets/logo.png")
        : FileImage(File(StudyData.instance.getAvatar()!));
  }
  void _navigateToPersonalScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PersonalScreen(title: '')),
    );
    setState(() {});
  }

  void _navigateToSettingScreen() {
    Navigator.push(
      context,
      CupertinoPageRoute(builder: (context) => const SettingScreen()),
    );
  }

  void _navigateToBankManagerScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const BankManagerScreen(title: '')),
    );
    setState(() {});
  }
}


