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
    final shuffledList = List<SingleQuestionData>.from(_questionList);
    shuffledList.shuffle();
    return shuffledList;
  }

  /// Access to the persistent storage for section learning data
  Box<SectionUserData> get learningDataBox =>
      WrongQuestionBook.instance.sectionDataBox;

  LearningPlanItem(this.bank);

  /// Find all leaf sections in the bank that need to be learned
  Iterable<Section> getAllSectionsToLearn() sync* {
    yield* _getAllSectionsToLearn(bank.data!, []);
  }

  Iterable<Section> _getAllSectionsToLearn(
      List<Section> sections, List<String> indexPath) sync* {
    for (var section in sections) {
      if (section.children != null && section.children!.isNotEmpty) {
        // 非叶子节点，继续遍历子节点
        yield* _getAllSectionsToLearn(section.children!, [...indexPath, section.index]);
      } else {
        // 叶子节点，检查是否有学习价值且需要学习
        if (section.hasLearnableContent() && needsToLearn(section)) {
        yield section;
      }
        // 如果叶子节点没有学习价值（只有图片等），则查找其父节点
        else if (!section.hasLearnableContent() && needsToLearn(section)) {
          // 向上查找有学习价值的父节点
          Section? parent = _findLearnableParent(indexPath);
          if (parent != null && needsToLearn(parent)) {
            yield parent;
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

    var newQuestions = targetSection!.randomMultipleSectionQuestions(
        bank.id!, bank.displayName!, _questionList.length,
        onlyLayer: true);
        
    for (var i = 0; i < _questionList.length; i++) {
      _questionList[i] = newQuestions[i];
    }
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

    _questionList.addAll(targetSection!.randomMultipleSectionQuestions(
        bank.id!, bank.displayName!, count,
        onlyLayer: true));

    return this;
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
  
  /// Sections manually added to the learning plan
  Map<String, Section> manuallyAddedSections = {};

  /// Access to persistent storage
  Box get sectionData => WrongQuestionBook.instance.sectionDataBox;
  Box<BankLearnData> get bankLearningData =>
      WrongQuestionBook.instance.sectionLearnBox;
  Box<String> get manualSectionsBox => 
      WrongQuestionBook.instance.manualSectionsBox;

  /// Singleton instance
  static LearningPlanManager instance = LearningPlanManager();

  LearningPlanManager() {
    // Load manually added sections from persistent storage
    _loadManualSections();
  }
  
  /// Load manually added sections from persistent storage
  void _loadManualSections() async {
    try {
      // First load all question banks
      questionBanks = await QuestionBank.getAllLoadedQuestionBanks();
      
      // Get saved manual section IDs
      final keys = manualSectionsBox.keys;
      for (var key in keys) {
        // Format: bankId:sectionId
        final value = manualSectionsBox.get(key);
        if (value != null) {
          final parts = value.split(':');
          if (parts.length == 2) {
            final bankId = parts[0];
            final sectionId = parts[1];
            
            // Find corresponding bank and section
            for (var bank in questionBanks) {
              if (bank.id == bankId) {
                Section section = bank.findSection(sectionId.split('/'));
                // Restore to in-memory map
                manuallyAddedSections[key.toString()] = section;
                              break;
              }
            }
          }
        }
      }
    } catch (e) {
      print('Error loading manual sections: $e');
    }
  }

  /// Add a section to the manual learning plan (only sections with learnable content allowed)
  bool addSectionToManualLearningPlan(Section section, QuestionBank bank) {
    // 直接检查是否有学习价值
    if (!section.hasLearnableContent()) {
      return false;
    }
    
    String key = "${bank.id!}/${section.id}";

    // Return if already exists
    if (manuallyAddedSections.containsKey(key)) {
      return false;
    }

    // Add to manual selection collection
    manuallyAddedSections[key] = section;
    
    // Save to persistent storage
    manualSectionsBox.put(key, "${bank.id!}:${section.id}");

    // Create and add learning plan item
    LearningPlanItem planItem = LearningPlanItem(bank);
    planItem.targetSection = section;
    planItem.addRandomQuestions(StudyData.instance.needCompleteQuestionNum);

    // Only add if not already exists
    bool alreadyInPlan = learningPlanItems.any((item) => item.targetSection?.id == section.id);
    
    if (!alreadyInPlan) {
      learningPlanItems.add(planItem);

      // Update bank learning data
      var bankData = planItem.getBankLearningData();
      bankData.needLearnSectionNum += 1;
      planItem.saveBankLearningData(bankData);
    }
    return true;
  }



  /// Clear all manually added sections
  void clearManuallyAddedSections() {
    manuallyAddedSections.clear();
    manualSectionsBox.clear();
  }

  /// Update the learning plan based on auto-selected and manually added sections
  Future<void> updateLearningPlan() async {
    // Save manually added sections for later
    Map<String, Section> savedManualSections = Map.from(manuallyAddedSections);
    Map<String, QuestionBank> bankMap = {};

    // Clear existing plan and reload banks
    learningPlanItems.clear();
    questionBanks.clear();
    questionBanks.addAll(await QuestionBank.getAllLoadedQuestionBanks());

    // Create bank lookup map
    for (var bank in questionBanks) {
      bankMap[bank.id!] = bank;
    }

    // First add auto-selected sections
    for (var bank in questionBanks) {
      var tempPlanItem = LearningPlanItem(bank);
      int remainingSections = tempPlanItem.getBankLearningData().needLearnSectionNum - 
                             tempPlanItem.getBankLearningData().alreadyLearnSectionNum;
                             
      tempPlanItem.getSectionsToLearn(remainingSections).forEach((section) {
        var planItem = LearningPlanItem(bank);
        planItem.targetSection = section;
        planItem.addRandomQuestions(StudyData.instance.needCompleteQuestionNum);
        learningPlanItems.add(planItem);
      });
    }

    // Then add manually selected sections
    for (var entry in savedManualSections.entries) {
      String fullId = entry.key;
      Section section = entry.value;

      // Extract bank ID
      String bankId = fullId.substring(0, fullId.indexOf("/"));

      // Find corresponding bank
      if (bankMap.containsKey(bankId)) {
        QuestionBank bank = bankMap[bankId]!;

        LearningPlanItem planItem = LearningPlanItem(bank);
        planItem.targetSection = section;
        
        // Ensure section is not duplicate and needs learning
        if (!learningPlanItems.any((item) => item.targetSection?.id == section.id) &&
            planItem.needsToLearn(section)) {
          planItem.addRandomQuestions(StudyData.instance.needCompleteQuestionNum);
          learningPlanItems.add(planItem);
        }
      }
    }
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
