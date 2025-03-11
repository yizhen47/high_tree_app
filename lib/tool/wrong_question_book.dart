import 'dart:convert';

import 'package:flutter_application_1/tool/question_bank.dart';
import 'package:flutter_application_1/tool/question_controller.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
part 'wrong_question_book.g.dart';

class WrongQuestionBook {
  late Box<String> wrongBox;
  late Box<QuestionUserData> questionBox;
  late Box<SectionUserData> sectionDataBox;
  late Box<BankLearnData> sectionLearnBox;
  // We'll use Map<String, String> for manual sections until the adapter is generated
  late Box<String> manualSectionsBox;
  
  WrongQuestionBook() {
    wrongBox = Hive.box<String>("wrong_question_book");
    questionBox = Hive.box<QuestionUserData>("question_book");
    sectionDataBox = Hive.box<SectionUserData>("section_data");
    sectionLearnBox = Hive.box<BankLearnData>("bank_learn_data");
    manualSectionsBox = Hive.box<String>("manual_sections");
  }
  static init() async {
    Hive.init(
        path.join((await getApplicationDocumentsDirectory()).path, "hive"));
    Hive.registerAdapter(QuestionUserDataAdapter());
    Hive.registerAdapter(SectionUserDataAdapter());
    Hive.registerAdapter(BankLearnDataAdapter());
    // We'll need to run code generation to create this adapter
    // For now, we'll remove this line until the adapter is generated
    await Hive.openBox<String>("wrong_question_book");
    await Hive.openBox<QuestionUserData>("question_book");
    await Hive.openBox<SectionUserData>("section_data");
    await Hive.openBox<BankLearnData>("bank_learn_data");
    await Hive.openBox<String>("manual_sections");
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

  void updateQuestion(String questionId, QuestionUserData questionUserData){
    questionBox.put(questionId, questionUserData);
  }


  mksureQuestion(String questionId) {
    if (!questionBox.containsKey(questionId)) {
      questionBox.put(questionId, QuestionUserData(0));
    }
  }

  clearData(){
    questionBox.clear();
    sectionDataBox.clear();
    sectionLearnBox.clear();
    wrongBox.clear();
    manualSectionsBox.clear();
  }
}

@HiveType(typeId: 1)
class QuestionUserData {
  @HiveField(0)
  int tryCompleteTimes = 0;
  @HiveField(1)
  String? note = "";

  QuestionUserData(this.tryCompleteTimes);
}
