import 'dart:io';
import 'dart:convert';
import 'dart:math';

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
        return "智能推荐";
      case StudyType.testMode:
        return "智能推荐";
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
    
    // 初始化小时级别的学习数据
    _hourlyStudyData = {};
    final dataList = sharedPreferences?.getStringList('hourlyStudyData');
    if (dataList != null) {
      for (final entry in dataList) {
        final parts = entry.split(':');
        if (parts.length == 2) {
          try {
            _hourlyStudyData[parts[0]] = double.parse(parts[1]);
          } catch (e) {
            // 忽略解析错误
          }
        }
      }
    }
    
    // 初始化知识点掌握数据
    _topicMasteryData = {};
    _topicStudyCountData = {};
    _topicLastStudyData = {};
    
    // 加载数据（已经在getter方法中实现）
    topicMasteryData;
    topicStudyCountData;
    topicLastStudyData;
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
    return sharedPreferences!.getInt("studyCount") ?? 0;
  }

  set studyCount(int value) {
    sharedPreferences!.setInt("studyCount", value);
  }

  double get studyMinute {
    return sharedPreferences!.getDouble("studyMinute") ?? 0.0;
  }

  set studyMinute(double value) {
    sharedPreferences!.setDouble("studyMinute", value);
  }

  StudyType get studyType {
    return StudyType.values[
        sharedPreferences!.getInt("studyType") ?? StudyType.recommandMode.index];
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
  
  int get currentPlanId {
    return sharedPreferences?.getInt('currentPlanId') ?? -1;
  }
  
  set currentPlanId(int value) {
    sharedPreferences?.setInt('currentPlanId', value);
  }
  
  // 增加学习时间（以分钟为单位）
  void incrementStudyTime(int minutes) {
    // 获取当前学习时间（小时）
    double currentTime = studyMinute;
    // 转换分钟为小时并累加（保留两位小数）
    studyMinute = double.parse((currentTime + (minutes / 60)).toStringAsFixed(2));
    // 同时增加学习次数
    if (minutes > 0) {
      studyCount = studyCount + 1;
    }
  }
  
  // 记录学习开始时间
  DateTime? _studyStartTime;
  
  // 按小时存储的学习时间数据 (Key格式: YYYY-MM-DD-HH)
  Map<String, double> _hourlyStudyData = {};

  // 知识点掌握度数据 (Key格式: topicId, Value: 掌握度0.0-1.0)
  Map<String, double> _topicMasteryData = {};

  // 知识点学习次数 (Key格式: topicId, Value: 学习次数)
  Map<String, int> _topicStudyCountData = {};

  // 知识点最近学习时间 (Key格式: topicId, Value: 时间戳毫秒)
  Map<String, int> _topicLastStudyData = {};

  // 获取所有小时级别的学习数据
  Map<String, double> get hourlyStudyData {
    // 先加载保存的数据
    Map<String, double> result = {};
    final dataList = sharedPreferences?.getStringList('hourlyStudyData');
    
    if (dataList != null && dataList.isNotEmpty) {
      for (final entry in dataList) {
        final parts = entry.split(':');
        if (parts.length == 2) {
          try {
            result[parts[0]] = double.parse(parts[1]);
          } catch (e) {
            // 忽略解析错误
          }
        }
      }
    }
    
    // 合并内存中的数据
    result.addAll(_hourlyStudyData);
    return result;
  }

  // 保存小时级别的学习数据
  void _saveHourlyStudyData() {
    // 合并现有数据
    final allData = hourlyStudyData;
    
    final dataList = allData.entries
        .map((entry) => '${entry.key}:${entry.value}')
        .toList();
    
    sharedPreferences?.setStringList('hourlyStudyData', dataList);
  }

  // 获取指定日期的学习时间（分钟）
  double getStudyTimeForDate(DateTime date) {
    final dateStr = _formatDate(date);
    return hourlyStudyData.entries
        .where((entry) => entry.key.startsWith(dateStr))
        .fold(0.0, (sum, entry) => sum + entry.value);
  }

  // 获取指定小时的学习时间（分钟）
  double getStudyTimeForHour(DateTime dateTime) {
    final key = _formatDateTime(dateTime);
    return hourlyStudyData[key] ?? 0.0;
  }

  // 获取过去N天的学习时间数据
  Map<String, double> getStudyTimeForLastDays(int days) {
    final result = <String, double>{};
    final now = DateTime.now();
    
    for (int i = 0; i < days; i++) {
      final date = now.subtract(Duration(days: i));
      final dateStr = _formatDate(date);
      final timeForDate = getStudyTimeForDate(date);
      result[dateStr] = timeForDate;
    }
    
    return result;
  }

  // 格式化日期为 YYYY-MM-DD
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // 格式化日期时间为 YYYY-MM-DD-HH
  String _formatDateTime(DateTime dateTime) {
    return '${_formatDate(dateTime)}-${dateTime.hour.toString().padLeft(2, '0')}';
  }

  // 开始学习会话
  void startStudySession() {
    _studyStartTime = DateTime.now();
  }
  
  // 结束学习会话并更新学习时间
  void endStudySession() {
    if (_studyStartTime != null) {
      final now = DateTime.now();
      final duration = now.difference(_studyStartTime!);
      
      // 如果学习时间跨越了不同的小时，则需要分别记录每个小时的学习时间
      DateTime currentHour = DateTime(_studyStartTime!.year, _studyStartTime!.month, 
                                     _studyStartTime!.day, _studyStartTime!.hour);
      DateTime nextHour = currentHour.add(const Duration(hours: 1));
      
      while (currentHour.isBefore(now)) {
        final endOfHour = nextHour.isBefore(now) ? nextHour : now;
        final minutesInHour = endOfHour.difference(
            currentHour.isAfter(_studyStartTime!) ? currentHour : _studyStartTime!
        ).inMinutes;
        
        if (minutesInHour > 0) {
          final hourKey = _formatDateTime(currentHour);
          _hourlyStudyData[hourKey] = (_hourlyStudyData[hourKey] ?? 0.0) + minutesInHour;
        }
        
        currentHour = nextHour;
        nextHour = currentHour.add(const Duration(hours: 1));
      }
      
      // 将学习时长转换为分钟并更新总时间
      final minutes = duration.inMinutes;
      if (minutes > 0) {
        incrementStudyTime(minutes);
        _saveHourlyStudyData(); // 保存小时级别数据
      }
      
      // 重置开始时间
      _studyStartTime = null;
    }
  }

  // 获取所有知识点掌握度数据
  Map<String, double> get topicMasteryData {
    final dataString = sharedPreferences?.getString('topicMasteryData');
    Map<String, double> result = {};
    
    if (dataString != null && dataString.isNotEmpty) {
      try {
        final decoded = Map<String, dynamic>.from(
          json.decode(dataString) as Map
        );
        result = decoded.map((key, value) => 
          MapEntry(key, (value as num).toDouble()));
      } catch (e) {
        print('Error decoding topic mastery data: $e');
      }
    }
    
    // 合并内存中的数据
    result.addAll(_topicMasteryData);
    return result;
  }

  // 保存知识点掌握度数据
  void _saveTopicMasteryData() {
    // 合并现有数据
    final allData = topicMasteryData;
    final jsonData = json.encode(allData);
    sharedPreferences?.setString('topicMasteryData', jsonData);
  }

  // 获取知识点学习次数数据
  Map<String, int> get topicStudyCountData {
    final dataString = sharedPreferences?.getString('topicStudyCountData');
    Map<String, int> result = {};
    
    if (dataString != null && dataString.isNotEmpty) {
      try {
        final decoded = Map<String, dynamic>.from(
          json.decode(dataString) as Map
        );
        result = decoded.map((key, value) => 
          MapEntry(key, (value as num).toInt()));
      } catch (e) {
        print('Error decoding topic study count data: $e');
      }
    }
    
    // 合并内存中的数据
    result.addAll(_topicStudyCountData);
    return result;
  }

  // 保存知识点学习次数数据
  void _saveTopicStudyCountData() {
    // 合并现有数据
    final allData = topicStudyCountData;
    final jsonData = json.encode(allData);
    sharedPreferences?.setString('topicStudyCountData', jsonData);
  }

  // 获取知识点最近学习时间数据
  Map<String, int> get topicLastStudyData {
    final dataString = sharedPreferences?.getString('topicLastStudyData');
    Map<String, int> result = {};
    
    if (dataString != null && dataString.isNotEmpty) {
      try {
        final decoded = Map<String, dynamic>.from(
          json.decode(dataString) as Map
        );
        result = decoded.map((key, value) => 
          MapEntry(key, (value as num).toInt()));
      } catch (e) {
        print('Error decoding topic last study data: $e');
      }
    }
    
    // 合并内存中的数据
    result.addAll(_topicLastStudyData);
    return result;
  }

  // 保存知识点最近学习时间数据
  void _saveTopicLastStudyData() {
    // 合并现有数据
    final allData = topicLastStudyData;
    final jsonData = json.encode(allData);
    sharedPreferences?.setString('topicLastStudyData', jsonData);
  }

  // 更新知识点掌握度
  void updateTopicMastery(String topicId, double correctRate, {double weight = 0.3}) {
    // 获取当前掌握度
    final currentMastery = topicMasteryData[topicId] ?? 0.0;
    
    // 逐渐增加掌握度，但考虑到正确率的影响
    // 公式: 新掌握度 = 旧掌握度 * (1-权重) + 正确率 * 权重
    final newMastery = currentMastery * (1 - weight) + correctRate * weight;
    
    // 限制在0.0-1.0之间
    _topicMasteryData[topicId] = newMastery.clamp(0.0, 1.0);
    
    // 更新学习次数
    final currentCount = topicStudyCountData[topicId] ?? 0;
    _topicStudyCountData[topicId] = currentCount + 1;
    
    // 更新最近学习时间
    _topicLastStudyData[topicId] = DateTime.now().millisecondsSinceEpoch;
    
    // 保存数据
    _saveTopicMasteryData();
    _saveTopicStudyCountData();
    _saveTopicLastStudyData();
  }

  // 获取指定知识点的掌握度
  double getTopicMastery(String topicId) {
    return topicMasteryData[topicId] ?? 0.0;
  }

  // 获取指定知识点的学习次数
  int getTopicStudyCount(String topicId) {
    return topicStudyCountData[topicId] ?? 0;
  }

  // 获取知识点最近学习时间
  DateTime? getTopicLastStudyTime(String topicId) {
    final timestamp = topicLastStudyData[topicId];
    if (timestamp == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  // 根据遗忘曲线计算当前实际掌握度
  double getCurrentTopicMastery(String topicId) {
    final baseMastery = getTopicMastery(topicId);
    final lastStudyTime = getTopicLastStudyTime(topicId);
    
    if (lastStudyTime == null) return baseMastery;
    
    // 计算距离上次学习的天数
    final daysSinceLastStudy = DateTime.now().difference(lastStudyTime).inDays;
    
    // 基于艾宾浩斯遗忘曲线计算保留率
    // R = e^(-t/S)，其中t是时间，S是稳定性参数
    final stability = 20.0 * (getTopicStudyCount(topicId) + 1); // 学习次数越多，稳定性越高
    final retentionRate = exp(-daysSinceLastStudy / stability);
    
    // 计算当前掌握度
    return (baseMastery * retentionRate).clamp(0.0, 1.0);
  }

  // 计算知识点的保留天数（距离上次学习的天数）
  int getTopicRetentionDay(String topicId) {
    final lastStudyTime = getTopicLastStudyTime(topicId);
    if (lastStudyTime == null) return 0;
    
    // 计算天数差
    return DateTime.now().difference(lastStudyTime).inDays + 1;
  }
  
  // 获取知识点的详细掌握情况，包括基础掌握度、应用遗忘曲线后的实际掌握度、保留天数等
  Map<String, dynamic> getTopicMasteryDetails(String topicId) {
    final baseMastery = getTopicMastery(topicId);
    final currentMastery = getCurrentTopicMastery(topicId);
    final studyCount = getTopicStudyCount(topicId);
    final lastStudyTime = getTopicLastStudyTime(topicId);
    final retentionDay = getTopicRetentionDay(topicId);
    
    // 计算保留率
    double retentionRate = 1.0;
    if (lastStudyTime != null) {
      final daysSinceLastStudy = DateTime.now().difference(lastStudyTime).inDays;
      final stability = 20.0 * (studyCount + 1);
      retentionRate = exp(-daysSinceLastStudy / stability);
    }
    
    return {
      'baseMastery': baseMastery,
      'currentMastery': currentMastery,
      'retentionRate': retentionRate,
      'studyCount': studyCount,
      'lastStudyTime': lastStudyTime,
      'retentionDay': retentionDay,
    };
  }

  // 获取需要复习的知识点
  List<String> getTopicsNeedingReview({double threshold = 0.7}) {
    final result = <String>[];
    final allTopics = topicMasteryData.keys.toList();
    
    for (final topicId in allTopics) {
      final currentMastery = getCurrentTopicMastery(topicId);
      if (currentMastery < threshold) {
        result.add(topicId);
      }
    }
    
    // 按掌握度排序，最需要复习的排在前面
    result.sort((a, b) => 
      getCurrentTopicMastery(a).compareTo(getCurrentTopicMastery(b)));
    
    return result;
  }
}
