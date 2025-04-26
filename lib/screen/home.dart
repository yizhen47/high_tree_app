// ignore_for_file: unused_element

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
import 'package:flutter_application_1/screen/learning_report.dart';
import 'package:flutter_application_1/tool/hotspot_attendance.dart';
import 'package:flutter_application_1/tool/page_intent_trans.dart';
import 'package:flutter_application_1/tool/question/question_bank.dart';
import 'package:flutter_application_1/tool/question/question_controller.dart';
import 'package:flutter_application_1/tool/study_data.dart';
import 'package:flutter_application_1/tool/question/wrong_question_book.dart';
import 'package:latext/latext.dart';
import 'package:page_transition/page_transition.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import 'package:flutter_application_1/tool/statistics_manager.dart';

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

// 社区页面
class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> with SingleTickerProviderStateMixin {
  // 临时变量用于切换学生/教师角色 (在实际应用中，应从用户账户信息获取)
  bool isTeacher = false;
  
  // 选项卡控制器 (用于学生视图的聊天室/问答选项卡)
  late TabController _tabController;
  
  // 实际签到数据，不再使用硬编码的测试数据
  final List<Map<String, dynamic>> _attendanceList = [];
  // 模拟聊天数据
  final List<Map<String, dynamic>> _chatMessages = [
    {'sender': '李老师', 'message': '同学们，今天我们讨论一下昨天的习题', 'time': '10:30', 'isTeacher': true},
    {'sender': '王同学', 'message': '老师，我对第三题有疑问', 'time': '10:32', 'isTeacher': false},
    {'sender': '张同学', 'message': '我也是，那个公式应用有点不明白', 'time': '10:33', 'isTeacher': false},
    {'sender': '李老师', 'message': '好的，这个问题很好，我来讲解一下', 'time': '10:35', 'isTeacher': true},
    {'sender': '李老师', 'message': '这个公式的关键在于理解初始条件...', 'time': '10:36', 'isTeacher': true},
    {'sender': '赵同学', 'message': '谢谢老师，我明白了！', 'time': '10:40', 'isTeacher': false},
  ];
  
  // 模拟问答数据
  final List<Map<String, dynamic>> _qaItems = [
    {
      'question': '如何理解微分方程的特解和通解的关系？',
      'asker': '王同学',
      'time': '昨天',
      'answers': 3,
      'solved': true
    },
    {
      'question': '二次函数的顶点式与一般式如何转换？',
      'asker': '李同学',
      'time': '今天',
      'answers': 2,
      'solved': false
    },
    {
      'question': '向量的点乘和叉乘有什么几何意义？',
      'asker': '张同学',
      'time': '2天前',
      'answers': 5,
      'solved': true
    },
    {
      'question': '如何判断一个数列是否收敛？',
      'asker': '赵同学',
      'time': '3天前',
      'answers': 4,
      'solved': true
    },
  ];
  
  
  // 模拟当前课程信息
  final Map<String, dynamic> _currentClass = {
    'name': '高等数学（上）',
    'teacher': '李教授',
    'time': '周一 8:30-10:00',
    'room': '理教楼 301',
    'studentCount': 42,
    'attendedCount': 0, // 初始化为0，将根据实际签到人数更新
    'id': 'MATH101',
  };
  
  // Hotspot attendance manager
  final HotspotAttendanceManager _attendanceManager = HotspotAttendanceManager();
  
  // Status message for attendance
  String _attendanceStatus = "";
  bool _attendanceInProgress = false;
  
  // 新增：导出功能是否可用
  bool _canExportAttendance = false;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Set up attendance manager callbacks
    _attendanceManager.onStatusChanged = (status) {
      setState(() {
        _attendanceStatus = status;
      });
    };
    
    _attendanceManager.onStudentAttended = (studentData) {
      // Update the attendance list with real data
      setState(() {
        // Find if student already exists in list
        final existingIndex = _attendanceList.indexWhere(
          (item) => item['name'] == studentData.studentName
        );
        
        if (existingIndex >= 0) {
          // Update existing student
          _attendanceList[existingIndex]['status'] = '已签到';
          _attendanceList[existingIndex]['time'] = studentData.getFormattedTime();
        } else {
          // Add new student
          _attendanceList.add({
            'name': studentData.studentName,
            'status': '已签到',
            'time': studentData.getFormattedTime(),
            'streak': 1, // Default streak for new students
          });
        }
        
        // Update the attended count
        _currentClass['attendedCount'] = _attendanceList.where(
          (item) => item['status'] == '已签到'
        ).length;
        
        // Enable export if we have attendance data
        _canExportAttendance = _attendanceList.isNotEmpty;
      });
    };
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _attendanceManager.stopTeacherMode();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            flexibleSpace: _buildHeader(),
            actions: [
              // 切换角色按钮 (仅用于演示)
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: IconButton(
                  icon: Icon(
                    isTeacher ? Icons.school : Icons.person,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      isTeacher = !isTeacher;
                    });
                  },
                ),
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.all(12),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildCurrentClassCard(),
                if (_attendanceStatus.isNotEmpty)
                  _buildAttendanceStatusCard(),
                const SizedBox(height: 16),
                // 根据角色显示不同内容
                if (isTeacher)
                  _buildTeacherView()
                else
                  _buildStudentView(),
              ]),
            ),
          ),
        ],
      ),
      // 学生视图底部添加消息输入框
      bottomNavigationBar: !isTeacher && _tabController.index == 0
          ? _buildMessageInput()
          : null,
    );
  }
  
  // Build status card for attendance operations
  Widget _buildAttendanceStatusCard() {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: CommonComponents.buildCommonCard(
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _attendanceInProgress 
                        ? Icons.wifi_tethering 
                        : Icons.info_outline,
                    color: _attendanceInProgress 
                        ? AppTheme.primaryColor 
                        : Colors.orange,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _attendanceStatus,
                      style: TextStyle(
                        fontSize: 12,
                        color: _attendanceInProgress 
                            ? AppTheme.textPrimary 
                            : Colors.orange,
                      ),
                    ),
                  ),
                  if (_attendanceInProgress)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 顶部标题
                  Text(
                    isTeacher ? '班级管理' : '课堂互动',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // 当前状态
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      isTeacher 
                          ? '当前上课: ${_currentClass['name']}'
                          : '${_currentClass['name']} - ${_currentClass['teacher']}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                      ),
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
  
  // 当前课程卡片
  Widget _buildCurrentClassCard() {
    return CommonComponents.buildCommonCard(
      Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.class_outlined,
                    color: AppTheme.primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentClass['name'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_currentClass['time']} | ${_currentClass['room']}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // 学生显示签到按钮，老师显示出勤率和开始/结束签到按钮
                if (!isTeacher)
                  _buildStudentAttendanceButton()
                else
                  _buildTeacherAttendanceButtons()
              ],
            ),
            if (isTeacher)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildAttendanceStatItem(
                      icon: Icons.people,
                      value: '${_currentClass['studentCount']}',
                      label: '总人数',
                    ),
                    _buildAttendanceStatItem(
                      icon: Icons.check_circle,
                      value: '${_currentClass['attendedCount']}',
                      label: '已到',
                      color: Colors.green,
                    ),
                    _buildAttendanceStatItem(
                      icon: Icons.cancel,
                      value: '${_currentClass['studentCount'] - _currentClass['attendedCount']}',
                      label: '未到',
                      color: Colors.orange,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  // Student attendance button
  Widget _buildStudentAttendanceButton() {
    return ElevatedButton(
      onPressed: _attendanceInProgress 
          ? null // Disable button while operation is in progress
          : () async {
              // Start the sign-in process
              setState(() {
                _attendanceInProgress = true;
                _attendanceStatus = "正在查找签到热点...";
              });
              
              // Attempt to sign in
              final result = await _attendanceManager.studentSignIn(_currentClass['id']);
              
              // Update UI based on result
              setState(() {
                _attendanceInProgress = false;
                _attendanceStatus = result.message;
                
                if (result.success) {
                  // Update local attendance status
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('签到成功!'),
                      backgroundColor: AppTheme.successColor,
                    ),
                  );
                  
                  // Clear status message after a few seconds
                  Future.delayed(const Duration(seconds: 5), () {
                    if (mounted) {
                      setState(() {
                        _attendanceStatus = "";
                      });
                    }
                  });
                }
              });
            },
      style: ElevatedButton.styleFrom(
        backgroundColor: _attendanceManager.isSessionActive() 
            ? Colors.orange  // Show different color if already in progress
            : AppTheme.primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        textStyle: const TextStyle(fontSize: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(_attendanceInProgress ? '签到中...' : '签到'),
    );
  }
  
  // Teacher attendance buttons
  Widget _buildTeacherAttendanceButtons() {
    // If attendance session is active, show stop button
    if (_attendanceManager.isSessionActive()) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.people, size: 12, color: Colors.green),
                const SizedBox(width: 4),
                Text(
                  '${_currentClass['attendedCount']}/${_currentClass['studentCount']}',
                  style: const TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _attendanceInProgress 
                ? null 
                : () async {
                    setState(() {
                      _attendanceInProgress = true;
                      _attendanceStatus = "正在结束签到...";
                    });
                    
                    await _attendanceManager.stopTeacherMode();
                    
                    setState(() {
                      _attendanceInProgress = false;
                      _attendanceStatus = "签到已结束";
                      _canExportAttendance = _attendanceList.isNotEmpty;
                      
                      // Clear status message after a few seconds
                      Future.delayed(const Duration(seconds: 5), () {
                        if (mounted) {
                          setState(() {
                            _attendanceStatus = "";
                          });
                        }
                      });
                    });
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              textStyle: const TextStyle(fontSize: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('结束签到'),
          ),
        ],
      );
    } else {
      // If no attendance session is active, show start button
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_canExportAttendance)
            IconButton(
              onPressed: _exportAttendanceData,
              icon: const Icon(Icons.file_download_outlined, size: 16),
              tooltip: '导出签到数据',
              color: AppTheme.primaryColor,
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(),
            ),
          ElevatedButton(
            onPressed: _attendanceInProgress 
                ? null 
                : () async {
                    setState(() {
                      _attendanceInProgress = true;
                      _attendanceStatus = "正在启动签到...";
                    });
                    
                    final success = await _attendanceManager.startTeacherMode(
                      _currentClass['id'],
                      _currentClass['teacher'],
                    );
                    
                    setState(() {
                      _attendanceInProgress = false;
                      if (success) {
                        _attendanceStatus = "签到已开始，学生可以通过WiFi签到";
                      } else {
                        _attendanceStatus = "启动签到失败";
                      }
                    });
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              textStyle: const TextStyle(fontSize: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('开始签到'),
          ),
        ],
      );
    }
  }
  
  // 新增：导出签到数据
  void _exportAttendanceData() async {
    if (_attendanceList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('没有可导出的签到数据'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    // 显示导出选项对话框
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('导出签到数据'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('请选择导出格式:'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.file_present_outlined, size: 18),
                  label: const Text('CSV'),
                  onPressed: () {
                    Navigator.pop(context);
                    _performExport('csv');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.code, size: 18),
                  label: const Text('JSON'),
                  onPressed: () {
                    Navigator.pop(context);
                    _performExport('json');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.secondaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('取消'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  // 执行实际的导出操作
  void _performExport(String format) async {
    try {
      String exportData;
      String extension;
      
      // 获取导出数据
      if (format == 'csv') {
        exportData = _attendanceManager.exportAttendanceDataAsCsv();
        extension = 'csv';
      } else {
        exportData = _attendanceManager.exportAttendanceDataAsJson();
        extension = 'json';
      }
      
      // 获取课程信息
      final sessionInfo = _attendanceManager.getSessionInfo();
      final classId = sessionInfo['classId'] ?? 'unknown';
      final dateStr = DateTime.now().toString().substring(0, 10);
      final fileName = 'attendance_${classId}_$dateStr.$extension';
      
      // 这里应该实现文件写入逻辑
      // 由于Flutter文件写入需要平台集成，这里只显示成功提示
      // 在实际应用中，应该使用path_provider和dart:io来写入文件
      
      // 显示导出成功提示
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('签到数据已导出为$extension格式'),
          backgroundColor: AppTheme.successColor,
          action: SnackBarAction(
            label: '查看',
            textColor: Colors.white,
            onPressed: () {
              // 显示预览对话框
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('签到数据预览 ($fileName)'),
                  content: SingleChildScrollView(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        exportData,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      child: const Text('关闭'),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('导出失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // 学生视图
  Widget _buildStudentView() {
    return Column(
      children: [
        // 选项卡标题
        TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primaryColor,
          tabs: const [
            Tab(text: '聊天室'),
            Tab(text: '问答区'),
          ],
        ),
        
        // 选项卡内容
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.5, // 设置适当的高度
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildChatRoom(),
              _buildQASection(),
            ],
          ),
        ),
      ],
    );
  }
  
  // 教师视图
  Widget _buildTeacherView() {
    return _buildAttendanceList();
  }
  
  // 聊天室
  Widget _buildChatRoom() {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 16),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _chatMessages.length,
      itemBuilder: (context, index) {
        final message = _chatMessages[index];
        final bool isTeacherMessage = message['isTeacher'] as bool;
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: isTeacherMessage 
                ? MainAxisAlignment.start 
                : MainAxisAlignment.end,
            children: [
              if (isTeacherMessage) ...[
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppTheme.primaryColor,
                  child: const Text('T', style: TextStyle(color: Colors.white, fontSize: 12)),
                ),
                const SizedBox(width: 8),
              ],
              
              Flexible(
                child: Column(
                  crossAxisAlignment: isTeacherMessage 
                      ? CrossAxisAlignment.start 
                      : CrossAxisAlignment.end,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2.0),
                      child: Text(
                        '${message['sender']} · ${message['time']}',
                        style: TextStyle(
                          fontSize: 10,
                          color: isTeacherMessage 
                              ? AppTheme.primaryColor 
                              : AppTheme.textSecondary,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isTeacherMessage 
                            ? AppTheme.primaryColor.withOpacity(0.1) 
                            : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        message['message'],
                        style: TextStyle(
                          fontSize: 13,
                          color: isTeacherMessage 
                              ? AppTheme.textPrimary 
                              : AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              if (!isTeacherMessage) ...[
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.grey[300],
                  child: Text(
                    message['sender'][0],
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
  
  // 问答区
  Widget _buildQASection() {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 16),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _qaItems.length,
      itemBuilder: (context, index) {
        final item = _qaItems[index];
        
        return CommonComponents.buildCommonCard(
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.question_answer,
                      size: 16,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item['question'],
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${item['asker']} · ${item['time']}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.comment,
                          size: 12,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${item['answers']}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: item['solved'] 
                                ? Colors.green.withOpacity(0.1) 
                                : Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            item['solved'] ? '已解决' : '待解答',
                            style: TextStyle(
                              fontSize: 10,
                              color: item['solved'] ? Colors.green : Colors.orange,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  // 签到列表 (教师视图)
  Widget _buildAttendanceList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '学生签到情况',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              // 添加操作按钮
              Row(
                children: [
                  if (_attendanceManager.isSessionActive())
                    IconButton(
                      onPressed: _showAddStudentDialog,
                      icon: const Icon(Icons.person_add_outlined, size: 18),
                      tooltip: '手动添加签到',
                      color: AppTheme.primaryColor,
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(8),
                    ),
                  if (_canExportAttendance)
                    IconButton(
                      onPressed: _exportAttendanceData,
                      icon: const Icon(Icons.file_download_outlined, size: 18),
                      tooltip: '导出签到数据',
                      color: AppTheme.primaryColor,
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(8),
                    ),
                  IconButton(
                    onPressed: () {
                      // 刷新签到列表
                      setState(() {});
                    },
                    icon: const Icon(Icons.refresh, size: 18),
                    tooltip: '刷新签到列表',
                    color: AppTheme.primaryColor,
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(8),
                  ),
                ],
              ),
            ],
          ),
        ),
        CommonComponents.buildCommonCard(
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    const Expanded(
                      flex: 3,
                      child: Text(
                        '学生',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                    const Expanded(
                      flex: 2,
                      child: Text(
                        '状态',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                    const Expanded(
                      flex: 2,
                      child: Text(
                        '时间',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                    const Expanded(
                      flex: 2,
                      child: Text(
                        '连续签到',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                    if (_attendanceManager.isSessionActive())
                      const SizedBox(width: 40),
                  ],
                ),
              ),
              const Divider(height: 1),
              if (_attendanceList.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32.0),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 36,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _attendanceManager.isSessionActive() 
                              ? '等待学生签到...' 
                              : '尚无签到数据',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (_attendanceManager.isSessionActive())
                          TextButton.icon(
                            onPressed: _showAddStudentDialog,
                            icon: const Icon(Icons.person_add_outlined, size: 16),
                            label: const Text('手动添加学生'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppTheme.primaryColor,
                            ),
                          ),
                      ],
                    ),
                  ),
                )
              else
                ...List.generate(
                  _attendanceList.length,
                  (index) => Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(
                                _attendanceList[index]['name'],
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(_attendanceList[index]['status']).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _attendanceList[index]['status'],
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _getStatusColor(_attendanceList[index]['status']),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                _attendanceList[index]['time'] ?? '-',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                '${_attendanceList[index]['streak']}天',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: _attendanceList[index]['streak'] > 0 
                                      ? FontWeight.w500 
                                      : FontWeight.normal,
                                  color: _attendanceList[index]['streak'] > 5 
                                      ? AppTheme.primaryColor 
                                      : AppTheme.textSecondary,
                                ),
                              ),
                            ),
                            // 如果签到会话活跃，显示删除按钮
                            if (_attendanceManager.isSessionActive())
                              SizedBox(
                                width: 32,
                                child: IconButton(
                                  onPressed: () {
                                    // 确认删除对话框
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('删除确认'),
                                        content: Text('确定要删除${_attendanceList[index]['name']}的签到记录吗？'),
                                        actions: [
                                          TextButton(
                                            child: const Text('取消'),
                                            onPressed: () => Navigator.pop(context),
                                          ),
                                          TextButton(
                                            child: const Text('删除'),
                                            onPressed: () {
                                              // 获取学生ID
                                              final studentId = _attendanceManager
                                                  .getAttendedStudents()
                                                  .entries
                                                  .firstWhere(
                                                    (entry) => entry.value.studentName == _attendanceList[index]['name'],
                                                    orElse: () => MapEntry('', StudentAttendanceData(
                                                      studentId: '',
                                                      studentName: '',
                                                      classId: '',
                                                      timestamp: 0,
                                                      deviceInfo: '',
                                                    )),
                                                  )
                                                  .key;
                                                  
                                              if (studentId.isNotEmpty) {
                                                _attendanceManager.removeAttendance(studentId);
                                                
                                                // 从UI列表中移除
                                                setState(() {
                                                  _attendanceList.removeAt(index);
                                                  _currentClass['attendedCount'] = _attendanceList.where(
                                                    (item) => item['status'] == '已签到'
                                                  ).length;
                                                });
                                              }
                                              
                                              Navigator.pop(context);
                                            },
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.close, size: 16),
                                  color: Colors.grey,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (index < _attendanceList.length - 1)
                        const Divider(height: 1, indent: 16, endIndent: 16),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
  
  // 签到状态颜色
  Color _getStatusColor(String status) {
    switch (status) {
      case '已签到':
        return Colors.green;
      case '未签到':
        return Colors.red;
      case '请假':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
  
  // 考勤统计项
  Widget _buildAttendanceStatItem({
    required IconData icon,
    required String value,
    required String label,
    Color? color,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          size: 18,
          color: color ?? AppTheme.textPrimary,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color ?? AppTheme.textPrimary,
          ),
        ),
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
  
  // 消息输入框
  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -1),
            blurRadius: 3,
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            color: Colors.grey,
            onPressed: () {},
          ),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: '发送消息...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                border: InputBorder.none,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            color: AppTheme.primaryColor,
            onPressed: () {
              // 发送消息
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('消息已发送'),
                  backgroundColor: AppTheme.primaryColor,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // 新增：添加学生签到对话框
  void _showAddStudentDialog() {
    final TextEditingController idController = TextEditingController();
    final TextEditingController nameController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('手动添加签到'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: idController,
              decoration: const InputDecoration(
                labelText: '学号',
                hintText: '请输入学生学号',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: '姓名',
                hintText: '请输入学生姓名',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('取消'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text('添加'),
            onPressed: () {
              if (idController.text.isNotEmpty && nameController.text.isNotEmpty) {
                _attendanceManager.addManualAttendance(
                  idController.text,
                  nameController.text,
                );
                Navigator.pop(context);
                
                // 刷新UI
                setState(() {});
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('学号和姓名不能为空'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
          ),
        ],
      ),
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
            expandedHeight: 120, // 进一步减小顶部高度
            flexibleSpace: _buildProfileHeader(),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(12),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildPracticeSection(context),
                const SizedBox(height: 16),
                _buildLearningStatistics(),
                const SizedBox(height: 16),
                _buildLearningPlan(context),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPracticeSection(BuildContext context) {
    // 计算学习等级 - 使用实际数据
    final studyLevel = (StudyData.instance.studyMinute / 10).ceil();

    return CommonComponents.buildCommonCard(
      Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 学习进度标题和等级
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '今日学习进度',
                  style: AppTheme.getSubtitleStyle(context),
                ),
                // 学习等级
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.military_tech_outlined,
                        size: 14,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Lv.$studyLevel',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // 每日学习进度条
            Stack(
              alignment: Alignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: 0.65,
                    backgroundColor: Colors.grey.withOpacity(0.2),
                    valueColor: const AlwaysStoppedAnimation(AppTheme.primaryColor),
                    minHeight: 24,
                  ),
                ),
                const Text(
                  '65.0%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // 功能按钮区 - 一排四个按钮
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSimpleButton(
                  context: context,
                  icon: Icons.auto_awesome_motion,
                  label: '智能学习',
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
                    ).whenComplete(() => LearningPlanManager.instance
                        .updateLearningPlan()
                        .whenComplete(() => setState(() {})));
                  },
                ),
                _buildSimpleButton(
                  context: context,
                  icon: Icons.play_circle_outline,
                  label: '顺序练习',
                  onPressed: () {
                    PageIntentTrans.map[PageIntentTrans.bankChooseTarget] =
                        () => const ModeScreen(title: '',);
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
                    ).whenComplete(() => LearningPlanManager.instance
                        .updateLearningPlan()
                        .whenComplete(() => setState(() {})));
                  },
                ),
                _buildSimpleButton(
                  context: context,
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
                _buildSimpleButton(
                  context: context,
                  icon: Icons.bar_chart,
                  label: '学习报告',
                  onPressed: () {
                    Navigator.push(
                      context,
                      PageTransition(
                        type: PageTransitionType.rightToLeftPop,
                        childCurrent: widget,
                        alignment: const Alignment(10, 20),
                        child: const LearningReportScreen(title: ''),
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOut,
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  // 最简单的按钮构建方法 - 无任何动态计算
  Widget _buildSimpleButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: AppTheme.primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // 新的学习统计卡片 (从_buildPracticeSection中提取出来)
  Widget _buildLearningStatistics() {
    // 计算累计完成的章节数和总章节数
    int totalSections = 0;
    int completedSections = 0;
    
    // 遍历所有题库的章节数据
    for (var key in WrongQuestionBook.instance.sectionDataBox.keys) {
      // 获取章节数据
      final sectionData = WrongQuestionBook.instance.sectionDataBox.get(key);
      if (sectionData != null) {
        // 如果章节已经学习过（learnTimes > 0），则计为已完成
        if (sectionData.learnTimes > 0) {
          completedSections++;
        }
        totalSections++;
      }
    }
    
    // 计算累计进度百分比
    final progressPercentage = totalSections > 0 ? ((completedSections / totalSections) * 100).toInt() : 0;
    
    // 计算当日学习时间 - 使用实际数据
    final dailyStudyHours = (StudyData.instance.studyMinute / max(StudyData.instance.studyCount, 1)).toStringAsFixed(1);
    final targetHours = "5.0";
    
    // 计算正确率变化 - 使用实际数据
    final wrongQuestions = WrongQuestionBook.instance.getWrongQuestionIds().length;
    final totalAttemptedQuestions = WrongQuestionBook.instance.questionBox.length;
    final accuracyRate = totalAttemptedQuestions > 0 ? 
        ((totalAttemptedQuestions - wrongQuestions) / totalAttemptedQuestions * 100).toStringAsFixed(1) : 
        "0.0";
    final accuracyChange = "$accuracyRate%";
    
    // 计算最近7天的学习情况
    final lastWeekData = StudyData.instance.getStudyTimeForLastDays(7);
    final weekday = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    final today = DateTime.now().weekday - 1; // 0-6, 对应周一到周日
    
    return CommonComponents.buildCommonCard(
      Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 学习统计标题
            Text(
              '学习情况统计',
              style: AppTheme.getSubtitleStyle(context),
            ),
            
            const SizedBox(height: 20),
            
            // 学习统计数据行
            Row(
              children: [
                Expanded(
                  child: _buildStatRow(
                    context,
                    Icons.today, 
                    "今日学习", 
                    "$dailyStudyHours h", 
                    "/$targetHours h目标"
                  ),
                ),
                Expanded(
                  child: _buildStatRow(
                    context,
                    Icons.assignment_turned_in, 
                    "累计进度", 
                    "$completedSections/$totalSections", 
                    "$progressPercentage%"
                  ),
                ),
                Expanded(
                  child: _buildStatRow(
                    context,
                    Icons.insights, 
                    "正确率", 
                    accuracyChange, 
                    "总体"
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // 最近学习情况
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "最近学习情况",
                  style: TextStyle(
                    fontSize: TextScaler.instance.getScaledFontSize(context, 12),
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(7, (index) {
                    final dayIndex = (today - 6 + index) % 7;
                    final day = weekday[dayIndex];
                    final dateStr = _getDateStringForDaysAgo(6 - index);
                    final studyTime = lastWeekData[dateStr] ?? 0;
                    final barHeight = (studyTime > 0 ? 12 + min(60, studyTime / 5 * 20) : 12).toDouble();
                    final isToday = index == 6;
                    
                    return Column(
                      children: [
                        Container(
                          width: 24,
                          height: barHeight,
                          decoration: BoxDecoration(
                            color: isToday 
                                ? AppTheme.primaryColor 
                                : (studyTime > 0 ? AppTheme.primaryColor.withOpacity(0.6) : Colors.grey.withOpacity(0.2)),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          day,
                          style: TextStyle(
                            fontSize: TextScaler.instance.getScaledFontSize(context, 10),
                            color: isToday ? AppTheme.primaryColor : AppTheme.textSecondary,
                            fontWeight: isToday ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                        if (studyTime > 0)
                          Text(
                            "${studyTime.toStringAsFixed(1)}分",
                            style: TextStyle(
                              fontSize: TextScaler.instance.getScaledFontSize(context, 9),
                              color: AppTheme.textSecondary,
                            ),
                          ),
                      ],
                    );
                  }),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 获取几天前的日期字符串
  String _getDateStringForDaysAgo(int daysAgo) {
    final date = DateTime.now().subtract(Duration(days: daysAgo));
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
  
  // 更新后的统计行组件 - 只保留主要数值
  Widget _buildStatRow(BuildContext context, IconData icon, String title, String value, String subText) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
              width: 24,
              height: 24,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.center,
              child: Icon(icon, size: 14, color: AppTheme.primaryColor),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: TextScaler.instance.getScaledFontSize(context, 11),
                    color: AppTheme.textSecondary.withOpacity(0.8)
                  )
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: TextScaler.instance.getScaledFontSize(context, 13),
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
          ),
        ],
      ),
      ],
    );
  }

  Widget _buildProfileHeader() {
    // 计算学习等级
    final studyLevel = (StudyData.instance.studyMinute / 10).ceil();
    final statManager = StatisticsManager(StatisticsManager.PERIOD_WEEK);
    final streakInfo = statManager.getStudyStreakInfo();
    final currentStreak = streakInfo['currentStreak'] as int;
    
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
  
  Widget _buildHomeStatBadge({
    required IconData icon,
    required String value,
    required String label,
    Color? iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // 减少上下内边距
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: iconColor ?? Colors.white,
                size: 14,
              ),
              const SizedBox(width: 6), // 增加图标和文字间距
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4), // 增加垂直间距
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLearningPlan(BuildContext context) {
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
        _buildLearningPlanCards(context),
      ],
    );
  }
  
  // 恢复为列表形式的学习计划
  Widget _buildLearningPlanCards(BuildContext context) {
    if (LearningPlanManager.instance.learningPlanItems.isEmpty) {
      // 检查是否有题库但没有学习计划
      final hasQuestionBanks = QuestionBank.getAllLoadedQuestionBankIds().isNotEmpty;
      
      if (hasQuestionBanks) {
        return CommonComponents.buildCommonCard(
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
          ),
        );
      } else {
        return CommonComponents.buildCommonCard(
          InkWell(
            onTap: () {
              PageIntentTrans.map[PageIntentTrans.bankChooseTarget] =
                  () => const ModeScreen(title: '',);
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
              ).whenComplete(() => LearningPlanManager.instance
                  .updateLearningPlan()
                  .whenComplete(() => setState(() {})));
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Column(
                  children: [
                    Text(
                      '还没有添加题库，请先添加题库',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textPrimary,
                        height: 1.6,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '点击这里添加题库',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w500,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }
    }
    
    // 恢复为列表形式的学习计划
    return CommonComponents.buildCommonCard(
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: List.generate(
            LearningPlanManager.instance.learningPlanItems.length,
            (index) => Column(
              children: [
                InkWell(
                  onTap: () {
                    // Set the current plan for targeted studying
                    StudyData.instance.studyType = StudyType.recommandMode;
                    StudyData.instance.currentPlanId = index;
                    
                    // Navigate to question screen
                    Navigator.push(
                      context,
                      PageTransition(
                        type: PageTransitionType.rightToLeftPop,
                        childCurrent: widget,
                        alignment: const Alignment(10, 20),
                        child: const QuestionScreen(title: ''),
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOut,
                      ),
                    ).whenComplete(() => LearningPlanManager.instance
                        .updateLearningPlan()
                        .whenComplete(() => setState(() {})));
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Row(
                      children: [
                        // 左侧图标
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.school_outlined,
                              color: AppTheme.primaryColor,
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        
                        // 中间内容
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 标题
                              LaTexT(
                                laTeXCode: Text(
                                  LearningPlanManager.instance.learningPlanItems[index].targetSection!.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              
                              // 进度指示器
                              LinearProgressIndicator(
                                value: LearningPlanManager.instance.learningPlanItems[index].getSectionLearningData(LearningPlanManager.instance.learningPlanItems[index].targetSection!).alreadyCompleteQuestion / 
                                    max(LearningPlanManager.instance.learningPlanItems[index].getSectionLearningData(LearningPlanManager.instance.learningPlanItems[index].targetSection!).allNeedCompleteQuestion, 1),
                                backgroundColor: Colors.grey.withOpacity(0.2),
                                valueColor: AlwaysStoppedAnimation(
                                  LearningPlanManager.instance.learningPlanItems[index].getSectionLearningData(LearningPlanManager.instance.learningPlanItems[index].targetSection!).alreadyCompleteQuestion > 0 
                                    ? AppTheme.successColor 
                                    : AppTheme.primaryColor,
                                ),
                                minHeight: 3,
                                borderRadius: BorderRadius.circular(1.5),
                              ),
                              const SizedBox(height: 6),
                              
                              // 统计信息
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Text(
                                      '${LearningPlanManager.instance.learningPlanItems[index].getSectionLearningData(LearningPlanManager.instance.learningPlanItems[index].targetSection!).alreadyCompleteQuestion}/${LearningPlanManager.instance.learningPlanItems[index].getSectionLearningData(LearningPlanManager.instance.learningPlanItems[index].targetSection!).allNeedCompleteQuestion}题',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.textSecondary,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      '掌握: ${(StudyData.instance.getTopicMastery(LearningPlanManager.instance.learningPlanItems[index].targetSection!.id) * 100).toStringAsFixed(0)}%',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.textSecondary,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        // 右侧按钮
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Text(
                            '开始',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // 添加分隔线，但最后一个项目不添加
                if (index < LearningPlanManager.instance.learningPlanItems.length - 1)
                  Divider(
                    height: 1,
                    thickness: 0.5,
                    indent: 64,
                    endIndent: 16,
                    color: Colors.grey.withOpacity(0.2),
                  ),
              ],
            ),
          ),
        ),
      ),
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

