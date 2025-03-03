import 'dart:ui';

import 'package:flutter_application_1/tool/question_bank.dart';
import 'package:flutter_application_1/tool/study_data.dart';
import 'package:flutter_application_1/tool/wrong_question_book.dart';
import 'package:flutter_application_1/widget/mind_map.dart';
import 'package:hive/hive.dart';

part 'question_controller.g.dart';

class QuestionController {
  QuestionBank bank;
  List<SingleQuestionData> currentQuestionList = [];

  late Box<SectionUserData> learnMap;

  QuestionController(this.bank) {
    learnMap = WrongQuestionBook.instance.sectionDataBox;
  }

  Iterable<Section> getAllNeedLearnSection() sync* {
    yield* _getAllNeedLearnSection(bank.data!, []);
  }

  Iterable<Section> _getAllNeedLearnSection(
      List<Section> secs, List<String> indexId) sync* {
    for (var sec in secs) {
      if (isNeedLearnSection([...indexId, sec.index].join("/"))) {
        yield sec;
      }

      if (sec.children != null && sec.children!.isNotEmpty) {
        yield* _getAllNeedLearnSection(sec.children!, [...indexId, sec.index]);
      }
    }
  }

  List<Section> getNeedLearnSection(int num) {
    var list = getAllNeedLearnSection().toList();
    if (list.length < num) {
      return list;
    }
    return list.sublist(0, num);
  }

  bool isNeedLearnSection(String secId) {
    return !learnMap.containsKey(secId);
  }

  void completeLearn(List<String> secIdList) {
    var secId = secIdList.join("/");
    var learnKey = bank.id! + "/" + secId;
    if (learnMap.containsKey(learnKey)) {
      learnMap.get(learnKey)!.learnTimes++;
      learnMap.get(learnKey)!.lastLearnTime =
          DateTime.now().millisecondsSinceEpoch;
    } else {
      learnMap.put(
          learnKey,
          SectionUserData()
            ..learnTimes = 1
            ..lastLearnTime = DateTime.now().millisecondsSinceEpoch);
    }
  }

  QuestionController addSimilarQuestion(SingleQuestionData question) {
    currentQuestionList.addAll(bank
        .findSectionByQuestion(question)
        .sectionQuestionOnly(question.fromId, question.fromDisplayName));
    return removeSameQuestion();
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

  void getMindMapNode(MindMapNode node) {
    _getMindMapNode(node, bank.data!);
  }

  Section getSectionByNodeId(String id) {
    return bank.findSection(id.split("/"));
  }

  void _getMindMapNode(MindMapNode node, List<Section> secs) {
    for (var sec in secs) {
      MindMapHelper.addChildNode(node, sec.title,
          id: sec.fromKonwledgeIndex.join("/"));
      if (sec.children != null && sec.children!.isNotEmpty) {
        _getMindMapNode(node, sec.children!);
      }
    }
  }

  static List<QuestionController> instances = [];

  static updateInstance() async {
    instances.clear();
    instances = (await QuestionBank.getAllLoadedQuestionBanks())
        .map((e) => QuestionController(e))
        .toList();
  }
}

@HiveType(typeId: 2)
class SectionUserData {
  @HiveField(0)
  int lastLearnTime = 0;

  @HiveField(1)
  int learnTimes = 0;
}
