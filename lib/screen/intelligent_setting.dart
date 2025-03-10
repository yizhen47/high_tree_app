import 'dart:io';

import 'package:file_picker/file_picker.dart';  
import 'package:flutter/material.dart';
import 'package:flutter_application_1/screen/mode.dart';
import 'package:flutter_application_1/tool/page_intent_trans.dart';
import 'package:flutter_application_1/tool/question_bank.dart';
import 'package:flutter_application_1/tool/question_controller.dart';
import 'package:flutter_application_1/tool/study_data.dart';
import 'package:flutter_application_1/widget/mind_map.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

class IntelligentSettingScreen extends StatefulWidget {
  const IntelligentSettingScreen({super.key});
  @override
  State<IntelligentSettingScreen> createState() => _InnerState();
}

//这里是在一个页面中加了PageView，PageView可以载入更多的StatefulWidget或者StatelessWidget（也就是页面中加载其他页面作为子控件）
class _InnerState extends State<IntelligentSettingScreen> {
  List<String> selectIds = QuestionBank.getAllLoadedQuestionBankIds();
  //这修改页面2的内容
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TDNavBar(
        title: '智能刷题',
        onBack: () {},
      ),
      body: Column(
        children: [
          Flexible(fit: FlexFit.tight, child: buildMindMap(context)),
          buildNagBar()
        ],
      ),
    );
  }

  buildMindMap(BuildContext context) {
    var ids = QuestionGroupController.instances.controllers.map((toElement) => toElement.currentLearn
    !.id).toList();
    var width = MediaQuery.of(context).size.width;
    var layout = LayoutBuilder(builder: (context, constraints) {
      var mindMap = MindMap<Section>(
          rootNode: MindMapHelper.createRoot(data: Section("", "")),
          width: width,
          controller: MindMapController(),
          onNodeTap: (MindMapNode<Section> node) {
            if (node.data == null) {
              return;
            }
            print(node.data!);
          },
          height: constraints.maxHeight);
      for (var c in QuestionGroupController.instances.banksCache
          .map((toElement) => QuestionController(toElement))) {
        c.getMindMapNode(
            MindMapHelper.addChildNode(mindMap.rootNode, c.bank.displayName!));
      }
      MindMapHelper.organizeTree(mindMap.rootNode);
      mindMap.controller!.highlightNodeById(ids);
      return mindMap;
    });
    return layout;
  }

  buildNagBar() {
    return Container(
      color: Theme.of(context).cardColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Expanded(
            child: InkWell(
              onTap: () {
                QuestionGroupController.instances.toDayUpdater();                          
                TDToast.showSuccess("计划刷新", context: context);
                setState(() {
                  
                });
              },
              child: Padding(
                padding: EdgeInsets.only(bottom: 15, top: 15),
                child: Icon(
                  Icons.skip_next_outlined,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
          ),
                                                                                                                                                                                                                                                                                                                                                                                                               
        ],
      ),
    );
  }

  Future<void> saveLoadedOption() async {
    List<Future> futures = [];
    var lastSelectIds = QuestionBank.getAllLoadedQuestionBankIds();
    for (var id in lastSelectIds) {
      if (!selectIds.contains(id)) {
        futures
            .add((await QuestionBank.getQuestionBankById(id)).removeFromData());
      }
    }
    for (var id in selectIds) {
      if (!lastSelectIds.contains(id)) {
        futures
            .add((await QuestionBank.getQuestionBankById(id)).loadIntoData());
      }
    }
    await Future.wait(futures);
    if (StudyData.instance.getStudyType() == StudyType.studyMode &&
        selectIds.length > 1) {
      StudyData.instance.setStudyType(StudyType.testMode);
    }
    StudyData.instance.setStudySection(null);

    QuestionGroupController.instances.update();
  }
}
