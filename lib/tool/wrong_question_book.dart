import 'dart:convert';

import 'package:flutter_application_1/tool/question_bank.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class WrongWuestionBook {
  late Box<String> box;
  WrongWuestionBook() {
    box = Hive.box<String>("wrong_question_book");
  }
  static init() async {
    Hive.init(
        path.join((await getApplicationDocumentsDirectory()).path, "hive"));
    await Hive.openBox<String>("wrong_question_book");
  }

  static WrongWuestionBook instance = WrongWuestionBook();

  void addWrongQuestion(String questionId, SingleQuestionData question) {
    box.put(questionId, json.encode(question.toJson()));
  }

  void removeWrongQuestion(String questionId) {
    box.delete(questionId);
  }

  void clearWrongQuestion() {
    box.clear();
  }

  List<String> getWrongQuestionIds() {
    return box.keys.map((toElement) => toElement.toString()).toList();
  }

  SingleQuestionData getWrongQuestion(String questionId) {
    return SingleQuestionData.fromJson(
        json.decode(box.get(questionId)!) as Map<String, dynamic>);
  }

  bool hasWrongQuestion(String questionId) {
    return box.containsKey(questionId);
  }

  exportWrongQuestion(String outputPath) async {
    var builder = QuestionBankBuilder(displayName: "错题本", version: 2);
    for (var questionId in box.keys) {
      builder.addQuestionByOld(getWrongQuestion(questionId));
    }
    builder.addTestFile("build by wrong question book");
    await builder.addNeedImageForBuilder();
    // builder.getDataFileContent();

    builder.build(outputPath);
  }
}
