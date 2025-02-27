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
  List<String> fromKonwledgePoint;
  List<String> fromKonwledgeIndex;
  Map<String, String> question;
  String fromId;
  String fromDisplayName;

  factory SingleQuestionData.fromJson(Map<String, dynamic> json) =>
      _$SingleQuestionDataFromJson(json);

  Map<String, dynamic> toJson() => _$SingleQuestionDataToJson(this);
  SingleQuestionData(this.fromKonwledgePoint, this.fromKonwledgeIndex,
      this.question, this.fromId, this.fromDisplayName);

  String getKonwledgePoint() {
    return fromKonwledgePoint.join('/');
  }

  String getKonwledgeIndex() {
    return fromKonwledgeIndex.join('/');
  }

  SingleQuestionData clone() {
    return SingleQuestionData(
        List.from(fromKonwledgePoint),
        List.from(fromKonwledgeIndex),
        Map.from(question),
        fromId,
        fromDisplayName);
  }
}

@JsonSerializable()
class Section {
  String index;
  String title;
  String? note;
  List<Section>? children;
  List<Map<String, String>>? questions;

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

  SingleQuestionData randomSectionQuestion(List<String> fromKonwledgePoint,
      List<String> fromKonwledgeIndex, String fromId, String fromName,
      {retryingTimes = 20}) {
    SingleQuestionData? q;
    for (var i = 0; i < retryingTimes; i++) {
      q = _randomSectionQuestion(List.from(fromKonwledgePoint),
          List.from(fromKonwledgeIndex), fromId, fromName);
      if (q != null) {
        break;
      }
    }
    if (q == null) {
      return SingleQuestionData(
          [],
          [],
          {'q': '本章没有题目', 'w': '本章没有答案', 'id': const Uuid().v4()},
          fromId,
          fromName);
    }
    return q;
  }

  SingleQuestionData? _randomSectionQuestion(List<String> fromKonwledgePoint,
      List<String> fromKonwledgeIndex, String fromId, String fromName) {
    if (_random!.nextInt(3) == 1) {
      // ignore: unnecessary_null_comparison
      if (questions == null) {
        return null;
      }
      if (fromKonwledgePoint.isEmpty || fromKonwledgePoint.last != title) {
        fromKonwledgePoint.add(title);
        fromKonwledgeIndex.add(index);
      } else {}

      return SingleQuestionData(
          List.from(fromKonwledgePoint),
          List.from(fromKonwledgeIndex),
          questions![_random!.nextInt(questions!.length)],
          fromId,
          fromName);
    } else {
      // ignore: unnecessary_null_comparison
      if (children == null) {
        return null;
      } else {
        var sec = children![_random!.nextInt(children!.length)];
        fromKonwledgePoint.add(title);
        fromKonwledgeIndex.add(index);
        return sec.randomSectionQuestion(List.from(fromKonwledgePoint),
            List.from(fromKonwledgeIndex), fromId, fromName);
      }
    }
  }

  List<SingleQuestionData> sectionQuestion(List<String> fromKonwledgePoint,
      List<String> fromKonwledgeIndex, String fromId, String fromName,
      {List<SingleQuestionData>? questionsList}) {
    questionsList ??= [];
    questionsList.addAll(sectionQuestionOnly(
        fromKonwledgePoint, fromKonwledgeIndex, fromId, fromName));
    if (children != null) {
      for (var c in children!) {
        c.sectionQuestion(List.from(fromKonwledgePoint),
            List.from(fromKonwledgeIndex), fromId, fromName,
            questionsList: questionsList);
      }
    }
    return questionsList;
  }

  List<SingleQuestionData> sectionQuestionOnly(List<String> fromKonwledgePoint,
      List<String> fromKonwledgeIndex, String fromId, String fromName,
      {List<SingleQuestionData>? questionsList}) {
    questionsList ??= [];
    if (fromKonwledgeIndex.isNotEmpty && fromKonwledgeIndex.last == index) {
    } else {
      fromKonwledgePoint.add(title);
      fromKonwledgeIndex.add(index);
    }
    // ignore: unnecessary_null_comparison
    if (questions != null) {
      for (var q in questions!) {
        questionsList.add(SingleQuestionData(
            fromKonwledgePoint, fromKonwledgeIndex, q, fromId, fromName));
      }
    }
    return questionsList;
  }
}

@JsonSerializable() // 使用泛型的注解
class QuestionBankData {
  String? displayName;
  List<Section>? data;
  String? id;
  int? version;

  factory QuestionBankData.fromJson(Map<String, dynamic> json) =>
      _$QuestionBankDataFromJson(json);

  Map<String, dynamic> toJson() => _$QuestionBankDataToJson(this);

  QuestionBankData();
  @override
  String toString() {
    return jsonEncode(this);
  }
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
    var iid = path.basenameWithoutExtension(filePath);
    var dir = path.join(QuestionBank.loadedDirPath, iid);
    if (Directory(dir).existsSync()) {
      _getQuestionBankInf(
          utf8.decode(await File(path.join(dir, "data.json")).readAsBytes()));
    } else {
      File fromFile = File(filePath);
      final achieve = _zipDecoder!.decodeBytes(await fromFile.readAsBytes());
      for (final file in achieve) {
        if (file.name == "data.json") {
          _getQuestionBankInf(utf8.decode(file.content));
          break;
        }
      }
    }
    return this;
  }

  _getQuestionBankInf(String d) {
    Map<String, dynamic> jsonO = jsonDecode(d);
    var json = QuestionBankData.fromJson(jsonO);
    data = json.data;
    displayName = json.displayName;
    id = json.id;
    version = json.version;
    cacheDir = path.join(loadedDirPath, id);
  }

  static deleteQuestionBank(String id) async {
    mksureInit();
    await _removeDirectoryIfExists(Directory(path.join(loadedDirPath, id)));
    await _removeFileIfExists(File(path.join(importedDirPath, "$id.qset")));
  }

  void close() {
    if (cacheDir != null) Directory(cacheDir!).delete();
  }

  static clean() async {
    return Directory(QuestionBank.loadedDirPath).list().forEach((e) async {
      if ((await e.stat()).type == FileSystemEntityType.directory) {
        e.delete();
      }
    });
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
            .randomSectionQuestion([], [], id!, displayName!);
      } else {
        q = sec.randomSectionQuestion([], [], id!, displayName!);
      }
    }
    return q;
  }

  List<SingleQuestionData> sectionQuestion() {
    mksureInit();
    List<SingleQuestionData> qList = [];
    for (var sec in data!) {
      qList.addAll(sec.sectionQuestion([], [], id!, displayName!));
    }
    return qList;
  }

  static Future<void> importQuestionBank(File file) async {
    mksureInit();
    if (!file.existsSync()) {
      throw Exception("文件不存在");
    }
    var achieve = _zipDecoder!.decodeBytes(await file.readAsBytes());
    String? id;
    for (final f in achieve) {
      if (f.name == "data.json") {
        var json = jsonDecode(utf8.decode(f.content));
        id = json["id"];
        break;
      }
    }
    if (id == null) {
      throw Exception("文件格式不正确");
    }
    var npath = path.join(QuestionBank.importedDirPath, "$id.qset");
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

  String getDataFileContent() {
    return jsonEncode(getDataFileJson());
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
      final jsonContent = utf8.encode(getDataFileContent());
      archive
          .addFile(ArchiveFile('data.json', jsonContent.length, jsonContent));
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
    var inLatex = false;
    for (var lineIndex = 0; lineIndex < lines.length; lineIndex++) {
      if (!inLatex) {
        line = lines[lineIndex];
      } else {
        if (line.startsWith('\$\$')) {
          inLatex = false;
        }
        line = line + '\n' + lines[lineIndex];
        continue;
      }
      // Handle examples and exercise questions only when inside exercises section
      if (RegExp(r'[一二三四五六七八九]+、.*题').hasMatch(line) && inExercises) continue;

      if (line.trim().isEmpty) continue;

      if (line.startsWith('\$\$')) {
        inLatex = true;
        continue;
      }

      if ((line.startsWith('例') || (inExercises && matchf.hasMatch(line)))) {
        stack.last.questions!.add({'q': '', 'w': ''});
        inState = 1;
        if (!inExercises && line.startsWith('例')) {
          appendQuestionOrAnswer(
              stack.last.questions!.last, 'q', line.substring(2).trim());
        } else if (inExercises) {
          // Inside exercises section, treat numbered lines as questions
          appendQuestionOrAnswer(stack.last.questions!.last, 'q',
              line.substring(matchf.firstMatch(line)?.end ?? 0 + 1).trim());
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
    return QuestionBankBuilder(
        data: root.children!, id: id, displayName: title, version: 3);
  }
}
