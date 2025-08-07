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
    if (onlyLayer) {
      if (questions == null || questions!.isEmpty) return null;
      var selectedQuestion = questions![_random!.nextInt(questions!.length)];
      return SingleQuestionData(selectedQuestion, fromId, fromName)
        ..fromKonwledgeIndex = (List.from(fromKonwledgeIndex)..add(index))
        ..fromKonwledgePoint = (List.from(fromKonwledgePoint)..add(title));
    }

    int currentQ = questions?.length ?? 0;
    List<int> childQs = [];
    int childTotal = 0;

    if (children != null) {
      for (var child in children!) {
        int total = child.getTotalQuestions();
        childQs.add(total);
        childTotal += total;
      }
    }

    int total = currentQ + childTotal;
    if (total == 0) return null;

    int rand = _random!.nextInt(total);
    if (rand < currentQ) {
      if (questions == null || questions!.isEmpty) return null;
      var selectedQuestion = questions![_random!.nextInt(questions!.length)];
      return SingleQuestionData(selectedQuestion, fromId, fromName)
        ..fromKonwledgeIndex = (List.from(fromKonwledgeIndex)..add(index))
        ..fromKonwledgePoint = (List.from(fromKonwledgePoint)..add(title));
    } else {
      if (children == null || children!.isEmpty) return null;
      int target = rand - currentQ;
      int accumulated = 0;
      for (int i = 0; i < children!.length; i++) {
        accumulated += childQs[i];
        if (target < accumulated) {
          return children![i]
              .randomSectionQuestion(fromId, fromName, onlyLayer: false);
        }
      }
    }
    return null;
  }

// 添加方法以递归获取题目总数
  int getTotalQuestions({bool onlyLayer = false}) {
    int total = questions?.length ?? 0;
    if (!onlyLayer) {
      for (Section child in (children ?? [])) {
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
    questionsList.addAll(sectionQuestionOnly(fromId, fromName));
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
    // ignore: unnecessary_null_comparison
    if (questions != null) {
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
    return findSection(q.fromKonwledgeIndex);
  }

  Section findSection(List<String> knowledgePath) {
    var currentSection = Section("", "");
    currentSection.children = data;

    // 定位目标章节
    for (final index in knowledgePath) {
      if(index.isEmpty) continue;
      currentSection =
          currentSection.children!.firstWhere((e) => e.index == index);
    }
    return currentSection;
  }

  Future<void> loadIntoData() async {
    mksureInit();
    
    if (cacheDir == null) throw Exception("cache dir not found");
    
    try {
      // 使用 archive_io 直接解压到目标目录，内存效率更高
      await extractFileToDisk(filePath, cacheDir!);
    } catch (e) {
      throw Exception("题库文件解压失败: $e");
      }
  }

  Future<void> removeFromData() async {
    mksureInit();
    print(path.join(cacheDir!, '$id.qset'));
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
      
      // 检查文件大小
      final fileSize = await fromFile.length();
      if (fileSize > 500 * 1024 * 1024) { // 500MB 限制
        throw Exception("题库文件过大 (${(fileSize / 1024 / 1024).toStringAsFixed(1)}MB)，无法读取信息");
      }
      
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
    await _removeFileIfExists(File(path.join(importedDirPath, "$id.qset")));
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
          Directory(path.join(tempPath, 'qset_import_${const Uuid().v4()}'));

      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
      await tempDir.create(recursive: true);
      sendPort.send('log: Temp directory created at ${tempDir.path}');

      sendPort.send(0.1);

      sendPort.send('log: Extracting archive...');
      try {
        final bytes = await file.readAsBytes();
        final archive = ZipDecoder().decodeBytes(bytes);

        if (archive.files.isEmpty) {
          sendPort.send('log: Archive is empty or could not be read.');
        } else {
          sendPort.send('log: Archive contains ${archive.numberOfFiles()} files.');
          for (final file in archive.files) {
            final filename = file.name;
            final outputPath = path.join(tempDir.path, filename);
            sendPort.send('log:  - Extracting ${file.name}');
            if (file.isFile) {
              final outputStream = OutputFileStream(outputPath);
              file.writeContent(outputStream);
              outputStream.close();
            } else {
              await Directory(outputPath).create(recursive: true);
            }
          }
        }
        sendPort.send('log: Archive extracted successfully.');
      } catch (e) {
        sendPort.send('log: Error extracting archive: $e');
        // 可以在这里发送一个错误消息回主线程
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

      final newPath = path.join(importedPath, "$id.qset");
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
        .where((element) => element.path.endsWith(".qset"))
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
        .where((element) => element.path.endsWith(".qset"))
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
    var p = path.join(QuestionBank.importedDirPath, '$id.qset');
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

  int imageIndex = 0;
  void addImageFile(Uint8List contents, String name) {
    ArchiveFile archiveFile = ArchiveFile(
        //rId1.png
        'assets/images/$name',
        contents.length,
        contents);
    archive.addFile(archiveFile);
  }

  Future<void> addNeedImageForBuilder() async {
    for (var bank in QuestionBank.getAllImportedQuestionBanksWithId()) {
      var achieve =
          ZipDecoder().decodeBytes(await File(bank.filePath).readAsBytes());
      for (var aFile in achieve) {
        if (aFile.isFile && aFile.name.startsWith("assets/images/")) {
          var key = '${bank.id}/${path.basename(aFile.name)}';
          if (customMap.containsKey(key)) {
            addImageByOld(aFile.content, customMap[key]!);
          }
        }
      }
    }
  }

  var customMap = <String, int>{};
  void addQuestionByOld(SingleQuestionData oldQuestion) {
    oldQuestion = oldQuestion.clone();
    var imgMatcher = RegExp(
        r'\[image:[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}:(rId[0-9]*.png)\]');
    void handleKey(String key) {
      if (oldQuestion.question[key] == null) return;
      for (var m in imgMatcher.allMatches(oldQuestion.question[key]!)) {
        String imgName = m.group(1)!;
        if (!customMap.containsKey('${oldQuestion.fromId}/$imgName')) {
          customMap['${oldQuestion.fromId}/$imgName'] = imageIndex;
          imageIndex++;
        }
        oldQuestion.question[key] = oldQuestion.question[key]!.replaceAll(
            imgMatcher,
            '[image:$id:rId${customMap['${oldQuestion.fromId}/$imgName']!}.png]');
      }
    }

    handleKey('q');
    handleKey('w');
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

  void addImageByOld(Uint8List contents, int index) {
    ArchiveFile archiveFile = ArchiveFile(
        //rId1.png
        'assets/images/rId$index.png',
        contents.length,
        contents);
    archive.addFile(archiveFile);
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
