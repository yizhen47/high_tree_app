import 'dart:math';
import 'dart:ui';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/screen/home/home.dart';
import 'package:flutter_application_1/tool/question/question_bank.dart';
import 'package:flutter_application_1/tool/question/question_controller.dart';
import 'package:flutter_application_1/tool/question/wrong_question_book.dart';
import 'package:flutter_application_1/tool/study_data.dart';
import 'package:flutter_application_1/tool/question/question_bank_accessor.dart';

class StatisticsManager {
  // Time periods in days
  static const int PERIOD_WEEK = 7;
  static const int PERIOD_MONTH = 30;
  static const int PERIOD_ALL_TIME = 9999;

  // Current selected period
  final int selectedPeriod;

  // Constructor
  StatisticsManager(this.selectedPeriod);

  // Convert period to readable string
  String _periodToString(int period) {
    switch (period) {
      case PERIOD_WEEK:
        return '过去7天';
      case PERIOD_MONTH:
        return '过去30天';
      case PERIOD_ALL_TIME:
        return '全部时间';
      default:
        return '过去$period天';
    }
  }

  // Convert string period to int days
  static int periodStringToDays(String periodString) {
    switch (periodString) {
      case '过去7天':
        return PERIOD_WEEK;
      case '过去30天':
        return PERIOD_MONTH;
      default: // '全部时间'
        return PERIOD_ALL_TIME;
    }
  }

  // Get study time in minutes for the selected period
  double getStudyTimeInMinutes() {
    final now = DateTime.now();
    // print('[StudyTimeAnalysis] 开始分析学习时间 - 选择期间: ${_periodToString(selectedPeriod)}');
    
    if (selectedPeriod == PERIOD_ALL_TIME) {
      final totalHours = StudyData.instance.studyMinute;
      final totalMinutes = totalHours * 60;
      print('[StudyTimeAnalysis] 全部时间学习时长: ${totalHours.toStringAsFixed(1)}小时 (${totalMinutes.toStringAsFixed(0)}分钟)');
      return totalMinutes;
    }
    
    // Get actual time data for the period
    double totalMinutes = 0;
    int activeDays = 0;
    // print('[StudyTimeAnalysis] 分析过去${selectedPeriod}天的学习数据:');
    
    for (int i = 0; i < selectedPeriod; i++) {
      final date = now.subtract(Duration(days: i));
      final dayMinutes = StudyData.instance.getStudyTimeForDate(date);
      totalMinutes += dayMinutes;
      
      if (dayMinutes > 0) {
        activeDays++;
        print('[DEBUG] ${date.toString().substring(0, 10)}: ${dayMinutes.toStringAsFixed(0)}分钟 = ${(dayMinutes/60).toStringAsFixed(1)}小时');
      }
    }
    
    print('[DEBUG] 总计: ${totalMinutes.toStringAsFixed(0)}分钟 = ${(totalMinutes/60).toStringAsFixed(1)}小时, 活跃天数: $activeDays/$selectedPeriod天');
    return totalMinutes;
  }

  // Get study days count for the selected period
  int getStudyDaysCount() {
    final now = DateTime.now();
    int studyDaysCount = 0;
    
    // Use actual hourly data to count days with study activity
    for (int i = 0; i < (selectedPeriod == PERIOD_ALL_TIME ? 365 : selectedPeriod); i++) {
      final date = now.subtract(Duration(days: i));
      if (StudyData.instance.getStudyTimeForDate(date) > 0) {
        studyDaysCount++;
      }
    }
    
    return studyDaysCount > 0 ? studyDaysCount : StudyData.instance.studyCount;
  }

  // Get completed questions count for the selected period
  int getCompletedQuestionsCount() {
    int totalQuestions = WrongQuestionBook.instance.questionBox.length;
    
    if (selectedPeriod == PERIOD_ALL_TIME) {
      return totalQuestions;
    }
    
    // Approximate for the period
    double scaleFactor = selectedPeriod == PERIOD_WEEK ? 0.3 : 0.7;
    return (totalQuestions * scaleFactor).round();
  }

  // Get wrong questions count for the selected period
  int getWrongQuestionsCount() {
    int totalWrong = WrongQuestionBook.instance.getWrongQuestionIds().length;
    
    if (selectedPeriod == PERIOD_ALL_TIME) {
      return totalWrong;
    }
    
    // Approximate for the period
    double scaleFactor = selectedPeriod == PERIOD_WEEK ? 0.3 : 0.7;
    return (totalWrong * scaleFactor).round();
  }

  // Calculate accuracy rate for the selected period
  double calculateAccuracyRate() {
    int completedQuestions = getCompletedQuestionsCount();
    int wrongQuestions = getWrongQuestionsCount();
    
    if (completedQuestions == 0) return 0;
    return ((completedQuestions - wrongQuestions) / completedQuestions) * 100;
  }

  // Get daily study data for the selected period
  List<double> getDailyStudyData() {
    final now = DateTime.now();
    final List<double> dailyData = List.filled(7, 0);
    final days = ['一', '二', '三', '四', '五', '六', '日'];
    
    // print('[DailyStudyAnalysis] 开始分析每日学习数据');
    
    // For 7-day period, use actual data
    for (int i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: 6 - i)); // Last 7 days in chronological order
      if (selectedPeriod == PERIOD_WEEK || i >= 7 - selectedPeriod) {
        final dayMinutes = StudyData.instance.getStudyTimeForDate(date);
        dailyData[i] = dayMinutes;
        
        if (dayMinutes > 0) {
          // print('[DailyStudyAnalysis] 周${days[i]} (${date.toString().substring(5, 10)}): ${(dayMinutes/60).toStringAsFixed(1)}小时');
        }
      }
    }
    
    // If no data is available, generate some example data
    if (dailyData.every((element) => element == 0)) {
      // Generate realistic daily data based on study patterns (same as before)
      double totalMinutes = StudyData.instance.studyMinute * 60; // studyMinute is in hours, convert to minutes
      double avgMinutes = totalMinutes / 7;
      
      for (int i = 0; i < 7; i++) {
        // Create variations for different days
        double factor = 1.0;
        if (i < 5) { // Weekdays
          factor = 0.7 + (i / 10); // Gradually increases during weekdays
        } else { // Weekend
          factor = 1.2; // Higher on weekends
        }
        
        // Add random variation but maintain pattern
        final random = Random(i + StudyData.instance.studyCount);
        final variation = 0.8 + (random.nextDouble() * 0.4);
        
        dailyData[i] = avgMinutes * factor * variation;
      }
    }
    
    return dailyData;
  }
  
  // Get topic mastery for the selected period and topic
  double getTopicMastery(int topicIndex, List<String> topics) {
    if (topicIndex >= topics.length) return 0.1;
    
    final topicId = _getTopicIdFromName(topics[topicIndex]);
    
    // If we have actual mastery data for this topic, use it
    if (topicId != null) {
      // Use StudyData's getCurrentTopicMastery which includes Ebbinghaus forgetting curve
      final mastery = StudyData.instance.getCurrentTopicMastery(topicId);
      if (mastery > 0.0) {
        return mastery;
      }
    }
    
    // Get all section data and filter by topic
    final sectionDataBoxKeys = WrongQuestionBook.instance.sectionDataBox.keys;
    final topicSections = sectionDataBoxKeys.where((key) => 
      key.toString().toLowerCase().contains(topics[topicIndex].toLowerCase())).toList();
    
    if (topicSections.isEmpty) {
      // 改用基于上次学习时间的遗忘曲线计算，而不是随机方法
      final now = DateTime.now();
      DateTime? lastStudyTime;
      
      // 尝试从StudyData查找与该主题相关的最后学习时间
      // 使用QuestionBankAccessor获取学习计划项
      List<Section> matchingSections = QuestionBankAccessor.instance.getSectionsByTopic(topics[topicIndex]);
      
      for (final section in matchingSections) {
        // 查找该section的最后学习时间
        if (section.id.isNotEmpty) {
          final sectionId = section.id;
          final learnTime = StudyData.instance.getTopicLastStudyTime(sectionId);
          if (learnTime != null && (lastStudyTime == null || learnTime.isAfter(lastStudyTime))) {
            lastStudyTime = learnTime;
          }
        }
      }
      
      // 如果没有找到学习记录，返回最低掌握度
      if (lastStudyTime == null) {
        return 0.1; // 最低掌握度
      }
      
      // 基于遗忘曲线计算掌握度衰减
      // 参考艾宾浩斯遗忘曲线：R = e^(-t/S)，其中R是保留率，t是时间，S是相对强度系数
      final daysDifference = now.difference(lastStudyTime).inHours / 24.0;
      // 计算记忆保留率，S设为30表示中等难度的知识点
      final retentionRate = exp(-daysDifference / 30.0);
      
      // 掌握度从0.1到0.95，基于保留率线性映射
      final mastery = 0.1 + (retentionRate * 0.85);
      
      return max(0.1, min(0.95, mastery));
    }
    
    // Calculate completion rate for this topic
    int completedSections = 0;
    int totalCorrectQuestions = 0;
    int totalQuestions = 0;
    
    for (var key in topicSections) {
      final sectionData = WrongQuestionBook.instance.sectionDataBox.get(key);
      if (sectionData != null) {
        // Filter by time period if appropriate
        if (selectedPeriod != PERIOD_ALL_TIME) {
          final now = DateTime.now();
          final periodStart = now.subtract(Duration(days: selectedPeriod));
          if (sectionData.lastLearnTime < periodStart.millisecondsSinceEpoch) {
            continue;
          }
        }
        
        if (sectionData.learnTimes > 0) {
          completedSections++;
        }
        
        // Add question completion information
        if (sectionData.allNeedCompleteQuestion > 0) {
          totalQuestions += sectionData.allNeedCompleteQuestion;
          totalCorrectQuestions += sectionData.alreadyCompleteQuestion;
        }
      }
    }
    
    // Calculate mastery based on section completion and question accuracy
    double sectionCompletionRate = topicSections.isEmpty ? 0.1 : 
      completedSections / topicSections.length;
    
    double questionAccuracyRate = totalQuestions > 0 ? 
      totalCorrectQuestions / totalQuestions : 0.5;
    
    // Weight: 60% completion rate, 40% accuracy
    double masteryScore = (0.6 * sectionCompletionRate) + (0.4 * questionAccuracyRate);
    
    return max(0.1, min(1.0, masteryScore));
  }

  // Get all topics from loaded question banks
  List<String> getTopics() {
    // 使用QuestionBankAccessor获取所有主题
    Set<String> topicsSet = QuestionBankAccessor.instance.getAllTopics();
    final topics = topicsSet.toList();
    
    // 如果没有实际主题，返回默认主题列表
    if (topics.isEmpty) {
      return ['数学', '语文', '英语', '物理', '化学', '生物', '历史', '地理'];
    }
    
    return topics;
  }
  
  // 获取树状主题结构
  List<Map<String, dynamic>> getTopicTree() {
    // 创建主题树
    Map<String, Map<String, dynamic>> topicMap = {};
    List<Map<String, dynamic>> rootTopics = [];
    int topicIndex = 0;
    
    // 用于跟踪已处理的题库ID，避免重复添加相同题库
    Set<String> processedBankIds = {};
    
    // 使用QuestionBankAccessor获取所有可用的题库
    final banks = QuestionBankAccessor.instance.getAllAvailableBanksSynchronously();
    
    for (final bank in banks) {
      if (bank.data != null) {
        // 获取题库ID，如果为空则使用默认值
        final bankId = bank.id ?? 'unknown_bank_${processedBankIds.length}';
        
        // 跳过已处理过的题库
        if (processedBankIds.contains(bankId)) {
          continue;
        }
        
        // 标记题库为已处理
        processedBankIds.add(bankId);
        
        // 使用题库名称作为根主题
        final bankName = bank.displayName ?? '未命名题库';
        
        // 获取题库级别的进度数据
        final bankProgress = getBankProgress(bankId);
        
        if (!topicMap.containsKey(bankName)) {
          final rootTopic = {
            'name': bankName,
            'index': null, // 根主题没有具体索引
            'children': <Map<String, dynamic>>[],
            'bankId': bankId, // 保存题库ID以便引用
            'progress': bankProgress,
            'isCompleted': bankProgress['completionRate'] >= 1.0,
          };
          topicMap[bankName] = rootTopic;
          rootTopics.add(rootTopic);
        }
        
        // 递归添加章节为子主题，直接传递题库ID
        final children = topicMap[bankName]!['children'] as List<Map<String, dynamic>>;
        _addSectionToTree(bank.data!, children, topicIndex, bankId);
        
        // 更新章节索引，为下一个题库做准备
        topicIndex += _countAllSections(bank.data!);
      }
    }
    
    // 如果没有实际主题，返回默认主题树
    if (rootTopics.isEmpty) {
      final defaultSubjects = [
        {'name': '数学', 'children': [
          {'name': '代数', 'index': 0, 'children': [], 'progress': {'completionRate': 0.0}, 'isCompleted': false},
          {'name': '几何', 'index': 1, 'children': [], 'progress': {'completionRate': 0.0}, 'isCompleted': false},
          {'name': '统计', 'index': 2, 'children': [], 'progress': {'completionRate': 0.0}, 'isCompleted': false},
        ], 'progress': {'completionRate': 0.0}, 'isCompleted': false},
        {'name': '语文', 'children': [
          {'name': '阅读理解', 'index': 3, 'children': [], 'progress': {'completionRate': 0.0}, 'isCompleted': false},
          {'name': '写作', 'index': 4, 'children': [], 'progress': {'completionRate': 0.0}, 'isCompleted': false},
        ], 'progress': {'completionRate': 0.0}, 'isCompleted': false},
        {'name': '英语', 'children': [
          {'name': '词汇', 'index': 5, 'children': [], 'progress': {'completionRate': 0.0}, 'isCompleted': false},
          {'name': '语法', 'index': 6, 'children': [], 'progress': {'completionRate': 0.0}, 'isCompleted': false},
          {'name': '阅读', 'index': 7, 'children': [], 'progress': {'completionRate': 0.0}, 'isCompleted': false},
        ], 'progress': {'completionRate': 0.0}, 'isCompleted': false},
      ];
      return defaultSubjects;
    }
    
    return rootTopics;
  }
  
  // 计算章节总数（用于索引计算）
  int _countAllSections(List<Section> sections) {
    int count = sections.length;
    
    for (final section in sections) {
      if (section.children != null && section.children!.isNotEmpty) {
        // 限制为最多两层，所以只需要加上直接子节点数量
        count += section.children!.length;
        
        // 如果需要计算再深一层，可以使用以下代码（但当前我们限制为两层）
        // for (final child in section.children!) {
        //   if (child.children != null) {
        //     count += child.children!.length;
        //   }
        // }
      }
    }
    
    return count;
  }
  
  // 递归检查章节是否有学习价值（包括子节点）
  bool _hasLearnableContentRecursive(Section section) {
    // 如果当前节点有学习价值，直接返回true
    if (section.hasLearnableContent()) {
      return true;
    }
    
    // 如果没有子节点，返回false
    if (section.children == null || section.children!.isEmpty) {
      return false;
    }
    
    // 递归检查子节点
    for (final child in section.children!) {
      if (_hasLearnableContentRecursive(child)) {
        return true;
      }
    }
    
    return false;
  }
  
  // 递归添加章节到树中
  void _addSectionToTree(List<Section> sections, List<Map<String, dynamic>> targetList, int topicIndex, [String? bankId]) {
    int currentIndex = topicIndex; // 使用局部变量跟踪当前索引
    int totalSections = 0;
    int learnableSections = 0;
    int filteredSections = 0;
    
    // 如果没有提供题库ID，尝试查找
    if (bankId == null) {
      for (final bank in QuestionBankAccessor.instance.getAllAvailableBanksSynchronously()) {
        if (bank.data == sections) {
          bankId = bank.id;
          break;
        }
      }
    }
    

    
    for (final section in sections) {
      totalSections++;
      
      // 检查章节是否有学习价值（包括子节点）
      bool hasLearnableContent = _hasLearnableContentRecursive(section);
      
      if (hasLearnableContent) {
        learnableSections++;
        
      // 获取章节学习进度数据
      final progress = _getSectionProgress(section.id, bankId);
      
      // 确保进度信息包含计算后的完成率
      _ensureProgressCompletionRate(progress);
      
      final childTopic = {
        'name': section.title,
        'index': currentIndex,
        'children': <Map<String, dynamic>>[],
        'id': section.id,
        'progress': progress,
        'isCompleted': progress['learnTimes'] > 0,
          'hasLearnableContent': true,
      };
      
      targetList.add(childTopic);
      currentIndex++; // 每个章节递增索引
        

      
      // 递归处理子章节
      if (section.children != null && section.children!.isNotEmpty) {
        // 递归调用并更新索引值（第一层深度为1）
        currentIndex = _addSectionToTreeWithReturn(
          section.children!,
          childTopic['children'] as List<Map<String, dynamic>>,
          currentIndex,
          2,
          bankId
        );
      }
      } else {
        filteredSections++;

        
        // 如果当前章节没有学习价值，但有子章节，仍需要检查子章节
        if (section.children != null && section.children!.isNotEmpty) {
          // 直接处理子章节，不添加当前无价值节点
          currentIndex = _addSectionToTreeWithReturn(
            section.children!,
            targetList, // 直接添加到当前层级，不创建新的父节点
            currentIndex,
            2,
            bankId
          );
        }
      }
    }
    

  }
  
  // 返回更新后索引的递归方法
  int _addSectionToTreeWithReturn(
    List<Section> sections, 
    List<Map<String, dynamic>> targetList, 
    int topicIndex, 
    [int depth = 1, String? bankId]
  ) {
    int currentIndex = topicIndex;
    int filteredAtDepth = 0;
    int addedAtDepth = 0;
    
    // 限制最多三层深度（题库-一层-二层-三层）
    if (depth > 3) {
      return currentIndex;
    }
    
    for (final section in sections) {
      // 检查章节是否有学习价值（包括子节点）
      bool hasLearnableContent = _hasLearnableContentRecursive(section);
      
      if (hasLearnableContent) {
        addedAtDepth++;
        
      // 获取章节学习进度数据
      final progress = _getSectionProgress(section.id, bankId);
      
      // 确保进度信息包含计算后的完成率
      _ensureProgressCompletionRate(progress);
      
      final childTopic = {
        'name': section.title,
        'index': currentIndex,
        'children': <Map<String, dynamic>>[],
        'id': section.id,
        'progress': progress,
        'isCompleted': progress['learnTimes'] > 0,
          'hasLearnableContent': true,
      };
      
      targetList.add(childTopic);
      currentIndex++; // 每个章节递增索引
      
      // 递归处理子章节
      if (section.children != null && section.children!.isNotEmpty) {
        currentIndex = _addSectionToTreeWithReturn(
          section.children!,
          childTopic['children'] as List<Map<String, dynamic>>,
          currentIndex,
          depth + 1,
          bankId
        );
      }
      } else {
        filteredAtDepth++;
        
        // 如果当前章节没有学习价值，但有子章节，仍需要检查子章节
        if (section.children != null && section.children!.isNotEmpty) {
          // 直接处理子章节，不添加当前无价值节点
          currentIndex = _addSectionToTreeWithReturn(
            section.children!,
            targetList, // 直接添加到当前层级，不创建新的父节点
            currentIndex,
            depth + 1,
            bankId
          );
        }
      }
    }
    

    
    return currentIndex; // 返回更新后的索引
  }
  
  // 确保进度信息包含完成率，如果不存在则计算
  void _ensureProgressCompletionRate(Map<String, dynamic> progress) {
    // 如果已经有完成率，则不需要计算
    if (progress.containsKey('completionRate')) {
      return;
    }
    
    // 计算题目完成率
    if (progress['allNeedCompleteQuestion'] != null && 
        progress['allNeedCompleteQuestion'] > 0 && 
        progress['alreadyCompleteQuestion'] != null) {
      final allNeeded = progress['allNeedCompleteQuestion'] as int;
      final completed = progress['alreadyCompleteQuestion'] as int;
      progress['completionRate'] = completed / allNeeded;
      return;
    }
    
    // 基于学习次数估算
    if (progress['learnTimes'] != null) {
      final learnTimes = progress['learnTimes'] as int;
      if (learnTimes > 0) {
        // 每次学习增加20%掌握度，最多100%
        progress['completionRate'] = min(1.0, 0.2 * learnTimes);
        return;
      }
    }
    
    // 默认值
    progress['completionRate'] = 0.0;
  }

  // 获取章节的学习进度
  Map<String, dynamic> _getSectionProgress(String sectionId, [String? bankId]) {
    final result = {
      'learnTimes': 0,
      'lastLearnTime': 0,
      'completionRate': 0.0,
      'alreadyCompleteQuestion': 0,
      'allNeedCompleteQuestion': 0,
    };
    
    // 如果提供了题库ID，直接查找该题库下的章节数据
    if (bankId != null) {
      final fullSectionId = "$bankId/$sectionId";
      final sectionData = WrongQuestionBook.instance.sectionDataBox.get(fullSectionId);
      
      if (sectionData != null) {
        result['learnTimes'] = sectionData.learnTimes;
        result['lastLearnTime'] = sectionData.lastLearnTime;
        result['alreadyCompleteQuestion'] = sectionData.alreadyCompleteQuestion;
        result['allNeedCompleteQuestion'] = sectionData.allNeedCompleteQuestion;
        
        // 计算完成率
        if (sectionData.allNeedCompleteQuestion > 0) {
          result['completionRate'] = sectionData.alreadyCompleteQuestion / 
                                    sectionData.allNeedCompleteQuestion;
        }
        
        return result;
      }
    }
    
    // 如果没有提供题库ID或未找到数据，则遍历所有题库
    final banks = QuestionBankAccessor.instance.getAllAvailableBanksSynchronously();
    
    // 查找每个题库中的章节数据
    for (final bank in banks) {
      if (bank.id == null) continue;
      
      // 构建完整的章节ID（与LearningPlanItem.getSectionLearningData的逻辑一致）
      final fullSectionId = "${bank.id!}/$sectionId";
      
      // 从WrongQuestionBook获取章节学习数据
      final sectionData = WrongQuestionBook.instance.sectionDataBox.get(fullSectionId);
      if (sectionData != null) {
        result['learnTimes'] = sectionData.learnTimes;
        result['lastLearnTime'] = sectionData.lastLearnTime;
        result['alreadyCompleteQuestion'] = sectionData.alreadyCompleteQuestion;
        result['allNeedCompleteQuestion'] = sectionData.allNeedCompleteQuestion;
        
        // 计算完成率
        if (sectionData.allNeedCompleteQuestion > 0) {
          result['completionRate'] = sectionData.alreadyCompleteQuestion / 
                                    sectionData.allNeedCompleteQuestion;
        }
        
        // 找到数据后跳出循环
        break;
      }
    }
    
    return result;
  }

  // 获取题库级别的学习进度
  Map<String, dynamic> getBankProgress(String bankId) {
    final result = {
      'needLearnSectionNum': 0,
      'alreadyLearnSectionNum': 0,
      'completionRate': 0.0,
      'learnTimes': 0,
    };
    
    // 从WrongQuestionBook获取题库学习数据
    final bankData = WrongQuestionBook.instance.sectionLearnBox.get(bankId);
    if (bankData != null) {
      result['needLearnSectionNum'] = bankData.needLearnSectionNum;
      result['alreadyLearnSectionNum'] = bankData.alreadyLearnSectionNum;
      
      // 计算完成率
      if (bankData.needLearnSectionNum > 0) {
        result['completionRate'] = bankData.alreadyLearnSectionNum / 
                                  bankData.needLearnSectionNum;
      } else if (bankData.alreadyLearnSectionNum > 0) {
        // 如果需要学习的章节数为0但已经学习了章节，将完成率设为1.0
        result['completionRate'] = 1.0;
      }
    }
    
    // 增加学习次数信息
    result['learnTimes'] = result['alreadyLearnSectionNum'] as int;
    
    return result;
  }

  // 递归提取章节标题作为主题
  void _extractTopicsFromSections(List<Section> sections, Set<String> topicsSet) {
    for (final section in sections) {
      if (section.title.isNotEmpty) {
        topicsSet.add(section.title);
      }
      
      if (section.children != null && section.children!.isNotEmpty) {
        _extractTopicsFromSections(section.children!, topicsSet);
      }
    }
  }

  // Helper method to get a topic ID from its name, for use with StudyData
  String? _getTopicIdFromName(String topicName) {
    // First try direct matching with topic mastery data
    final topicKeys = StudyData.instance.topicMasteryData.keys;
    
    // Direct match
    if (topicKeys.contains(topicName)) {
      return topicName;
    }
    
    // Pattern match
    for (final key in topicKeys) {
      // Simple pattern matching - the topic ID often contains the topic name
      if (key.contains(topicName) || topicName.contains(key)) {
        return key;
      }
    }
    
    // 使用QuestionBankAccessor获取主题ID
    return QuestionBankAccessor.instance.getTopicIdFromName(topicName);
  }

  // Get correct questions count for the selected period
  int getCorrectQuestionsCount() {
    int completedQuestions = getCompletedQuestionsCount();
    int wrongQuestions = getWrongQuestionsCount();
    return completedQuestions - wrongQuestions;
  }
  
  // Get pie chart data for correct vs wrong questions
  PieChartData getPieChartData() {
    final correctCount = getCorrectQuestionsCount();
    final wrongCount = getWrongQuestionsCount();
    
    // If both are zero, provide default data
    if (correctCount == 0 && wrongCount == 0) {
      return PieChartData(
        sections: [
          PieChartSectionData(
            color: AppTheme.primaryColor,
            value: 1,
            title: '暂无数据',
            radius: 40,
            titleStyle: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
        sectionsSpace: 0,
        centerSpaceRadius: 30,
      );
    }
    
    return PieChartData(
      sections: [
        PieChartSectionData(
          color: AppTheme.successColor,
          value: correctCount.toDouble(),
          title: '$correctCount',
          radius: 40,
          titleStyle: const TextStyle(color: Colors.white, fontSize: 12),
        ),
        PieChartSectionData(
          color: Colors.redAccent,
          value: wrongCount.toDouble(),
          title: '$wrongCount',
          radius: 40,
          titleStyle: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ],
      sectionsSpace: 0,
      centerSpaceRadius: 30,
    );
  }
  
  // Get the best time to study based on performance data
  String getBestStudyTime() {
    // Check if we have hourly data
    final hourlyData = StudyData.instance.hourlyStudyData;
    
    if (hourlyData.isEmpty) {
      // Fallback to previous implementation if no hourly data
      final studyCount = StudyData.instance.studyCount;
      
      if (studyCount < 3) {
        return "晚上"; // Default for new users
      }
      
      // Use a deterministic but personalized value based on user data
      final timeOptions = ["早上", "下午", "晚上"];
      final index = (studyCount * 7) % 3;
      return timeOptions[index.toInt()];
    }
    
    // Analyze hourly study time to find the best time period
    final morningMinutes = _getTimeRangeMinutes(5, 11); // 5:00 - 11:59
    final afternoonMinutes = _getTimeRangeMinutes(12, 17); // 12:00 - 17:59
    final eveningMinutes = _getTimeRangeMinutes(18, 23); // 18:00 - 23:59
    
    if (morningMinutes >= afternoonMinutes && morningMinutes >= eveningMinutes) {
      return "早上";
    } else if (afternoonMinutes >= morningMinutes && afternoonMinutes >= eveningMinutes) {
      return "下午";
    } else {
      return "晚上";
    }
  }
  
  // Helper method to calculate total study minutes for a time range
  double _getTimeRangeMinutes(int startHour, int endHour) {
    final now = DateTime.now();
    double total = 0;
    
    // Look at data for the selected period
    for (int day = 0; day < selectedPeriod; day++) {
      final date = now.subtract(Duration(days: day));
      
      for (int hour = startHour; hour <= endHour; hour++) {
        final dateTime = DateTime(date.year, date.month, date.day, hour);
        total += StudyData.instance.getStudyTimeForHour(dateTime);
      }
    }
    
    return total;
  }
  
  // Calculate study regularity based on study patterns
  double getStudyRegularity() {
    final now = DateTime.now();
    int daysWithStudy = 0;
    final int daysToCheck = selectedPeriod == PERIOD_ALL_TIME ? 30 : selectedPeriod; // Limit all-time to 30 days
    
    // Count days with study activity
    for (int i = 0; i < daysToCheck; i++) {
      final date = now.subtract(Duration(days: i));
      if (StudyData.instance.getStudyTimeForDate(date) > 0) {
        daysWithStudy++;
      }
    }
    
    // Calculate streak (consecutive days)
    int currentStreak = 0;
    int maxStreak = 0;
    
    for (int i = 0; i < daysToCheck; i++) {
      final date = now.subtract(Duration(days: i));
      if (StudyData.instance.getStudyTimeForDate(date) > 0) {
        currentStreak++;
        maxStreak = max(maxStreak, currentStreak);
      } else {
        currentStreak = 0;
      }
    }
    
    // Calculate regularity score
    // Mix of overall coverage and streak length
    final coverageScore = daysWithStudy / daysToCheck;
    final streakScore = maxStreak / min(7, daysToCheck);
    
    // Weight: 60% coverage, 40% streak
    return (0.6 * coverageScore) + (0.4 * streakScore);
  }
  
  // Calculate average time per question
  String getAverageTimePerQuestion() {
    int totalQuestions = getCompletedQuestionsCount();
    double totalMinutes = getStudyTimeInMinutes();
    
    if (totalQuestions == 0) return "0秒";
    
    double avgSeconds = (totalMinutes * 60) / totalQuestions;
    int cappedSeconds = min(999, avgSeconds.round());
    
    return cappedSeconds.toStringAsFixed(0);
  }
  
  // Get the weakest topic based on mastery calculations
  String getWeakestTopic() {
    final topics = getTopics();
    if (topics.isEmpty) return "暂无数据";
    
    int weakestIndex = 0;
    double lowestMastery = 1.0;
    
    // First check if we have mastery data in StudyData
    final topicMasteryData = StudyData.instance.topicMasteryData;
    if (topicMasteryData.isNotEmpty) {
      // Find the topic with lowest mastery
      String? weakestTopic;
      for (final entry in topicMasteryData.entries) {
        final currentMastery = StudyData.instance.getCurrentTopicMastery(entry.key);
        if (currentMastery < lowestMastery) {
          lowestMastery = currentMastery;
          weakestTopic = entry.key;
        }
      }
      
      // Try to match with a readable topic name
      if (weakestTopic != null) {
        for (final topic in topics) {
          if (weakestTopic.contains(topic) || topic.contains(weakestTopic)) {
            return topic;
          }
        }
      }
    }
    
    // Fallback to comparing mastery for each topic
    for (int i = 0; i < topics.length; i++) {
      double mastery = getTopicMastery(i, topics);
      if (mastery < lowestMastery) {
        lowestMastery = mastery;
        weakestIndex = i;
      }
    }
    
    return topics[weakestIndex];
  }

  // Get hourly study distribution
  Map<int, double> getHourlyStudyDistribution() {
    final hourDistribution = <int, double>{};
    final now = DateTime.now();
    
    // Initialize all hours with zero
    for (int i = 0; i < 24; i++) {
      hourDistribution[i] = 0;
    }
    
    // Get actual hourly distribution for selected period
    for (int day = 0; day < (selectedPeriod == PERIOD_ALL_TIME ? 30 : selectedPeriod); day++) {
      final date = now.subtract(Duration(days: day));
      
      for (int hour = 0; hour < 24; hour++) {
        final dateTime = DateTime(date.year, date.month, date.day, hour);
        final hourMinutes = StudyData.instance.getStudyTimeForHour(dateTime);
        hourDistribution[hour] = (hourDistribution[hour] ?? 0) + hourMinutes;
      }
    }
    
    return hourDistribution;
  }
  
  // Get best study day of week
  String getBestStudyDayOfWeek() {
    final dayNames = ["周一", "周二", "周三", "周四", "周五", "周六", "周日"];
    final dayDistribution = <int, double>{};
    final now = DateTime.now();
    
    // Initialize all days with zero
    for (int i = 0; i < 7; i++) {
      dayDistribution[i] = 0;
    }
    
    // Get study minutes by day of week
    for (int day = 0; day < (selectedPeriod == PERIOD_ALL_TIME ? 60 : selectedPeriod); day++) {
      final date = now.subtract(Duration(days: day));
      // Adjust to match dayNames array (1-7 to 0-6)
      final weekday = (date.weekday - 1) % 7;
      
      final dayMinutes = StudyData.instance.getStudyTimeForDate(date);
      dayDistribution[weekday] = (dayDistribution[weekday] ?? 0) + dayMinutes;
    }
    
    // Find the day with most study time
    int bestDay = 0;
    double maxMinutes = 0;
    
    dayDistribution.forEach((day, minutes) {
      if (minutes > maxMinutes) {
        maxMinutes = minutes;
        bestDay = day;
      }
    });
    
    return dayNames[bestDay];
  }

  // Get topic detail including question count and mastery level
  Map<String, dynamic> getTopicDetail(int topicIndex, List<String> topics) {
    if (topicIndex >= topics.length) {
      return {'questionCount': 0, 'masteryLevel': 0.1, 'lastStudiedTime': null};
    }
    
    final topicName = topics[topicIndex];
    final topicId = _getTopicIdFromName(topicName);
    
    // Check if we have data in StudyData first
    if (topicId != null) {
      final mastery = StudyData.instance.getCurrentTopicMastery(topicId);
      final studyCount = StudyData.instance.getTopicStudyCount(topicId);
      final lastStudiedTime = StudyData.instance.getTopicLastStudyTime(topicId);
      
      if (studyCount > 0) {
        return {
          'questionCount': studyCount * 2, // Approximate 2 questions per study session
          'completedCount': studyCount,
          'masteryLevel': mastery,
          'lastStudiedTime': lastStudiedTime,
        };
      }
    }
    
    // 使用QuestionBankAccessor获取与主题相关的章节
    List<Section> matchingSections = QuestionBankAccessor.instance.getSectionsByTopic(topicName);
    
    int totalQuestions = 0;
    int completedQuestions = 0;
    int lastStudyTimestamp = 0;
    
    // 遍历所有匹配的章节获取进度信息
    for (final section in matchingSections) {
      // 尝试获取章节的银行ID
      String? bankId;
      for (final bank in QuestionBankAccessor.instance.getAllAvailableBanksSynchronously()) {
        if (bank.id != null && bank.data != null) {
          if (_isSectionInBank(section, bank.data!)) {
            bankId = bank.id;
            break;
          }
        }
      }
      
      if (bankId != null) {
        // 获取章节的学习进度
        final progress = _getSectionProgress(section.id, bankId);
        
        // 过滤时间期限
        if (selectedPeriod != PERIOD_ALL_TIME) {
          final now = DateTime.now();
          final periodStart = now.subtract(Duration(days: selectedPeriod));
          if (progress['lastLearnTime'] < periodStart.millisecondsSinceEpoch) {
            continue;
          }
        }
        
        // 更新最后学习时间
        if (progress['lastLearnTime'] > lastStudyTimestamp) {
          lastStudyTimestamp = progress['lastLearnTime'];
        }
        
        // 计数问题
        totalQuestions += progress['allNeedCompleteQuestion'] as int;
        completedQuestions += progress['alreadyCompleteQuestion'] as int;
      }
    }
    
    // 如果没有找到题目，使用QuestionBankAccessor计算题目数量
    if (totalQuestions == 0) {
      totalQuestions = QuestionBankAccessor.instance.countQuestionsForTopic(topicName);
    }
    
    // Calculate mastery
    double mastery = getTopicMastery(topicIndex, topics);
    
    DateTime? lastStudied = lastStudyTimestamp > 0 
      ? DateTime.fromMillisecondsSinceEpoch(lastStudyTimestamp) 
      : null;
    
    return {
      'questionCount': max(totalQuestions, 5), // At least show 5 questions
      'completedCount': completedQuestions,
      'masteryLevel': mastery,
      'lastStudiedTime': lastStudied,
    };
  }
  
  // 检查章节是否存在于题库中
  bool _isSectionInBank(Section targetSection, List<Section> bankSections) {
    for (final section in bankSections) {
      if (section.id == targetSection.id) {
        return true;
      }
      
      if (section.children != null && section.children!.isNotEmpty) {
        if (_isSectionInBank(targetSection, section.children!)) {
          return true;
        }
      }
    }
    
    return false;
  }
  
  // Get study streak information
  Map<String, dynamic> getStudyStreakInfo() {
    final now = DateTime.now();
    int currentStreak = 0;
    int maxStreak = 0;
    List<bool> lastDaysStudied = List.filled(30, false);
    
    // Calculate streak and last days pattern
    for (int i = 0; i < 30; i++) {
      final date = now.subtract(Duration(days: i));
      bool studiedOnDay = StudyData.instance.getStudyTimeForDate(date) > 0;
      
      if (i < lastDaysStudied.length) {
        lastDaysStudied[i] = studiedOnDay;
      }
      
      if (studiedOnDay) {
        if (i == 0 || currentStreak > 0) {
          currentStreak++;
        }
      } else if (i == 0) {
        // Reset current streak if didn't study today
        currentStreak = 0;
      } else {
        // Stop counting after first break
        break;
      }
    }
    
    // Calculate max streak within 30 days
    int tempStreak = 0;
    for (int i = 0; i < 30; i++) {
      final date = now.subtract(Duration(days: i));
      if (StudyData.instance.getStudyTimeForDate(date) > 0) {
        tempStreak++;
        maxStreak = max(maxStreak, tempStreak);
      } else {
        tempStreak = 0;
      }
    }
    
    return {
      'currentStreak': currentStreak,
      'maxStreak': maxStreak,
      'lastDaysStudied': lastDaysStudied
    };
  }

  // 统一计算节点掌握度的辅助方法
  double _calculateNodeMastery(Map<String, dynamic> node, List<String> topics) {
    double mastery = 0.5; // 默认值
    DateTime? lastStudyTime;
    int studyCount = 0;
    final sectionId = node['id'] as String?;
    final sectionName = node['name'] as String? ?? '未知章节';
    
    // 检查节点是否有学习价值，如果没有则跳过遗忘曲线计算
    final hasLearnableContent = node['hasLearnableContent'] as bool? ?? true;
    if (!hasLearnableContent) {
      print('[ForgettingCurveCalculation] 跳过无学习价值节点: $sectionName');
      return 0.1; // 返回最低掌握度
    }
    
    print('[ForgettingCurveCalculation] 开始计算节点掌握度: $sectionName (ID: $sectionId)');
    
    // 从节点进度信息获取掌握度
    if (node.containsKey('progress') && node['progress'] is Map) {
      final progress = node['progress'] as Map<String, dynamic>;
      
      // 获取基础掌握度
      if (progress.containsKey('completionRate')) {
        mastery = progress['completionRate'] as double;
        print('[ForgettingCurveCalculation] 使用完成率作为基础掌握度: ${mastery.toStringAsFixed(2)}');
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
          print('[ForgettingCurveCalculation] 基于题目完成情况计算掌握度: ${progress['alreadyCompleteQuestion']}/${progress['allNeedCompleteQuestion']} = ${mastery.toStringAsFixed(2)}');
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
          mastery = getTopicMastery(topicIndex, topics);
        }
      }
    }
    
    // 如果有id，尝试从StudyData获取更精确的遗忘曲线数据
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
      // 计算距离上次学习的天数
      final daysSinceLastStudy = DateTime.now().difference(lastStudyTime).inDays;
      
      print('[ForgettingCurveCalculation] 应用遗忘曲线 - 距离上次学习: $daysSinceLastStudy天, 学习次数: $studyCount');
      
      // 基于艾宾浩斯遗忘曲线计算保留率
      // R = e^(-t/S)，其中t是时间，S是稳定性参数
      final stability = 20.0 * (studyCount + 1); // 学习次数越多，稳定性越高
      final retentionRate = exp(-daysSinceLastStudy / stability);
      
      final originalMastery = mastery;
      // 应用遗忘曲线，计算实际掌握度
      mastery = (mastery * retentionRate).clamp(0.0, 1.0);
      
      print('[ForgettingCurveCalculation] 遗忘曲线应用完成 - 原始掌握度: ${originalMastery.toStringAsFixed(2)}, 保留率: ${retentionRate.toStringAsFixed(2)}, 最终掌握度: ${mastery.toStringAsFixed(2)}');
    } else {
      print('[ForgettingCurveCalculation] 无学习时间记录，使用基础掌握度: ${mastery.toStringAsFixed(2)}');
    }
    
    // 确保掌握度在有效范围内
    return mastery.clamp(0.0, 1.0);
  }
}
