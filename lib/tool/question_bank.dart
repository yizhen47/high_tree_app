import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:flutter_application_1/tool/question_bank.dart';
import 'package:flutter_application_1/widget/question_text.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:xml/xml.dart' as xml;
import 'dart:convert';
import './wmf2png.dart';
import 'package:xml/xml.dart';
import 'package:path/path.dart' as path;
import 'package:json_annotation/json_annotation.dart';

part 'question_bank.g.dart';

ZipDecoder? _zipDecoder;
ZipEncoder? _zipEncoder;
Wmf2Png? _wmf2png;
Random? _random;

void mksureInit() {
  _zipDecoder ??= ZipDecoder();
  _zipEncoder ??= ZipEncoder();
  _wmf2png ??= Wmf2Png();
  _random ??= Random();
}

@JsonSerializable()
class SingleQuestionData {
  List<String> fromKonwledgePoint = [];
  List<String> fromKonwledgeIndex = [];
  Map<String, String> question;
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
    return SingleQuestionData(Map.from(question), fromId, fromDisplayName)
      ..fromKonwledgeIndex = List.from(fromKonwledgeIndex)
      ..fromKonwledgePoint = List.from(fromKonwledgePoint);
  }

  XmlElement toXml() {
    return XmlElement(XmlName('SingleQuestionData'), [
      XmlAttribute(XmlName('fromId'), fromId),
      XmlAttribute(XmlName('fromDisplayName'), fromDisplayName),
    ], [
      XmlElement(
          XmlName('fromKonwledgePoint'),
          [],
          fromKonwledgePoint
              .map((point) => XmlElement(XmlName('item'), [], [XmlText(point)]))
              .toList()),
      XmlElement(
          XmlName('fromKonwledgeIndex'),
          [],
          fromKonwledgeIndex
              .map((index) => XmlElement(XmlName('item'), [], [XmlText(index)]))
              .toList()),
      XmlElement(
          XmlName('question'),
          [],
          question.entries
              .map((entry) =>
                  XmlElement(XmlName(entry.key), [], [XmlText(entry.value)]))
              .toList())
    ]);
  }

  // SingleQuestionData 的反序列化
  factory SingleQuestionData.fromXml(XmlElement element) {
    final fromId = element.getAttribute('fromId') ?? '';
    final fromDisplayName = element.getAttribute('fromDisplayName') ?? '';

    final knowledgePoint = element
        .findElements('fromKonwledgePoint')
        .first
        .findElements('item')
        .map((e) => e.text)
        .toList();

    final knowledgeIndex = element
        .findElements('fromKonwledgeIndex')
        .first
        .findElements('item')
        .map((e) => e.text)
        .toList();

    final questionMap = element
        .findElements('question')
        .first
        .childElements
        .fold<Map<String, String>>({}, (map, element) {
      map[element.name.local] = element.text;
      return map;
    });

    return SingleQuestionData(
      questionMap,
      fromId,
      fromDisplayName,
    );
  }
}

@JsonSerializable()
class Section {
  String index;
  String title;
  String? note;
  List<Section>? children;
  List<Map<String, String>>? questions;

  List<String> fromKonwledgePoint = [];
  List<String> fromKonwledgeIndex = [];

  String get id => fromKonwledgeIndex.join('/') + '/' + index;

  factory Section.fromJson(Map<String, dynamic> json) =>
      _$SectionFromJson(json);

  Map<String, dynamic> toJson() => _$SectionToJson(this);

  Section(this.index, this.title)
      : children = [],
        questions = [],
        note = '';

  Map<String, dynamic> toTrimJson() {
    return {
      'index': index,
      'title': title,
      'children': children!.map((child) => child.toTrimJson()).toList(),
      'note': note!.isNotEmpty ? note!.trim() : null,
      'fromKonwledgePoint': fromKonwledgePoint,
      'fromKonwledgeIndex': fromKonwledgeIndex,
      'questions': questions!.isNotEmpty
          ? questions!
              .map((q) => {
                    'q': q['q']?.trim(),
                    'w': q['w']?.trim(),
                    'id': q['id'] ?? const Uuid().v4(),
                    if (q['note'] != null) 'note': q['note']?.trim()
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
      if (children != null && children!.isNotEmpty)
        XmlElement(XmlName('children'), [],
            children!.map((child) => child.toXml()).toList()),
      if (fromKonwledgeIndex != null && fromKonwledgeIndex!.isNotEmpty)
        XmlElement(
            XmlName('fromKonwledgeIndex'),
            [],
            fromKonwledgeIndex!
                .map((index) =>
                    XmlElement(XmlName('item'), [], [XmlText(index)]))
                .toList()),
      if (fromKonwledgePoint != null && fromKonwledgePoint!.isNotEmpty)
        XmlElement(
            XmlName('fromKonwledgePoint'),
            [],
            fromKonwledgePoint!
                .map((point) =>
                    XmlElement(XmlName('item'), [], [XmlText(point)]))
                .toList()),
      if (questions != null && questions!.isNotEmpty)
        XmlElement(
            XmlName('questions'),
            [],
            questions!.map((q) {
              final id = q['id'] ?? const Uuid().v4();
              return XmlElement(
                  XmlName('question'),
                  [XmlAttribute(XmlName('id'), id)],
                  q.entries
                      .where((e) => e.key != 'id')
                      .map((entry) => XmlElement(
                          XmlName(entry.key), [], [XmlText(entry.value ?? '')]))
                      .toList());
            }).toList())
    ]);
  }

  factory Section.fromXml(XmlElement element) {
    final index = element.getAttribute('index') ?? '';
    final title = element.getAttribute('title') ?? '';
    final section = Section(index, title);

    // 解析备注
    section.note = element.findElements('note').firstOrNull?.text;

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

    // 解析题目
    section.questions = element
            .findElements('questions')
            .firstOrNull
            ?.findElements('question')
            .map((q) {
          final id = q.getAttribute('id') ?? const Uuid().v4();
          return {
            'id': id,
            ...q.childElements.fold<Map<String, String>>(
                {}, (map, e) => map..[e.name.local] = e.text)
          };
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

Future<void> generateByMd(File fromFile, File saveFile) async {
  mksureInit();
  var id = const Uuid().v4();
  var text = await fromFile.readAsString();
  var builder = QuestionBankBuilder.parseWordToJSONData(
      text, path.basename(fromFile.path.split('/').first), id);

  List<Future> futures = [];

  await Future.wait(futures);
  _wmf2png!.cleanup();
  builder.addTestFile(text);
  builder.build(saveFile.path);
}

Future<void> generateByDocx(File fromFile, File saveFile) async {
  mksureInit();
  var id = const Uuid().v4();
  final bytes = await fromFile.readAsBytes();

  final archiveDecoder = _zipDecoder!.decodeBytes(bytes);

  final List<String> list = [];

  // Find relationships for images
  Map<String, String> imageRels = {};
  for (final file in archiveDecoder) {
    if (file.isFile) {
      if (file.name == 'word/_rels/document.xml.rels') {
        final fileContent = utf8.decode(file.content);
        final document = xml.XmlDocument.parse(fileContent);
        document.findAllElements('Relationship').forEach((rel) {
          if (rel.getAttribute('Type') ==
              'http://schemas.openxmlformats.org/officeDocument/2006/relationships/image') {
            imageRels["word/${rel.getAttribute('Target')!}"] =
                rel.getAttribute('Id')!;
          }
        });
      }
    }
  }

  for (final file in archiveDecoder) {
    if (file.isFile && file.name == 'word/document.xml') {
      final fileContent = utf8.decode(file.content);
      final document = xml.XmlDocument.parse(fileContent);
      String parseRender(XmlElement render) {
        var texts = [];
        for (final atti in render.childElements) {
          switch (atti.name.local) {
            case 't':
              texts.add(atti.innerText);
              break;
            case 'pict':
              for (final shape in atti.findElements("v:shape")) {
                for (final data in shape.childElements) {
                  if (data.name.local == "imagedata") {
                    final imageId = data.getAttribute("r:id");
                    // final imagePath = imageRels[imageId];
                    texts.add('[image:$id:$imageId.png]');
                  }
                }
              }
              break;
            case 'drawing':
              for (final typeUsed in atti.childElements) {
                if (typeUsed.name.local == "inline") {
                  for (final blip in typeUsed.findAllElements("a:blip")) {
                    final imageId = blip.getAttribute("r:embed");
                    texts.add('[image:$id:$imageId.png]');
                  }
                }
              }
              break;
          }
        }
        return texts.join('').trim();
      }

      String parsePara(XmlElement paragraph) {
        var texts = [];
        for (final element in paragraph.childElements) {
          switch (element.name.local) {
            case "r":
              texts.add(parseRender(element));
              break;
            case "smartTag":
              for (final render in element.findElements("w:r")) {
                texts.add(parseRender(render));
              }
              break;
            default:
              break;
          }
        }
        return texts.join().trim();
      }

      final bodies = document.findAllElements('w:body');
      for (final body in bodies) {
        for (final paragraph in body.childElements) {
          switch (paragraph.name.local) {
            case "p":
              var res = parsePara(paragraph);
              if (res != "") {
                list.add(res);
              }
              break;
            default:
              break;
          }
        }
      }
    }
  }

  var builder = QuestionBankBuilder.parseWordToJSONData(
      list.join('\n'), path.basename(fromFile.path.split('/').first), id);

  List<Future> futures = [];
  for (final file in archiveDecoder) {
    if (file.isFile) {
      if (file.name.startsWith("word/media/")) {
        futures.add((() async {
          final contents = await _wmf2png!.convert(file.content, dpi: 300);
          print(file.name);
          builder.addImageFile(contents, '${imageRels[(file.name)]}.png');
        })());
      }
    }
  }

  await Future.wait(futures);
  _wmf2png!.cleanup();
  builder.addTestFile(list.join('\n'));
  builder.build(saveFile.path);
}

// Dummy function to convert math XML to LaTeX
String mathToLatex(xml.XmlElement mathElement) {
  // Implement actual conversion logic here
  return '[LaTeX representation]';
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
      currentSection =
          currentSection.children!.firstWhere((e) => e.index == index);
    }
    return currentSection;
  }

  Future<void> loadIntoData() async {
    mksureInit();
    var achieve = _zipDecoder!.decodeBytes(await File(filePath).readAsBytes());
    if (cacheDir == null) throw Exception("cache dir not found");
    List<Future> waitList = [];
    for (final file in achieve) {
      Directory(path.dirname(path.join(cacheDir!, file.name)))
          .createSync(recursive: true);
      if (file.isFile) {
        waitList.add(
            File(path.join(cacheDir!, file.name)).writeAsBytes(file.content));
      }
    }
    await Future.wait(waitList);
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
      final archive = _zipDecoder!.decodeBytes(await fromFile.readAsBytes());

      final xmlEntry = archive.files.firstWhere(
          (file) => file.name == "data.xml",
          orElse: () => throw Exception("ZIP包中缺少 data.xml 文件"));

      return _parseQuestionBankXml(utf8.decode(xmlEntry.content));
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

  static Future<void> importQuestionBank(File file) async {
    mksureInit();

    if (!file.existsSync()) {
      throw Exception("文件不存在");
    }

    final archive = _zipDecoder!.decodeBytes(await file.readAsBytes());
    String? id;

    try {
      // 在 ZIP 中查找 XML 数据文件
      final xmlEntry = archive.files.firstWhere((f) => f.name == "data.xml",
          orElse: () => throw Exception("ZIP 包中缺少 data.xml 文件"));

      // 解析 XML 内容
      final xmlDoc = XmlDocument.parse(utf8.decode(xmlEntry.content));
      final rootElement = xmlDoc.rootElement;

      // 验证根元素并获取 ID
      if (rootElement.name.local != 'QuestionBank') {
        throw Exception("无效的 XML 根元素");
      }

      id = rootElement.getAttribute('id');
      if (id == null || id.isEmpty) {
        throw Exception("XML 文件缺少有效的 ID 属性");
      }

      // 验证版本号
      final version = rootElement.getAttribute('version');
      if (version == null || int.tryParse(version) == null) {
        throw Exception("无效的版本号格式");
      }
    } on XmlParserException catch (e) {
      throw Exception("XML 解析失败: ${e.message}");
    } on FormatException catch (e) {
      throw Exception("文件格式错误: ${e.message}");
    }
    // 保存到题库目录
    final npath = path.join(QuestionBank.importedDirPath, "$id.qset");
    await file.copy(npath);
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

    setCurMathImgPath(QuestionBank.loadedDirPath);
    // await clean();
  }

  static create(String path, String outputFile) async {
    if (path.endsWith('.md')) {
      await generateByMd(File(path), File(outputFile));
    } else if (path.endsWith('.docx')) {
      await generateByDocx(File(path), File(outputFile));
    }
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
          _zipDecoder!.decodeBytes(await File(bank.filePath).readAsBytes());
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
    List<int>? outputData = _zipEncoder!.encode(archive);
    if (outputData == null) {
      return;
    }
    saveFile.writeAsBytesSync(outputData);

    print('Saved to ${saveFile.path}');
  }

  static QuestionBankBuilder parseWordToJSONData(
      String text, String title, String id) {
    var lines = text.trim().split('\n');
    var root = Section('', '');
    var stack = [root];
    bool inExercises = false;
    bool inSummerize = false;
    var inState = 0;

    void appendQuestionOrAnswer(
        Map<String, String> qa, String key, String content) {
      if (!qa.containsKey(key) || qa[key] == null) {
        qa[key] = '';
      }
      qa[key] = '${qa[key]}$content\n';
    }

    var matchf = RegExp(r'^[0-9]+ *[\.|．|、] *(?![0-9 ])');

    var line = '';

    var lineIndex = -1;

    lines = lines
        .map((e) => e.trim())
        .toList()
        .where(
          (element) => element.isNotEmpty,
        )
        .toList();

    List<String> processStringArray(List<String> input) {
      final List<String> result = [];

      for (final element in input) {
        if (element.isEmpty) {
          // 当遇到空字符串且存在前驱非空元素时
          if (result.isNotEmpty) {
            // 给最后一个元素追加换行符
            result[result.length - 1] += '\n';
          }
          // 没有前驱元素时直接忽略空字符串
        } else {
          // 非空元素直接保留
          result.add(element);
        }
      }

      return result;
    }

    lines = processStringArray(lines);
    getNextLine() {
      if (lineIndex + 1 >= lines.length) return '-1';
      return lines[lineIndex + 1];
    }

    getPrevLine() {
      if (lineIndex - 1 < 0) return '-1';
      return lines[lineIndex - 1];
    }

    String nextLine() {
      lineIndex++;
      if (lineIndex >= lines.length) return '-1';
      return lines[lineIndex];
    }

    String getLine() {
      return lines[lineIndex];
    }

    ;

    while (getNextLine() != '-1') {
      line = nextLine();
      while (getNextLine() == ('\$\$')) {
        line += "\n" + nextLine();
        nextLine();
        while (getLine() != ('\$\$')) {
          line += '\n' + getLine();
          nextLine();
        }
        line += '\n' + getLine();
      }
      // print(line);

      // Handle examples and exercise questions only when inside exercises section
      if (RegExp(r'[一二三四五六七八九]+、.*题').hasMatch(line) && inExercises) continue;

      if ((line.startsWith('例') || (inExercises && matchf.hasMatch(line)))) {
        stack.last.questions!.add({'q': '', 'w': ''});
        inState = 1;
        if (!inExercises && line.startsWith('例')) {
          appendQuestionOrAnswer(
              stack.last.questions!.last, 'q', line.substring(2).trim());
        } else if (inExercises) {
          // Inside exercises section, treat numbered lines as questions
          var q = line.substring(matchf.firstMatch(line)?.end ?? 0 + 1).trim();
          if (q.startsWith('.') || q.startsWith('．')) {
            q = q.substring(1).trim();
          }
          appendQuestionOrAnswer(stack.last.questions!.last, 'q', q);
        }
      } else if (line.startsWith('解')) {
        // Handle solutions
        inState = 2;
        if (stack.last.questions!.isNotEmpty) {
          appendQuestionOrAnswer(
              stack.last.questions!.last, 'w', line.substring(1).trim());
        }
      } else if (line.startsWith('习题')) {
        // Start of exercises section
        inExercises = true;
        // Ensure exercises are added to the correct parent section
        // Extract the section number from "习题" line, e.g., "习题 1.1"
        var match = RegExp(r'^习题 *([0-9]+ *(\.[0-9]+)*)').firstMatch(line);
        if (match != null) {
          var targetIndex = match.group(1)!.replaceAll(' ', '');
          // Pop the stack until we find the correct parent section or reach the root
          while (stack.length > 1 && stack.last.index != (targetIndex)) {
            stack.removeLast();
          }
        }
      } else {
        // Parse sections and subsections or add to the current section's note
        // Match top-level chapters like "第一章"
        var matchTop = RegExp(r'^(第[一二三四五六七八九]+章) *(.+)$').firstMatch(line);
        var matchSub =
            RegExp(r'^([0-9]+ *(?:\. *[0-9]+)*) *．?(.+)$').firstMatch(line);
        var matchNum = RegExp(r'^([0-9]+)$');
        if (line.startsWith("本章内容小结")) {
          inExercises = false;
          inSummerize = true;
          inState = 0;
          while (stack.length > 1 &&
              !RegExp(r'^第[一二三四五六七八九]+章$').hasMatch(stack.last.index)) {
            stack.removeLast();
          }
        } else if (RegExp(r'^(复习题[一二三四五六七八九]+)$').hasMatch(line)) {
          inExercises = true;
          inSummerize = false;
          inState = 0;
          while (stack.length > 1 &&
              !RegExp(r'^第[一二三四五六七八九]+章$').hasMatch(stack.last.index)) {
            stack.removeLast();
          }
        } else if (matchTop != null) {
          // Top-level chapter found
          var newIndex = matchTop.group(1)!.replaceAll(' ', '');
          var newTitle = matchTop.group(2)!.replaceAll(' ', '');

          // Reset exercise flag when a new chapter starts
          inExercises = false;
          inSummerize = false;
          inState = 0;
          var newSection = Section(newIndex, newTitle);
          while (stack.length > 1) {
            stack.removeLast();
          }
          stack.last.children!.add(newSection);
          stack.add(newSection);
        } else if (inSummerize) {
          stack.last.note = '${stack.last.note!}$line\n';
        } else if (matchSub != null) {
          // Reset exercise flag when a new section starts
          inExercises = false;
          inState = 0;
          var newIndex = matchSub.group(1)!.replaceAll(' ', '');
          var newTitle = matchSub.group(2)!.replaceAll(' ', '');

          if (newTitle.startsWith(".") || newTitle.startsWith("．")) {
            newTitle = newTitle.substring(1);
          }

          // Find the correct parent section based on newIndex
          while (stack.length > 2 &&
              (!newIndex.startsWith(stack.last.index) &&
                      !matchNum.hasMatch(newIndex) ||
                  (matchNum.hasMatch(newIndex) &&
                      matchNum.hasMatch(stack.last.index)) ||
                  (!matchNum.hasMatch(newIndex) &&
                      matchNum.hasMatch(stack.last.index)))) {
            stack.removeLast();
          }

          var newSection = Section(newIndex, newTitle);
          stack.last.children!.add(newSection);
          stack.add(newSection);
        } else {
          if (inState == 1) {
            appendQuestionOrAnswer(stack.last.questions!.last, 'q', line);
          } else if (inState == 2) {
            appendQuestionOrAnswer(stack.last.questions!.last, 'w', line);
          } else {
            stack.last.note = '${stack.last.note!}$line\n';
          }
        }
      }
    }

    //遍历加入路径
    handleSection(List<String> fromKnowledgePoint, List<String> fromIndexPoint,
        List<Section> secs) {
      for (var sec in secs) {
        sec.fromKonwledgePoint = fromKnowledgePoint;
        sec.fromKonwledgeIndex = fromIndexPoint;
        if (sec.children != null && sec.children!.isNotEmpty) {
          handleSection([...fromKnowledgePoint, sec.title],
              [...fromIndexPoint, sec.index], sec.children!);
        }
      }
    }

    handleSection([], [], root.children!);

    return QuestionBankBuilder(
        data: root.children!, id: id, displayName: title, version: 4);
  }
}
