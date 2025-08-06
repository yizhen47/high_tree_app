import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/screen/mode.dart';
import 'package:flutter_application_1/tool/page_intent_trans.dart';
import 'package:flutter_application_1/tool/question/question_bank.dart';
import 'package:flutter_application_1/tool/question/question_controller.dart';
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
        title: '智能学习',
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
    var ids = LearningPlanManager.instance.learningPlanItems
        .map((item) => item.targetSection!.id)
        .toList();
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
            // 显示节点点击弹窗
            _showNodeActionDialog(context, node);
          },
          height: constraints.maxHeight);
      for (var bank in LearningPlanManager.instance.questionBanks) {
        var planItem = LearningPlanItem(bank);
        planItem.buildMindMapNodes(
            MindMapHelper.addChildNode(mindMap.rootNode, bank.displayName!));
      }
      MindMapHelper.organizeTree(mindMap.rootNode);
      Future.delayed(const Duration(milliseconds: 100)).then((_) {
        mindMap.controller!.highlightNodeById(ids);
      });
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
                LearningPlanManager.instance.resetDailyProgress();
                TDToast.showSuccess("计划刷新", context: context);
                setState(() {});
              },
              child: Padding(
                padding: const EdgeInsets.only(bottom: 15, top: 15),
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

  void _showNodeActionDialog(BuildContext context, MindMapNode<Section> node) {
    bool isAlreadyInPlan = LearningPlanManager.instance.learningPlanItems
        .any((item) => item.targetSection?.id == node.data!.id);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        elevation: 4,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                node.text,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1565C0),
                ),
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, color: Color(0xFFE0E0E0)),
              const SizedBox(height: 16),
              Text(
                '知识点 ID: ${node.data!.id}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  letterSpacing: 0.2,
                ),
              ),
              Text(
                '上次完成时间: ${
                  DateTime.fromMillisecondsSinceEpoch(
                    LearningPlanItem(findBank(node.data!)!).getSectionLearningData(node.data!).lastLearnTime
                  ).toString()
                }',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 12),
              if (isAlreadyInPlan)
                Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.blue[800], size: 16),
                    const SizedBox(width: 8),
                    Text(
                      '已加入学习计划',
                      style: TextStyle(
                          color: Colors.blue[800],
                          fontSize: 14,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blueAccent,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: const BorderSide(color: Color(0xFFE0E0E0)),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('关闭'),
                  ),
                  if (!isAlreadyInPlan) const SizedBox(width: 12),
                  if (!isAlreadyInPlan)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        _addToLearningPlan(node.data!);
                        Navigator.pop(context);
                      },
                      child: const Text('加入今日计划'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 将节点添加到今日学习计划
  void _addToLearningPlan(Section section) {
    bool added = false;
    var bank = findBank(section);
    if (bank != null) {
      // 使用新方法将节点添加到手动学习计划中
      added = LearningPlanManager.instance
          .addSectionToManualLearningPlan(section, bank);
    }

    // 更新UI
    setState(() {});

    // 显示相应提示
    if (added) {
      TDToast.showSuccess('已添加到计划', context: context);
    } else {
      TDToast.showWarning('无法添加', context: context);
    }
  }

  QuestionBank? findBank(Section section) {
    for (var bank in LearningPlanManager.instance.questionBanks) {
      try {
        Section bankSection = bank.findSection(section.id.split('/'));
        return bank;
            } catch (e) {
        // Ignore exceptions for banks that don't have this section
      }
    }
    return null;
  }
}
