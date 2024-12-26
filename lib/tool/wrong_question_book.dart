import 'dart:convert';

import 'package:flutter_application_1/tool/question_bank.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
part 'wrong_question_book.g.dart';

class WrongQuestionBook {
  late Box<String> wrongBox;
  late Box<QuestionUserData> questionBox;
  WrongQuestionBook() {
    wrongBox = Hive.box<String>("wrong_question_book");
    questionBox = Hive.box<QuestionUserData>("question_book");
  }
  static init() async {
    Hive.init(
        path.join((await getApplicationDocumentsDirectory()).path, "hive"));
    Hive.registerAdapter(QuestionUserDataAdapter());
    await Hive.openBox<String>("wrong_question_book");
    await Hive.openBox<QuestionUserData>("question_book");

  }

  static WrongQuestionBook instance = WrongQuestionBook();

  void addWrongQuestion(String questionId, SingleQuestionData question) {
    wrongBox.put(questionId, json.encode(question.toJson()));
  }

  void removeWrongQuestion(String questionId) {
    wrongBox.delete(questionId);
  }

  void clearWrongQuestion() {
    wrongBox.clear();
  }

  List<String> getWrongQuestionIds() {
    return wrongBox.keys.map((toElement) => toElement.toString()).toList();
  }

  SingleQuestionData getWrongQuestion(String questionId) {
    return SingleQuestionData.fromJson(
        json.decode(wrongBox.get(questionId)!) as Map<String, dynamic>);
  }

  bool hasWrongQuestion(String questionId) {
    return wrongBox.containsKey(questionId);
  }

  exportWrongQuestion(String outputPath) async {
    var builder = QuestionBankBuilder(displayName: "错题本", version: 2);
    for (var questionId in wrongBox.keys) {
      builder.addQuestionByOld(getWrongQuestion(questionId));
    }
    builder.addTestFile("build by wrong question book");
    await builder.addNeedImageForBuilder();
    // builder.getDataFileContent();

    builder.build(outputPath);
  }

  Future<void> addQuestion(
      String questionId, QuestionUserData questionUserData) async {
    await questionBox.put(questionId, questionUserData);
  }

  Future<void> removeQuestion(String questionId) async {
    await questionBox.delete(questionId);
  }

  Future<void> clearQuestion() async {
    await questionBox.clear();
  }

  hasQuestion(String questionId) {
    return questionBox.containsKey(questionId);
  }

  QuestionUserData getQuestion(String questionId) {
    return questionBox.get(questionId) ?? QuestionUserData(0);
  }
}

@HiveType(typeId: 1)
class QuestionUserData {
  @HiveField(0)
  int happenedTimes = 0;

  QuestionUserData(this.happenedTimes);
}
