import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as path;

enum StudyDifficulty {
  easy(displayName: "简单模式"),
  normal(displayName: "普通模式"),
  hard(displayName: "困难模式");

  const StudyDifficulty({required this.displayName});
  final String displayName;
}

enum StudyType {
  studyMode,
  testMode,
  recommandMode;

  String getDisplayName() {
    switch (this) {
      case StudyType.studyMode:
        return "学习模式";
      case StudyType.testMode:
        return "测试模式";
      case StudyType.recommandMode:
        return "推荐模式";
    }
  }
}

class StudyData {
  SharedPreferences? sharedPreferences;
  String? dataDir;
  static StudyData instance = StudyData();

  StudyData();
  init() async {
    sharedPreferences = await SharedPreferences.getInstance();
    dataDir =
        path.join((await getApplicationSupportDirectory()).path, "userData");
    if (!Directory(dataDir!).existsSync()) {
      Directory(dataDir!).createSync();
    }
  }

  String get userName {
    return sharedPreferences!.getString("userName") ?? "未命名";
  }

  set userName(String value) {
    sharedPreferences!.setString("userName", value);
  }

  String get sign {
    return sharedPreferences!.getString("sign") ?? "这个人很懒，没有设置签名";
  }

  set sign(String value) {
    sharedPreferences!.setString("sign", value);
  }

  int get studyCount {
    return sharedPreferences!.getInt("studyCount")!;
  }

  set studyCount(int value) {
    sharedPreferences!.setInt("studyCount", value);
  }

  int get studyTime {
    return sharedPreferences!.getInt("studyTime")!;
  }

  set studyTime(int value) {
    sharedPreferences!.setInt("studyTime", value);
  }

  StudyType get studyType {
    return StudyType.values[
        sharedPreferences!.getInt("studyType") ?? StudyType.testMode.index];
  }

  set studyType(StudyType value) {
    sharedPreferences!.setInt("studyType", value.index);
  }

  StudyDifficulty get studyDifficulty {
    return StudyDifficulty.values[
        sharedPreferences!.getInt("studyDifficulty") ??
            StudyDifficulty.normal.index];
  }

  set studyDifficulty(StudyDifficulty value) {
    sharedPreferences!.setInt("studyDifficulty", value.index);
  }

  String? get studySection {
    return sharedPreferences!.getString("studySection");
  }

  set studySection(String? value) {
    if (value == null) {
      sharedPreferences!.remove("studySection");
    } else {
      sharedPreferences!.setString("studySection", value);
    }
  }

  int get studyQuestionNum {
    return sharedPreferences!.getInt("sStudyQuestionNum") ?? 5;
  }

  set studyQuestionNum(int value) {
    sharedPreferences!.setInt("sStudyQuestionNum", value);
  }

  String? get avatar {
    return sharedPreferences!.getString("avatar") == null
        ? null
        : path.join(dataDir!, "avatar");
  }

  // Fixed: Removed async and matched parameter type with getter return type
  set avatar(String? value) {
    if (value != null) {
      sharedPreferences!.setString("avatar", value);
      File(value).copy(path.join(dataDir!, "avatar"));
    }
  }

  Color get themeColor {
    return Color(
        sharedPreferences!.getInt("themeColor") ?? Colors.blueAccent.value);
  }

  // Fixed: Removed async
  set themeColor(Color value) {
    sharedPreferences!.setInt("themeColor", value.value);
  }

  bool get nightModeFollowSystem {
    return sharedPreferences!.getBool("nightModeFollowSystem") ?? false;
  }

  // Fixed: Removed async
  set nightModeFollowSystem(bool value) {
    sharedPreferences!.setBool("nightModeFollowSystem", value);
  }

  bool get nightMode {
    return nightModeFollowSystem
        ? true
        : sharedPreferences!.getBool("nightMode") ?? false;
  }

  // Fixed: Removed async
  set nightMode(bool value) {
    sharedPreferences!.setBool("nightMode", value);
  }

  int get today {
    return sharedPreferences!.getInt("today") ?? 0;
  }
  
  set today(int value) {
    sharedPreferences!.setInt("today", value);
  }
  
  bool todayUpdater() {
    var today = DateTime.now().day;
    if (this.today != today) {
      this.today = today;
      return true;
    }
    return false;
  }

  int get needLearnSectionNum {
    return sharedPreferences?.getInt('needLearnSectionNum') ?? 5;
  }

  set needLearnSectionNum(int value) {
    sharedPreferences?.setInt('needLearnSectionNum', value);
  }

  int get needCompleteQuestionNum {
    return sharedPreferences?.getInt('needCompleteQuestionNum') ?? 2;
  }

  set needCompleteQuestionNum(int value) {
    sharedPreferences?.setInt('needCompleteQuestionNum', value);
  }
}
