import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/tool/question/question_bank.dart';
import 'package:flutter_application_1/tool/study_data.dart';
import 'package:flutter_application_1/tool/question/wrong_question_book.dart';
import 'package:flutter_application_1/widget/mind_map.dart';
import 'package:hive/hive.dart';

part 'question_controller.g.dart';

// Hive model for manual section entries
@HiveType(typeId: 4)
class ManualSectionEntry {
  @HiveField(0)
  String bankId;

  @HiveField(1)
  String sectionId;

  ManualSectionEntry(this.bankId, this.sectionId);
}

/// Represents an individual learning plan item for a specific section
/// Each learning plan item contains a list of questions to be studied
class LearningPlanItem {
  /// The question bank this learning plan item belongs to
  final QuestionBank bank;
  
  /// The list of questions to be studied in this learning plan item
  final List<SingleQuestionData> _questionList = [];

  /// The section being studied in this learning plan item
  Section? targetSection;

  /// Returns a shuffled list of questions for the current learning item.
  List<SingleQuestionData> get questionList {
    return _questionList;
  }

  /// Access to the persistent storage for section learning data
  Box<SectionUserData> get learningDataBox =>
      WrongQuestionBook.instance.sectionDataBox;

  LearningPlanItem(this.bank);

  /// Find all leaf sections in the bank that need to be learned
  Iterable<Section> getAllSectionsToLearn() sync* {
    final yieldedSectionIds = <String>{};
    yield* _getAllSectionsToLearn(bank.data!, [], yieldedSectionIds);
  }

  Iterable<Section> _getAllSectionsToLearn(
      List<Section> sections, List<String> indexPath, Set<String> yieldedSectionIds) sync* {
    for (var section in sections) {
      if (section.children != null && section.children!.isNotEmpty) {
        // 非叶子节点，继续遍历子节点
        yield* _getAllSectionsToLearn(section.children!, [...indexPath, section.index], yieldedSectionIds);
      } else {
        // 叶子节点，检查是否有学习价值且需要学习
        if (section.hasLearnableContent() && needsToLearn(section)) {
          if (yieldedSectionIds.add(section.id)) {
            yield section;
          }
      }
        // 如果叶子节点没有学习价值（只有图片等），则查找其父节点
        else if (!section.hasLearnableContent() && needsToLearn(section)) {
          // 向上查找有学习价值的父节点
          Section? parent = _findLearnableParent(indexPath);
          if (parent != null && needsToLearn(parent)) {
            if (yieldedSectionIds.add(parent.id)) {
              yield parent;
            }
          }
        }
      }
    }
  }

  /// 根据路径查找有学习价值的父节点
  Section? _findLearnableParent(List<String> indexPath) {
    if (indexPath.isEmpty) return null;
    
    // 从根节点开始，按路径查找父节点
    Section? current = Section("", "");
    current.children = bank.data;
    
    try {
      // 遍历路径，但不包括最后一级（因为最后一级就是当前的无价值叶子节点）
      for (int i = 0; i < indexPath.length; i++) {
        current = current!.children!.firstWhere((e) => e.index == indexPath[i]);
        // 检查当前节点是否有学习价值
        if (current.hasLearnableContent()) {
          return current;
        }
      }
    } catch (e) {
      // 路径查找失败
      return null;
    }
    
    return null;
  }

  /// Returns a subset of sections that need to be learned, limited by count
  List<Section> getSectionsToLearn(int count) {
    var allSections = getAllSectionsToLearn().toList();
    if (allSections.length <= count) {
      return allSections;
    }
    return allSections.sublist(0, count);
  }

  /// Determines if a section needs to be learned based on learning history
  bool needsToLearn(Section section) {
    return getSectionLearningData(section).learnTimes < 1;
  }

  /// Mark the current section as completed
  void completeSection() {
    if (targetSection == null) {
      throw "No target section selected";
    }
    
    var sectionData = getSectionLearningData(targetSection!);
    sectionData.learnTimes++;
    sectionData.lastLearnTime = DateTime.now().millisecondsSinceEpoch;
    saveSectionLearningData(targetSection!, sectionData);

    // Update bank-level progress data
    var bankData = getBankLearningData();
    bankData.alreadyLearnSectionNum = 
        min(bankData.alreadyLearnSectionNum + 1, bankData.needLearnSectionNum);
    saveBankLearningData(bankData);
    
    // Remove this completed item from the learning plan
    LearningPlanManager.instance.removeCompletedPlanItem(this);
  }

  /// Mark the current section as failed and replace questions
  void failSection() {
    if (targetSection == null) {
      throw "No target section selected";
    }
    
    var sectionData = getSectionLearningData(targetSection!);
    replaceAllQuestions();
    sectionData.allNeedCompleteQuestion = _questionList.length;
    saveSectionLearningData(targetSection!, sectionData);
  }

  /// Replace all questions with new random questions from the same section
  LearningPlanItem replaceAllQuestions() {
    if (targetSection == null) {
      throw "No target section selected";
    }

    _questionList.clear();
    _questionList.addAll(_generateGradedQuestions());
    return this;
  }

  /// Add similar questions from the same section
  LearningPlanItem addSimilarQuestions() {
    if (targetSection == null) {
      throw "No target section selected";
    }
    
    _questionList.addAll(
        targetSection!.sectionQuestionOnly(bank.id!, bank.displayName!));
    return removeDuplicateQuestions();
  }

  /// Add random questions from the target section
  LearningPlanItem addRandomQuestions(int count) {
    if (targetSection == null) {
      throw "No target section selected";
    }

    final newQuestions = targetSection!.randomMultipleSectionQuestions(
        bank.id!, bank.displayName!, count,
        onlyLayer: true);
    
    // 只添加非空的题目列表
    if (newQuestions.isNotEmpty) {
      _questionList.addAll(newQuestions);
    } else {
      print('HighTree-Debug: No valid questions found for section ${targetSection!.title}');
    }

    return this;
  }

  /// Adds one question of each difficulty (easy, medium, hard) if available.
  LearningPlanItem addGradedQuestions() {
    if (targetSection == null) {
      throw "No target section selected";
    }

    _questionList.addAll(_generateGradedQuestions());
    return this;
  }

  List<SingleQuestionData> _generateGradedQuestions() {
    if (targetSection == null) {
      throw "No target section selected";
    }

    final allSectionQuestions =
        targetSection!.sectionQuestionOnly(bank.id!, bank.displayName!);
    if (allSectionQuestions.isEmpty) {
      print('HighTree-Debug: No questions in section ${targetSection!.title}');
      return [];
    }

    final easyQuestions = allSectionQuestions
        .where((q) => q.question['difficulty'] == '简单')
        .toList();
    final mediumQuestions = allSectionQuestions
        .where((q) => q.question['difficulty'] == '中等')
        .toList();
    final hardQuestions = allSectionQuestions
        .where((q) => q.question['difficulty'] == '困难')
        .toList();

    easyQuestions.shuffle();
    mediumQuestions.shuffle();
    hardQuestions.shuffle();

    final newQuestions = <SingleQuestionData>[];
    final addedQuestionIds = <String>{};

    // Helper to add a unique question
    void addUnique(SingleQuestionData q) {
      final id = q.question['id'] as String?;
      if (id != null && addedQuestionIds.add(id)) {
        newQuestions.add(q);
      }
    }

    if (easyQuestions.isNotEmpty) addUnique(easyQuestions.first);
    if (mediumQuestions.isNotEmpty) addUnique(mediumQuestions.first);
    if (hardQuestions.isNotEmpty) addUnique(hardQuestions.first);

    // Fill up to 3
    final allShuffled = List<SingleQuestionData>.from(allSectionQuestions)
      ..shuffle();
    for (var q in allShuffled) {
      if (newQuestions.length >= 3) break;
      addUnique(q);
    }

    return newQuestions;
  }

  /// Get learning data for a specific section
  SectionUserData getSectionLearningData(Section section) {
    var sectionId = "${bank.id!}/${section.id}";
    if (!learningDataBox.containsKey(sectionId)) {
      learningDataBox.put(sectionId, SectionUserData());
    }
    return learningDataBox.get(sectionId)!;
  }

  /// Save learning data for a specific section
  void saveSectionLearningData(Section section, SectionUserData data) {
    var sectionId = "${bank.id!}/${section.id}";
    learningDataBox.put(sectionId, data);
  }

  /// Get learning data for the entire bank
  BankLearnData getBankLearningData() {
    var bankId = bank.id!;
    if (!WrongQuestionBook.instance.sectionLearnBox.containsKey(bankId)) {
      WrongQuestionBook.instance.sectionLearnBox.put(bankId, BankLearnData());
    }
    
    var data = WrongQuestionBook.instance.sectionLearnBox.get(bankId)!;
    if (data.needLearnSectionNum == 0) {
      data.needLearnSectionNum = StudyData.instance.needLearnSectionNum;
    }
    return data;
  }

  /// Save learning data for the entire bank
  void saveBankLearningData(BankLearnData data) {
    WrongQuestionBook.instance.sectionLearnBox.put(bank.id!, data);
  }

  /// Calculate section mastery using Ebbinghaus forgetting curve algorithm
  /// This method provides consistent mastery calculation across the app
  double calculateSectionMastery(Section section) {
    if (section == null) return 0.0;
    
    double mastery = 0.5; // Default mastery value
    DateTime? lastStudyTime;
    int studyCount = 0;
    
    // Get section learning data
    final sectionData = getSectionLearningData(section);
    
    // Calculate basic mastery from completion rate
    if (sectionData.allNeedCompleteQuestion > 0) {
      mastery = sectionData.alreadyCompleteQuestion / sectionData.allNeedCompleteQuestion;
    }
    
    // Get study count
    studyCount = sectionData.learnTimes;
    
    // Get last study time
    if (sectionData.lastLearnTime > 0) {
      lastStudyTime = DateTime.fromMillisecondsSinceEpoch(sectionData.lastLearnTime);
    }
    
    // Try to get more precise data from StudyData
    final sectionId = section.id;
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
    
    // Apply Ebbinghaus forgetting curve if there's a last study time
    if (lastStudyTime != null) {
      // Calculate days since last study (with decimal precision)
      final daysSinceLastStudy = DateTime.now().difference(lastStudyTime).inHours / 24.0;
      
      // Use effective study count
      int effectiveStudyCount = max(studyCount, 1);
      if (sectionId != null) {
        effectiveStudyCount = max(StudyData.instance.getTopicStudyCount(sectionId), studyCount);
      }
      
      // Calculate retention rate based on Ebbinghaus curve: R = e^(-t/S)
      // Where S is stability factor and t is time in days
      double retentionRate;
      
      if (effectiveStudyCount <= 1) {
        // First study, moderate decay
        const stabilityFactor = 2.5;
        retentionRate = exp(-daysSinceLastStudy / stabilityFactor);
      } else if (effectiveStudyCount == 2) {
        // Second study, significantly improved stability
        const stabilityFactor = 5.0;
        retentionRate = exp(-daysSinceLastStudy / stabilityFactor);
        retentionRate = max(retentionRate, 0.4); // Minimum 40% retention
      } else if (effectiveStudyCount == 3) {
        // Third study, more stable memory
        const stabilityFactor = 8.0;
        retentionRate = exp(-daysSinceLastStudy / stabilityFactor);
        retentionRate = max(retentionRate, 0.5); // Minimum 50% retention
      } else if (effectiveStudyCount == 4) {
        // Fourth study, entering long-term memory
        const stabilityFactor = 12.0;
        retentionRate = exp(-daysSinceLastStudy / stabilityFactor);
        retentionRate = max(retentionRate, 0.6); // Minimum 60% retention
      } else {
        // 5+ times, very stable memory
        final stabilityFactor = 15.0 + ((effectiveStudyCount - 5) * 3.0);
        retentionRate = exp(-daysSinceLastStudy / stabilityFactor);
        // Minimum 70% + bonus for additional studies (up to 95%)
        retentionRate = max(retentionRate, 0.7 + min((effectiveStudyCount - 5) * 0.05, 0.25));
      }
      
      // Apply forgetting curve to mastery
      mastery = (mastery * retentionRate).clamp(0.1, 1.0);
    }
    
    return mastery.clamp(0.1, 1.0);
  }

  /// Remove duplicate questions from the question list
  LearningPlanItem removeDuplicateQuestions() {
    var uniqueQuestions = <String, SingleQuestionData>{};
    var duplicates = [];
    
    for (var question in _questionList) {
      if (uniqueQuestions.containsKey(question.question['id']!)) {
        duplicates.add(question);
      } else {
        uniqueQuestions[question.question['id']!] = question;
      }
    }
    
    for (var duplicate in duplicates) {
      _questionList.remove(duplicate);
    }
    return this;
  }

  /// Build mind map nodes for sections in this bank
  void buildMindMapNodes(MindMapNode<Section> rootNode) {
    _buildMindMapNodes(rootNode, bank.data!);
  }

  /// Get a section by its node ID
  Section getSectionByNodeId(String id) {
    return bank.findSection(id.split("/"));
  }

  /// Recursively build mind map nodes
  void _buildMindMapNodes(MindMapNode<Section> node, List<Section> sections) {
    for (var section in sections) {
      // 根据节点状态设置不同颜色
      Color? nodeColor;
      bool isLeafNode = section.children == null || section.children!.isEmpty;
      bool hasLearnableContent = section.hasLearnableContent();
      
      if (isLeafNode) {
        // 叶子节点
        if (hasLearnableContent) {
          if (needsToLearn(section)) {
            // 需要学习的叶子节点：保持默认颜色（蓝色系）
            nodeColor = null;
          } else {
            // 已完成学习的叶子节点：绿色
            nodeColor = Colors.greenAccent.shade400;
          }
        } else {
          // 无学习价值的叶子节点：保持默认颜色，不再设为灰色
          nodeColor = null;
        }
      } else {
        // 非叶子节点
        if (hasLearnableContent) {
          // 有学习价值的非叶子节点：橙色系
          nodeColor = Colors.orange.shade300;
        } else {
          // 无学习价值的非叶子节点：保持默认颜色，不再设为灰色
          nodeColor = null;
        }
      }
      
      var childNode = MindMapHelper.addChildNode(node, section.title,
          id: section.id,
          data: section,
          color: nodeColor,
          image: section.image); // 传递章节图片
          
      if (section.children != null && section.children!.isNotEmpty) {
        _buildMindMapNodes(childNode, section.children!);
      }
    }
  }
}

@HiveType(typeId: 2)
class SectionUserData {
  @HiveField(0)
  int lastLearnTime = 0;

  @HiveField(1)
  int learnTimes = 0;

  @HiveField(2)
  int alreadyCompleteQuestion = 0;

  @HiveField(3)
  int allNeedCompleteQuestion = 2;
}

@HiveType(typeId: 3)
class BankLearnData {
  @HiveField(0)
  int needLearnSectionNum = 0;

  @HiveField(1)
  int alreadyLearnSectionNum = 0;
}

/// Manages the overall learning plan including automatic and manual sections
class LearningPlanManager {
  /// List of all learning plan items (each item is a section with questions)
  List<LearningPlanItem> learningPlanItems = [];
  
  /// Cached question banks for quick reference
  List<QuestionBank> questionBanks = [];

  /// Access to persistent storage
  Box get sectionData => WrongQuestionBook.instance.sectionDataBox;
  Box<BankLearnData> get bankLearningData =>
      WrongQuestionBook.instance.sectionLearnBox;
  Box<String> get manualSectionsBox => 
      WrongQuestionBook.instance.manualSectionsBox;

  /// Singleton instance
  static LearningPlanManager instance = LearningPlanManager();

  LearningPlanManager();
  
  /// Check if a section is already in the manual learning plan
  bool isSectionInManualPlan(String bankId, String sectionId) {
    String key = "$bankId/$sectionId";
    return manualSectionsBox.containsKey(key);
  }

  /// Add a section to the manual learning plan.
  /// This method solely records the user's intent to learn a section, allowing for re-learning.
  bool addSectionToManualLearningPlan(Section section, QuestionBank bank) {
    if (!section.hasLearnableContent()) {
      print('HighTree-Debug: Section ${section.title} has no learnable content.');
      return false;
    }
    String key = "${bank.id!}/${section.id}";
    // Always allow adding/re-adding. This simply records the user's intent to learn this section.
    manualSectionsBox.put(key, "${bank.id!}:${section.id}");
    print('HighTree-Debug: Added section ${section.title} to manual plan.');
    return true;
  }



  /// Clear all manually added sections
  void clearManuallyAddedSections() {
    // manuallyAddedSections.clear(); // This line is removed
    manualSectionsBox.clear();
  }

  /// Remove a completed plan item from all data sources
  void removeCompletedPlanItem(LearningPlanItem planItem) {
    if (planItem.targetSection == null || planItem.bank.id == null) {
      return;
    }
    
    String key = "${planItem.bank.id!}/${planItem.targetSection!.id}";
    
    // Remove from Hive persistent storage (single source of truth)
    manualSectionsBox.delete(key);
    
    // Remove from memory cache
    // manuallyAddedSections.remove(key); // This line is removed
    
    // Remove from current learning plan items
    learningPlanItems.removeWhere((item) => 
        item.bank.id == planItem.bank.id && 
        item.targetSection?.id == planItem.targetSection?.id);
    
    print('HighTree-Debug: Removed completed plan item: ${planItem.targetSection!.title}');
  }

  /// Update the learning plan based on manually added sections only
  Future<void> updateLearningPlan() async {
    // 0. Setup: Load banks, clear old plan
    print('HighTree-Debug: Updating learning plan...');
    Map<String, QuestionBank> bankMap = {};
    learningPlanItems.clear();
    questionBanks.clear();
    questionBanks.addAll(await QuestionBank.getAllLoadedQuestionBanks());
    print('HighTree-Debug: Loaded ${questionBanks.length} question banks.');
    for (var bank in questionBanks) {
      bankMap[bank.id!] = bank;
    }
    final addedSectionIds = <String>{};

    // Reload manual sections from Hive every time to ensure it's the single source of truth.
    // ... (removed old logic for manuallyAddedSections map)

    // 1. Build plan from the single source of truth: the user's intent in manualSectionsBox.
    // This logic does not filter by 'needsToLearn', allowing any section to be re-added for learning.
    print(
        'HighTree-Debug: Building plan from ${manualSectionsBox.length} manual sections...');
    for (var key in manualSectionsBox.keys.toList()) { // Use toList() to allow safe deletion during iteration
      final value = manualSectionsBox.get(key);
      if (value == null) continue;

      final parts = value.split(':');
      if (parts.length != 2) continue;

      final bankId = parts[0];
      final sectionId = parts[1];

      // Use the composite key for uniqueness check to prevent duplicates from the same bank
      if (bankMap.containsKey(bankId) && addedSectionIds.add(key.toString())) {
        final bank = bankMap[bankId]!;
        try {
          final section = bank.findSection(sectionId.split('/'));
          final planItem = LearningPlanItem(bank);
          planItem.targetSection = section;
          planItem.addGradedQuestions();

          if (planItem.questionList.isNotEmpty) {
            var sectionData = planItem.getSectionLearningData(section);
            sectionData.allNeedCompleteQuestion = planItem.questionList.length;
            planItem.saveSectionLearningData(section, sectionData);
            learningPlanItems.add(planItem);
          } else {
            // Housekeeping: remove sections that are impossible to learn (e.g., no questions)
            print(
                'HighTree-Debug: Skipping manual section ${section.title} (no questions). Removing from plan.');
            manualSectionsBox.delete(key);
          }
        } catch (e) {
          // Housekeeping: remove invalid section references
          print("Error finding section $sectionId for manual plan, removing: $e");
          manualSectionsBox.delete(key);
        }
      }
    }
    
    print(
        'HighTree-Debug: Final learning plan has ${learningPlanItems.length} items.');
  }

  /// Get the list of question banks used in the learning plan
  List<QuestionBank> getBanksInLearningPlan() {
    return learningPlanItems.map((item) => item.bank).toSet().toList();
  }

  /// Reset daily learning progress for all banks
  void resetDailyProgress() {
    for (String bankId in bankLearningData.keys) {
      var data = bankLearningData.get(bankId);
      if (data != null) {
        data.alreadyLearnSectionNum = 0;
        data.needLearnSectionNum = StudyData.instance.needLearnSectionNum;
        bankLearningData.put(bankId, data);
      }
    }
    
    // Clear manually added sections to allow re-adding learned content
    clearManuallyAddedSections();
  }

  /// Calculate daily learning progress
  double getDailyProgress() {
    var progress = 0.0;
    var bankIds = QuestionBank.getAllLoadedQuestionBankIds();
    if (bankIds.isEmpty) return 0.0;

    // Calculate progress from completed sections
    for (var bankId in bankIds) {
      var data = bankLearningData.get(bankId);
      if (data != null) {
        progress += data.alreadyLearnSectionNum / 
                   data.needLearnSectionNum / 
                   bankIds.length;
      }
    }

    // Calculate progress from partially completed questions
    for (var planItem in learningPlanItems) {
      if (planItem.targetSection != null) {
        var sectionData = planItem.getSectionLearningData(planItem.targetSection!);
        var bankData = bankLearningData.get(planItem.bank.id);
        
        if (bankData != null && 
            sectionData.alreadyCompleteQuestion != sectionData.allNeedCompleteQuestion) {
          progress += (sectionData.alreadyCompleteQuestion /
                     sectionData.allNeedCompleteQuestion) /
                     bankData.needLearnSectionNum /
                     bankIds.length;
        }
      }
    }

    return progress;
  }
}
