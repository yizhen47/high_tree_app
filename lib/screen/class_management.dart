import 'package:fl_chart/fl_chart.dart' as fl;
import 'package:flutter/material.dart';
import 'package:flutter_application_1/screen/home/home.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import 'dart:math';

// 资源使用偏好数据
class ResourceUsageData {
  final String type;
  final int count;
  final double percentage;
  final Color color;

  ResourceUsageData({
    required this.type,
    required this.count,
    required this.percentage,
    required this.color,
  });
}

// 章节掌握情况数据
class ChapterMasteryData {
  final String chapterName;
  final double masteryRate;
  final int totalQuestions;
  final int completedQuestions;

  ChapterMasteryData({
    required this.chapterName,
    required this.masteryRate,
    required this.totalQuestions,
    required this.completedQuestions,
  });
}

// 班级统计数据结构
class ClassStatisticsData {
  final String className;
  final int totalStudents;
  final int activeStudents;
  final double averageAccuracy;
  final double averageStudyTime;
  final List<double> weeklyStudyData; // 7天的班级学习数据
  final List<StudentRankData> studentRankings;
  final Map<String, dynamic> classStreakInfo;
  final String bestStudyTime;
  final double classRegularity;
  final List<SubjectPerformance> subjectPerformances;
  final Map<int, double> hourlyClassDistribution;
  final List<DailyClassProgress> dailyProgress; // 用于折线图
  final List<ResourceUsageData> resourceUsage; // 资源使用偏好
  final List<ChapterMasteryData> chapterMastery; // 章节掌握情况
  final double overallMasteryRate; // 班级整体掌握程度

  ClassStatisticsData({
    required this.className,
    required this.totalStudents,
    required this.activeStudents,
    required this.averageAccuracy,
    required this.averageStudyTime,
    required this.weeklyStudyData,
    required this.studentRankings,
    required this.classStreakInfo,
    required this.bestStudyTime,
    required this.classRegularity,
    required this.subjectPerformances,
    required this.hourlyClassDistribution,
    required this.dailyProgress,
    required this.resourceUsage,
    required this.chapterMastery,
    required this.overallMasteryRate,
  });
}

// 学生排名数据
class StudentRankData {
  final String name;
  final double studyTime;
  final double accuracy;
  final int rank;

  StudentRankData({
    required this.name,
    required this.studyTime,
    required this.accuracy,
    required this.rank,
  });
}

// 科目表现数据
class SubjectPerformance {
  final String subject;
  final double averageScore;
  final int completedQuestions;
  final Color color;

  SubjectPerformance({
    required this.subject,
    required this.averageScore,
    required this.completedQuestions,
    required this.color,
  });
}

// 每日班级进度数据（用于折线图）
class DailyClassProgress {
  final DateTime date;
  final double averageStudyTime;
  final double averageAccuracy;
  final int activeStudents;

  DailyClassProgress({
    required this.date,
    required this.averageStudyTime,
    required this.averageAccuracy,
    required this.activeStudents,
  });
}

class ClassManagementScreen extends StatefulWidget {
  const ClassManagementScreen({super.key});

  @override
  State<ClassManagementScreen> createState() => _ClassManagementScreenState();
}

class _ClassManagementScreenState extends State<ClassManagementScreen> {
  // 时间段选择 - 修改为包含去年2月到5月的时间段
  final List<String> _timePeriods = ['上个学期', '本学期'];
  String _selectedPeriod = '本学期';
  
  // 演示模式
  bool _isDemoMode = false;
  String _demoType = '';
  ClassStatisticsData? _demoData;

  @override
  void initState() {
    super.initState();
    // 初始化演示数据
    _switchToDemo('标准班级');
  }

  // 生成演示数据
  ClassStatisticsData _generateDemoData(String demoType) {
    switch (demoType) {
      case '标准班级':
        return ClassStatisticsData(
          className: '高数实验班',
          totalStudents: 42,
          activeStudents: 38,
          averageAccuracy: 76.5,
          averageStudyTime: 78.0,
          weeklyStudyData: [85, 92, 68, 105, 125, 88, 98],
          studentRankings: [
            StudentRankData(name: '张三', studyTime: 180.0, accuracy: 92.5, rank: 1),
            StudentRankData(name: '李四', studyTime: 165.0, accuracy: 89.3, rank: 2),
            StudentRankData(name: '王五', studyTime: 145.0, accuracy: 87.8, rank: 3),
            StudentRankData(name: '赵六', studyTime: 130.0, accuracy: 85.2, rank: 4),
            StudentRankData(name: '钱七', studyTime: 120.0, accuracy: 84.1, rank: 5),
          ],
          classStreakInfo: {'currentStreak': 12, 'maxStreak': 18},
          bestStudyTime: '19:00-21:00',
          classRegularity: 0.78,
          subjectPerformances: [
            SubjectPerformance(subject: '微积分', averageScore: 82.3, completedQuestions: 1250, color: const Color(0xff0293ee)),
            SubjectPerformance(subject: '线性代数', averageScore: 75.8, completedQuestions: 890, color: const Color(0xff13d38e)),
            SubjectPerformance(subject: '概率论', averageScore: 69.2, completedQuestions: 654, color: const Color(0xff845bef)),
            SubjectPerformance(subject: '数理统计', averageScore: 71.5, completedQuestions: 432, color: const Color(0xffff6b6b)),
          ],
          hourlyClassDistribution: {
            8: 25.0, 9: 32.0, 10: 18.0,
            14: 28.0, 15: 35.0, 16: 22.0,
            19: 78.0, 20: 95.0, 21: 82.0, 22: 45.0,
            for (int i = 0; i < 24; i++) 
              if (![8, 9, 10, 14, 15, 16, 19, 20, 21, 22].contains(i)) i: 0.0
          },
          dailyProgress: [
            // 3月份开学（开学初期，适应期）
            DailyClassProgress(date: DateTime(2024, 3, 1), averageStudyTime: 15.0, averageAccuracy: 45.5, activeStudents: 25),
            DailyClassProgress(date: DateTime(2024, 3, 5), averageStudyTime: 18.0, averageAccuracy: 52.2, activeStudents: 28),
            DailyClassProgress(date: DateTime(2024, 3, 10), averageStudyTime: 20.0, averageAccuracy: 58.1, activeStudents: 30),
            DailyClassProgress(date: DateTime(2024, 3, 15), averageStudyTime: 16.0, averageAccuracy: 48.5, activeStudents: 27),
            DailyClassProgress(date: DateTime(2024, 3, 20), averageStudyTime: 19.0, averageAccuracy: 49.8, activeStudents: 29),
            DailyClassProgress(date: DateTime(2024, 3, 25), averageStudyTime: 17.0, averageAccuracy: 55.2, activeStudents: 28),
            DailyClassProgress(date: DateTime(2024, 3, 30), averageStudyTime: 21.0, averageAccuracy: 55.5, activeStudents: 32),
            
            // 4月份（春困期，但正确率逐步提升）
            DailyClassProgress(date: DateTime(2024, 4, 5), averageStudyTime: 12.0, averageAccuracy: 54.5, activeStudents: 22),
            DailyClassProgress(date: DateTime(2024, 4, 10), averageStudyTime: 14.0, averageAccuracy: 55.8, activeStudents: 25),
            DailyClassProgress(date: DateTime(2024, 4, 15), averageStudyTime: 16.0, averageAccuracy: 56.1, activeStudents: 27),
            DailyClassProgress(date: DateTime(2024, 4, 20), averageStudyTime: 18.0, averageAccuracy: 56.5, activeStudents: 29),
            DailyClassProgress(date: DateTime(2024, 4, 25), averageStudyTime: 22.0, averageAccuracy: 60.2, activeStudents: 32),
            DailyClassProgress(date: DateTime(2024, 4, 30), averageStudyTime: 28.0, averageAccuracy: 64.8, activeStudents: 36),
            
            // 5月份（期中考试5.7 + 期中后放松）
            DailyClassProgress(date: DateTime(2024, 5, 3), averageStudyTime: 25.0, averageAccuracy: 70.2, activeStudents: 35), // 期中前准备
            DailyClassProgress(date: DateTime(2024, 5, 6), averageStudyTime: 35.0, averageAccuracy: 72.5, activeStudents: 40), // 期中前一天
            DailyClassProgress(date: DateTime(2024, 5, 7), averageStudyTime: 42.0, averageAccuracy: 70.8, activeStudents: 45), // 期中考试当天，冲刺复习
            DailyClassProgress(date: DateTime(2024, 5, 10), averageStudyTime: 2.0, averageAccuracy: 60.2, activeStudents: 28), // 期中后大放松
            DailyClassProgress(date: DateTime(2024, 5, 15), averageStudyTime: 2.0, averageAccuracy: 60, activeStudents: 30),
            DailyClassProgress(date: DateTime(2024, 5, 20), averageStudyTime: 2.0, averageAccuracy: 64.5, activeStudents: 29),
            DailyClassProgress(date: DateTime(2024, 5, 25), averageStudyTime: 4.0, averageAccuracy: 62.8, activeStudents: 31),
            DailyClassProgress(date: DateTime(2024, 5, 30), averageStudyTime: 10.0, averageAccuracy: 65.3, activeStudents: 30),
            
            // 6月份（平时 + 开始准备期末）
            DailyClassProgress(date: DateTime(2024, 6, 5), averageStudyTime: 15.0, averageAccuracy: 59.1, activeStudents: 32),
            DailyClassProgress(date: DateTime(2024, 6, 10), averageStudyTime: 15.0, averageAccuracy: 54.8, activeStudents: 34),
            DailyClassProgress(date: DateTime(2024, 6, 15), averageStudyTime: 17.0, averageAccuracy: 71.5, activeStudents: 36),
            DailyClassProgress(date: DateTime(2024, 6, 20), averageStudyTime: 17.0, averageAccuracy: 78.2, activeStudents: 38),
            DailyClassProgress(date: DateTime(2024, 6, 25), averageStudyTime: 16.0, averageAccuracy: 85.1, activeStudents: 40),
            DailyClassProgress(date: DateTime(2024, 6, 30), averageStudyTime: 20.0, averageAccuracy: 88.8, activeStudents: 42),
            
            // 7月份（高数考试7.10冲刺）
            DailyClassProgress(date: DateTime(2024, 7, 3), averageStudyTime: 38.0, averageAccuracy: 81.5, activeStudents: 42), // 开始冲刺
            DailyClassProgress(date: DateTime(2024, 7, 6), averageStudyTime: 45.0, averageAccuracy: 83.8, activeStudents: 46), // 考前准备
            DailyClassProgress(date: DateTime(2024, 7, 8), averageStudyTime: 58.0, averageAccuracy: 86.2, activeStudents: 50), // 考前两天
            DailyClassProgress(date: DateTime(2024, 7, 9), averageStudyTime: 68.0, averageAccuracy: 88.5, activeStudents: 52), // 考前一天
            DailyClassProgress(date: DateTime(2024, 7, 10), averageStudyTime: 72.0, averageAccuracy: 80.2, activeStudents: 55), // 高数考试当天
            DailyClassProgress(date: DateTime(2024, 7, 12), averageStudyTime: 25.0, averageAccuracy: 90.2, activeStudents: 35), // 考试结束，大放松
          ],
          resourceUsage: [
            ResourceUsageData(type: '看知识点', count: 856, percentage: 22.8, color: const Color(0xff0293ee)),
            ResourceUsageData(type: '看视频解析', count: 1124, percentage: 29.9, color: const Color(0xff13d38e)),
            ResourceUsageData(type: '问AI', count: 1775, percentage: 47.3, color: const Color(0xff845bef)),
          ],
          chapterMastery: [
            ChapterMasteryData(chapterName: '第六章 微分方程', masteryRate: 78.3, totalQuestions: 156, completedQuestions: 122),
            ChapterMasteryData(chapterName: '第七章 多元函数微分法', masteryRate: 82.1, totalQuestions: 198, completedQuestions: 163),
            ChapterMasteryData(chapterName: '第八章 重积分', masteryRate: 68.5, totalQuestions: 134, completedQuestions: 92),
            ChapterMasteryData(chapterName: '第九章 曲线与曲面积分', masteryRate: 45.2, totalQuestions: 112, completedQuestions: 51), // 最难的！
            ChapterMasteryData(chapterName: '第十章 无穷级数', masteryRate: 78.0, totalQuestions: 89, completedQuestions: 69),
          ],
          overallMasteryRate: 75.3,
        );
      
      case '优秀班级':
        return ClassStatisticsData(
          className: '高数尖子班',
          totalStudents: 30,
          activeStudents: 30,
          averageAccuracy: 89.2,
          averageStudyTime: 220.0,
          weeklyStudyData: [195, 210, 185, 230, 245, 205, 225],
          studentRankings: [
            StudentRankData(name: '学霸A', studyTime: 350.0, accuracy: 96.8, rank: 1),
            StudentRankData(name: '学霸B', studyTime: 340.0, accuracy: 95.5, rank: 2),
            StudentRankData(name: '学霸C', studyTime: 335.0, accuracy: 94.2, rank: 3),
            StudentRankData(name: '学霸D', studyTime: 320.0, accuracy: 93.8, rank: 4),
            StudentRankData(name: '学霸E', studyTime: 310.0, accuracy: 92.5, rank: 5),
          ],
          classStreakInfo: {'currentStreak': 25, 'maxStreak': 28},
          bestStudyTime: '20:00-22:00',
          classRegularity: 0.92,
          subjectPerformances: [
            SubjectPerformance(subject: '微积分', averageScore: 92.8, completedQuestions: 1850, color: const Color(0xff0293ee)),
            SubjectPerformance(subject: '线性代数', averageScore: 89.5, completedQuestions: 1320, color: const Color(0xff13d38e)),
            SubjectPerformance(subject: '概率论', averageScore: 86.7, completedQuestions: 980, color: const Color(0xff845bef)),
            SubjectPerformance(subject: '数理统计', averageScore: 84.2, completedQuestions: 720, color: const Color(0xffff6b6b)),
          ],
          hourlyClassDistribution: {
            8: 45.0, 9: 52.0, 10: 38.0,
            14: 48.0, 15: 55.0, 16: 42.0,
            19: 98.0, 20: 125.0, 21: 118.0, 22: 85.0, 23: 25.0,
            for (int i = 0; i < 24; i++) 
              if (![8, 9, 10, 14, 15, 16, 19, 20, 21, 22, 23].contains(i)) i: 0.0
          },
          dailyProgress: [
            // 2月份数据（优秀班级，规律性强）
            DailyClassProgress(date: DateTime(2024, 2, 28), averageStudyTime: 38.0, averageAccuracy: 84.2, activeStudents: 29),
            DailyClassProgress(date: DateTime(2024, 2, 29), averageStudyTime: 42.0, averageAccuracy: 85.8, activeStudents: 30),
            DailyClassProgress(date: DateTime(2024, 3, 1), averageStudyTime: 45.0, averageAccuracy: 87.1, activeStudents: 30),
            DailyClassProgress(date: DateTime(2024, 3, 2), averageStudyTime: 35.0, averageAccuracy: 85.5, activeStudents: 28), // 周六，轻微下降
            DailyClassProgress(date: DateTime(2024, 3, 3), averageStudyTime: 32.0, averageAccuracy: 84.8, activeStudents: 26), // 周日
            DailyClassProgress(date: DateTime(2024, 3, 4), averageStudyTime: 43.0, averageAccuracy: 87.5, activeStudents: 30),
            DailyClassProgress(date: DateTime(2024, 3, 5), averageStudyTime: 46.0, averageAccuracy: 88.2, activeStudents: 30),
            DailyClassProgress(date: DateTime(2024, 3, 6), averageStudyTime: 44.0, averageAccuracy: 87.9, activeStudents: 29),
            DailyClassProgress(date: DateTime(2024, 3, 7), averageStudyTime: 47.0, averageAccuracy: 89.1, activeStudents: 30),
            DailyClassProgress(date: DateTime(2024, 3, 8), averageStudyTime: 48.0, averageAccuracy: 89.5, activeStudents: 30),
            // 3月中旬（期中考试周，优秀班级也会加强）
            DailyClassProgress(date: DateTime(2024, 3, 15), averageStudyTime: 68.0, averageAccuracy: 91.2, activeStudents: 30),
            DailyClassProgress(date: DateTime(2024, 3, 16), averageStudyTime: 75.0, averageAccuracy: 92.5, activeStudents: 30),
            DailyClassProgress(date: DateTime(2024, 3, 17), averageStudyTime: 82.0, averageAccuracy: 93.1, activeStudents: 30), // 考前最高
            DailyClassProgress(date: DateTime(2024, 3, 18), averageStudyTime: 58.0, averageAccuracy: 90.8, activeStudents: 29), // 考后适当放松
            // 3月底（回到正常水平，但比普通班高）
            DailyClassProgress(date: DateTime(2024, 3, 25), averageStudyTime: 45.0, averageAccuracy: 88.2, activeStudents: 29),
            DailyClassProgress(date: DateTime(2024, 3, 26), averageStudyTime: 46.0, averageAccuracy: 88.8, activeStudents: 30),
            DailyClassProgress(date: DateTime(2024, 3, 27), averageStudyTime: 43.0, averageAccuracy: 87.5, activeStudents: 28),
            DailyClassProgress(date: DateTime(2024, 3, 28), averageStudyTime: 47.0, averageAccuracy: 89.2, activeStudents: 30),
            // 4月份（优秀班级春困期影响小）
            DailyClassProgress(date: DateTime(2024, 4, 8), averageStudyTime: 42.0, averageAccuracy: 86.8, activeStudents: 29),
            DailyClassProgress(date: DateTime(2024, 4, 15), averageStudyTime: 45.0, averageAccuracy: 88.1, activeStudents: 30),
            DailyClassProgress(date: DateTime(2024, 4, 22), averageStudyTime: 48.0, averageAccuracy: 89.2, activeStudents: 30),
            // 5月份（提前准备期末）
            DailyClassProgress(date: DateTime(2024, 5, 8), averageStudyTime: 52.0, averageAccuracy: 89.5, activeStudents: 30),
            DailyClassProgress(date: DateTime(2024, 5, 15), averageStudyTime: 58.0, averageAccuracy: 90.8, activeStudents: 30),
            DailyClassProgress(date: DateTime(2024, 5, 22), averageStudyTime: 62.0, averageAccuracy: 91.5, activeStudents: 30),
            // 6月份（期末冲刺，但比普通班更有规划）
            DailyClassProgress(date: DateTime(2024, 6, 10), averageStudyTime: 75.0, averageAccuracy: 93.2, activeStudents: 30), // 稳定高效
            DailyClassProgress(date: DateTime(2024, 6, 20), averageStudyTime: 85.0, averageAccuracy: 94.5, activeStudents: 30), // 有序冲刺
            DailyClassProgress(date: DateTime(2024, 6, 25), averageStudyTime: 92.0, averageAccuracy: 95.1, activeStudents: 30), // 期末巅峰
            DailyClassProgress(date: DateTime(2024, 6, 28), averageStudyTime: 68.0, averageAccuracy: 92.8, activeStudents: 30), // 考后仍维持
          ],
          resourceUsage: [
            ResourceUsageData(type: '看知识点', count: 1245, percentage: 21.5, color: const Color(0xff0293ee)),
            ResourceUsageData(type: '看视频解析', count: 1625, percentage: 28.1, color: const Color(0xff13d38e)),
            ResourceUsageData(type: '问AI', count: 2920, percentage: 50.4, color: const Color(0xff845bef)),
          ],
          chapterMastery: [
            ChapterMasteryData(chapterName: '第六章 微分方程', masteryRate: 92.5, totalQuestions: 156, completedQuestions: 144),
            ChapterMasteryData(chapterName: '第七章 多元函数微分法', masteryRate: 94.2, totalQuestions: 198, completedQuestions: 187),
            ChapterMasteryData(chapterName: '第八章 重积分', masteryRate: 85.8, totalQuestions: 134, completedQuestions: 115),
            ChapterMasteryData(chapterName: '第九章 曲线与曲面积分', masteryRate: 72.3, totalQuestions: 112, completedQuestions: 81), // 优秀班级也觉得难
            ChapterMasteryData(chapterName: '第十章 无穷级数', masteryRate: 88.5, totalQuestions: 89, completedQuestions: 79),
          ],
          overallMasteryRate: 89.5,
        );
      
      default:
        return _generateDemoData('标准班级');
    }
  }

  // 切换演示模式
  void _switchToDemo(String demoType) {
    setState(() {
      _isDemoMode = true;
      _demoType = demoType;
      _demoData = _generateDemoData(demoType);
    });
  }

  // 退出演示模式
  void _exitDemoMode() {
    setState(() {
      _isDemoMode = false;
      _demoType = '';
      _demoData = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TDNavBar(
        title: '班级管理',
        onBack: () => Navigator.of(context).pop(),
      ),
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 演示模式菜单和时间筛选
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: _buildTimePeriodSelector()),
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert, 
                      color: _isDemoMode ? AppTheme.primaryColor : AppTheme.textSecondary,
                    ),
                    onSelected: (String value) {
                      if (value == 'exit_demo') {
                        _exitDemoMode();
                      } else {
                        _switchToDemo(value);
                      }
                    },
                    itemBuilder: (BuildContext context) => [
                      if (_isDemoMode)
                        const PopupMenuItem<String>(
                          value: 'exit_demo',
                          child: Row(
                            children: [
                              Icon(Icons.exit_to_app, size: 20),
                              SizedBox(width: 8),
                              Text('退出演示'),
                            ],
                          ),
                        ),
                      const PopupMenuItem<String>(
                        value: '标准班级',
                        child: Row(
                          children: [
                            Icon(Icons.school, size: 20),
                            SizedBox(width: 8),
                            Text('标准班级'),
                          ],
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: '优秀班级',
                        child: Row(
                          children: [
                            Icon(Icons.stars, size: 20),
                            SizedBox(width: 8),
                            Text('优秀班级'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildClassSummaryCard(),
              const SizedBox(height: 12),
              _buildClassProgressChart(),
              const SizedBox(height: 12),
              _buildChapterMasteryCard(),
              const SizedBox(height: 12),
              _buildResourceUsageCard(),
              const SizedBox(height: 12),
              _buildStudentRankings(),
              const SizedBox(height: 12),
              _buildSubjectPerformance(),
              const SizedBox(height: 12),
              _buildClassHabits(),
            ],
          ),
        ),
      ),
    );
  }

  // 获取当前数据
  ClassStatisticsData _getCurrentData() {
    if (_isDemoMode && _demoData != null) {
      return _demoData!;
    }
    
    // 这里可以返回真实的班级数据
    return _generateDemoData('标准班级');
  }

  // 时间筛选器
  Widget _buildTimePeriodSelector() {
    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _timePeriods.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final isSelected = _timePeriods[index] == _selectedPeriod;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedPeriod = _timePeriods[index];
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryColor : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        )
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        )
                      ],
              ),
              child: Text(
                _timePeriods[index],
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? Colors.white : AppTheme.textPrimary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // 班级概览卡片
  Widget _buildClassSummaryCard() {
    final data = _getCurrentData();
    
    return CommonComponents.buildCommonCard(
      Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 班级名称和基本信息
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.className,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${data.activeStudents}/${data.totalStudents} 活跃学生',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
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
  }

  // 统计项组件
  Widget _buildStatItem({
    required IconData icon,
    required String title,
    required String value,
    required String subValue,
  }) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: AppTheme.primaryColor),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            color: AppTheme.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          subValue,
          style: const TextStyle(
            fontSize: 10,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  // 班级进度折线图
  Widget _buildClassProgressChart() {
    final data = _getCurrentData();
    
    return _buildSectionCard(
      title: '班级学习趋势',
      content: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(
              height: 200,
              child: fl.LineChart(
                fl.LineChartData(
                  gridData: fl.FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 20,
                    getDrawingHorizontalLine: (value) {
                      return fl.FlLine(
                        color: Colors.grey.withOpacity(0.2),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: fl.FlTitlesData(
                    leftTitles: fl.AxisTitles(
                      sideTitles: fl.SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}min',
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppTheme.textSecondary,
                            ),
                          );
                        },
                      ),
                    ),
                    rightTitles: fl.AxisTitles(
                      sideTitles: fl.SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          // 将左侧的学习时间值转换为右侧的正确率值
                          // 左侧最大250分钟对应右侧100%
                          final accuracyValue = (value / 250 * 100).toInt();
                          return Text(
                            '${accuracyValue}%',
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppTheme.successColor,
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: fl.AxisTitles(
                      sideTitles: fl.SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() % 2 == 0 && value.toInt() < data.dailyProgress.length) {
                            final date = data.dailyProgress[value.toInt()].date;
                            return Text(
                              '${date.month}/${date.day}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppTheme.textSecondary,
                              ),
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                    ),
                    topTitles: const fl.AxisTitles(sideTitles: fl.SideTitles(showTitles: false)),
                  ),
                  borderData: fl.FlBorderData(show: false),
                  lineBarsData: [
                    // 平均学习时间线
                    fl.LineChartBarData(
                      spots: data.dailyProgress
                          .asMap()
                          .entries
                          .map((entry) => fl.FlSpot(
                                entry.key.toDouble(),
                                entry.value.averageStudyTime,
                              ))
                          .toList(),
                      isCurved: true,
                      color: AppTheme.primaryColor,
                      barWidth: 3,
                      dotData: fl.FlDotData(show: false),
                      belowBarData: fl.BarAreaData(
                        show: true,
                        color: AppTheme.primaryColor.withOpacity(0.1),
                      ),
                    ),
                    // 平均正确率线（独立数据）
                    fl.LineChartBarData(
                      spots: data.dailyProgress
                          .asMap()
                          .entries
                          .map((entry) => fl.FlSpot(
                                entry.key.toDouble(),
                                entry.value.averageAccuracy * 2.5, // 适配到0-250的范围
                              ))
                          .toList(),
                      isCurved: true,
                      color: AppTheme.successColor,
                      barWidth: 3,
                      dotData: fl.FlDotData(show: false),
                    ),
                  ],
                  minX: 0,
                  maxX: (data.dailyProgress.length - 1).toDouble(),
                  minY: 0,
                  maxY: 250,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // 图例和轴说明
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLegendItem('平均学习时间', AppTheme.primaryColor),
                    const SizedBox(width: 24),
                    _buildLegendItem('平均正确率', AppTheme.successColor),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '学习时间 (分钟)',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppTheme.primaryColor.withOpacity(0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '正确率 (%)',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppTheme.successColor.withOpacity(0.8),
                        fontWeight: FontWeight.w500,
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
  }

  // 图例项
  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(1.5),
          ),
        ),
        const SizedBox(width: 6),
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

  // 章节掌握情况卡片
  Widget _buildChapterMasteryCard() {
    final data = _getCurrentData();
    
    return _buildSectionCard(
      title: '章节掌握情况 (高数下)',
      content: Column(
        children: [
          // 班级整体掌握程度
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '班级整体掌握程度',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    '${data.overallMasteryRate.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // 各章节详细情况
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: data.chapterMastery.map((chapter) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              chapter.chapterName,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${chapter.completedQuestions}/${chapter.totalQuestions}题',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Column(
                          children: [
                            Text(
                              '${chapter.masteryRate.toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _getMasteryColor(chapter.masteryRate),
                              ),
                            ),
                            const SizedBox(height: 4),
                            LinearProgressIndicator(
                              value: chapter.masteryRate / 100,
                              backgroundColor: Colors.grey.withOpacity(0.2),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _getMasteryColor(chapter.masteryRate),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // 资源使用偏好卡片
  Widget _buildResourceUsageCard() {
    final data = _getCurrentData();
    
    return _buildSectionCard(
      title: '资源使用偏好',
      content: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 250,
          child: SfCircularChart(
            legend: Legend(
              isVisible: true,
              position: LegendPosition.bottom,
              textStyle: const TextStyle(fontSize: 12),
            ),
            series: <CircularSeries<ResourceUsageData, String>>[
              PieSeries<ResourceUsageData, String>(
                dataSource: data.resourceUsage,
                radius: '70%',
                xValueMapper: (ResourceUsageData data, _) => data.type,
                yValueMapper: (ResourceUsageData data, _) => data.count,
                dataLabelMapper: (ResourceUsageData data, _) => '${data.percentage.toStringAsFixed(1)}%',
                pointColorMapper: (ResourceUsageData data, _) => data.color,
                dataLabelSettings: const DataLabelSettings(
                  isVisible: true,
                  labelPosition: ChartDataLabelPosition.outside,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  // 获取掌握程度颜色
  Color _getMasteryColor(double masteryRate) {
    if (masteryRate >= 85) {
      return Colors.green;
    } else if (masteryRate >= 70) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  // 学生排名
  Widget _buildStudentRankings() {
    final data = _getCurrentData();
    
    return _buildSectionCard(
      title: '学生排名',
      content: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: List.generate(
            min(data.studentRankings.length, 5),
            (index) {
              final student = data.studentRankings[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    // 排名
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: _getRankColor(student.rank),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          student.rank.toString(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // 学生信息
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            student.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                '学习时间: ${student.studyTime.toInt()}分钟',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Text(
                                '正确率: ${student.accuracy.toStringAsFixed(1)}%',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // 获取排名颜色
  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.grey;
      case 3:
        return Colors.orange;
      default:
        return AppTheme.primaryColor;
    }
  }

  // 科目表现
  Widget _buildSubjectPerformance() {
    final data = _getCurrentData();
    
    return _buildSectionCard(
      title: '科目表现',
      content: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 200,
          child: SfCircularChart(
            legend: Legend(
              isVisible: true,
              position: LegendPosition.bottom,
              textStyle: const TextStyle(fontSize: 12),
            ),
            series: <CircularSeries<SubjectPerformance, String>>[
              PieSeries<SubjectPerformance, String>(
                dataSource: data.subjectPerformances,
                radius: '70%',
                xValueMapper: (SubjectPerformance data, _) => data.subject,
                yValueMapper: (SubjectPerformance data, _) => data.completedQuestions,
                dataLabelMapper: (SubjectPerformance data, _) => '${data.averageScore.toStringAsFixed(1)}分',
                pointColorMapper: (SubjectPerformance data, _) => data.color,
                dataLabelSettings: const DataLabelSettings(
                  isVisible: true,
                  labelPosition: ChartDataLabelPosition.outside,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  // 班级学习习惯
  Widget _buildClassHabits() {
    final data = _getCurrentData();
    final maxValue = data.hourlyClassDistribution.values.fold(0.0, (max, value) => value > max ? value : max);
    
    return _buildSectionCard(
      title: '班级学习时间分布',
      content: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(
              height: 120,
              child: Row(
                children: List.generate(24, (hour) {
                  final value = data.hourlyClassDistribution[hour] ?? 0;
                  final normalizedHeight = maxValue > 0 ? (value / maxValue) : 0.0;
                  
                  return Expanded(
                    child: Column(
                      children: [
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            width: double.infinity,
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              height: normalizedHeight * 80,
                              decoration: BoxDecoration(
                                color: _getHourColor(hour, normalizedHeight),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),
                        if (hour % 6 == 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '$hour',
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '最佳学习时段: ${data.bestStudyTime}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 获取小时颜色
  Color _getHourColor(int hour, double normalizedHeight) {
    if (normalizedHeight < 0.05) {
      return Colors.grey.withOpacity(0.2);
    }
    
    if (hour >= 8 && hour <= 11) {
      return Colors.orangeAccent.withOpacity(0.3 + (normalizedHeight * 0.7));
    } else if (hour >= 14 && hour <= 17) {
      return Colors.greenAccent.withOpacity(0.3 + (normalizedHeight * 0.7));
    } else if (hour >= 19 && hour <= 22) {
      return Colors.blueAccent.withOpacity(0.3 + (normalizedHeight * 0.7));
    } else {
      return Colors.purpleAccent.withOpacity(0.3 + (normalizedHeight * 0.7));
    }
  }

  // 通用卡片组件
  Widget _buildSectionCard({
    required String title,
    required Widget content,
  }) {
    return CommonComponents.buildCommonCard(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          Divider(
            height: 16,
            thickness: 1,
            color: Colors.grey.withOpacity(0.1),
          ),
          content,
        ],
      ),
    );
  }
} 