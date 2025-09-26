import 'dart:io';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/tool/page_intent_trans.dart';
import 'package:flutter_application_1/tool/question/question_bank.dart';
import 'package:flutter_application_1/tool/question/question_controller.dart';
import 'package:flutter_application_1/tool/study_data.dart';
import 'package:flutter_application_1/widget/mind_map.dart';
import 'package:flutter_application_1/widget/question_card/knowledge_card_widget.dart';
import 'package:flutter_application_1/widget/tech_ui_components.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

class MindMapScreen extends StatefulWidget {
  const MindMapScreen({super.key});
  @override
  State<MindMapScreen> createState() => _InnerState();
}

// 单个章节的知识图谱页面
class ChapterMindMapScreen extends StatefulWidget {
  final Section chapterSection;
  final QuestionBank questionBank;
  final String chapterTitle;
  
  const ChapterMindMapScreen({
    super.key,
    required this.chapterSection,
    required this.questionBank,
    required this.chapterTitle,
  });
  
  @override
  State<ChapterMindMapScreen> createState() => _ChapterMindMapState();
}

class _ChapterMindMapState extends State<ChapterMindMapScreen> with TickerProviderStateMixin {
  late AnimationController _backgroundController;
  late Animation<double> _backgroundAnimation;
  
  @override
  void initState() {
    super.initState();
    
    // 背景动画控制器
    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    
    _backgroundAnimation = CurvedAnimation(
      parent: _backgroundController,
      curve: Curves.linear,
    );
  }
  
  @override
  void dispose() {
    _backgroundController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: _buildTechAppBar(),
      body: Container(
        decoration: buildTechBackground(),
        child: Column(
          children: [
            Flexible(fit: FlexFit.tight, child: _buildChapterMindMap(context)),
            _buildTechNavBar()
          ],
        ),
      ),
    );
  }
  
  // 科技风应用栏
  PreferredSizeWidget _buildTechAppBar() {
    return TechAppBar(
      title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.chapterTitle,
                        style: TextStyle(
                          color: const Color(0xFF00F5FF),
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                          shadows: [
                            Shadow(
                              offset: const Offset(0, 0),
                              blurRadius: 12.0,
                              color: const Color(0xFF00F5FF).withOpacity(0.8),
                            ),
                          ],
                        ),
                      ),
                                             Text(
                         '章节图谱',
                         style: TextStyle(
                           color: const Color(0xFF00F5FF).withOpacity(0.7),
                           fontSize: 14,
                           fontWeight: FontWeight.w600,
                           letterSpacing: 1.0,
                         ),
                       ),
                    ],
                  ),
      trailing: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF00F5FF).withOpacity(0.6),
                        Colors.transparent,
                      ],
                    ),
                    border: Border.all(
                      color: const Color(0xFF00FFFF).withOpacity(0.4),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.account_tree,
                      color: const Color(0xFF00F5FF).withOpacity(0.8),
                      size: 20,
          ),
        ),
      ),
    );
  }
  
  // 构建章节知识图谱
  Widget _buildChapterMindMap(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    
    // 构建题库ID到缓存目录的映射
    final questionBankCacheDirs = <String, String>{};
    if (widget.questionBank.id != null && widget.questionBank.cacheDir != null) {
      questionBankCacheDirs[widget.questionBank.id!] = widget.questionBank.cacheDir!;
    }
    
    return LayoutBuilder(builder: (context, constraints) {
      // 创建以章节为根节点的知识图谱
      var rootNode = MindMapNode<Section>(
        id: widget.chapterSection.id,
        text: widget.chapterSection.title,
        position: Offset(width / 2, constraints.maxHeight / 2),
        data: widget.chapterSection,
        color: const Color(0xFF00F5FF),
      );
      
      var mindMap = MindMap<Section>(
        rootNode: rootNode,
        width: width,
        controller: MindMapController(),
        questionBankCacheDirs: questionBankCacheDirs,
        onNodeTap: (MindMapNode<Section> node) {
          if (node.data == null) {
            return;
          }
          // 显示节点详情弹窗
          _showNodeActionDialog(context, node);
        },
        height: constraints.maxHeight,
      );
      
      // 递归添加章节的子节点
      _buildChapterNodes(rootNode, widget.chapterSection);
      
      // 组织树结构
      MindMapHelper.organizeTree(mindMap.rootNode);
      
      return mindMap;
    });
  }
  
  // 递归构建章节节点
  void _buildChapterNodes(MindMapNode<Section> parentNode, Section section) {
    if (section.children != null && section.children!.isNotEmpty) {
      for (var child in section.children!) {
        var childNode = MindMapHelper.addChildNode<Section>(
          parentNode,
          child.title,
          id: child.id,
          data: child,
          image: child.image,
        );
        
        // 递归添加子节点
        _buildChapterNodes(childNode, child);
      }
    }
  }
  
  // 科技风底部导航栏
  Widget _buildTechNavBar() {
    return const ChapterMindMapNavBar();
  }
  
  void _showNodeActionDialog(BuildContext context, MindMapNode<Section> node) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.8),
      builder: (context) => _NodeActionDialog(
        node: node,
        questionBank: widget.questionBank,
        onAddToPlan: (section, bank) {
          if (bank == null) {
            showTechToast(context, '无法添加');
            return;
          }
          final added = LearningPlanManager.instance.addSectionToManualLearningPlan(section, bank);
          if (added) {
            showTechToast(context, '已添加到计划');
          } else {
            showTechToast(context, '无法添加');
          }
        },
        onShowKnowledge: (section, bank) {
          _showKnowledgeDetail(context, section);
        },
      ),
    );
  }

  void _showKnowledgeDetail(BuildContext context, Section section) {
    showKnowledgeCard(context, section, questionBank: widget.questionBank);
  }
}

//这里是在一个页面中加了PageView，PageView可以载入更多的StatefulWidget或者StatelessWidget（也就是页面中加载其他页面作为子控件）
class _InnerState extends State<MindMapScreen> with TickerProviderStateMixin {
  List<String> selectIds = QuestionBank.getAllLoadedQuestionBankIds();
  
  late AnimationController _backgroundController;
  late Animation<double> _backgroundAnimation;
  
  @override
  void initState() {
    super.initState();
    
    // 背景动画控制器
    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    
    _backgroundAnimation = CurvedAnimation(
      parent: _backgroundController,
      curve: Curves.linear,
    );
  }
  
  @override
  void dispose() {
    _backgroundController.dispose();
    super.dispose();
  }
  
  //这修改页面2的内容
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: _buildTechAppBar(),
      body: Container(
        decoration: buildTechBackground(),
        child: Column(
        children: [
          Flexible(fit: FlexFit.tight, child: buildMindMap(context)),
            buildTechNavBar()
        ],
        ),
      ),
    );
  }
  
  // 科技风应用栏
  PreferredSizeWidget _buildTechAppBar() {
    return TechAppBar(
      title: Text(
                    '知识图谱',
                    style: TextStyle(
                      color: const Color(0xFF00F5FF),
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2.0,
                      shadows: [
                        Shadow(
                          offset: const Offset(0, 0),
                          blurRadius: 12.0,
                          color: const Color(0xFF00F5FF).withOpacity(0.8),
                        ),
                        Shadow(
                          offset: const Offset(0, 0),
                          blurRadius: 24.0,
                          color: const Color(0xFF00F5FF).withOpacity(0.4),
                        ),
                      ],
                    ),
                  ),
      trailing: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF00F5FF).withOpacity(0.6),
                        Colors.transparent,
                      ],
                    ),
                    border: Border.all(
                      color: const Color(0xFF00FFFF).withOpacity(0.4),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.blur_on,
                      color: const Color(0xFF00F5FF).withOpacity(0.8),
                      size: 20,
          ),
        ),
      ),
    );
  }
  
  // 科技风背景
  BoxDecoration _buildTechBackground() {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFF0A0A0F), // 深蓝黑
          const Color(0xFF1A1A2E), // 深蓝紫
          const Color(0xFF16213E), // 深蓝
          const Color(0xFF0F0F23), // 深紫黑
          const Color(0xFF0A0A0F), // 深蓝黑
        ],
        stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
      ),
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
            
            // 检查是否是章节节点（包含"第"和"章"的节点）
            if (_isChapterNode(node)) {
              // 找到对应的题库
              final bank = findBank(node.data!);
              if (bank != null) {
                // 跳转到章节知识图谱页面
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChapterMindMapScreen(
                      chapterSection: node.data!,
                      questionBank: bank,
                      chapterTitle: node.text,
                    ),
                  ),
                );
                return;
              }
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

  // 检查是否是章节节点
  bool _isChapterNode(MindMapNode<Section> node) {
    // 检查节点文本是否包含"第"和"章"
    final text = node.text.toLowerCase();
    return text.contains('第') && text.contains('章');
  }

  // 科技风底部导航栏
  Widget buildTechNavBar() {
    return MainMindMapNavBar(
      backgroundAnimation: _backgroundAnimation,
      onRefresh: () {
                LearningPlanManager.instance.resetDailyProgress();
        showTechToast(context, "计划刷新成功");
                setState(() {});
              },
    );
  }

  void _showNodeActionDialog(BuildContext context, MindMapNode<Section> node) {
    final bank = findBank(node.data!);
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.8),
      builder: (context) => _NodeActionDialog(
        node: node,
        questionBank: bank,
        onAddToPlan: (section, bank) {
          if (bank == null) {
            showTechToast(context, '无法添加');
            return;
          }
          final added = LearningPlanManager.instance.addSectionToManualLearningPlan(section, bank);
          if (added) {
            showTechToast(context, '已添加到计划');
          } else {
            showTechToast(context, '无法添加');
          }
        },
        onShowKnowledge: (section, bank) {
          _showKnowledgeDetail(context, section);
        },
      ),
    );
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
            Section bankSection = bank.findSection(path);
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

class _NodeActionDialog extends StatelessWidget {
  final MindMapNode<Section> node;
  final QuestionBank? questionBank;
  final Function(Section, QuestionBank?) onAddToPlan;
  final Function(Section, QuestionBank?) onShowKnowledge;

  const _NodeActionDialog({
    required this.node,
    required this.questionBank,
    required this.onAddToPlan,
    required this.onShowKnowledge,
  });

  @override
  Widget build(BuildContext context) {
    bool isAlreadyInPlan = LearningPlanManager.instance.learningPlanItems
        .any((item) => item.targetSection?.id == node.data!.id);
    
    // 检查节点是否有学习价值（可以添加到学习计划）
    bool canAddToPlan = node.data!.hasLearnableContent();
    
    // 检查是否为叶子节点
    bool isLeafNode = node.data!.children == null || node.data!.children!.isEmpty;
    
    // 检查是否有知识点内容（备注或视频）
    bool hasKnowledgeContent = (node.data!.note?.isNotEmpty ?? false) || 
                              (node.data!.videos?.isNotEmpty ?? false);
    
    return Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF0A0A0F).withOpacity(0.98),
                const Color(0xFF1A1A2E).withOpacity(0.98),
                const Color(0xFF16213E).withOpacity(0.98),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFF00F5FF).withOpacity(0.6),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00F5FF).withOpacity(0.3),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
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
                      node.text,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                        color: const Color(0xFF00F5FF),
                        shadows: [
                          Shadow(
                            offset: const Offset(0, 0),
                            blurRadius: 8.0,
                            color: const Color(0xFF00F5FF).withOpacity(0.8),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF00F5FF).withOpacity(0.3),
                          const Color(0xFF1E90FF).withOpacity(0.3),
                        ],
                      ),
                      border: Border.all(
                        color: const Color(0xFF00FFFF).withOpacity(0.6),
                        width: 1,
                      ),
                    ),
                    child: IconButton(
                    onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Color(0xFF00F5FF),
                        size: 20,
                      ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    splashRadius: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                height: 2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      const Color(0xFF00F5FF).withOpacity(0.8),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildInfoRow(
                icon: Icons.fingerprint,
                label: '知识点 ID',
                value: node.data!.id,
              ),
              const SizedBox(height: 12),
              Builder(
                builder: (context) {
                if (questionBank == null) {
                    return _buildInfoRow(
                      icon: Icons.schedule,
                      label: '上次完成时间',
                      value: '未知',
                    );
                  }
                  
                  try {
                  final lastLearnTime = LearningPlanItem(questionBank!)
                        .getSectionLearningData(node.data!)
                        .lastLearnTime;
                    
                    return _buildInfoRow(
                      icon: Icons.schedule,
                      label: '上次完成时间',
                      value: lastLearnTime > 0 
                          ? DateTime.fromMillisecondsSinceEpoch(lastLearnTime).toString().split('.')[0]
                          : '从未学习',
                    );
                  } catch (e) {
                    return _buildInfoRow(
                      icon: Icons.schedule,
                      label: '上次完成时间',
                      value: '从未学习',
                    );
                  }
                },
              ),
              
              // 显示视频信息
              if (node.data!.videos?.isNotEmpty ?? false) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF00F5FF).withOpacity(0.1),
                        const Color(0xFF1E90FF).withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF00F5FF).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                  children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              const Color(0xFF00F5FF).withOpacity(0.8),
                              const Color(0xFF00F5FF).withOpacity(0.3),
                            ],
                          ),
                        ),
                        child: const Icon(
                          Icons.video_library,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                    Text(
                      '包含 ${node.data!.videos!.length} 个视频课程',
                      style: TextStyle(
                          color: const Color(0xFF00F5FF),
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                    ),
                  ],
                  ),
                ),
              ],
              
              const SizedBox(height: 16),
              if (isAlreadyInPlan)
                _buildStatusContainer(
                  icon: Icons.check_circle,
                  text: '已加入学习计划',
                  color: const Color(0xFF00F5FF),
                ),
              if (!canAddToPlan && !isAlreadyInPlan)
                _buildStatusContainer(
                  icon: Icons.info_outline,
                  text: isLeafNode ? '此节点无学习内容' : '请选择有学习内容的知识点',
                  color: Colors.orange,
                ),
              const SizedBox(height: 28),
              // 底部按钮区域
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 16,
                runSpacing: 16,
                children: [
                  if (hasKnowledgeContent)
                    _buildTechButton(
                      onPressed: () {
                        if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                          Future.delayed(const Duration(milliseconds: 100), () {
                          onShowKnowledge(node.data!, questionBank);
                          });
                        }
                      },
                      text: '查看知识点',
                      color: const Color(0xFF00F5FF),
                      icon: Icons.visibility,
                    ),
                  if (!isAlreadyInPlan && canAddToPlan)
                    _buildTechButton(
                      onPressed: () {
                        if (Navigator.canPop(context)) {
                        onAddToPlan(node.data!, questionBank);
                          Navigator.pop(context);
                        }
                      },
                      text: '加入今日计划',
                      color: const Color(0xFF1E90FF),
                      icon: Icons.add_circle_outline,
                    ),
                ],
              ),
            ],
        ),
      ),
    );
  }
  
  // 信息行组件
  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                const Color(0xFF00F5FF).withOpacity(0.6),
                const Color(0xFF00F5FF).withOpacity(0.2),
              ],
            ),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 16,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[400],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  // 状态容器组件
  Widget _buildStatusContainer({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.2),
            color.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.3),
            ),
            child: Icon(
              icon,
              color: color,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // 科技风按钮组件
  Widget _buildTechButton({
    required VoidCallback onPressed,
    required String text,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.8),
            color.withOpacity(0.6),
          ],
        ),
        border: Border.all(
          color: color.withOpacity(0.8),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          minimumSize: const Size(0, 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
