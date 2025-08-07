// ignore_for_file: unused_element

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/tool/question/question_bank.dart';
import 'package:flutter_application_1/tool/question/question_controller.dart';
import 'package:flutter_application_1/tool/statistics_manager.dart';
import 'package:flutter_application_1/tool/study_data.dart';
import 'package:flutter_application_1/tool/question/wrong_question_book.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import 'dart:math';
import 'package:flutter_application_1/screen/home/home.dart';

class LearningReportScreen extends StatefulWidget {
  const LearningReportScreen({super.key, required this.title});

  final String title;

  @override
  State<LearningReportScreen> createState() => _LearningReportScreenState();
}

class _LearningReportScreenState extends State<LearningReportScreen> {
  // Time periods for report filtering
  final List<String> _timePeriods = ['过去7天', '过去30天', '全部时间'];
  String _selectedPeriod = '过去7天';
  // Initialize directly instead of using late
  StatisticsManager _statsManager = StatisticsManager(StatisticsManager.PERIOD_WEEK);

  @override
  void initState() {
    super.initState();
    // No need to initialize here since we've done it inline
  }

  // Update statistics manager when period changes
  void _updateStatsManager() {
    setState(() {
      _statsManager = StatisticsManager(
        StatisticsManager.periodStringToDays(_selectedPeriod)
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TDNavBar(
        title: '学习报告',
        onBack: () => Navigator.of(context).pop(),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTimePeriodSelector(),
              const SizedBox(height: 12),
              _buildSummaryCard(),
              const SizedBox(height: 12),
              _buildStudyProgressChart(),
              const SizedBox(height: 12),
              _buildCategoryPerformance(),
              const SizedBox(height: 12),
              _buildStudyHabits(),
              const SizedBox(height: 12),
              _buildAchievements(),
            ],
          ),
        ),
      ),
    );
  }

  // Time period selector
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
                _updateStatsManager();
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

  // Summary card with key metrics in compact left-right layout
  Widget _buildSummaryCard() {
    // Calculate study data
    final studyMinutes = _statsManager.getStudyTimeInMinutes();
    final studyDays = _statsManager.getStudyDaysCount();
    final questionsCompleted = _statsManager.getCompletedQuestionsCount();
    final correctQuestions = _statsManager.getCorrectQuestionsCount();
    final wrongQuestions = _statsManager.getWrongQuestionsCount();
    final accuracyRate = _statsManager.calculateAccuracyRate();
    
    return CommonComponents.buildCommonCard(
      Padding(
        padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
        child: Row(
          children: [
            // Left side - Progress chart
            Expanded(
              flex: 1,
              child: _buildProgressIndicator(correctQuestions, wrongQuestions),
            ),
            Container(
              height: 80,
              margin: const EdgeInsets.only(right: 20),
              decoration: BoxDecoration(
                  border: Border(
                      right: BorderSide(
                          color: Colors.grey.withOpacity(0.3), width: 1))),
            ),
            // Right side - Stats
            Expanded(
              flex: 1,
              child: Align(
                alignment: Alignment.centerRight,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCompactStatRow(Icons.timer, "学习时长", "${studyMinutes.toInt()}分钟", "${_getAverageDailyStudyTime()}分钟/天"),
                    const SizedBox(height: 12),
                    _buildCompactStatRow(
                        Icons.assignment_turned_in, "累计完成", "$questionsCompleted题", "正确率${accuracyRate.toStringAsFixed(1)}%"),
                    const SizedBox(height: 12),
                    _buildCompactStatRow(Icons.insights, "连续学习", "${_getStudyStreakInfo()['currentStreak']}天", "$studyDays天总计"),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Compact row for statistics
  Widget _buildCompactStatRow(
      IconData icon, String title, String value, String subText) {
    return SizedBox(
      width: 180, // Fixed width for stats
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
              crossAxisAlignment: CrossAxisAlignment.start,
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
  
  // Progress indicator with accuracy visualization
  Widget _buildProgressIndicator(int correctQuestions, int wrongQuestions) {
    final total = correctQuestions + wrongQuestions;
    final double correctRate = total > 0 ? correctQuestions / total : 0.0;
    
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 100,
            height: 100,
            child: CircularProgressIndicator(
              value: correctRate,
              strokeWidth: 10,
              backgroundColor: Colors.redAccent.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation(AppTheme.successColor),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "${(correctRate * 100).toStringAsFixed(1)}%",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                "正确率",
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  // Get study streak information
  Map<String, dynamic> _getStudyStreakInfo() {
    return _statsManager.getStudyStreakInfo();
  }

  // Study progress chart showing daily study time
  Widget _buildStudyProgressChart() {
    // Get the daily study data
    final dailyData = _statsManager.getDailyStudyData();
    final days = ['一', '二', '三', '四', '五', '六', '日'];
    
    // Check if data exists and find max value for warnings
    final hasRealData = dailyData.any((time) => time > 0);
    final maxDailyValue = dailyData.fold(0.0, (max, value) => value > max ? value : max);
    
    return _buildSectionCard(
      title: '学习时间分析',
      content: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(
              height: 200,
              child: hasRealData 
                ? BarChart(_createBarChartData())
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.timeline_outlined, 
                          size: 48, 
                          color: Colors.grey.withOpacity(0.5)
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "暂无学习数据",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.withOpacity(0.8),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "完成学习后将显示您的学习时间分析",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
            ),
            const SizedBox(height: 16),
            // Warning if data was capped
            if (maxDailyValue > 480)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber, size: 16, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '检测到异常高的学习时间数据，图表已限制显示最高8小时',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            // Average study time indicator with more informative data
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.insights, color: AppTheme.primaryColor, size: 16),
                      const SizedBox(width: 8),
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
                          children: [
                            const TextSpan(text: '日均学习时间 '),
                            TextSpan(
                              text: '${_getAverageDailyStudyTime()}分钟',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (hasRealData) ...[
                    const SizedBox(height: 8),
                    const Divider(height: 1),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildDailyStat('最长学习', '${_getMaxDailyStudyMinutes().toInt()}分钟'),
                        _buildDailyStat('本周学习', '${_getWeeklyTotalStudyMinutes().toInt()}分钟'),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget for daily stats
  Widget _buildDailyStat(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryColor,
          ),
        ),
      ],
    );
  }

  // Get average daily study time
  String _getAverageDailyStudyTime() {
    final studyDays = _statsManager.getStudyDaysCount();
    final totalMinutes = _statsManager.getStudyTimeInMinutes();
    
    if (studyDays == 0) return "0";
    
    return (totalMinutes / studyDays).round().toString();
  }

  // Get max daily study minutes
  double _getMaxDailyStudyMinutes() {
    final dailyData = _statsManager.getDailyStudyData();
    return dailyData.fold(0.0, (max, minutes) => minutes > max ? minutes : max);
  }

  // Get total study minutes for the week
  double _getWeeklyTotalStudyMinutes() {
    final dailyData = _statsManager.getDailyStudyData();
    return dailyData.fold(0.0, (sum, minutes) => sum + minutes);
  }

  // Create data for bar chart showing study time by day
  BarChartData _createBarChartData() {
    final List<BarChartGroupData> barGroups = [];
    final days = ['一', '二', '三', '四', '五', '六', '日'];
    
    // Get daily activity data - this is already in chronological order
    // where index 0 = 6 days ago, index 6 = today
    final dailyData = _statsManager.getDailyStudyData();
    
    // Find the maximum value for proper scaling
    final maxValue = dailyData.fold(0.0, (max, value) => value > max ? value : max);
    
    // Cap the maximum value to prevent extremely tall bars (max 8 hours = 480 minutes per day)
    final cappedMaxValue = maxValue > 480 ? 480 : maxValue;
    
          for (int i = 0; i < 7; i++) {
        // The dailyData is already in the right order (last 7 days in chronological order)
        // so we can use i directly as the index
        final value = dailyData[i];
        // Cap individual values to prevent extremely tall bars
        final displayValue = value > 480 ? 480.0 : value;
      
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: displayValue.toDouble(),
              color: AppTheme.primaryColor,
              width: 15,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
          ],
          // Remove tooltip indicators completely
          showingTooltipIndicators: [],
        ),
      );
    }

    return BarChartData(
      barGroups: barGroups,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: cappedMaxValue > 60 ? 30 : 10,  // Adjust grid based on data scale
        getDrawingHorizontalLine: (value) => FlLine(
          color: Colors.grey.withOpacity(0.2),
          strokeWidth: 1,
        ),
      ),
      maxY: cappedMaxValue > 0 ? max(cappedMaxValue * 1.2, 60) : 60, // Add room above highest bar, with minimum of 60 minutes
      titlesData: FlTitlesData(
        show: true,
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              if (value % (cappedMaxValue > 60 ? 30 : 10) != 0) return const SizedBox();
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  value.toInt().toString(),
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppTheme.textSecondary,
                  ),
                ),
              );
            },
            reservedSize: 28,
          ),
        ),
        topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index >= 0 && index < 7) {
                // This index corresponds to a date that is (6-index) days ago
                // Calculate the actual date for this bar
                final daysAgo = 6 - index;
                final date = DateTime.now().subtract(Duration(days: daysAgo));
                
                // Get weekday (1-7, where 1 is Monday) and convert to 0-based index for days array
                final weekdayIndex = date.weekday - 1; 
                final day = days[weekdayIndex];
                
                // Mark today's label differently
                final isToday = daysAgo == 0;
                
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '周$day${isToday ? '(今)' : ''}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isToday ? AppTheme.primaryColor : AppTheme.textSecondary,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              }
              return const SizedBox();
            },
          ),
        ),
      ),
      barTouchData: BarTouchData(
        enabled: false, // Disable all touch interactions with the chart
      ),
      borderData: FlBorderData(show: false),
    );
  }

  // Category performance analysis
  Widget _buildCategoryPerformance() {
    final topics = _getTopics();
    final topicTree = _getTopicTree();
    // Add debug mode state
    bool debugMode = false;
    
    return _buildSectionCard(
      title: '知识点掌握情况',
      content: StatefulBuilder(
        builder: (context, setState) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Show loading indicator if we're fetching topics
                if (topics.isEmpty)
                  const Center(
                    child: Column(
                      children: [
                        SizedBox(height: 20),
                        Text(
                          '暂无知识点数据',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          '完成更多学习后将显示知识点掌握情况',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        SizedBox(height: 20),
                      ],
                    ),
                  )
                else
                  Column(
                    children: [
                      // Summary of knowledge mastery
                      _buildMasteryOverview(),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 16),

                      // 树状结构的知识点标题栏
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '知识树结构',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          // Debug mode toggle
                          InkWell(
                            onTap: () {
                              setState(() {
                                debugMode = !debugMode;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: debugMode 
                                  ? AppTheme.primaryColor.withOpacity(0.1) 
                                  : Colors.grey.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.bug_report,
                                    size: 14,
                                    color: debugMode ? AppTheme.primaryColor : Colors.grey,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '调试',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: debugMode ? AppTheme.primaryColor : Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      // 艾宾浩斯遗忘曲线说明
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.info_outline,
                              size: 18,
                              color: AppTheme.primaryColor,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '艾宾浩斯遗忘曲线',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '掌握度会随时间自然衰减，每个知识点右侧标签显示当前处于记忆的第几天。重复学习可以增强记忆稳定性，降低遗忘速度。',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.textSecondary.withOpacity(0.8),
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // 树状视图
                      ...topicTree.map((parentTopic) => 
                        _buildTopicTreeItem(parentTopic, debug: debugMode)
                      ),
                    ],
                  ),
                  
                const SizedBox(height: 16),
                // Recommendation
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.successColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.lightbulb, color: AppTheme.successColor, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: topics.isEmpty
                          ? const Text(
                              '建议开始学习更多知识点',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.successColor,
                              ),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '建议加强学习:',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.successColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Builder(
                                  builder: (context) {
                                    // Find the weakest node once to avoid multiple calculations
                                    final weakestNode = _findWeakestLeafNode(topicTree);
                                    final String recommendationText;
                                    
                                    if (weakestNode != null && weakestNode.containsKey('fullPath')) {
                                      recommendationText = _formatTopicPath(weakestNode['fullPath']);
                                    } else {
                                      recommendationText = _getWeakestTopic();
                                    }
                                    
                                    return Text(
                                      recommendationText,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppTheme.successColor,
                                      ),
                                    );
                                  }
                                ),
                              ],
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
      ),
    );
  }

  // Build mastery overview chart
  Widget _buildMasteryOverview() {
    final topics = _getTopics();
    final topicTree = _getTopicTree();
    
    if (topics.isEmpty || topicTree.isEmpty) return const SizedBox.shrink();
    
    // 直接从主题树中计算统计数据，确保与树形显示一致
    double totalMastery = 0.0;
    int topicCount = 0;
    int strongTopics = 0;
    int weakTopics = 0;
    
    // 递归遍历主题树，统计所有叶子节点（无子节点的主题）的掌握度
    void processNode(Map<String, dynamic> node) {
      final children = node['children'] as List<dynamic>;
      
      // 如果是叶子节点（没有子节点）或者是有进度信息的节点，计入统计
      if (children.isEmpty || (node.containsKey('progress') && node['progress'] is Map)) {
        // 获取节点掌握度，使用统一的计算方法
        double mastery = _calculateNodeMastery(node, topics);
        
        // 更新统计
        totalMastery += mastery;
        topicCount++;
        
        if (mastery >= 0.7) {
          strongTopics++;
        } else if (mastery < 0.4) {
          weakTopics++;
        }
      }
      
      // 递归处理子节点
      for (final child in children) {
        processNode(child as Map<String, dynamic>);
      }
    }
    
    // 处理所有根节点
    for (final rootTopic in topicTree) {
      processNode(rootTopic);
    }
    
    // 计算平均掌握度
    final averageMastery = topicCount > 0 ? totalMastery / topicCount : 0.0;
    
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildMasteryMetric(
              label: '平均掌握度',
              value: '${(averageMastery * 100).round()}%',
              color: _getMasteryColor(averageMastery),
            ),
            _buildMasteryMetric(
              label: '已掌握',
              value: '$strongTopics个',
              color: AppTheme.successColor,
            ),
            _buildMasteryMetric(
              label: '需加强',
              value: '$weakTopics个',
              color: weakTopics > 0 ? Colors.redAccent : AppTheme.successColor,
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Visualize topic distribution
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 8,
            child: Row(
              children: [
                Expanded(
                  flex: max(1, weakTopics),
                  child: Container(
                    color: Colors.redAccent,
                  ),
                ),
                Expanded(
                  flex: max(1, topicCount - weakTopics - strongTopics),
                  child: Container(
                    color: AppTheme.warningColor,
                  ),
                ),
                Expanded(
                  flex: max(1, strongTopics),
                  child: Container(
                    color: AppTheme.successColor,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 4),
                const Text(
                  '需加强',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppTheme.warningColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 4),
                const Text(
                  '基本掌握',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppTheme.successColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 4),
                const Text(
                  '熟练掌握',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildMasteryMetric({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
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
  
  Color _getMasteryColor(double mastery) {
    if (mastery < 0.4) {
      return Colors.redAccent;
    } else if (mastery < 0.7) {
      return AppTheme.warningColor;
    } else {
      return AppTheme.successColor;
    }
  }

  // Format date helper function
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return '今天';
    } else if (difference.inDays == 1) {
      return '昨天';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}天前';
    } else {
      return '${date.month}月${date.day}日';
    }
  }

  // Study habits analysis
  Widget _buildStudyHabits() {
    return _buildSectionCard(
      title: '学习习惯分析',
      content: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Grid layout for study habits stats
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              childAspectRatio: 2.8,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildCompactStudyHabitItem(
                  icon: Icons.access_time,
                  title: '最佳学习时段',
                  value: _getBestStudyTime(),
                ),
                _buildCompactStudyHabitItem(
                  icon: Icons.calendar_today,
                  title: '最佳学习日',
                  value: _getBestStudyDayOfWeek(),
                ),
                _buildCompactStudyHabitItem(
                  icon: Icons.repeat,
                  title: '学习规律性',
                  value: '${(_getStudyRegularity() * 100).toStringAsFixed(0)}%',
                ),
                _buildCompactStudyHabitItem(
                  icon: Icons.speed,
                  title: '平均做题速度',
                  value: '${_getAverageTimePerQuestion()}秒',
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildHourlyDistributionChart(),
            const SizedBox(height: 12),
            // Study habit advice
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        size: 14,
                        color: AppTheme.primaryColor,
                      ),
                      SizedBox(width: 6),
                      Text(
                        '学习建议',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6),
                  Text(
                    '• 尝试固定每天的学习时间，养成规律的学习习惯\n'
                    '• 在高效时段集中进行重难点学习\n'
                    '• 每次学习后进行错题分析和总结',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Compact study habit item
  Widget _buildCompactStudyHabitItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: AppTheme.primaryColor, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Hourly distribution chart
  Widget _buildHourlyDistributionChart() {
    final hourlyData = _statsManager.getHourlyStudyDistribution();
    final maxValue = hourlyData.values.fold(0.0, (max, value) => value > max ? value : max);
    
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.bar_chart,
                size: 14,
                color: AppTheme.primaryColor,
              ),
              SizedBox(width: 6),
              Text(
                '24小时学习分布',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 100,
            child: Row(
              children: List.generate(24, (hour) {
                final value = hourlyData[hour] ?? 0;
                final double normalizedHeight = maxValue > 0 ? (value / maxValue) : 0.0;
                
                return Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          width: double.infinity,
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            height: normalizedHeight * 70,
                            decoration: BoxDecoration(
                              color: _getColumnColor(hour, normalizedHeight),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                      if (hour % 6 == 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            '$hour',
                            style: const TextStyle(
                              fontSize: 9,
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
          const SizedBox(height: 4),
          // Time period indicators with more space
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _buildTimeIndicator('凌晨', Colors.purpleAccent),
                _buildTimeIndicator('上午', Colors.orangeAccent),
                _buildTimeIndicator('下午', Colors.greenAccent),
                _buildTimeIndicator('晚上', Colors.blueAccent),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper method for time period indicators
  Widget _buildTimeIndicator(String label, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color.withOpacity(0.7),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // Get color for hour column based on time and activity
  Color _getColumnColor(int hour, double normalizedHeight) {
    // No activity
    if (normalizedHeight < 0.05) {
      return Colors.grey.withOpacity(0.2);
    }
    
    // Morning (5-11)
    if (hour >= 5 && hour <= 11) {
      return Colors.orangeAccent.withOpacity(0.3 + (normalizedHeight * 0.7));
    }
    // Afternoon (12-17)
    else if (hour >= 12 && hour <= 17) {
      return Colors.greenAccent.withOpacity(0.3 + (normalizedHeight * 0.7));
    }
    // Evening (18-23)
    else if (hour >= 18 && hour <= 23) {
      return Colors.blueAccent.withOpacity(0.3 + (normalizedHeight * 0.7));
    }
    // Night (0-4)
    else {
      return Colors.purpleAccent.withOpacity(0.3 + (normalizedHeight * 0.7));
    }
  }

  // Achievements and badges
  Widget _buildAchievements() {
    return _buildSectionCard(
      title: '成就与徽章',
      content: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildAchievementBadge(
                  icon: Icons.emoji_events,
                  label: '学习达人',
                  isUnlocked: StudyData.instance.studyMinute >= 20,
                ),
                _buildAchievementBadge(
                  icon: Icons.auto_awesome,
                  label: '连续学习7天',
                  isUnlocked: StudyData.instance.studyCount >= 7,
                ),
                _buildAchievementBadge(
                  icon: Icons.psychology,
                  label: '正确率90%',
                  isUnlocked: _statsManager.calculateAccuracyRate() >= 90,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildAchievementBadge(
                  icon: Icons.verified,
                  label: '完成100题',
                  isUnlocked: WrongQuestionBook.instance.questionBox.length >= 100,
                ),
                _buildAchievementBadge(
                  icon: Icons.local_fire_department,
                  label: '单日5小时',
                  isUnlocked: false,
                ),
                _buildAchievementBadge(
                  icon: Icons.stars,
                  label: '全部掌握',
                  isUnlocked: false,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Section card builder (replaces CommonComponents.buildCommonCard for consistency with bank_manager.dart)
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

  // Individual achievement badge
  Widget _buildAchievementBadge({
    required IconData icon,
    required String label,
    required bool isUnlocked,
  }) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: isUnlocked ? AppTheme.primaryColor : Colors.grey.withOpacity(0.2),
            shape: BoxShape.circle,
            boxShadow: isUnlocked
                ? [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    )
                  ]
                : [],
          ),
          child: Icon(
            icon,
            color: isUnlocked ? Colors.white : Colors.grey,
            size: 30,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isUnlocked ? AppTheme.textPrimary : Colors.grey,
            fontWeight: isUnlocked ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  // HELPER METHODS FOR DATA CALCULATIONS

  // Get correct questions count based on actual data
  int _getCorrectQuestionsCount() {
    return _statsManager.getCorrectQuestionsCount();
  }

  // Get wrong questions count based on actual data
  int _getWrongQuestionsCount() {
    return _statsManager.getWrongQuestionsCount();
  }

  // Get all topics from loaded question banks
  List<String> _getTopics() {
    return _statsManager.getTopics();
  }

  // Get the weakest topic based on mastery calculations
  String _getWeakestTopic() {
    return _statsManager.getWeakestTopic();
  }

  // Get the best time to study based on actual data
  String _getBestStudyTime() {
    return _statsManager.getBestStudyTime();
  }

  // Calculate study regularity based on actual data
  double _getStudyRegularity() {
    return _statsManager.getStudyRegularity();
  }

  // Calculate average time per question
  String _getAverageTimePerQuestion() {
    return _statsManager.getAverageTimePerQuestion();
  }

  // Get topic detail including question count and mastery level
  Map<String, dynamic> _getTopicDetail(int topicIndex) {
    return _statsManager.getTopicDetail(topicIndex, _getTopics());
  }
  
  // Get best study day of week
  String _getBestStudyDayOfWeek() {
    return _statsManager.getBestStudyDayOfWeek();
  }

  // Create data for pie chart showing correct vs wrong questions
  PieChartData _createPieChartData() {
    return _statsManager.getPieChartData();
  }

  // 获取树状主题结构
  List<Map<String, dynamic>> _getTopicTree() {
    return _statsManager.getTopicTree();
  }

  // 统一计算节点掌握度的辅助方法
  double _calculateNodeMastery(Map<String, dynamic> node, List<String> topics) {
    // 快速返回：如果已经计算过此节点，直接返回缓存值（防止重复计算）
    if (node.containsKey('_cachedMastery')) {
      return node['_cachedMastery'] as double;
    }
    
    double mastery;
    final children = node['children'] as List<dynamic>;
    final hasChildren = children.isNotEmpty;
    
    // 计算本节点自身的掌握度（不考虑子节点）
    double selfMastery = _calculateNodeSelfMastery(node, topics);
    
    // 对于有子节点的情况
    if (hasChildren) {
      // 计算所有子节点的掌握度
      List<double> childrenMasteryValues = [];
      for (final child in children) {
        childrenMasteryValues.add(_calculateNodeMastery(child as Map<String, dynamic>, topics));
      }
      
      // 计算子节点的平均掌握度
      double childrenAvgMastery = childrenMasteryValues.isNotEmpty 
          ? childrenMasteryValues.reduce((a, b) => a + b) / childrenMasteryValues.length 
          : 0.0;
      
      // 对于父节点，主要使用子节点的平均掌握度（权重90%）
      // 仅在父节点有自己的学习记录时，适当考虑父节点自身的掌握度（权重10%）
      if (node.containsKey('progress') && node['progress'] is Map) {
        final progress = node['progress'] as Map<String, dynamic>;
        
        if ((progress.containsKey('learnTimes') && (progress['learnTimes'] as int) > 0) ||
            (progress.containsKey('lastLearnTime') && (progress['lastLearnTime'] as int?) != null)) {
          // 父节点有学习记录，但仍以子节点平均为主
          mastery = (childrenAvgMastery * 0.9) + (selfMastery * 0.1);
        } else {
          // 父节点无学习记录，完全使用子节点平均
          mastery = childrenAvgMastery;
        }
      } else {
        // 没有进度信息的父节点，使用子节点平均
        mastery = childrenAvgMastery;
      }
      
      // 调试输出
      // if (mastery < 0.4) {
      //   print('节点 ${node['name']} 掌握度低: $mastery, 子节点掌握度: $childrenMasteryValues, 自身掌握度: $selfMastery');
      // }
    } else {
      // 没有子节点，使用自身掌握度
      mastery = selfMastery;
    }
    
    // 缓存计算结果
    node['_cachedMastery'] = mastery.clamp(0.1, 1.0);
    
    // 确保掌握度在有效范围内
    return mastery.clamp(0.1, 1.0);
  }
  
  // 计算节点自身的掌握度（不考虑子节点）
  double _calculateNodeSelfMastery(Map<String, dynamic> node, List<String> topics) {
    double mastery = 0.5; // 默认值
    DateTime? lastStudyTime;
    int studyCount = 0;
    final String? sectionId = node['id'] as String?;
    
    // 从节点进度信息获取掌握度
    if (node.containsKey('progress') && node['progress'] is Map) {
      final progress = node['progress'] as Map<String, dynamic>;
      
      // 使用完成率作为掌握度指标
      if (progress.containsKey('completionRate')) {
        mastery = progress['completionRate'] as double;
      } else if (progress.containsKey('learnTimes') && 
                progress.containsKey('allNeedCompleteQuestion') && 
                progress['allNeedCompleteQuestion'] > 0) {
        // 如果没有直接的完成率，但有学习次数和需要完成的问题数
        mastery = progress['learnTimes'] > 0 ? 0.7 : 0.3; // 简单估计
        
        if (progress['alreadyCompleteQuestion'] != null && 
            progress['allNeedCompleteQuestion'] != null &&
            progress['allNeedCompleteQuestion'] > 0) {
          // 如果有更详细的完成题目数据，计算更精确的掌握度
          mastery = progress['alreadyCompleteQuestion'] / 
                   progress['allNeedCompleteQuestion'];
        }
      }
      
      // 获取学习次数
      if (progress.containsKey('learnTimes')) {
        studyCount = progress['learnTimes'] as int;
      }
      
      // 获取最后学习时间
      if (progress.containsKey('lastLearnTime') && progress['lastLearnTime'] != null && progress['lastLearnTime'] > 0) {
        lastStudyTime = DateTime.fromMillisecondsSinceEpoch(progress['lastLearnTime'] as int);
      }
    } 
    // 如果没有进度信息，但有索引，则使用旧方法
    else if (node.containsKey('index')) {
      final topicIndex = node['index'] as int?;
      if (topicIndex != null) {
        if (topicIndex < topics.length) {
          mastery = _statsManager.getTopicMastery(topicIndex, topics);
        }
      }
    }
    
    // 如果有sectionId，尝试从StudyData获取更精确的遗忘曲线数据
    if (sectionId != null) {
      final topicMastery = StudyData.instance.getTopicMastery(sectionId);
      if (topicMastery > 0) {
        mastery = topicMastery;
      }
      
      final topicStudyCount = StudyData.instance.getTopicStudyCount(sectionId);
      if (topicStudyCount > 0) {
        studyCount = topicStudyCount;
      }
      
      final topicLastStudyTime = StudyData.instance.getTopicLastStudyTime(sectionId);
      if (topicLastStudyTime != null) {
        lastStudyTime = topicLastStudyTime;
      }
    }
    
    // 应用艾宾浩斯遗忘曲线
    if (lastStudyTime != null) {
      // 计算距离上次学习的天数 (使用小数表示更精确的时间)
      final daysSinceLastStudy = DateTime.now().difference(lastStudyTime).inHours / 24.0;
      
      // 获取更精准的学习次数，确保考虑所有学习记录
      int effectiveStudyCount = studyCount;
      if (sectionId != null) {
        effectiveStudyCount = max(StudyData.instance.getTopicStudyCount(sectionId), studyCount);
      }
      
      // 基于艾宾浩斯曲线计算保留率
      // 经典艾宾浩斯曲线使用单一的指数衰减函数: R = e^(-t/S)
      // 其中S是稳定性参数，t是时间（天）
      double retentionRate;
      
      // 使学习次数成为关键因素，强化其对记忆的影响
      // 第一次学习的遗忘最快，每次重复学习大幅提高记忆保留
      if (effectiveStudyCount <= 1) {
        // 首次学习，使用较为平缓的衰减曲线
        const stabilityFactor = 2.5; // 中等稳定性
        retentionRate = exp(-daysSinceLastStudy / stabilityFactor);
      } else if (effectiveStudyCount == 2) {
        // 第二次学习，记忆稳定性显著提升
        const stabilityFactor = 5.0;
        retentionRate = exp(-daysSinceLastStudy / stabilityFactor);
        // 确保至少保留40%
        retentionRate = max(retentionRate, 0.4);
      } else if (effectiveStudyCount == 3) {
        // 第三次学习，记忆更加牢固
        const stabilityFactor = 8.0;
        retentionRate = exp(-daysSinceLastStudy / stabilityFactor);
        // 确保至少保留50%
        retentionRate = max(retentionRate, 0.5);
      } else if (effectiveStudyCount == 4) {
        // 第四次学习，记忆进入长期记忆
        const stabilityFactor = 12.0;
        retentionRate = exp(-daysSinceLastStudy / stabilityFactor);
        // 确保至少保留60%
        retentionRate = max(retentionRate, 0.6);
      } else {
        // 5次及以上，记忆非常牢固
        final stabilityFactor = 15.0 + ((effectiveStudyCount - 5) * 3.0);
        retentionRate = exp(-daysSinceLastStudy / stabilityFactor);
        // 确保至少保留70%，且随学习次数增加而提高
        retentionRate = max(retentionRate, 0.7 + min((effectiveStudyCount - 5) * 0.05, 0.25));
      }
      
      // 应用遗忘曲线，计算实际掌握度
      mastery = (mastery * retentionRate).clamp(0.1, 1.0);
    }
    
    // 确保掌握度在有效范围内
    return mastery.clamp(0.1, 1.0);
  }

  // 构建树状主题项
  Widget _buildTopicTreeItem(Map<String, dynamic> topic, {int level = 0, bool debug = false}) {
    final children = topic['children'] as List<dynamic>;
    final hasChildren = children.isNotEmpty;
    final topicName = topic['name'] as String;
    final sectionId = topic['id'] as String?;
    final topics = _getTopics();
    
    // 直接从节点获取进度信息，而不是重新计算
    double mastery = _calculateNodeMastery(topic, topics);
    int learnTimes = 0;
    int completedQuestions = 0;
    int totalQuestions = 0;
    int retentionDay = 0; // 添加保留天数变量
    DateTime? lastStudyTime; // 添加最后学习时间变量
    
    // 获取学习次数和题目完成情况用于调试显示
    if (topic.containsKey('progress') && topic['progress'] is Map) {
      final progress = topic['progress'] as Map<String, dynamic>;
      
      // 获取学习次数和题目完成情况
      if (progress.containsKey('learnTimes')) {
        learnTimes = progress['learnTimes'] as int;
      }
      
      if (progress.containsKey('alreadyCompleteQuestion')) {
        completedQuestions = progress['alreadyCompleteQuestion'] as int;
      }
      
      if (progress.containsKey('allNeedCompleteQuestion')) {
        totalQuestions = progress['allNeedCompleteQuestion'] as int;
      }
      
      // 获取最后学习时间（用于计算保留天数）
      if (progress.containsKey('lastLearnTime') && progress['lastLearnTime'] != null && progress['lastLearnTime'] > 0) {
        lastStudyTime = DateTime.fromMillisecondsSinceEpoch(progress['lastLearnTime'] as int);
        retentionDay = DateTime.now().difference(lastStudyTime).inDays + 1;
      }
    }
    
    // 如果有sectionId，尝试从StudyData获取更精确的遗忘曲线数据
    if (sectionId != null) {
      final topicLastStudyTime = StudyData.instance.getTopicLastStudyTime(sectionId);
      if (topicLastStudyTime != null) {
        lastStudyTime = topicLastStudyTime;
        retentionDay = DateTime.now().difference(lastStudyTime).inDays + 1;
      }
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: level * 20.0, bottom: 8, top: 8),
          child: Row(
            children: [
              // 层级指示线
              if (level > 0) ...[
                Container(
                  width: 12,
                  height: 2,
                  color: Colors.grey.withOpacity(0.5),
                ),
                const SizedBox(width: 8),
              ],
              
              // 折叠/展开图标
              if (hasChildren)
                const Icon(
                  Icons.arrow_drop_down,
                  size: 20,
                  color: AppTheme.primaryColor,
                )
              else
                const SizedBox(width: 20),
              
              // 主题名称和保留天数
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _truncateTopicName(topicName, level),
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: level == 0 ? FontWeight.w600 : FontWeight.normal,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        // 添加保留天数显示
                        if (retentionDay > 0 && mastery > 0.1)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: retentionDay > 14 
                                ? Colors.redAccent.withOpacity(0.1) 
                                : AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              retentionDay > 1 ? '第$retentionDay天' : '今天学习',
                              style: TextStyle(
                                fontSize: 10,
                                color: retentionDay > 14 
                                  ? Colors.redAccent 
                                  : AppTheme.primaryColor,
                              ),
                            ),
                          ),
                      ],
                    ),
                    // 显示调试信息
                    if (debug && sectionId != null)
                      Text(
                        'ID: $sectionId, 完成: $completedQuestions/$totalQuestions, 学习次数: $learnTimes${lastStudyTime != null ? ', 上次: ${_formatDate(lastStudyTime)}' : ''}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                  ],
                ),
              ),
              
              // 掌握度指示器
              Container(
                width: 60,
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: Colors.grey.withOpacity(0.2),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: mastery,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: _getMasteryColor(mastery),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 8),
              Text(
                '${(mastery * 100).round()}%',
                style: TextStyle(
                  fontSize: 12,
                  color: _getMasteryColor(mastery),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        
        // 递归构建子项，允许显示3层（0-父级，1-子级，2-孙级）
        if (hasChildren && level < 2)
          ...children.map((child) => _buildTopicTreeItem(child as Map<String, dynamic>, level: level + 1, debug: debug)),
      ],
    );
  }
  
  // 截断主题名称，根据层级设置最大长度
  String _truncateTopicName(String name, int level) {
    // 根据层级设置不同的最大长度
    int maxLength;
    if (level == 0) {
      maxLength = 12; // 根节点可以显示较长名称
    } else if (level == 1) {
      maxLength = 10; // 子节点显示中等长度
    } else {
      maxLength = 8; // 孙节点显示较短名称
    }
    
    if (name.length <= maxLength) {
      return name;
    }
    
    // 截断并添加省略号
    return '${name.substring(0, maxLength)}...';
  }

  // Find the weakest leaf node in the topic tree
  Map<String, dynamic>? _findWeakestLeafNode(List<Map<String, dynamic>> topicTree) {
    Map<String, dynamic>? weakestNode;
    double lowestMastery = 1.0;
    final topics = _getTopics();
    
    void searchNode(Map<String, dynamic> node, List<String> parentPath) {
      final List<dynamic> children = node['children'] as List<dynamic>;
      final nodeName = node['name'] as String;
      final currentPath = [...parentPath, nodeName];
      
      // If this is a leaf node (no children) or deepest level we want to analyze
      if (children.isEmpty || currentPath.length >= 3) { // Assuming we want to go at most 3 levels deep
        // 使用统一的方法计算掌握度
        final mastery = _calculateNodeMastery(node, topics);
        
        if (mastery < lowestMastery) {
          lowestMastery = mastery;
          // Store the node along with its full path
          weakestNode = {
            ...node,
            'fullPath': currentPath
          };
        }
      } else {
        // Continue searching in children
        for (final child in children) {
          searchNode(child as Map<String, dynamic>, currentPath);
        }
      }
    }
    
    // Start the search for each root topic
    for (final rootTopic in topicTree) {
      searchNode(rootTopic, []);
    }
    
    return weakestNode;
  }

  // Format a path to show the full knowledge point hierarchy
  String _formatTopicPath(List<dynamic> path) {
    if (path.isEmpty) return "未知知识点";
    
    if (path.length == 1) {
      return path[0] as String;
    }
    
    // Format as "Parent > Child > Grandchild"
    return path.join(" > ");
  }
}