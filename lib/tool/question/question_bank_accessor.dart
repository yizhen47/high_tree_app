import 'package:flutter_application_1/tool/question/question_bank.dart';
import 'package:flutter_application_1/tool/question/question_controller.dart';

/// 集中处理题库访问逻辑的类，避免在多处重复相同的代码
class QuestionBankAccessor {
  /// 单例实例
  static final QuestionBankAccessor instance = QuestionBankAccessor._internal();

  QuestionBankAccessor._internal();

  /// 获取所有可用的题库
  /// 首先尝试使用学习计划，然后是已加载的题库，最后尝试直接加载题库
  Future<List<QuestionBank>> getAllAvailableBanks() async {
    // 从学习计划获取题库
    if (LearningPlanManager.instance.learningPlanItems.isNotEmpty) {
      final Set<QuestionBank> uniqueBanks = {};
      for (final item in LearningPlanManager.instance.learningPlanItems) {
        uniqueBanks.add(item.bank);
      }
      if (uniqueBanks.isNotEmpty) {
        return uniqueBanks.toList();
      }
    }

    // 使用LearningPlanManager中缓存的题库
    if (LearningPlanManager.instance.questionBanks.isNotEmpty) {
      return LearningPlanManager.instance.questionBanks;
    }

    // 直接加载题库
    return await QuestionBank.getAllLoadedQuestionBanks();
  }

  /// 获取所有可用的题库（同步版本，可能不完整）
  List<QuestionBank> getAllAvailableBanksSynchronously() {
    // 从学习计划获取题库
    if (LearningPlanManager.instance.learningPlanItems.isNotEmpty) {
      final Set<QuestionBank> uniqueBanks = {};
      for (final item in LearningPlanManager.instance.learningPlanItems) {
        uniqueBanks.add(item.bank);
      }
      if (uniqueBanks.isNotEmpty) {
        return uniqueBanks.toList();
      }
    }

    // 使用LearningPlanManager中缓存的题库
    if (LearningPlanManager.instance.questionBanks.isNotEmpty) {
      return LearningPlanManager.instance.questionBanks;
    }

    // 返回空列表，异步版本会更完整
    return [];
  }

  /// 获取所有的学习计划项，如果没有则创建基于题库的虚拟学习计划项
  List<LearningPlanItem> getAllLearningItems() {
    if (LearningPlanManager.instance.learningPlanItems.isNotEmpty) {
      return LearningPlanManager.instance.learningPlanItems;
    }

    // 如果没有学习计划，则为每个题库创建虚拟的学习计划项
    final banks = getAllAvailableBanksSynchronously();
    final items = <LearningPlanItem>[];
    
    for (final bank in banks) {
      final item = LearningPlanItem(bank);
      // 不设置targetSection，仅用于访问题库数据
      items.add(item);
    }
    
    return items;
  }

  /// 获取所有主题
  Set<String> getAllTopics() {
    final Set<String> topicsSet = {};
    
    // 优先使用学习计划项
    final learningItems = getAllLearningItems();
    for (final item in learningItems) {
      if (item.bank.data != null) {
        _extractTopicsFromSections(item.bank.data!, topicsSet);
      }
    }
    
    return topicsSet;
  }

  /// 从章节中提取主题标题
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

  /// 根据主题名称查找对应的主题ID
  String? getTopicIdFromName(String topicName) {
    final learningItems = getAllLearningItems();
    
    for (final item in learningItems) {
      if (item.targetSection != null) {
        final section = item.targetSection!;
        
        // 标题匹配
        if (section.title == topicName) {
          return "${item.bank.id}/${section.id}";
        }
        
        // 检查知识点
        for (final point in section.fromKonwledgePoint) {
          if (point == topicName) {
            return "${item.bank.id}/${section.id}";
          }
        }
      }
      
      // 检查题库中的所有章节
      if (item.bank.data != null) {
        for (final bankSection in item.bank.data!) {
          if (bankSection.title == topicName) {
            return "${item.bank.id}/${bankSection.id}";
          }
          
          // 检查子章节
          if (bankSection.children != null) {
            for (final childSection in bankSection.children!) {
              if (childSection.title == topicName) {
                return "${item.bank.id}/${childSection.id}";
              }
            }
          }
        }
      }
    }
    
    return null;
  }

  /// 获取与主题名称匹配的所有章节
  List<Section> getSectionsByTopic(String topicName) {
    final List<Section> matchingSections = [];
    final allItems = getAllLearningItems();
    
    for (final item in allItems) {
      if (item.bank.data != null) {
        for (final section in item.bank.data!) {
          if (section.title.toLowerCase().contains(topicName.toLowerCase()) ||
              topicName.toLowerCase().contains(section.title.toLowerCase())) {
            matchingSections.add(section);
          }
          
          // 检查子章节
          if (section.children != null) {
            for (final childSection in section.children!) {
              if (childSection.title.toLowerCase().contains(topicName.toLowerCase()) ||
                  topicName.toLowerCase().contains(childSection.title.toLowerCase())) {
                matchingSections.add(childSection);
              }
            }
          }
        }
      }
    }
    
    return matchingSections;
  }

  /// 计算主题相关的题目总数
  int countQuestionsForTopic(String topicName) {
    int totalQuestions = 0;
    
    // 首先从学习计划中查找
    final learningItems = getAllLearningItems();
    for (final item in learningItems) {
      if (item.targetSection != null && 
          (item.targetSection!.title.contains(topicName) || 
           topicName.contains(item.targetSection!.title))) {
        totalQuestions += item.questionList.length;
        if (totalQuestions > 0) return totalQuestions;
      }
    }
    
    // 如果还是没找到，尝试直接从题库中统计相关章节的题目数
    final banks = getAllAvailableBanksSynchronously();
    for (final bank in banks) {
      if (bank.data != null) {
        for (final section in bank.data!) {
          if (section.title.contains(topicName) || topicName.contains(section.title)) {
            // 计算题目数量
            totalQuestions += section.questions?.length ?? 0;
            // 如果有子章节，也计算其题目
            if (section.children != null) {
              for (final child in section.children!) {
                totalQuestions += child.questions?.length ?? 0;
              }
            }
            if (totalQuestions > 0) return totalQuestions;
          }
        }
      }
    }
    
    return totalQuestions;
  }
} 