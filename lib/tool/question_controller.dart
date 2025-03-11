import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/tool/question_bank.dart';
import 'package:flutter_application_1/tool/study_data.dart';
import 'package:flutter_application_1/tool/wrong_question_book.dart';
import 'package:flutter_application_1/widget/mind_map.dart';
import 'package:hive/hive.dart';

part 'question_controller.g.dart';

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

    return WrongQuestionBook.instance.sectionLearnBox.get(bankId)!
      ..needLearnSectionNum = StudyData.instance.needLearnSectionNum;
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
      var nNode =
          MindMapHelper.addChildNode(node, sec.title, id: sec.id, data: sec,color:isNeedLearnSection(sec) ? null : Colors.greenAccent.shade400);
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

  Box get sectionData => WrongQuestionBook.instance.sectionDataBox;

  QuestionGroupController() {}
  static QuestionGroupController instances = QuestionGroupController();

  Future<void> update() async {
    controllers.clear();
    banksCache.clear();
    banksCache.addAll(await QuestionBank.getAllLoadedQuestionBanks());
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
  }
  List<QuestionBank> getRemainNeedBanks(){
    return controllers.map((toElement) => toElement.bank).toSet().toList();
  }

  toDayUpdater() {
    for (String k in WrongQuestionBook.instance.sectionLearnBox.keys) {
      var element = WrongQuestionBook.instance.sectionLearnBox.get(k);
      element!.alreadyLearnSectionNum = 0;
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
      if (secData.alreadyCompleteQuestion != secData.allNeedCompleteQuestion) {
        value += (secData.alreadyCompleteQuestion /
                secData.allNeedCompleteQuestion) /
            StudyData.instance.needLearnSectionNum /
            banks.length;
      }
    }
    
    return value;
  }
}
