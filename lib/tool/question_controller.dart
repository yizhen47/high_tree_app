import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/tool/question_bank.dart';
import 'package:flutter_application_1/tool/study_data.dart';
import 'package:flutter_application_1/tool/wrong_question_book.dart';
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

class QuestionController {
  QuestionBank bank;
  List<SingleQuestionData> currentQuestionList = [];

  Box<SectionUserData> get learnMap =>
      WrongQuestionBook.instance.sectionDataBox;

  QuestionController(this.bank) {}

  Iterable<Section> getAllNeedLearnSection() sync* {
    yield* _getAllNeedLearnSection(bank.data!, []);
  }

  Iterable<Section> _getAllNeedLearnSection(
      List<Section> secs, List<String> indexId) sync* {
    for (var sec in secs) {
      if (sec.children != null && sec.children!.isNotEmpty) {
        yield* _getAllNeedLearnSection(sec.children!, [...indexId, sec.index]);
      }
      if (isNeedLearnSection(sec)) {
        yield sec;
      }
    }
  }

  Section? currentLearn;

  List<Section> getNeedLearnSection(int num) {
    var list = getAllNeedLearnSection().toList();
    if (list.length < num) {
      return list;
    }
    return list.sublist(0, num);
  }

  bool isNeedLearnSection(Section sec) {
    return getSectionUserData(sec).learnTimes < 1;
  }

  void completeLearn() {
    if (currentLearn == null) {
      throw "currentLearn is null";
    }
    var secData = getSectionUserData(currentLearn!);
    secData.learnTimes++;
    secData.lastLearnTime = DateTime.now().millisecondsSinceEpoch;
    setSectionUserData(currentLearn!, secData);

    var learn = getBankLearnData();
    learn.alreadyLearnSectionNum =
        min(learn.alreadyLearnSectionNum + 1, learn.needLearnSectionNum);
    updateBankLearnData(learn);

    
  }

  void failCompleteLearn() {
    if (currentLearn == null) {
      throw "currentLearn is null";
    }
    var secData = getSectionUserData(currentLearn!);
    // addSimilarQuestion();
    replaceAllQuestions();

    secData.allNeedCompleteQuestion = currentQuestionList.length;
  }

  QuestionController replaceAllQuestions() {
    if (currentLearn == null) {
      throw "currentLearn is null";
    }

    var nArray = currentLearn!.randomMultipleSectionQuestions(
        bank.id!, bank.displayName!, 2,
        onlyLayer: true);
    for (var i = 0; i < currentQuestionList.length; i++) {
      currentQuestionList[i] = nArray[i];
    }
    return this;
  }

  QuestionController addSimilarQuestion() {
    if (currentLearn == null) {
      throw "currentLearn is null";
    }
    currentQuestionList
        .addAll(currentLearn!.sectionQuestionOnly(bank.id!, bank.displayName!));
    return removeSameQuestion();
  }

  QuestionController addRandomQuestion(int num) {
    if (currentLearn == null) {
      throw "currentLearn is null";
    }

    currentQuestionList.addAll(currentLearn!.randomMultipleSectionQuestions(
        bank.id!, bank.displayName!, num,
        onlyLayer: true));

    return this;
  }

  SectionUserData getSectionUserData(Section sec) {
    // sec ??= currentLearn;
    var secId = bank.id! + "/" + sec.id;
    if (!learnMap.containsKey(secId)) {
      learnMap.put(secId, SectionUserData());
    }
    return learnMap.get(secId)!;
  }

  void setSectionUserData(Section sec, SectionUserData data) {
    var secId = bank.id! + "/" + sec.id;

    learnMap.put(secId, data);
  }

  BankLearnData getBankLearnData() {
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

  void updateBankLearnData(BankLearnData data) {
    WrongQuestionBook.instance.sectionLearnBox.put(bank.id, data);
  }

  QuestionController removeSameQuestion() {
    var temp = Map<String, SingleQuestionData>();
    var aList = [];
    for (var element in currentQuestionList) {
      if (temp.containsKey(element.question['id']!)) {
        aList.add(element);
      }
      temp[element.question['id']!] = element;
    }
    for (var element in aList) {
      currentQuestionList.remove(element);
    }
    return this;
  }

  void getMindMapNode(MindMapNode<Section> node) {
    _getMindMapNode(node, bank.data!);
  }

  Section getSectionByNodeId(String id) {
    return bank.findSection(id.split("/"));
  }

  void _getMindMapNode(MindMapNode<Section> node, List<Section> secs) {
    for (var sec in secs) {
      var nNode = MindMapHelper.addChildNode(node, sec.title,
          id: sec.id,
          data: sec,
          color: isNeedLearnSection(sec) ? null : Colors.greenAccent.shade400);
      if (sec.children != null && sec.children!.isNotEmpty) {
        _getMindMapNode(nNode, sec.children!);
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

class QuestionGroupController {
  List<QuestionController> controllers = [];
  List<QuestionBank> banksCache = [];
  // 存储手动添加到学习计划的章节ID
  Map<String, Section> manuallyAddedSections = {};

  Box get sectionData => WrongQuestionBook.instance.sectionDataBox;
  Box<BankLearnData> get sectionLearnData =>
      WrongQuestionBook.instance.sectionLearnBox;
  Box<String> get manualSectionsBox => 
      WrongQuestionBook.instance.manualSectionsBox;

  QuestionGroupController() {
    // 加载之前保存的手动添加的章节
    _loadManualSections();
  }
  
  // 从持久化存储加载手动添加的章节
  void _loadManualSections() async {
    try {
      // 首先加载题库
      banksCache = await QuestionBank.getAllLoadedQuestionBanks();
      
      // 获取保存的手动章节ID
      final keys = manualSectionsBox.keys;
      for (var key in keys) {
        // 格式: bankId:sectionId
        final value = manualSectionsBox.get(key);
        if (value != null) {
          final parts = value.split(':');
          if (parts.length == 2) {
            final bankId = parts[0];
            final sectionId = parts[1];
            
            // 查找对应的题库和章节
            for (var bank in banksCache) {
              if (bank.id == bankId) {
                Section section = bank.findSection(sectionId.split('/'));
                if (section != null) {
                  // 恢复到内存中的Map
                  manuallyAddedSections[key.toString()] = section;
                }
                break;
              }
            }
          }
        }
      }
    } catch (e) {
      print('加载手动添加的章节时出错: $e');
    }
  }
  static QuestionGroupController instances = QuestionGroupController();

  // 将章节添加到手动学习计划中
  bool addSectionToManualLearningPlan(Section section, QuestionBank bank) {
    String key = bank.id! + "/" + section.id;

    // 如果已经存在，直接返回
    if (manuallyAddedSections.containsKey(key)) {
      return false;
    }

    // 添加到手动选择集合
    manuallyAddedSections[key] = section;
    
    // 保存到持久化存储
    manualSectionsBox.put(key, "${bank.id!}:${section.id}");

    // 创建控制器并添加到当前控制器列表
    QuestionController controller = QuestionController(bank);
    controller.currentLearn = section;
    controller.addRandomQuestion(StudyData.instance.needCompleteQuestionNum);

    // 只有在不存在时才添加
    if (!controllers.any((c) => c.currentLearn?.id == section.id)) {
      controllers.add(controller);

      controller.updateBankLearnData(
          controller.getBankLearnData()..needLearnSectionNum += 1);
    }

    return true;
  }

  // 清除手动添加的学习计划
  void clearManuallyAddedSections() {
    manuallyAddedSections.clear();
    // 同时清除持久化存储
    manualSectionsBox.clear();
  }

  Future<void> update() async {
    // 保存手动添加的节点
    Map<String, Section> savedManualSections = Map.from(manuallyAddedSections);
    Map<String, QuestionBank> savedBanks = {};

    controllers.clear();
    banksCache.clear();
    banksCache.addAll(await QuestionBank.getAllLoadedQuestionBanks());

    // 为每个题库创建映射，便于后续查找
    for (var bank in banksCache) {
      savedBanks[bank.id!] = bank;
    }

    // 首先添加自动选择的章节
    for (var action in banksCache) {
      var ctrl = QuestionController(action);
      ctrl
          .getNeedLearnSection(ctrl.getBankLearnData().needLearnSectionNum -
              ctrl.getBankLearnData().alreadyLearnSectionNum)
          .forEach((sec) {
        var secController = QuestionController(action);
        secController.currentLearn = sec;
        secController
            .addRandomQuestion(StudyData.instance.needCompleteQuestionNum);
        controllers.add(secController);
      });
    }

    // 然后添加手动选择的章节
    for (var entry in savedManualSections.entries) {
      String fullId = entry.key;
      Section section = entry.value;

      // 提取题库ID
      String bankId = fullId.substring(0, fullId.indexOf("/"));

      // 查找对应的题库
      if (savedBanks.containsKey(bankId)) {
        QuestionBank bank = savedBanks[bankId]!;

        QuestionController controller = QuestionController(bank);
        controller.currentLearn = section;
        // 确保章节不重复
        if (!controllers.any((c) => c.currentLearn?.id == section.id) &&
            controller.isNeedLearnSection(controller.currentLearn!)) {
          controller
              .addRandomQuestion(StudyData.instance.needCompleteQuestionNum);
          controllers.add(controller);
        }
      }
    }
  }

  List<QuestionBank> getRemainNeedBanks() {
    return controllers.map((toElement) => toElement.bank).toSet().toList();
  }

  toDayUpdater() {
    for (String k in WrongQuestionBook.instance.sectionLearnBox.keys) {
      var element = WrongQuestionBook.instance.sectionLearnBox.get(k);
      element!.alreadyLearnSectionNum = 0;
      element.needLearnSectionNum = StudyData.instance.needLearnSectionNum;
      WrongQuestionBook.instance.sectionLearnBox.put(k, element);
    }
  }

  getDayProgress() {
    var value = 0.0;
    var banks = QuestionBank.getAllLoadedQuestionBankIds();
    if (banks.isEmpty) return 0.0;

    // Calculate progress from completed sections
    for (var b in banks) {
      var bankData = WrongQuestionBook.instance.sectionLearnBox.get(b)!;
      value += bankData.alreadyLearnSectionNum /
          bankData.needLearnSectionNum /
          banks.length;
    }

    // Calculate progress from partially completed questions
    for (var c in controllers) {
      var secData = c.getSectionUserData(c.currentLearn!);
      var bankData = WrongQuestionBook.instance.sectionLearnBox.get(c.bank.id)!;
      if (secData.alreadyCompleteQuestion != secData.allNeedCompleteQuestion) {
        value += (secData.alreadyCompleteQuestion /
                secData.allNeedCompleteQuestion) /
            bankData.needLearnSectionNum /
            banks.length;
      }
    }

    return value;
  }
}
