
import 'package:flutter/material.dart';
import 'package:flutter_application_1/tool/question/question_bank.dart';
import 'package:flutter_application_1/tool/question/question_controller.dart';
import 'package:flutter_application_1/widget/mind_map.dart';
import 'package:flutter_application_1/widget/question_card/knowledge_card_widget.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

class MindMapScreen extends StatefulWidget {
  const MindMapScreen({super.key});
  @override
  State<MindMapScreen> createState() => _InnerState();
}

//这里是在一个页面中加了PageView，PageView可以载入更多的StatefulWidget或者StatelessWidget（也就是页面中加载其他页面作为子控件）
class _InnerState extends State<MindMapScreen> {
  List<String> selectIds = QuestionBank.getAllLoadedQuestionBankIds();
  //这修改页面2的内容
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TDNavBar(
        title: '知识点总览',
        onBack: () => Navigator.of(context).pop(),
      ),
      body: buildChapterList(context),
    );
  }

  Widget buildChapterList(BuildContext context) {
    final questionBanks = LearningPlanManager.instance.questionBanks;
    if (questionBanks.isEmpty) {
      return const Center(child: Text('没有加载任何题库'));
    }

    return ListView.builder(
      itemCount: questionBanks.length,
      itemBuilder: (context, index) {
        final bank = questionBanks[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: ExpansionTile(
            title: Text(bank.displayName ?? '未命名题库',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            children: bank.sections
                .map((section) => _buildSectionTile(context, section))
                .toList(),
          ),
        );
      },
    );
  }

  Widget _buildSectionTile(BuildContext context, Section section) {
    if (section.children == null || section.children!.isEmpty) {
      return ListTile(
        title: Text(section.title),
        onTap: () => _showNodeActionDialog(context, MindMapNode.fromSection(section)),
        contentPadding: const EdgeInsets.only(left: 32),
      );
    }

    return ExpansionTile(
      title: Text(section.title),
      tilePadding: const EdgeInsets.only(left: 32, right: 16),
      children: section.children!
          .map((child) => _buildSectionTile(context, child))
          .toList(),
    );
  }

  buildMindMap(BuildContext context) {
    var ids = LearningPlanManager.instance.learningPlanItems
        .map((item) => item.targetSection!.id)
        .toList();
    var width = MediaQuery.of(context).size.width;
    
    // 构建题库ID到缓存目录的映射
    final questionBankCacheDirs = <String, String>{};
    for (var bank in LearningPlanManager.instance.questionBanks) {
      if (bank.id != null && bank.cacheDir != null) {
        questionBankCacheDirs[bank.id!] = bank.cacheDir!;
      }
    }
    
    var layout = LayoutBuilder(builder: (context, constraints) {
      final questionBankCount = LearningPlanManager.instance.questionBanks.length;
      
      var mindMap = MindMap<Section>(
          rootNode: MindMapHelper.createSmartRoot(
            data: Section("", ""), 
            questionBankCount: questionBankCount,
            position: Offset(width / 2, constraints.maxHeight / 2), // 将根节点放在中心
          ),
          width: width,
          controller: MindMapController(),
          questionBankCacheDirs: questionBankCacheDirs, // 传递缓存目录映射
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
    
    // 检查节点是否有学习价值（可以添加到学习计划）
    bool canAddToPlan = node.data!.hasLearnableContent();
    
    // 检查是否为叶子节点
    bool isLeafNode = node.data!.children == null || node.data!.children!.isEmpty;
    
    // 检查是否有知识点内容（备注或视频）
    bool hasKnowledgeContent = (node.data!.note?.isNotEmpty ?? false) || 
                              (node.data!.videos?.isNotEmpty ?? false);
    


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
              // 标题栏，包含标题和关闭按钮
              Row(
                children: [
                  Expanded(
                    child: Text(
                      node.data!.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1565C0),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, size: 20),
                    color: Colors.grey[600],
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    splashRadius: 16,
                  ),
                ],
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
              Builder(
                builder: (context) {
                  final bank = findBank(node.data!);
                  if (bank == null) {
                    return Text(
                      '上次完成时间: 未知',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        letterSpacing: 0.2,
                      ),
                    );
                  }
                  
                  try {
                    final lastLearnTime = LearningPlanItem(bank)
                        .getSectionLearningData(node.data!)
                        .lastLearnTime;
                    
                    return Text(
                      '上次完成时间: ${lastLearnTime > 0 
                          ? DateTime.fromMillisecondsSinceEpoch(lastLearnTime).toString().split('.')[0]
                          : '从未学习'}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        letterSpacing: 0.2,
                      ),
                    );
                  } catch (e) {
                    return Text(
                      '上次完成时间: 从未学习',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  letterSpacing: 0.2,
                ),
                    );
                  }
                },
              ),
              
              // 显示视频信息
              if (node.data!.videos?.isNotEmpty ?? false) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.video_library, color: Colors.green[700], size: 16),
                    const SizedBox(width: 8),
                    Text(
                      '包含 ${node.data!.videos!.length} 个视频课程',
                      style: TextStyle(
                          color: Colors.green[700],
                          fontSize: 14,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
              
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
              if (!canAddToPlan && !isAlreadyInPlan)
                Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange[700], size: 16),
                    const SizedBox(width: 8),
                    Text(
                      isLeafNode ? '此节点无学习内容' : '请选择有学习内容的知识点',
                      style: TextStyle(
                          color: Colors.orange[700],
                          fontSize: 14,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              const SizedBox(height: 24),
              // 底部按钮区域 - 只显示功能按钮，关闭按钮已移到右上角
              Row(
                children: [
                  if (hasKnowledgeContent)
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          minimumSize: const Size(0, 44),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context);
                            Future.delayed(const Duration(milliseconds: 100), () {
                              if (context.mounted) {
                                _showKnowledgeDetail(context, node.data!);
                              }
                            });
                          }
                        },
                        child: const Text('查看知识点', 
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                      ),
                    ),
                  if (hasKnowledgeContent && (!isAlreadyInPlan && canAddToPlan)) 
                    const SizedBox(width: 12),
                  if (!isAlreadyInPlan && canAddToPlan)
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          minimumSize: const Size(0, 44),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          if (Navigator.canPop(context)) {
                            _addToLearningPlan(node.data!);
                            Navigator.pop(context);
                          }
                        },
                        child: const Text('加入今日计划',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                      ),
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

    // 显示相应提示
    if (added) {
      TDToast.showSuccess('已添加到计划', context: context);
    } else {
      TDToast.showWarning('无法添加', context: context);
    }
  }

  void _showKnowledgeDetail(BuildContext context, Section section) {
    final bank = findBank(section);
    showKnowledgeCard(context, section, questionBank: bank);
  }

  QuestionBank? findBank(Section section) {
    for (var bank in LearningPlanManager.instance.questionBanks) {
      try {
        // Try different path formats
        List<List<String>> pathsToTry = [];
        
        // 1. 原始方法：使用完整ID split
        var originalPath = section.id.split('/').where((s) => s.isNotEmpty).toList();
        if (originalPath.isNotEmpty) {
          pathsToTry.add(originalPath);
        }
        
        // 2. 使用 section.index 分割成子路径 (例如: "4.5.1" -> ["4", "5", "1"])
        if (section.index.contains('.')) {
          pathsToTry.add(section.index.split('.'));
        } else {
          pathsToTry.add([section.index]);
        }
        
        // 3. 使用 fromKonwledgeIndex + index
        if (section.fromKonwledgeIndex.isNotEmpty) {
          pathsToTry.add([...section.fromKonwledgeIndex, section.index]);
        }
        
        // 4. 构建层次化路径 (例如: "4.5.1.1" -> ["4.5", "4.5.1", "4.5.1.1"])
        if (section.index.contains('.')) {
          List<String> hierarchicalPath = [];
          var parts = section.index.split('.');
          // 从第二级开始构建路径 (跳过单独的章节号)
          for (int i = 1; i < parts.length; i++) {
            var pathPart = parts.sublist(0, i + 1).join('.');
            hierarchicalPath.add(pathPart);
          }
          pathsToTry.add(hierarchicalPath);
        }
        
        for (var path in pathsToTry) {
          try {
            bank.findSection(path);
            return bank;
          } catch (e) {
            continue;
          }
        }
        
      } catch (e) {
        // Continue to next bank
      }
    }
    return null;
  }
}
