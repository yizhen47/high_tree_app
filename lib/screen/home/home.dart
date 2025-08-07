// ignore_for_file: unused_element

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/screen/about.dart';
import 'package:flutter_application_1/screen/bank_management.dart';
import 'package:flutter_application_1/screen/home/community.dart';
import 'package:flutter_application_1/screen/home/main_home.dart';
import 'package:flutter_application_1/screen/personal.dart';
import 'package:flutter_application_1/tool/question/question_bank.dart';
import 'package:flutter_application_1/tool/study_data.dart';
import 'package:flutter_application_1/tool/question/wrong_question_book.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

// 添加文本缩放控制器，解决系统字体大小设置导致的UI错乱问题
class TextScaler {
  // 静态实例，用于全局访问
  static final TextScaler _instance = TextScaler._internal();
  static TextScaler get instance => _instance;
  
  // 默认缩放因子
  static const double defaultScaleFactor = 1.0;
  // 最大允许的缩放因子，防止UI过度膨胀
  static const double maxScaleFactor = 1.3;
  
  // 构造函数私有化
  TextScaler._internal();
  
  // 获取调整后的字体大小
  double getScaledFontSize(BuildContext context, double fontSize) {
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;
    // 限制最大缩放效果，防止UI错乱
    final adjustedScaleFactor = textScaleFactor > maxScaleFactor ? maxScaleFactor : textScaleFactor;
    return fontSize * (adjustedScaleFactor / defaultScaleFactor);
  }
  
  // 获取缩放后的TextStyle
  TextStyle getScaledTextStyle(BuildContext context, TextStyle style) {
    return style.copyWith(
      fontSize: style.fontSize != null 
        ? getScaledFontSize(context, style.fontSize!)
        : null,
    );
  }
  
  // 获取文本缩放因子
  double getTextScaleFactor(BuildContext context) {
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;
    return textScaleFactor > maxScaleFactor ? maxScaleFactor : textScaleFactor;
  }
}

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
  
  // 基础字体大小 - 这些值会根据系统字体大小设置进行适当缩放
  static const double fontSizeTiny = 10.0;
  static const double fontSizeSmall = 12.0;
  static const double fontSizeRegular = 14.0;
  static const double fontSizeMedium = 16.0;
  static const double fontSizeLarge = 18.0;
  
  // 获取调整后的标题文本样式
  static TextStyle getTitleStyle(BuildContext context) {
    return TextStyle(
      fontSize: TextScaler.instance.getScaledFontSize(context, fontSizeLarge),
      fontWeight: FontWeight.bold,
      color: textPrimary,
    );
  }
  
  // 获取调整后的副标题文本样式
  static TextStyle getSubtitleStyle(BuildContext context) {
    return TextStyle(
      fontSize: TextScaler.instance.getScaledFontSize(context, fontSizeMedium),
      fontWeight: FontWeight.w500,
      color: textPrimary,
    );
  }
  
  // 获取调整后的正文文本样式
  static TextStyle getBodyStyle(BuildContext context) {
    return TextStyle(
      fontSize: TextScaler.instance.getScaledFontSize(context, fontSizeRegular),
      color: textPrimary,
    );
  }
  
  // 获取调整后的小号文本样式
  static TextStyle getSmallStyle(BuildContext context) {
    return TextStyle(
      fontSize: TextScaler.instance.getScaledFontSize(context, fontSizeSmall),
      color: textSecondary,
    );
  }
  
  // 获取调整后的特小号文本样式
  static TextStyle getTinyStyle(BuildContext context) {
    return TextStyle(
      fontSize: TextScaler.instance.getScaledFontSize(context, fontSizeTiny),
      color: textSecondary,
    );
  }
}

// 通用组件
class CommonComponents {
  static Widget buildSectionTitle(String title, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        title,
        style: AppTheme.getTitleStyle(context),
      ),
    );
  }

  static Widget buildCommonCard(Widget child) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppTheme.cardBorderRadius,
        boxShadow: const [AppTheme.cardShadow],
      ),
      child: child,
    );
  }

  static Widget buildIconButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required BuildContext context,
  }) {
    // 获取字体缩放因子
    final fontScaleFactor = TextScaler.instance.getTextScaleFactor(context);
    // 动态计算图标容器大小，增加基础大小和缩放比例
    final containerSize = 56.0 * (0.95 + fontScaleFactor * 0.15);
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: containerSize,
          height: containerSize,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(icon, color: AppTheme.primaryColor),
            onPressed: onPressed,
            padding: const EdgeInsets.all(0), // 移除内边距使图标居中
            iconSize: containerSize * 0.5, // 增加图标比例
          ),
        ),
        SizedBox(height: 6 * fontScaleFactor), // 增加间距
        Text(
          label,
          style: TextStyle(
            fontSize: TextScaler.instance.getScaledFontSize(context, 12), // 增加文字大小
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500, // 增加字重，提高可见度
          ),
          textAlign: TextAlign.center, // 确保文本居中
          maxLines: 1,
          overflow: TextOverflow.ellipsis, // 处理长文本
        ),
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
        value: const SystemUiOverlayStyle(
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


// 个人中心界面
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120, // 进一步减小顶部高度
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
    // 获取用户学习等级
    final studyLevel = (StudyData.instance.studyMinute / 10).ceil();
    final wrongQuestions = WrongQuestionBook.instance.getWrongQuestionIds().length;
    final totalQuestions = WrongQuestionBook.instance.questionBox.length;
    final accuracyRate = totalQuestions > 0 ? 
      ((totalQuestions - wrongQuestions) / totalQuestions * 100).toInt() : 0;
    
    return FlexibleSpaceBar(
      background: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 用户信息
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        StudyData.instance.userName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.military_tech_outlined,
                              color: Colors.white,
                              size: 12,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Lv.$studyLevel',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  // 右侧头像
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: CircleAvatar(
                      radius: 20,
                      backgroundImage: StudyData.instance.avatar == null || StudyData.instance.avatar!.isEmpty
                          ? const AssetImage("assets/logo.png")
                          : FileImage(File(StudyData.instance.avatar!)) as ImageProvider,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildProfileStatItem({required String label, required String value}) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14, // 减小字体大小
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 3), // 减少垂直间距
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 10, // 减小字体大小
          ),
        ),
      ],
    );
  }
  
  Widget _buildProfileDivider() {
    return Container(
      height: 24,
      width: 1,
      color: Colors.white.withOpacity(0.2),
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
                      builder: (context) => const BankManagementScreen(),
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
                  StudyData.instance.sharedPreferences!.clear();
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
    // 计算学习天数 - 使用实际数据
    final studyDays = StudyData.instance.studyCount.toString();
    
    // 计算平均正确率 - 使用实际数据
    final wrongQuestions = WrongQuestionBook.instance.getWrongQuestionIds().length;
    final totalQuestions = WrongQuestionBook.instance.questionBox.length;
    final averageAccuracy = totalQuestions > 0 ? 
        "${((totalQuestions - wrongQuestions) / totalQuestions * 100).toInt()}%" : 
        "0%";
    
    // 学习积分基于学习时间和次数计算 - 使用实际数据
    final studyPoints = (StudyData.instance.studyMinute * 10 + StudyData.instance.studyCount * 5).toString();
    
    return CommonComponents.buildCommonCard(
      Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _CompactStatItem(value: '$studyDays天', label: '学习天数'),
            _CompactStatItem(value: averageAccuracy, label: '平均正确率'),
            _CompactStatItem(value: studyPoints, label: '学习积分'),
          ],
        ),
      ),
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
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}

