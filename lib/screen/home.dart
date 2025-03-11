import 'dart:io';
import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/screen/about.dart';
import 'package:flutter_application_1/screen/bank_choose.dart';
import 'package:flutter_application_1/screen/bank_manager.dart';
import 'package:flutter_application_1/screen/intelligent_setting.dart';
import 'package:flutter_application_1/screen/mode.dart';
import 'package:flutter_application_1/screen/personal.dart';
import 'package:flutter_application_1/screen/question.dart';
import 'package:flutter_application_1/screen/wrong_question.dart';
import 'package:flutter_application_1/tool/page_intent_trans.dart';
import 'package:flutter_application_1/tool/question_bank.dart';
import 'package:flutter_application_1/tool/question_controller.dart';
import 'package:flutter_application_1/tool/study_data.dart';
import 'package:flutter_application_1/tool/wrong_question_book.dart';
import 'package:latext/latext.dart';
import 'package:page_transition/page_transition.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

// 全局样式配置
class AppTheme {
  static const primaryColor = Color(0xFF6A88E6);
  static const secondaryColor = Color(0xFF8E49E2);
  static const warningColor = Color(0xFFFFA726);
  static const successColor = Color(0xFF4CAF50);
  static const textPrimary = Color(0xFF2D2D3A);
  static const textSecondary = Color(0xFF6E6E8A);

  static const backgroundGradient = LinearGradient(
    colors: [Color(0xFFF8FAFF), Color(0xFFF2F6FF)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const cardShadow = BoxShadow(
    color: Colors.black12,
    blurRadius: 8,
    offset: Offset(0, 4),
  );

  static BorderRadius cardBorderRadius = BorderRadius.circular(16);
}

// 通用组件
class CommonComponents {
  static Widget buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }

  static Widget buildCommonCard(Widget child) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppTheme.cardBorderRadius,
        boxShadow: [AppTheme.cardShadow],
      ),
      child: child,
    );
  }

  static Widget buildIconButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(icon, color: AppTheme.primaryColor),
            onPressed: onPressed,
          ),
        ),
        const SizedBox(height: 8),
        Text(label,
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12)),
      ],
    );
  }
}

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '学习平台',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFFF8FAFF),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 1;
  final PageController _pageController = PageController(initialPage: 1);

  final List<Widget> _pages = const [
    CommunityPage(),
    MainHomePage(),
    ProfilePage(),
  ];

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent, // 透明状态栏
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: AppTheme.primaryColor, // 系统导航栏背景色
          systemNavigationBarIconBrightness: Brightness.light, // 导航键白色
        ),
        child: Scaffold(
          extendBodyBehindAppBar: true,
          body: PageView(
            controller: _pageController,
            children: _pages,
            onPageChanged: (index) => setState(() => _currentIndex = index),
          ),
          bottomNavigationBar: CurvedNavigationBar(
            index: _currentIndex,
            height: 60,
            color: AppTheme.primaryColor,
            backgroundColor: Colors.transparent,
            animationDuration: const Duration(milliseconds: 300),
            items: const [
              Icon(Icons.analytics, color: Colors.white),
              Icon(Icons.home, color: Colors.white),
              Icon(Icons.person, color: Colors.white),
            ],
            onTap: _onTabTapped,
          ),
        ));
  }
}

// 社区页面
class CommunityPage extends StatelessWidget {
  const CommunityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 160, // 统一头部高度
            flexibleSpace: _buildProfileHeader(),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(12),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildCompactStats(),
                const SizedBox(height: 16),
                _buildTrendChart(),
                const SizedBox(height: 16),
                _buildRankingList(),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return FlexibleSpaceBar(
      background: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('学习社区',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                  )),
              const SizedBox(height: 8),
              Text('当前活跃用户：1,238人',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactStats() {
    return CommonComponents.buildCommonCard(
      const Padding(
        padding: EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _CompactStatItem(value: '356', label: '今日讨论'),
            _CompactStatItem(value: '89', label: '热门话题'),
            _CompactStatItem(value: '2.3K', label: '累计互动'),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendChart() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text('学习趋势',
              style: TextStyle(
                fontSize: 15,
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w500,
              )),
        ),
        const SizedBox(height: 8),
        CommonComponents.buildCommonCard(
          SizedBox(
            height: 200,
            child: LineChart(_buildChartData()),
          ),
        ),
      ],
    );
  }

  Widget _buildRankingList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text('学霸排行榜',
              style: TextStyle(
                fontSize: 15,
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w500,
              )),
        ),
        const SizedBox(height: 8),
        CommonComponents.buildCommonCard(
          Column(
            children: [
              _buildRankItem('李同学', '128小时', 1),
              _buildDivider(),
              _buildRankItem('王同学', '115小时', 2),
              _buildDivider(),
              _buildRankItem('张同学', '103小时', 3),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRankItem(String name, String time, int rank) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      leading: Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Text('$rank',
            style: const TextStyle(
              color: AppTheme.primaryColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            )),
      ),
      title: Text(name,
          style: const TextStyle(
            fontSize: 14,
            color: AppTheme.textPrimary,
          )),
      trailing: Text(time,
          style: const TextStyle(
            fontSize: 13,
            color: AppTheme.textSecondary,
          )),
      minLeadingWidth: 24,
    );
  }

  // 图表数据构建方法
  LineChartData _buildChartData() {
    return LineChartData(
      lineBarsData: [
        LineChartBarData(
          spots: List.generate(
              7, (i) => FlSpot(i.toDouble(), Random().nextDouble() * 10)),
          color: AppTheme.primaryColor,
          barWidth: 2,
          isCurved: true,
          dotData: const FlDotData(show: false), // 不显示数据点
          belowBarData: BarAreaData(show: false),
        ),
      ],
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false, // 只显示水平网格线
        getDrawingHorizontalLine: (value) => FlLine(
          color: Colors.grey.withOpacity(0.2),
          strokeWidth: 1,
        ),
      ),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) => Text(
              '周${value.toInt() + 1}',
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ),
        leftTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
      ),
      borderData: FlBorderData(show: false),
    );
  }

// 统一分隔线构建方法
  Widget _buildDivider() {
    return Divider(
      height: 0.5,
      thickness: 0.5,
      indent: 16, // 左侧缩进
      endIndent: 16, // 右侧缩进
      color: Colors.grey.withOpacity(0.2),
    );
  }
}

// 统一复用组件
class _CompactStatItem extends StatelessWidget {
  final String value;
  final String label;

  const _CompactStatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            )),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            )),
      ],
    );
  }
}

class _PlanItem extends StatelessWidget {
  final String title;
  final double progress;

  const _PlanItem({required this.title, required this.progress});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LaTexT(
          laTeXCode: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey[200],
          valueColor: const AlwaysStoppedAnimation(AppTheme.primaryColor),
          minHeight: 4,
        ),
      ],
    );
  }
}

// 主界面
class MainHomePage extends StatefulWidget {
  const MainHomePage({super.key});

  @override
  State<StatefulWidget> createState() => _MainHomePageState();
}

class _MainHomePageState extends State<MainHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 160,
            flexibleSpace: _buildProfileHeader(),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(12),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildPracticeSection(context), // 修改后的练习入口模块
                const SizedBox(height: 16),
                _buildQuickActions(context),
                const SizedBox(height: 8),
                _buildLearningPlan(),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressButton(BuildContext context) {
    var value = QuestionGroupController.instances.getDayProgress();
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 100,
          height: 100,
          child: CircularProgressIndicator(
            value: value,
            strokeWidth: 6,
            backgroundColor: Colors.grey.withOpacity(0.2),
            valueColor: const AlwaysStoppedAnimation(AppTheme.primaryColor),
          ),
        ),
        Material(
          color: AppTheme.primaryColor,
          shape: const CircleBorder(),
          child: InkWell(
            borderRadius: BorderRadius.circular(40),
            onTap: () {
              var banksIsds = QuestionBank.getAllLoadedQuestionBankIds();
              print(banksIsds);
              if (QuestionGroupController.instances.controllers.isEmpty &&
                  banksIsds.isNotEmpty) {
                TDToast.showSuccess("已完成今日计划", context: context);
              } else {
                StudyData.instance.studyType = StudyType.recommandMode;
                if (banksIsds.isEmpty) {
                  PageIntentTrans.map[PageIntentTrans.bankChooseTarget] =
                      () => const QuestionScreen(title: '');
                  Navigator.push(
                    context,
                    PageTransition(
                      type: PageTransitionType.rightToLeftPop,
                      childCurrent: widget,
                      alignment: const Alignment(10, 20),
                      child: const BankChooseScreen(),
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                    ),
                  ).whenComplete(() => QuestionGroupController.instances
                      .update()
                      .whenComplete(() => setState(() {})));
                  return;
                } else {
                  Navigator.push(
                    context,
                    PageTransition(
                      type: PageTransitionType.rightToLeftPop,
                      childCurrent: widget,
                      alignment: const Alignment(10, 20),
                      child: const QuestionScreen(
                        title: '',
                      ),
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                    ),
                  ).whenComplete(() => QuestionGroupController.instances
                      .update()
                      .whenComplete(() => setState(() {})));
                }
              }
            },
            child: Container(
              width: 72,
              height: 72,
              alignment: Alignment.center,
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.play_arrow_rounded, color: Colors.white, size: 32),
                  SizedBox(height: 4),
                  Text("开始",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

// 修改后的练习入口模块
  Widget _buildPracticeSection(BuildContext context) {
    return CommonComponents.buildCommonCard(
      Padding(
        padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: _buildProgressButton(context),
            ),
            Container(
              height: 80,
              margin: const EdgeInsets.only(right: 20),
              decoration: BoxDecoration(
                  border: Border(
                      right: BorderSide(
                          color: Colors.grey.withOpacity(0.3), width: 1))),
            ),
            Expanded(
              flex: 1,
              child: Align(
                // 整体右对齐容器
                alignment: Alignment.centerRight,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start, // 内部元素左对齐
                  children: [
                    _buildStatRow(Icons.today, "今日学习", "3.2h", "/5.0h目标"),
                    const SizedBox(height: 16),
                    _buildStatRow(
                        Icons.assignment_turned_in, "本周进度", "28章", "80%"),
                    const SizedBox(height: 16),
                    _buildStatRow(Icons.insights, "正确率", "+5.2%", "周同比"),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

// 更新后的统计行组件
  Widget _buildStatRow(
      IconData icon, String title, String value, String subText) {
    return SizedBox(
      width: 180, // 固定统计项宽度
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 16, color: AppTheme.primaryColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, // 文本左对齐
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary.withOpacity(0.8))),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(value,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary)),
                    const SizedBox(width: 6),
                    Text(subText,
                        style: TextStyle(
                            fontSize: 10,
                            color: AppTheme.textSecondary.withOpacity(0.6))),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return FlexibleSpaceBar(
      background: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('累计学习时长',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                  )),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('128 小时',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 24,
                        fontWeight: FontWeight.w300,
                      )),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text("Lv.12 学力",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500)),
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 4,
      childAspectRatio: 0.9,
      children: [
        CommonComponents.buildIconButton(
          icon: Icons.auto_awesome_motion,
          label: '智能刷题',
          onPressed: () {
            Navigator.push(
              context,
              PageTransition(
                type: PageTransitionType.rightToLeftPop,
                childCurrent: widget,
                alignment: const Alignment(10, 20),
                child: const IntelligentSettingScreen(),
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
              ),
            ).whenComplete(() => QuestionGroupController.instances
                .update()
                .whenComplete(() => setState(() {})));
          },
        ),
        CommonComponents.buildIconButton(
          icon: Icons.play_circle_outline,
          label: '顺序练习',
          onPressed: () {
            PageIntentTrans.map[PageIntentTrans.bankChooseTarget] =
                () => const ModeScreen(
                      title: '',
                    );
            Navigator.push(
              context,
              PageTransition(
                type: PageTransitionType.rightToLeftPop,
                childCurrent: widget,
                alignment: const Alignment(10, 20),
                child: const BankChooseScreen(),
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
              ),
            ).whenComplete(() => QuestionGroupController.instances
                .update()
                .whenComplete(() => setState(() {})));
          },
        ),
        CommonComponents.buildIconButton(
          icon: Icons.assignment_outlined,
          label: '错题本',
          onPressed: () {
            Navigator.push(
              context,
              PageTransition(
                type: PageTransitionType.rightToLeftPop,
                childCurrent: widget,
                alignment: const Alignment(10, 20),
                child: const WrongQuestionScreen(),
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
              ),
            );
          },
        ),
        CommonComponents.buildIconButton(
          icon: Icons.bar_chart,
          label: '学习报告',
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildLearningPlan() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text('学习计划',
              style: TextStyle(
                fontSize: 15,
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w500,
              )),
        ),
        const SizedBox(height: 8),
        CommonComponents.buildCommonCard(
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                ...(() {
                  if (QuestionGroupController.instances.controllers.isEmpty) {
                    return [
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: Text(
                            '🎉 恭喜你，所有学习计划已完成！\n继续保持哦~',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.textPrimary,
                              height: 1.6,
                            ),
                          ),
                        ),
                      )
                    ];
                  }

                  var arr = [];
                  for (var c in QuestionGroupController.instances.controllers) {
                    var data = c.getSectionUserData(c.currentLearn!);
                    arr.add(_PlanItem(
                        title: c.currentLearn!.title,
                        progress: data.alreadyCompleteQuestion /
                            data.allNeedCompleteQuestion));
                    arr.add(const SizedBox(height: 12));
                  }
                  // 移除最后一个间距
                  if (arr.isNotEmpty) arr.removeLast();
                  return arr;
                }()),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// 个人中心界面
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 160, // 降低头部高度
            flexibleSpace: _buildProfileHeader(),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(12), // 减少整体边距
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildProfileStats(),
                const SizedBox(height: 16),
                _buildAccountSettings(context),
                const SizedBox(height: 16),
                _buildSystemSettings(context),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return FlexibleSpaceBar(
      background: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 32, // 调整头像尺寸
                backgroundImage:
                    FileImage(File(StudyData.instance.avatar ?? '')),
              ),
              const SizedBox(height: 12), // 减少间距
              Text(StudyData.instance.userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20, // 调小字体
                    fontWeight: FontWeight.w500,
                  )),
              Text(StudyData.instance.sign,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14, // 调小字体
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountSettings(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Text(
            '账户设置',
            style: TextStyle(
              fontSize: 15, // 调小标题字体
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        CommonComponents.buildCommonCard(
          Column(
            children: [
              _buildCompactListTile(
                icon: Icons.person_outline,
                title: '个人资料',
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const PersonalScreen(
                              title: '',
                            ))),
              ),
              _buildDivider(),
              _buildCompactListTile(
                icon: Icons.security_outlined,
                title: '账户安全',
              ),
              _buildDivider(),
              _buildCompactListTile(
                icon: Icons.notifications_outlined,
                title: '通知设置',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompactListTile({
    required IconData icon,
    required String title,
    VoidCallback? onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 6), // 紧凑内边距
      leading: Icon(icon, size: 20, color: AppTheme.textPrimary), // 调小图标
      title: Text(title,
          style: const TextStyle(
            fontSize: 14, // 调小文字尺寸
            color: AppTheme.textPrimary,
          )),
      trailing: const Icon(Icons.chevron_right,
          size: 18, // 调小箭头
          color: AppTheme.textSecondary),
      minLeadingWidth: 24, // 减少图标间距
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 0.5, // 更细的分割线
      thickness: 0.5,
      indent: 48, // 对齐文字内容
      color: Colors.grey[300],
    );
  }

  Widget _buildSystemSettings(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Text('系统设置',
              style: TextStyle(
                fontSize: 15,
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w500,
              )),
        ),
        CommonComponents.buildCommonCard(
          Column(
            children: [
              _buildCompactListTile(
                icon: Icons.color_lens_outlined,
                title: '主题设置',
              ),
              _buildDivider(),
              _buildCompactListTile(
                icon: Icons.help_outline,
                title: '帮助中心',
              ),
              _buildDivider(),
              _buildCompactListTile(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BankManagerScreen(
                        title: '',
                      ),
                    ),
                  );
                },
                icon: Icons.menu_book_sharp,
                title: '题库管理',
              ),
              _buildDivider(),
              _buildCompactListTile(
                onTap: () {
                  QuestionBank.clearAllCache();
                  WrongQuestionBook.instance.clearData();
                  TDToast.showSuccess("清理完毕", context: context);
                },
                icon: Icons.cached_outlined,
                title: '数据清理',
              ),
              _buildDivider(),
              _buildCompactListTile(
                icon: Icons.info_outline,
                title: '关于我们',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AboutScreen(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileStats() {
    return CommonComponents.buildCommonCard(
      const Padding(
        padding: EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _CompactStatItem(value: '128天', label: '学习天数'),
            _CompactStatItem(value: '89%', label: '平均正确率'),
            _CompactStatItem(value: '2560', label: '学习积分'),
          ],
        ),
      ),
    );
  }
}

// 复用组件
class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            )),
        Text(label,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
            )),
      ],
    );
  }
}

class _GoalProgress extends StatelessWidget {
  final String title;
  final double progress;

  const _GoalProgress({required this.title, required this.progress});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey[200],
          valueColor: const AlwaysStoppedAnimation(AppTheme.primaryColor),
        ),
      ],
    );
  }
}
