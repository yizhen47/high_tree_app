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

  String getUserName() {
    return sharedPreferences!.getString("userName") ?? "未命名";
  }

  setSign(String sign) {
    sharedPreferences!.setString("sign", sign);
  }

  String getSign() {
    return sharedPreferences!.getString("sign") ?? "这个人很懒，没有设置签名";
  }

  setUserName(String userName) {
    sharedPreferences!.setString("userName", userName);
  }

  int getStudyCount() {
    return sharedPreferences!.getInt("studyCount")!;
  }

  setStudyCount(int studyCount) {
    sharedPreferences!.setInt("studyCount", studyCount);
  }

  int getStudyTime() {
    return sharedPreferences!.getInt("studyTime")!;
  }

  setStudyTime(int studyTime) {
    sharedPreferences!.setInt("studyTime", studyTime);
  }

  StudyType getStudyType() {
    return StudyType.values[
        sharedPreferences!.getInt("studyType") ?? StudyType.testMode.index];
  }

  setStudyType(StudyType studyType) {
    sharedPreferences!.setInt("studyType", studyType.index);
  }

  StudyDifficulty getStudyDifficulty() {
    return StudyDifficulty.values[
        sharedPreferences!.getInt("studyDifficulty") ??
            StudyDifficulty.normal.index];
  }

  setStudyDifficulty(StudyDifficulty studyDifficulty) {
    sharedPreferences!.setInt("studyDifficulty", studyDifficulty.index);
  }

  String? getStudySection() {
    return sharedPreferences!.getString("studySection");
  }

  setStudySection(String? studySection) {
    if (studySection == null) {
      sharedPreferences!.remove("studySection");
    } else {
      sharedPreferences!.setString("studySection", studySection);
    }
  }

  int getStudyQuestionNum() {
    return sharedPreferences!.getInt("sStudyQuestionNum") ?? 5;
  }

  setStudyQuestionNum(int studyQuestionNum) {
    sharedPreferences!.setInt("sStudyQuestionNum", studyQuestionNum);
  }

  String? getAvatar() {
    return sharedPreferences!.getString("avatar") == null
        ? null
        : path.join(dataDir!, "avatar");
  }

  setAvatar(String avatar) async {
    await sharedPreferences!.setString("avatar", avatar);
    await File(avatar).copy(path.join(dataDir!, "avatar"));
  }
  Color getThemeColor() {
    return Color(sharedPreferences!.getInt("themeColor") ?? Colors.blueAccent.value);
  }
  setThemeColor(Color color) async {
    await sharedPreferences!.setInt("themeColor", color.value);
  }
  
}
