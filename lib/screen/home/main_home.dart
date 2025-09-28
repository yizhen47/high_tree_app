// 主界面
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';

import 'package:flutter_application_1/screen/bank_management.dart';
import 'package:flutter_application_1/screen/home/home.dart' as HomeComponents;
import 'package:flutter_application_1/screen/home/home.dart';
import 'package:flutter_application_1/screen/mind_map_screen.dart';
import 'package:flutter_application_1/screen/learning_report.dart';
import 'package:flutter_application_1/screen/question.dart';
import 'package:flutter_application_1/screen/wrong_question.dart';

import 'package:flutter_application_1/tool/question/question_bank.dart';
import 'package:flutter_application_1/tool/question/question_bank_accessor.dart';
import 'package:flutter_application_1/tool/question/question_controller.dart';
import 'package:flutter_application_1/tool/question/wrong_question_book.dart';
import 'package:flutter_application_1/tool/statistics_manager.dart';
import 'package:flutter_application_1/tool/study_data.dart';
import 'package:flutter_application_1/widget/latex.dart';
import 'package:page_transition/page_transition.dart';

class MainHomePage extends StatefulWidget {
  const MainHomePage({super.key});

  @override
  State<StatefulWidget> createState() => _MainHomePageState();
}

class _MainHomePageState extends State<MainHomePage> 
    with AutomaticKeepAliveClientMixin {
  
  @override
  bool get wantKeepAlive => false;  // 不保持状态，每次都重新构建
  
  @override
  Widget build(BuildContext context) {
    super.build(context);  // 必须调用，虽然 wantKeepAlive 为 false
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

    return HomeComponents.CommonComponents.buildCommonCard(
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
                  style: HomeComponents.AppTheme.getSubtitleStyle(context),
                ),
                // 学习等级
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: HomeComponents.AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.military_tech_outlined,
                        size: 14,
                        color: HomeComponents.AppTheme.primaryColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Lv.$studyLevel',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: HomeComponents.AppTheme.primaryColor,
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
                                          valueColor: AlwaysStoppedAnimation(HomeComponents.AppTheme.primaryColor),
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
                  icon: Icons.account_tree,
                  label: '知识图谱',
                  onPressed: () {
                    Navigator.push(
                      context,
                      PageTransition(
                        type: PageTransitionType.scale,
                        alignment: Alignment.center,
                        child: const MindMapScreen(),
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
                  icon: Icons.folder_outlined,
                  label: '题库管理',
                  onPressed: () {
                    Navigator.push(
                      context,
                      PageTransition(
                        type: PageTransitionType.scale,
                        alignment: Alignment.center,
                        child: const BankManagementScreen(),
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
                        type: PageTransitionType.scale,
                        alignment: Alignment.center,
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
                        type: PageTransitionType.scale,
                        alignment: Alignment.center,
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
                              color: HomeComponents.AppTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: HomeComponents.AppTheme.primaryColor,
              size: 24,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: HomeComponents.AppTheme.textSecondary,
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
    // 计算累计完成的章节数和总章节数（只统计有学习价值的节点）
    int totalLearnableSections = 0;
    int completedLearnableSections = 0;
    
    // 遍历所有已加载的题库
    final availableBanks = QuestionBankAccessor.instance.getAllAvailableBanksSynchronously();
    for (final bank in availableBanks) {
      // 递归遍历每个题库中的所有节点
      if (bank.data != null) {
        final result = _countLearnableSections(bank.data!);
        totalLearnableSections += result['total']!;
        completedLearnableSections += result['completed']!;
      }
    }
    
    // 计算累计进度百分比
    final progressPercentage = totalLearnableSections > 0 ? ((completedLearnableSections / totalLearnableSections) * 100).toInt() : 0;
    
    // 计算当日学习时间 - 使用今日实际学习时间（分钟）
    final todayStudyMinutes = StudyData.instance.getStudyTimeForDate(DateTime.now());
    final dailyStudyMinutes = todayStudyMinutes.toStringAsFixed(0);
    const targetMinutes = "300"; // 5小时 = 300分钟
    
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
    
    return HomeComponents.CommonComponents.buildCommonCard(
      Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 学习统计标题
            Text(
              '学习情况统计',
              style: HomeComponents.AppTheme.getSubtitleStyle(context),
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
                    "$dailyStudyMinutes 分钟", 
                    "/$targetMinutes 分钟目标"
                  ),
                ),
                Expanded(
                  child: _buildStatRow(
                    context,
                    Icons.assignment_turned_in, 
                    "累计进度", 
                    "$completedLearnableSections/$totalLearnableSections", 
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
                    fontSize: HomeComponents.TextScaler.instance.getScaledFontSize(context, 12),
                    fontWeight: FontWeight.w500,
                    color: HomeComponents.AppTheme.textPrimary,
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
                            fontSize: HomeComponents.TextScaler.instance.getScaledFontSize(context, 10),
                            color: isToday ? HomeComponents.AppTheme.primaryColor : HomeComponents.AppTheme.textSecondary,
                            fontWeight: isToday ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                        if (studyTime > 0)
                          Text(
                            "${studyTime.toStringAsFixed(1)}分",
                            style: TextStyle(
                              fontSize: HomeComponents.TextScaler.instance.getScaledFontSize(context, 9),
                              color: HomeComponents.AppTheme.textSecondary,
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
                    fontSize: HomeComponents.TextScaler.instance.getScaledFontSize(context, 11),
                    color: HomeComponents.AppTheme.textSecondary.withOpacity(0.8)
                  )
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: HomeComponents.TextScaler.instance.getScaledFontSize(context, 13),
                    fontWeight: FontWeight.w600,
                    color: HomeComponents.AppTheme.textPrimary,
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
        child: Stack(
          children: [
            // 背景层
            _buildBackground(),
            // 内容层
            SafeArea(
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
          ],
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
              // 直接导航到题库管理页面，选择后自动使用智能推荐模式
              Navigator.push(
                context,
                PageTransition(
                  type: PageTransitionType.rightToLeftPop,
                  childCurrent: widget,
                  alignment: const Alignment(10, 20),
                  child: const BankManagementScreen(),
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                ),
              ).whenComplete(() => LearningPlanManager.instance
                  .updateLearningPlan()
                  .whenComplete(() => setState(() {})));
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
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
                    const SizedBox(height: 8),
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
                        type: PageTransitionType.fade,
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
                          child: Center(
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
                              LaTeX(
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
                              
                              // 掌握度进度指示器
                              LinearProgressIndicator(
                                value: LearningPlanManager.instance.learningPlanItems[index].calculateSectionMastery(LearningPlanManager.instance.learningPlanItems[index].targetSection!),
                                backgroundColor: Colors.grey.withOpacity(0.2),
                                valueColor: AlwaysStoppedAnimation(
                                  LearningPlanManager.instance.learningPlanItems[index].calculateSectionMastery(LearningPlanManager.instance.learningPlanItems[index].targetSection!) >= 0.7
                                    ? AppTheme.successColor 
                                    : LearningPlanManager.instance.learningPlanItems[index].calculateSectionMastery(LearningPlanManager.instance.learningPlanItems[index].targetSection!) >= 0.4
                                      ? AppTheme.warningColor
                                      : Colors.redAccent,
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
                                      '掌握: ${(LearningPlanManager.instance.learningPlanItems[index].calculateSectionMastery(LearningPlanManager.instance.learningPlanItems[index].targetSection!) * 100).toStringAsFixed(0)}%',
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

  /// 递归统计有学习价值的节点数量
  Map<String, int> _countLearnableSections(List<Section> sections) {
    int total = 0;
    int completed = 0;

    for (final section in sections) {
      if (section.hasLearnableContent()) {
        // 这是一个有学习价值的节点，计入总数
        total++;
        
        // 检查是否已完成学习
        final sectionData = WrongQuestionBook.instance.sectionDataBox.get(section.id);
        if (sectionData != null && sectionData.learnTimes > 0) {
          completed++;
        }
      }
      
      // 递归处理子节点
      if (section.children != null && section.children!.isNotEmpty) {
        final childResult = _countLearnableSections(section.children!);
        total += childResult['total']!;
        completed += childResult['completed']!;
      }
    }

    return {'total': total, 'completed': completed};
  }

  Widget _buildBackground() {
    final studyData = StudyData.instance;
    
    // 如果启用了自定义背景且有背景图片
    if (studyData.useCustomBackground && 
        studyData.customBackgroundPath != null && 
        File(studyData.customBackgroundPath!).existsSync()) {
      
      return Transform.scale(
        scale: studyData.backgroundScale,
        child: Transform.translate(
          offset: Offset(
            studyData.backgroundOffsetX * MediaQuery.of(context).size.width * 0.1,
            studyData.backgroundOffsetY * MediaQuery.of(context).size.height * 0.1,
          ),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: FileImage(File(studyData.customBackgroundPath!)),
                fit: studyData.backgroundFit,
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.3),
                  BlendMode.darken,
                ),
              ),
            ),
          ),
        ),
      );
    }
    
    // 默认渐变背景
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }
}
