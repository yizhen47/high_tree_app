import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_application_1/tool/question/question_bank.dart';
import 'package:flutter_application_1/tool/study_data.dart';
import 'package:flutter_application_1/widget/fan_mind_map.dart';
import 'package:flutter_application_1/widget/question_card/knowledge_card_widget.dart';
import 'package:flutter_application_1/widget/tech_ui_components.dart';
import 'package:flutter_application_1/tool/question/question_controller.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

class FanMindMapScreen extends StatefulWidget {
  const FanMindMapScreen({super.key});

  @override
  State<FanMindMapScreen> createState() => _FanMindMapScreenState();
}

class _FanMindMapScreenState extends State<FanMindMapScreen> with TickerProviderStateMixin {
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
            Flexible(fit: FlexFit.tight, child: _buildFanMindMap(context)),
            _buildTechNavBar()
          ],
        ),
      ),
    );
  }
  
  // 科技风应用栏
  PreferredSizeWidget _buildTechAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(80),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF0A0A0F).withOpacity(0.95),
              const Color(0xFF1A1A2E).withOpacity(0.95),
              const Color(0xFF16213E).withOpacity(0.95),
            ],
          ),
          border: Border(
            bottom: BorderSide(
              color: const Color(0xFF00F5FF).withOpacity(0.3),
              width: 2,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00F5FF).withOpacity(0.2),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // 自定义返回按钮
                Container(
                  margin: const EdgeInsets.all(8),
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
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: Color(0xFF00F5FF),
                      size: 20,
                    ),
                    padding: EdgeInsets.zero,
                  ),
                ),
                const SizedBox(width: 20),
                // 标题
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '知识图谱',
                        style: TextStyle(
                          color: const Color(0xFF00F5FF),
                          fontSize: 22,
                          fontWeight: FontWeight.normal,
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
                          '三层展开视图',
                          style: TextStyle(
                            color: const Color(0xFF00F5FF).withOpacity(0.7),
                            fontSize: 13,
                            fontWeight: FontWeight.normal,
                            letterSpacing: 1.0,
                          ),
                        ),
                    ],
                  ),
                ),
                // 右侧图标
                Container(
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
                      Icons.donut_large,
                      color: const Color(0xFF00F5FF).withOpacity(0.8),
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  // 构建扇形知识图谱
  Widget _buildFanMindMap(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    
    // 构建题库ID到缓存目录的映射
    final questionBankCacheDirs = <String, String>{};
    for (var bank in LearningPlanManager.instance.questionBanks) {
      if (bank.id != null && bank.cacheDir != null) {
        questionBankCacheDirs[bank.id!] = bank.cacheDir!;
      }
    }
    
    return LayoutBuilder(builder: (context, constraints) {
      final questionBankCount = LearningPlanManager.instance.questionBanks.length;
      
      var fanMindMap = FanMindMap<Section>(
        rootNode: FanMindMapHelper.createSmartFanRoot(
          data: Section("", ""), 
          questionBankCount: questionBankCount,
          position: Offset(width / 2, constraints.maxHeight / 2),
          text: '',
        ),
        width: width,
        controller: FanMindMapController(),
        questionBankCacheDirs: questionBankCacheDirs,
        onNodeTap: (FanMindMapNode<Section> node) {
          if (node.data == null) {
            return;
          }
          // 显示节点详情弹窗
          _showFanNodeActionDialog(context, node);
        },
        height: constraints.maxHeight,
      );
      
      // 构建扇形节点树（4层全展开）
      for (var bank in LearningPlanManager.instance.questionBanks) {
        var bankNode = FanMindMapHelper.addFanChildNode(
          fanMindMap.rootNode, 
          bank.displayName!,
          id: bank.id,
          data: Section(bank.id ?? "", bank.displayName ?? ""),
        );
        
        // 构建题库的章节节点（3层深度）
        _buildFanBankNodes(bankNode, bank, 3);
      }
      
      // 组织扇形树结构
      FanMindMapHelper.organizeFanTree(fanMindMap.rootNode, Size(width, constraints.maxHeight));
      
      // 高亮学习计划中的节点
      Future.delayed(const Duration(milliseconds: 100)).then((_) {
        var ids = LearningPlanManager.instance.learningPlanItems
            .map((item) => item.targetSection!.id)
            .toList();
        fanMindMap.controller?.highlightNodeById(ids);
      });
      
      return fanMindMap;
    });
  }
  
  // 构建题库的扇形节点（递归3层）
  void _buildFanBankNodes(FanMindMapNode<Section> bankNode, QuestionBank bank, int maxDepth) {
    if (maxDepth <= 0 || bank.data == null || bank.data!.isEmpty) return;
    
    // 显示所有章节，不限制数量
    final sectionsToAdd = bank.data!.toList();
    
    for (var section in sectionsToAdd) {
      var sectionNode = FanMindMapHelper.addFanChildNode(
        bankNode,
        _cleanChapterTitle(section.title),
        id: section.id,
        data: section,
      );
      
      // 递归添加子节点
      _buildFanSectionNodes(sectionNode, section, maxDepth - 1);
    }
  }
  
  // 递归构建节点的子节点
  void _buildFanSectionNodes(FanMindMapNode<Section> parentNode, Section section, int maxDepth) {
    if (maxDepth <= 0 || section.children == null || section.children!.isEmpty) return;
    
    // 显示所有子节点，不限制数量
    final childrenToAdd = section.children!.toList();
    
    for (var child in childrenToAdd) {
      var childNode = FanMindMapHelper.addFanChildNode(
        parentNode,
        _cleanChapterTitle(child.title),
        id: child.id,
        data: child,
      );
      
      // 递归添加更深层的子节点
      _buildFanSectionNodes(childNode, child, maxDepth - 1);
    }
  }
  
  // 清理章节标题
  String _cleanChapterTitle(String title) {
    final regex = RegExp(r'^第[\d一二三四五六七八九十百千万]+章\s*');
    return title.replaceFirst(regex, '').trim();
  }
  
  // 科技风底部导航栏
  Widget _buildTechNavBar() {
    return FanMindMapNavBar(
      backgroundAnimation: _backgroundAnimation,
      onRefresh: () {
        LearningPlanManager.instance.resetDailyProgress();
        showTechToast(context, "知识图谱刷新成功");
        setState(() {});
      },
    );
  }
  
  void _showFanNodeActionDialog(BuildContext context, FanMindMapNode<Section> node) {
    final bank = _findBank(node.data!);
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.8),
      builder: (context) => _FanNodeActionDialog(
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
    final bank = _findBank(section);
    showKnowledgeCard(context, section, questionBank: bank);
  }

  QuestionBank? _findBank(Section section) {
    for (var bank in LearningPlanManager.instance.questionBanks) {
      try {
        List<List<String>> pathsToTry = [];
        
        var originalPath = section.id.split('/').where((s) => s.isNotEmpty).toList();
        if (originalPath.isNotEmpty) {
          pathsToTry.add(originalPath);
        }
        
        if (section.index.contains('.')) {
          pathsToTry.add(section.index.split('.'));
        } else {
          pathsToTry.add([section.index]);
        }
        
        if (section.fromKonwledgeIndex.isNotEmpty) {
          pathsToTry.add([...section.fromKonwledgeIndex, section.index]);
        }
        
        if (section.index.contains('.')) {
          List<String> hierarchicalPath = [];
          var parts = section.index.split('.');
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

class _FanNodeActionDialog extends StatelessWidget {
  final FanMindMapNode<Section> node;
  final QuestionBank? questionBank;
  final Function(Section, QuestionBank?) onAddToPlan;
  final Function(Section, QuestionBank?) onShowKnowledge;

  const _FanNodeActionDialog({
    required this.node,
    required this.questionBank,
    required this.onAddToPlan,
    required this.onShowKnowledge,
  });

  @override
  Widget build(BuildContext context) {
    bool isAlreadyInPlan = LearningPlanManager.instance.learningPlanItems
        .any((item) => item.targetSection?.id == node.data!.id);
    
    bool canAddToPlan = node.data!.hasLearnableContent();
    bool isLeafNode = node.data!.children == null || node.data!.children!.isEmpty;
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
            // 标题栏
            Row(
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
                    Icons.donut_large,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    node.text,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.normal,
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
                      size: 18,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    splashRadius: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // 扇形信息
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
                          node.getLevelColor().withOpacity(0.8),
                          node.getLevelColor().withOpacity(0.3),
                        ],
                      ),
                    ),
                    child: const Icon(
                      Icons.layers,
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
                          '层级信息',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[400],
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '第 ${node.level + 1} 层 • 角度 ${(node.angle * 180 / math.pi).toStringAsFixed(1)}°',
                          style: TextStyle(
                            fontSize: 15,
                            color: node.getLevelColor(),
                            fontWeight: FontWeight.normal,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 显示视频信息
            if (node.data!.videos?.isNotEmpty ?? false) ...[
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
                        fontWeight: FontWeight.normal,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // 状态信息
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
                                fontWeight: FontWeight.normal,
                                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
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
                  fontWeight: FontWeight.normal,
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

// 扇形知识图谱导航栏
class FanMindMapNavBar extends StatelessWidget {
  final Animation<double> backgroundAnimation;
  final VoidCallback onRefresh;

  const FanMindMapNavBar({
    super.key,
    required this.backgroundAnimation,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF0A0A0F).withOpacity(0.95),
            const Color(0xFF1A1A2E).withOpacity(0.98),
          ],
        ),
        border: Border(
          top: BorderSide(
            color: const Color(0xFF00F5FF).withOpacity(0.3),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00F5FF).withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavButton(
                icon: Icons.refresh_rounded,
                label: '刷新',
                onTap: onRefresh,
              ),
              _buildNavButton(
                icon: Icons.donut_large,
                label: '扇形',
                onTap: () {},
                isActive: true,
              ),
              _buildNavButton(
                icon: Icons.info_outline,
                label: '说明',
                onTap: () => _showFanMindMapInfo(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: isActive
              ? LinearGradient(
                  colors: [
                    const Color(0xFF00F5FF).withOpacity(0.3),
                    const Color(0xFF1E90FF).withOpacity(0.3),
                  ],
                )
              : null,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive
                ? const Color(0xFF00F5FF).withOpacity(0.6)
                : const Color(0xFF00F5FF).withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isActive
                  ? const Color(0xFF00F5FF)
                  : const Color(0xFF00F5FF).withOpacity(0.7),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive
                    ? const Color(0xFF00F5FF)
                    : const Color(0xFF00F5FF).withOpacity(0.7),
                fontSize: 12,
                fontWeight: FontWeight.normal,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _showFanMindMapInfo(BuildContext context) {
  showDialog(
    context: context,
    barrierColor: Colors.black.withOpacity(0.8),
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0A0A0F),
              Color(0xFF1A1A2E),
              Color(0xFF16213E),
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
          children: [
            Row(
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
                    Icons.info_outline,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '扇形知识图谱说明',
                    style: TextStyle(
                                              fontSize: 20,
                        fontWeight: FontWeight.normal,
                        color: const Color(0xFF00F5FF),
                      shadows: [
                        Shadow(
                          color: const Color(0xFF00F5FF).withOpacity(0.8),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Color(0xFF00F5FF),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF00F5FF).withOpacity(0.1),
                    const Color(0xFF1E90FF).withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF00F5FF).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• 扇形布局：知识点以扇形方式辐射展开',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• 三层展开：自动展开至第三层，显示更多细节',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• 层级颜色：不同层级使用不同颜色标识',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• 节点交互：点击节点查看详情和学习内容',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
} 