import 'dart:math';
import 'dart:ui';

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
  List<SingleQuestionData> questionList = [];

  /// The section being studied in this learning plan item
  Section? targetSection;

  /// Access to the persistent storage for section learning data
  Box<SectionUserData> get learningDataBox =>
      WrongQuestionBook.instance.sectionDataBox;

  LearningPlanItem(this.bank);

  /// Find all sections in the bank that need to be learned
  Iterable<Section> getAllSectionsToLearn() sync* {
    yield* _getAllSectionsToLearn(bank.data!, []);
  }

  Iterable<Section> _getAllSectionsToLearn(
      List<Section> sections, List<String> indexPath) sync* {
    for (var section in sections) {
      if (section.children != null && section.children!.isNotEmpty) {
        yield* _getAllSectionsToLearn(section.children!, [...indexPath, section.index]);
      }
      if (needsToLearn(section)) {
        yield section;
      }
    }
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
    sectionData.allNeedCompleteQuestion = questionList.length;
    saveSectionLearningData(targetSection!, sectionData);
  }

  /// Replace all questions with new random questions from the same section
  LearningPlanItem replaceAllQuestions() {
    if (targetSection == null) {
      throw "No target section selected";
    }

    var newQuestions = targetSection!.randomMultipleSectionQuestions(
        bank.id!, bank.displayName!, questionList.length,
        onlyLayer: true);
        
    for (var i = 0; i < questionList.length; i++) {
      questionList[i] = newQuestions[i];
    }
    return this;
  }

  /// Add similar questions from the same section
  LearningPlanItem addSimilarQuestions() {
    if (targetSection == null) {
      throw "No target section selected";
    }
    
    questionList.addAll(
        targetSection!.sectionQuestionOnly(bank.id!, bank.displayName!));
    return removeDuplicateQuestions();
  }

  /// Add random questions from the target section
  LearningPlanItem addRandomQuestions(int count) {
    if (targetSection == null) {
      throw "No target section selected";
    }

    questionList.addAll(targetSection!.randomMultipleSectionQuestions(
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
    
    for (var question in questionList) {
      if (uniqueQuestions.containsKey(question.question['id']!)) {
        duplicates.add(question);
      } else {
        uniqueQuestions[question.question['id']!] = question;
      }
    }
    
    for (var duplicate in duplicates) {
      questionList.remove(duplicate);
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
      var childNode = MindMapHelper.addChildNode(node, section.title,
          id: section.id,
          data: section,
          color: needsToLearn(section) ? null : Colors.greenAccent.shade400,
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

  /// Add a section to the manual learning plan
  bool addSectionToManualLearningPlan(Section section, QuestionBank bank) {
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
    if (!learningPlanItems.any((item) => item.targetSection?.id == section.id)) {
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
