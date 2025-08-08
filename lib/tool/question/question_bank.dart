import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';
import 'package:archive/archive_io.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:xml/xml.dart';
import 'dart:convert';
import 'package:path/path.dart' as path;
import 'package:json_annotation/json_annotation.dart';

part 'question_bank.g.dart';

Random? _random;

void mksureInit() {
  _random ??= Random();
}

@JsonSerializable()
class SingleQuestionData {
  List<String> fromKonwledgePoint = [];
  List<String> fromKonwledgeIndex = [];
  Map<String, dynamic> question;
  String fromId;
  String fromDisplayName;

  factory SingleQuestionData.fromJson(Map<String, dynamic> json) =>
      _$SingleQuestionDataFromJson(json);

  Map<String, dynamic> toJson() => _$SingleQuestionDataToJson(this);
  SingleQuestionData(this.question, this.fromId, this.fromDisplayName);

  String getKonwledgePoint() {
    return fromKonwledgePoint.isEmpty ? '' : fromKonwledgePoint.last;
  }

  String getKonwledgeIndex() {
    return fromKonwledgeIndex.isEmpty ? '' : fromKonwledgeIndex.last;
  }

  SingleQuestionData clone() {
    final newQuestionMap = Map<String, dynamic>.from(question);
    if (question.containsKey('options')) {
      newQuestionMap['options'] =
          (question['options'] as List).map((opt) => Map.from(opt as Map)).toList();
    }
    return SingleQuestionData(newQuestionMap, fromId, fromDisplayName)
      ..fromKonwledgeIndex = List.from(fromKonwledgeIndex)
      ..fromKonwledgePoint = List.from(fromKonwledgePoint);
  }

  // toXml 和 fromXml 已被移除，因为它们不再被使用，且会与新的数据结构冲突。
  // 相关的 XML 序列化/反序列化逻辑已移至 Section 类中统一处理。
}

@JsonSerializable()
class Section {
  String index;
  String title;
  String? note;
  String? image;  // 添加图片解释支持，用于思维导图
  List<Section>? children;
  List<Map<String, dynamic>>? questions;
  List<String>? videos;  // 添加视频列表支持

  List<String> fromKonwledgePoint = [];
  List<String> fromKonwledgeIndex = [];

  String get id => '${fromKonwledgeIndex.join('/')}/$index';

  factory Section.fromJson(Map<String, dynamic> json) =>
      _$SectionFromJson(json);

  Map<String, dynamic> toJson() => _$SectionToJson(this);

  Section(this.index, this.title)
      : children = [],
        questions = [],
        videos = [],
        note = '',
        image = null;

  Map<String, dynamic> toTrimJson() {
    return {
      'index': index,
      'title': title,
      'children': children!.map((child) => child.toTrimJson()).toList(),
      'note': note!.isNotEmpty ? note!.trim() : null,
      'image': image?.isNotEmpty == true ? image!.trim() : null,
      'videos': videos!.isNotEmpty ? videos : null,
      'fromKonwledgePoint': fromKonwledgePoint,
      'fromKonwledgeIndex': fromKonwledgeIndex,
      'questions': questions!.isNotEmpty
          ? questions!
              .map((q) => {
                    'q': q['q']?.toString().trim(),
                    'w': q['w']?.toString().trim(),
                    'id': q['id'] ?? const Uuid().v4(),
                    if (q['note'] != null) 'note': q['note']?.toString().trim(),
                    if (q['options'] != null) 'options': q['options'],
                    if (q['answer'] != null) 'answer': q['answer'],
                    if (q['video'] != null) 'video': q['video']?.toString().trim(),
                  })
              .toList()
          : null,
    }..removeWhere(
        (key, value) => value == null || (value is List && value.isEmpty));
  }

  SingleQuestionData randomSectionQuestion(String fromId, String fromName,
      {int retryingTimes = 20, bool onlyLayer = false}) {
    SingleQuestionData? q;
    for (var i = 0; i < retryingTimes; i++) {
      q = _randomSectionQuestion(fromId, fromName, onlyLayer);
      if (q != null) {
        break;
      }
    }
    if (q == null) {
      return SingleQuestionData(
          {'q': '本章没有题目', 'w': '本章没有答案', 'id': const Uuid().v4()},
          fromId,
          fromName);
    }
    return q;
  }

  SingleQuestionData? _randomSectionQuestion(
      String fromId, String fromName, bool onlyLayer) {
    // 只有有学习价值的叶子节点才能有题目
    if (children == null || children!.isEmpty) {
      // 这是叶子节点，检查是否有学习价值（有题目）
      if (!hasLearnableContent()) return null;
      
      // 优先选择有视频的题目
      var selectedQuestion = _selectQuestionWithVideoPriority();
      return SingleQuestionData(selectedQuestion, fromId, fromName)
        ..fromKonwledgeIndex = (List.from(fromKonwledgeIndex)..add(index))
        ..fromKonwledgePoint = (List.from(fromKonwledgePoint)..add(title));
    }

    // 非叶子节点，从子节点中随机选择
    if (onlyLayer) {
      // 如果只要求当前层级，但当前是非叶子节点，返回null
      return null;
    }

    // 只考虑有学习价值的子节点
    List<int> childQs = [];
    int childTotal = 0;

      for (var child in children!) {
      if (child.hasLearnableContent()) {
        int total = child.getTotalQuestions();
        childQs.add(total);
        childTotal += total;
      } else {
        childQs.add(0); // 没有学习价值的子节点不参与随机选择
      }
    }

    if (childTotal == 0) return null;

    int rand = _random!.nextInt(childTotal);
      int accumulated = 0;
      for (int i = 0; i < children!.length; i++) {
        accumulated += childQs[i];
      if (rand < accumulated && childQs[i] > 0) { // 确保选择的是有学习价值的节点
          return children![i]
              .randomSectionQuestion(fromId, fromName, onlyLayer: false);
        }
      }
    return null;
  }

  // 优先选择有视频的题目
  Map<String, dynamic> _selectQuestionWithVideoPriority() {
    if (questions == null || questions!.isEmpty) {
      throw StateError('No questions available');
    }
    
    // 分离有视频和无视频的题目
    List<Map<String, dynamic>> questionsWithVideo = [];
    List<Map<String, dynamic>> questionsWithoutVideo = [];
    
    for (var question in questions!) {
      String? videoPath = question['video']?.toString();
      if (videoPath != null && videoPath.isNotEmpty) {
        questionsWithVideo.add(question);
      } else {
        questionsWithoutVideo.add(question);
      }
    }
    
    // 70% 概率选择有视频的题目，30% 概率选择无视频的题目
    if (questionsWithVideo.isNotEmpty && 
        (questionsWithoutVideo.isEmpty || _random!.nextDouble() < 0.7)) {
      return questionsWithVideo[_random!.nextInt(questionsWithVideo.length)];
    } else if (questionsWithoutVideo.isNotEmpty) {
      return questionsWithoutVideo[_random!.nextInt(questionsWithoutVideo.length)];
    } else {
      // 如果没有任何题目，返回第一个题目
      return questions![0];
    }
  }

  // 检查此节点是否有可学习的内容（有题目）
  bool hasLearnableContent() {
    return questions != null && questions!.isNotEmpty;
  }

  // 获取最适合学习的节点：如果当前节点是无题目的叶子节点，则查找有题目的父节点
  Section? getLearnableSection() {
    // 如果当前节点有学习价值，直接返回
    if (hasLearnableContent()) {
      return this;
    }
    // 如果没有学习价值，返回null，让调用者向上查找
    return null;
  }

  // 递归获取题目总数（只从有学习价值的叶子节点计算）
  int getTotalQuestions({bool onlyLayer = false}) {
    // 如果是叶子节点，只有有学习价值的才返回题目数
    if (children == null || children!.isEmpty) {
      return hasLearnableContent() ? (questions?.length ?? 0) : 0;
    }
    
    // 如果只计算当前层级，非叶子节点返回0
    if (onlyLayer) {
      return 0;
    }
    
    // 非叶子节点，递归计算有学习价值的子节点题目总数
    int total = 0;
    for (Section child in children!) {
      if (child.hasLearnableContent()) {
        total += child.getTotalQuestions();
      }
    }
    return total;
  }

  List<SingleQuestionData> randomMultipleSectionQuestions(
    String fromId,
    String fromName,
    int count, {
    int totalRetryTimes = 100,
    bool onlyLayer = false,
  }) {
    final Set<String> usedIds = {};
    final List<SingleQuestionData> result = [];

    for (int i = 0; i < count; i++) {
      SingleQuestionData? question;
      int retryCount = 0;

      // 尝试获取新问题的循环
      while (retryCount < totalRetryTimes) {
        final candidate = randomSectionQuestion(
          fromId,
          fromName,
          retryingTimes: 20,
          onlyLayer: onlyLayer,
        );

        // 检查是否重复且不是空问题
        if (!usedIds.contains(candidate.question['id']) &&
            candidate.question['q'] != '本章没有题目') {
          question = candidate;
          usedIds.add(candidate.question['id']!);
          break;
        }

        retryCount++;
      }

      // 最终仍未找到新问题时的处理
      result.add(question ??
          SingleQuestionData(
            {'q': '本章没有题目', 'w': '本章没有答案', 'id': const Uuid().v4()},
            fromId,
            fromName,
          ));
    }

    // 最终校验是否所有问题都有效
    final validCount = result
        .where((q) => q.question != '问题不足' && q.question != '本章没有题目')
        .length;
    return validCount >= count ? result : [];
  }

  List<SingleQuestionData> sectionQuestion(String fromId, String fromName,
      {List<SingleQuestionData>? questionsList}) {
    questionsList ??= [];
    
    // 首先，添加当前节点自身的题目
    if (questions != null) {
      for (var q in questions!) {
        questionsList.add(SingleQuestionData(q, fromId, fromName)
          ..fromKonwledgeIndex = (List.from(fromKonwledgeIndex)..add(index))
          ..fromKonwledgePoint = (List.from(fromKonwledgePoint)..add(title)));
      }
    }

    // 然后，递归地从所有子节点中获取题目
    if (children != null) {
      for (var c in children!) {
        c.sectionQuestion(fromId, fromName, questionsList: questionsList);
      }
    }
    return questionsList;
  }

  List<SingleQuestionData> sectionQuestionOnly(String fromId, String fromName,
      {List<SingleQuestionData>? questionsList}) {
    questionsList ??= [];
    
    // 无论是否为叶子节点，都直接获取当前节点的题目
    if (hasLearnableContent() && questions != null) {
      for (var q in questions!) {
        questionsList.add(SingleQuestionData(q, fromId, fromName)
          ..fromKonwledgeIndex = (List.from(fromKonwledgeIndex)..add(index))
          ..fromKonwledgePoint = (List.from(fromKonwledgePoint)..add(title)));
      }
    }
    
    return questionsList;
  }

  XmlElement toXml() {
    return XmlElement(XmlName('Section'), [
      XmlAttribute(XmlName('index'), index),
      XmlAttribute(XmlName('title'), title),
    ], [
      if (note != null && note!.isNotEmpty)
        XmlElement(XmlName('note'), [], [XmlText(note!)]),
      if (image != null && image!.isNotEmpty)
        XmlElement(XmlName('image'), [], [XmlText(image!)]),
      if (children != null && children!.isNotEmpty)
        XmlElement(XmlName('children'), [],
            children!.map((child) => child.toXml()).toList()),
      if (fromKonwledgeIndex.isNotEmpty)
        XmlElement(
            XmlName('fromKonwledgeIndex'),
            [],
            fromKonwledgeIndex
                .map((index) =>
                    XmlElement(XmlName('item'), [], [XmlText(index)]))
                .toList()),
      if (fromKonwledgePoint.isNotEmpty)
        XmlElement(
            XmlName('fromKonwledgePoint'),
            [],
            fromKonwledgePoint
                .map((point) =>
                    XmlElement(XmlName('item'), [], [XmlText(point)]))
                .toList()),
      if (videos != null && videos!.isNotEmpty)
        XmlElement(
            XmlName('videos'),
            [],
            videos!
                .map((video) =>
                    XmlElement(XmlName('video'), [], [XmlText(video)]))
                .toList()),
      if (questions != null && questions!.isNotEmpty)
        XmlElement(
            XmlName('questions'),
            [],
            questions!.map((q) {
              final id = q['id']?.toString() ?? const Uuid().v4();
              final questionElements = <XmlNode>[];

              // 序列化普通字段
              ['q', 'w', 'note', 'video'].forEach((key) {
                if (q[key] != null) {
                  questionElements.add(XmlElement(XmlName(key), [], [XmlText(q[key].toString())]));
                }
              });

              // 序列化答案字段
              if (q['answer'] != null) {
                final answerElement = XmlElement(XmlName('answer'));
                if (q['answer'] is List) {
                  for (var ans in (q['answer'] as List)) {
                    answerElement.children.add(XmlElement(XmlName('item'), [], [XmlText(ans.toString())]));
                  }
                } else {
                  answerElement.children.add(XmlText(q['answer'].toString()));
                }
                questionElements.add(answerElement);
              }

              // 序列化选项字段
              if (q['options'] != null && q['options'] is List) {
                final optionsElement = XmlElement(XmlName('options'));
                for (var opt in (q['options'] as List)) {
                  if (opt is Map) {
                    optionsElement.children.add(XmlElement(
                        XmlName('option'),
                        [XmlAttribute(XmlName('key'), opt['key'].toString())],
                        [XmlText(opt['value'].toString())]));
                  }
                }
                questionElements.add(optionsElement);
              }

              return XmlElement(XmlName('question'),
                  [XmlAttribute(XmlName('id'), id)], questionElements);
            }).toList())
    ]);
  }

  factory Section.fromXml(XmlElement element) {
    final index = element.getAttribute('index') ?? '';
    final title = element.getAttribute('title') ?? '';
    final section = Section(index, title);

    // 解析备注
    section.note = element.findElements('note').firstOrNull?.text;
    
    // 解析图片
    section.image = element.findElements('image').firstOrNull?.text;

    // 解析子章节
    section.children = element
            .findElements('children')
            .firstOrNull
            ?.findElements('Section')
            .map((e) => Section.fromXml(e))
            .toList() ??
        [];

    //解析index和point
    section.fromKonwledgeIndex = element
            .findElements('fromKonwledgeIndex')
            .firstOrNull
            ?.findElements('item')
            .map((e) => e.text)
            .toList() ??
        [];

    section.fromKonwledgePoint = element
            .findElements('fromKonwledgePoint')
            .firstOrNull
            ?.findElements('item')
            .map((e) => e.text)
            .toList() ??
        [];

    // 解析视频
    section.videos = element
            .findElements('videos')
            .firstOrNull
            ?.findElements('video')
            .map((e) => e.text)
            .toList() ??
        [];

    // 解析题目
    section.questions = element
            .findElements('questions')
            .firstOrNull
            ?.findElements('question')
            .map((q) {
          final id = q.getAttribute('id') ?? const Uuid().v4();
          final questionMap = <String, dynamic>{'id': id};

          for (final child in q.childElements) {
            final key = child.name.local;
            if (key == 'options') {
              questionMap[key] =
                  child.findElements('option').map((opt) => {
                        'key': opt.getAttribute('key'),
                        'value': opt.text
                      }).toList();
            } else if (key == 'answer') {
              final items = child.findElements('item');
              if (items.isNotEmpty) {
                questionMap[key] = items.map((e) => e.text).toList();
              } else {
                questionMap[key] = child.text;
              }
            } else {
              questionMap[key] = child.text;
            }
          }
          return questionMap;
        }).toList() ??
        [];

    return section;
  }
}

// 擴展方法用於安全訪問元素
extension XmlElementExtensions on XmlElement {
  XmlElement? firstOrNull(String name) =>
      findElements(name).isEmpty ? null : findElements(name).first;
}

class QuestionBank {
  String filePath;
  List<Section>? data;
  String? displayName;
  int? version;
  String? id;
  String? cacheDir;

  static late String importedDirPath;
  static late String loadedDirPath;

  QuestionBank(this.filePath);

  Section findSectionByQuestion(SingleQuestionData q) {
    // 根据调试信息，结构层次是：
    // 顶层: 4.1, 4.2, 4.3, 4.4, 4.5, 4.6, 4.7, 4.8, 4.9, 4.10
    // 4.6 下: 4.6.1, 4.6.2, 4.6.3
    // 所以 "4.6.2" 应该直接作为完整路径 ["4.6.2"]
    List<String> knowledgePath = [];
    for (String index in q.fromKonwledgeIndex) {
      // 直接使用完整的索引，不进行拆分
      knowledgePath.add(index);
    }
    print('HighTree-Debug: Using direct path: $knowledgePath');
    return findSection(knowledgePath);
  }

  Section findSection(List<String> knowledgePath) {
    var currentSection = Section("", "");
    currentSection.children = data;

    // 定位目标章节
    for (final index in knowledgePath) {
      if(index.isEmpty) continue;
      try {
        currentSection =
            currentSection.children!.firstWhere((e) => e.index == index);
      } catch (e) {
        print('HighTree-Debug: Failed to find section with index: $index in path: $knowledgePath');
        print('HighTree-Debug: Available sections: ${currentSection.children?.map((e) => e.index).toList()}');
        
        // 尝试深度搜索：递归查找所有子节点
        Section? found = _findSectionRecursive(currentSection, index);
        if (found != null) {
          print('HighTree-Debug: Found section via recursive search: ${found.index}');
          return found;
        }
        
        throw Exception('Section not found: $index in path $knowledgePath');
      }
    }
    return currentSection;
  }
  
  Section? _findSectionRecursive(Section parent, String targetIndex) {
    // 在当前层级查找
    if (parent.children != null) {
      for (Section child in parent.children!) {
        if (child.index == targetIndex) {
          return child;
        }
        // 递归查找子节点
        Section? found = _findSectionRecursive(child, targetIndex);
        if (found != null) {
          return found;
        }
      }
    }
    return null;
  }

  Future<void> loadIntoData() async {
    mksureInit();
    
    if (cacheDir == null) throw Exception("cache dir not found");
    
    try {
      final fileExtension = path.extension(filePath).toLowerCase();
      
      if (fileExtension == '.zip') {
        // .zip文件是ZIP格式，但扩展名不被extractFileToDisk识别，手动解压
        final inputStream = InputFileStream(filePath);
        final archive = ZipDecoder().decodeStream(inputStream);
        
        try {
          for (final archiveFile in archive.files) {
            final outputPath = path.join(cacheDir!, archiveFile.name);
            
            if (archiveFile.isFile) {
              // 确保目录存在
              final outputDir = Directory(path.dirname(outputPath));
              if (!await outputDir.exists()) {
                await outputDir.create(recursive: true);
              }
              
              final outputStream = OutputFileStream(outputPath);
              try {
                archiveFile.writeContent(outputStream);
              } finally {
                await outputStream.close();
              }
            } else {
              await Directory(outputPath).create(recursive: true);
            }
          }
        } finally {
          await inputStream.close();
        }
      } else {
        // 对于标准压缩格式，使用extractFileToDisk
        await extractFileToDisk(filePath, cacheDir!);
      }
    } catch (e) {
      throw Exception("题库文件解压失败: $e");
    }
  }

  Future<void> removeFromData() async {
    mksureInit();
    print(path.join(cacheDir!, '$id.zip'));
    await _removeDirectoryIfExists(Directory(cacheDir!));
  }

  Future<QuestionBank> getQuestionBankInf() async {
    mksureInit();
    final iid = path.basenameWithoutExtension(filePath);
    final dir = path.join(QuestionBank.loadedDirPath, iid);

    try {
      // 优先从已解压目录读取
      if (Directory(dir).existsSync()) {
        final xmlFile = File(path.join(dir, "data.xml"));
        // print(xmlFile.path);
        if (!xmlFile.existsSync()) {
          throw Exception("在目录中未找到 data.xml 文件");
        }
        final xmlContent = await xmlFile.readAsString();
        return _parseQuestionBankXml(xmlContent);
      }

      // 从压缩包直接读取
      final fromFile = File(filePath);
      
      
      // 使用流式读取ZIP文件，不加载到内存
      final inputStream = InputFileStream(fromFile.path);
      final archive = ZipDecoder().decodeStream(inputStream);

      try {
        // 查找data.xml文件
        ArchiveFile? xmlEntry;
        for (final file in archive.files) {
          if (file.name == "data.xml") {
            xmlEntry = file;
            break;
          }
        }
        
        if (xmlEntry == null) {
          throw Exception("ZIP包中缺少 data.xml 文件");
        }
        
                 // 读取XML内容
         final xmlContent = utf8.decode(xmlEntry.readBytes() as List<int>);
        return _parseQuestionBankXml(xmlContent);
      } finally {
        inputStream.close();
      }
    } on XmlParserException catch (e) {
      throw Exception("XML解析失败: ${e.message}");
    } on FormatException catch (e) {
      throw Exception("文件格式错误: ${e.message}");
    }
  }

  QuestionBank _parseQuestionBankXml(String xmlString) {
    final xmlDoc = XmlDocument.parse(xmlString);
    final root = xmlDoc.rootElement;

    // 验证根元素
    if (root.name.local != 'QuestionBank') {
      throw FormatException("无效的根元素: ${root.name.local}");
    }

    // 解析元数据
    id = root.getAttribute('id') ?? const Uuid().v4();
    version = int.tryParse(root.getAttribute('version') ?? '0') ?? 0;
    displayName = root.getAttribute('displayName') ?? '未命名题库';

    // 解析章节数据
    final sectionsElement = root.findElements('Sections').firstOrNull;
    data = sectionsElement
            ?.findElements('Section')
            .map((e) => Section.fromXml(e))
            .toList() ??
        [];

    // 设置缓存路径
    cacheDir = path.join(QuestionBank.loadedDirPath, id);

    return this;
  }

  static deleteQuestionBank(String id) async {
    mksureInit();
    await _removeDirectoryIfExists(Directory(path.join(loadedDirPath, id)));
    await _removeFileIfExists(File(path.join(importedDirPath, "$id.zip")));
  }

  void close() {
    if (cacheDir != null) Directory(cacheDir!).delete();
  }

  static Future<void> clearAllCache() async {
    mksureInit();

    // 清理已解压文件
    final cacheDir = Directory(loadedDirPath);
    if (await cacheDir.exists()) {
      await cacheDir.delete(recursive: true);
      await cacheDir.create();
    }

    // 清理导入的题库文件
    final importedDir = Directory(importedDirPath);
    if (await importedDir.exists()) {
      await importedDir.delete(recursive: true);
      await importedDir.create();
    }
  }

  static Future<bool> _removeDirectoryIfExists(Directory file) async {
    if (await file.exists()) {
      await file.delete(recursive: true);
      return true;
    }
    return false;
  }

  static Future<bool> _removeFileIfExists(File file) async {
    if (await file.exists()) {
      await file.delete(recursive: true);
      return true;
    }
    return false;
  }

  SingleQuestionData randomChoiceQuestion({Section? sec}) {
    mksureInit();
    SingleQuestionData? q;
    while (q == null) {
      if (sec == null) {
        q = data![Random().nextInt(data!.length)]
            .randomSectionQuestion(id!, displayName!);
      } else {
        q = sec.randomSectionQuestion(id!, displayName!);
      }
    }
    return q;
  }

  List<SingleQuestionData> sectionQuestion() {
    mksureInit();
    List<SingleQuestionData> qList = [];
    for (var sec in data!) {
      qList.addAll(sec.sectionQuestion(id!, displayName!));
    }
    return qList;
  }

  static Future<void> importQuestionBank(
      File file, {Function(double)? onProgress}) async {
    mksureInit();
    if (!file.existsSync()) {
      throw Exception("文件不存在");
    }

    final receivePort = ReceivePort();
    final completer = Completer<void>();

    try {
      // 在主 Isolate 中获取路径
      final tempPath = (await getTemporaryDirectory()).path;
      final importedPath = QuestionBank.importedDirPath;

      final isolate = await Isolate.spawn(
        _importQuestionBankIsolate,
        _IsolateData(file.path, receivePort.sendPort, tempPath, importedPath),
      );

      receivePort.listen((message) {
        if (message is double) {
          onProgress?.call(message);
        } else if (message is String && message.startsWith('log:')) {
          if (kDebugMode) {
            print(message.substring(4));
          }
        } else if (message is String && message.startsWith('error:')) {
          var errorMsg = message.substring(6);
          if (errorMsg.startsWith('Exception: ')) {
            errorMsg = errorMsg.substring('Exception: '.length);
          }
          completer.completeError(Exception(errorMsg));
          receivePort.close();
          isolate.kill();
        } else if (message == 'done') {
          completer.complete();
          receivePort.close();
          isolate.kill();
        }
      });
    } catch (e) {
      completer.completeError(e);
    }

    return completer.future;
  }

  static Future<void> _importQuestionBankIsolate(_IsolateData data) async {
    final sendPort = data.sendPort;
    final filePath = data.filePath;
    final tempPath = data.tempPath;
    final importedPath = data.importedPath;
    final file = File(filePath);

    try {
      sendPort.send('log: Isolate started for $filePath');
      sendPort.send(0.0);
      final tempDir =
          Directory(path.join(tempPath, 'zip_import_${const Uuid().v4()}'));

      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
      await tempDir.create(recursive: true);
      sendPort.send('log: Temp directory created at ${tempDir.path}');

      sendPort.send(0.1);

      sendPort.send('log: Extracting archive...');
    try {
        // 检查文件是否存在和可读
        if (!await file.exists()) {
          throw Exception('Archive file does not exist: ${file.path}');
        }
        
        final fileSize = await file.length();
        sendPort.send('log: Archive file size: $fileSize bytes');
        
        // 使用archive_io的便利函数来处理大文件
        sendPort.send('log: Attempting to extract ${file.path} to ${tempDir.path}');
        await extractFileToDisk(file.path, tempDir.path);
        sendPort.send('log: Archive extracted successfully using extractFileToDisk');
        
        // 立即检查解压结果
        final extractedItems = await tempDir.list(recursive: true).toList();
        sendPort.send('log: Immediately after extraction, found ${extractedItems.length} items');
        for (final item in extractedItems) {
          sendPort.send('log: - ${item.path} (${item is File ? 'File' : 'Directory'})');
        }
      } catch (e) {
        sendPort.send('log: Error extracting archive: $e');
        sendPort.send({'error': 'Error extracting archive: $e'});
        return;
      }

      final items = await tempDir.list(recursive: true).toList();
      sendPort.send('log: Found ${items.length} items in temp directory:');
      for (final item in items) {
        sendPort.send('log:  - ${item.path}');
      }

      final filteredItems = items
          .where((entity) => entity is File && path.basename(entity.path) == 'data.xml')
          .firstOrNull;

      if (filteredItems == null) {
        throw Exception("题库压缩包中缺少 data.xml 文件");
      }
      final xmlFile = filteredItems as File;
      sendPort.send(0.6);

      String id;
      try {
        sendPort.send('log: Parsing data.xml');
        final xmlContent = await xmlFile.readAsString();
        final xmlDoc = XmlDocument.parse(xmlContent);
      final rootElement = xmlDoc.rootElement;

      if (rootElement.name.local != 'QuestionBank') {
        throw Exception("无效的 XML 根元素");
      }
        id = rootElement.getAttribute('id') ?? '';
        if (id.isEmpty) {
        throw Exception("XML 文件缺少有效的 ID 属性");
      }
        sendPort.send('log: Parsed id: $id');
      } catch (e) {
        throw Exception("XML 文件解析或验证失败: $e");
      }
      sendPort.send(0.8);

      final newPath = path.join(importedPath, "$id.zip");
      sendPort.send('log: Copying file to $newPath');
      await file.copy(newPath);
      sendPort.send('log: File copied.');

      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
        sendPort.send('log: Temp directory deleted.');
      }

      sendPort.send(1.0);
      sendPort.send('done');
    } catch (e) {
      sendPort.send('error:${e.toString()}');
    }
  }

  static Future<List<QuestionBank>> getAllImportedQuestionBanks() async {
    mksureInit();
    var dir = Directory(QuestionBank.importedDirPath);
    if (!dir.existsSync()) {
      return [];
    }
    final List<QuestionBank> res = [];
    for (var action in List.from(dir
        .listSync()
        .where((element) => element.path.endsWith(".zip"))
        .map((e) => (e.path)))) {
      res.add(await QuestionBank(action).getQuestionBankInf());
    }
    return res;
  }

  static List<QuestionBank> getAllImportedQuestionBanksWithId() {
    mksureInit();
    var dir = Directory(QuestionBank.importedDirPath);
    if (!dir.existsSync()) {
      return [];
    }
    final List<QuestionBank> res = [];
    for (var action in List.from(dir
        .listSync()
        .where((element) => element.path.endsWith(".zip"))
        .map((e) => (e.path)))) {
      res.add(QuestionBank(action)..id = path.basenameWithoutExtension(action));
    }
    return res;
  }

  static Future<List<QuestionBank>> getAllLoadedQuestionBanks() async {
    mksureInit();
    List<QuestionBank> q = [];
    for (var action in getAllLoadedQuestionBankIds()) {
      q.add(await (await QuestionBank.getQuestionBankById(action))
          .getQuestionBankInf());
    }
    return q;
  }

  static List<String> getAllLoadedQuestionBankIds() {
    mksureInit();
    var dir = Directory(QuestionBank.loadedDirPath);
    if (!dir.existsSync()) {
      return [];
    }

    return List.from(dir.listSync().map((e) => (path.basename(e.path))));
  }

  bool isLoaded() {
    return Directory(path.join(QuestionBank.loadedDirPath, id)).existsSync();
  }

  static Future<QuestionBank> getQuestionBankById(String id) async {
    mksureInit();
    var p = path.join(QuestionBank.importedDirPath, '$id.zip');
    var q = QuestionBank(p);
    await q.getQuestionBankInf();
    return q;
  }

  static init() async {
    mksureInit();
    QuestionBank.importedDirPath = path.join(
        (await getApplicationSupportDirectory()).path, "questionBank");
    QuestionBank.loadedDirPath = path.join(
        (await getApplicationCacheDirectory()).path, "questionBankLoaded");
    await Directory(QuestionBank.importedDirPath).create();
    await Directory(QuestionBank.loadedDirPath).create();
    // await clean();
  }
}

class QuestionBankBuilder {
  static late String cacheDir;
  String id;
  List<Section> data;
  String displayName;
  int version;
  Archive archive = Archive();

  static init() async {
    QuestionBankBuilder.cacheDir = path.join(
        (await getApplicationCacheDirectory()).path, "questionBankBuilder");
    mksureInit();
  }

  QuestionBankBuilder(
      {List<Section>? data,
      String? id,
      required this.displayName,
      required this.version})
      : data = data ?? <Section>[],
        id = id ?? const Uuid().v4();
  Map<String, dynamic> getDataFileJson() {
    return {
      'displayName': displayName,
      'data': ((Section("", "")..children = data).toTrimJson())['children'],
      'id': id,
      'version': version
    };
  }

  // 將整個數據結構轉換為 XML 文檔
  XmlDocument buildDataFileXml() {
    final root = XmlElement(XmlName('QuestionBank'));

    // 添加元數據屬性
    root.attributes.addAll([
      XmlAttribute(XmlName('id'), id),
      XmlAttribute(XmlName('version'), version.toString()),
      XmlAttribute(XmlName('displayName'), displayName)
    ]);

    // 構建章節數據樹
    final dataElement = XmlElement(XmlName('Sections'));
    dataElement.children.addAll(data.map((section) => section.toXml()));

    root.children.add(dataElement);
    return XmlDocument([root]);
  }

  // 生成 XML 字符串的快捷方法
  String toXmlString({bool pretty = false}) {
    return buildDataFileXml().toXmlString(pretty: pretty);
  }


  void addImageFile(Uint8List contents, String name) {
    ArchiveFile archiveFile = ArchiveFile(
        //rId1.png
        'assets/images/$name',
        contents.length,
        contents);
    archive.addFile(archiveFile);
  }

  Future<void> addNeedImageForBuilder() async {
    // 图片引用格式已废除，此方法暂时保留但不执行任何操作
  }
  void addQuestionByOld(SingleQuestionData oldQuestion) {
    oldQuestion = oldQuestion.clone();
    var quedtionBankName = oldQuestion.fromDisplayName;

    //根据Section和index新建对应层级
    Section current = data.firstWhere(
      (e) => e.title == quedtionBankName,
      orElse: () {
        var target = Section('错题集${data.length}', quedtionBankName);
        data.add(target);
        return target;
      },
    );

    while (oldQuestion.fromKonwledgePoint.isNotEmpty) {
      var targetIndex = oldQuestion.fromKonwledgeIndex.removeAt(0);
      var targetTitle = oldQuestion.fromKonwledgePoint.removeAt(0);
      current.children ??= [];
      current = current.children!.firstWhere(
        (e) => e.index == targetIndex,
        orElse: () {
          var target = Section(targetIndex, targetTitle);
          current.children!.add(target);
          return target;
        },
      );
    }
    current.questions ??= [];
    current.questions!.add(oldQuestion.question);
  }



  void addTestFile(String textTester) {
    final jsonContentTester = utf8.encode(textTester);
    archive.addFile(
        ArchiveFile('data.txt', jsonContentTester.length, jsonContentTester));
  }

  Future<void> build(String outputPath) async {
    File saveFile = File(outputPath);
    try {
      // final jsonContent = utf8.encode(getDataFileContent());
      // archive
      //     .addFile(ArchiveFile('data.json', jsonContent.length, jsonContent));
      final xmlContent = utf8.encode(toXmlString());
      archive.addFile(ArchiveFile('data.xml', xmlContent.length, xmlContent));
    } catch (e) {
      print(e);
    }
    List<int>? outputData = ZipEncoder().encode(archive);
    if (outputData == null) {
      return;
    }
    saveFile.writeAsBytesSync(outputData);

    print('Saved to ${saveFile.path}');
  }
}

class _IsolateData {
  final String filePath;
  final SendPort sendPort;
  final String tempPath;
  final String importedPath;

  _IsolateData(this.filePath, this.sendPort, this.tempPath, this.importedPath);
}
