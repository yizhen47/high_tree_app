import 'package:flutter/material.dart';
import 'package:flutter_application_1/screen/question_card.dart';
import 'package:flutter_application_1/tool/question/question_bank.dart';
import 'package:flutter_application_1/tool/question/question_controller.dart';
import 'package:flutter_application_1/tool/question/wrong_question_book.dart';
import 'package:flutter_application_1/widget/latex.dart';
import 'package:flutter_application_1/widget/question_card/question_card_widget.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

class WrongQuestionScreen extends StatefulWidget {
  const WrongQuestionScreen({super.key});
  @override
  State<WrongQuestionScreen> createState() => _WrongQuestionScreenInnerState();
}

class _WrongQuestionScreenInnerState extends State<WrongQuestionScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: TDNavBar(title: '错题查看', onBack: () {}),
        body: const WrongQuestionWidget());
  }
}

class WrongQuestionWidget extends StatefulWidget {
  const WrongQuestionWidget({super.key});
  @override
  State<WrongQuestionWidget> createState() => _WrongQuestionWidthInnerState();
}

class _WrongQuestionWidthInnerState extends State<WrongQuestionWidget> {
  // 分类方式：0-按知识点分类，1-按掌握程度分类
  int _categoryMode = 0;
  
  // 根据掌握程度获取颜色
  Color _getMasteryColor(double mastery) {
    if (mastery < 0.4) {
      return Colors.redAccent; // 需加强
    } else if (mastery < 0.7) {
      return Colors.orange; // 基本掌握
    } else {
      return Colors.green; // 熟练掌握
    }
  }
  
  // 计算题目掌握程度
  double _calculateQuestionMastery(String questionId) {
    if (!WrongQuestionBook.instance.hasQuestion(questionId)) {
      return 0.1; // 没有做过，掌握度很低
    }
    
    final questionData = WrongQuestionBook.instance.getQuestion(questionId);
    final tryTimes = questionData.tryCompleteTimes;
    
    if (WrongQuestionBook.instance.hasWrongQuestion(questionId)) {
      // 仍在错题本中，掌握度较低，但根据尝试次数有所提升
      return (0.2 + (tryTimes * 0.1)).clamp(0.1, 0.5);
    } else {
      // 不在错题本中（已掌握），根据尝试次数计算掌握程度
      return (0.6 + (tryTimes * 0.1)).clamp(0.6, 1.0);
    }
  }

  writeNote({filteredList, index, screenWidth, screenHeight, context}) {
    Navigator.of(context).push(
      TDSlidePopupRoute(
        slideTransitionFrom: SlideTransitionFrom.center,
        builder: (_) {
          final TextEditingController laTeXInputController = TextEditingController(
              text: r'What do you think about $L'
                  '\''
                  r' = {L}{\sqrt{1-\frac{v^2}{c^2}}}$ ?'
                  r'\n'
                  r'And some display $\LaTeX$: $$\boxed{\rm{A function: } f(x) = \frac{5}{3} \cdot x}$$');

          // 初始化逻辑保持不变
          if (WrongQuestionBook.instance
                      .getQuestion(filteredList[index]['id']!)
                      .note !=
                  null &&
              WrongQuestionBook.instance
                  .getQuestion(filteredList[index]['id']!)
                  .note!
                  .isNotEmpty) {
            laTeXInputController.text = WrongQuestionBook.instance
                .getQuestion(filteredList[index]['id']!)
                .note!;
          }

          var latexText = laTeXInputController.text;

          return StatefulBuilder(
            builder: (context, innerSetState) {
              return TDPopupCenterPanel(
                radius: 24, // 增加圆角
                child: SizedBox(
                  width: screenWidth - 40, // 增加弹窗宽度
                  height: screenHeight - 100, // 增加弹窗高度
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 30, 20, 20),
                    child: Scaffold(
                      resizeToAvoidBottomInset: true,
                      backgroundColor: Colors.white,
                      body: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 标题栏
                          Row(
                            children: [
                              Icon(Icons.edit_note,
                                  color: Colors.blue[800], size: 24),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                '编辑笔记',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                                ),
                              ),
                              // 关闭按钮
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
                          const SizedBox(height: 20),

                          // 预览区域
                          Expanded(
                            flex: 4,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 6,
                                    offset: Offset(0, 2),
                                  )
                                ],
                              ),
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('预览',
                                      style: TextStyle(
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.w500)),
                                  const SizedBox(height: 10),
                                  Expanded(
                                    child: SingleChildScrollView(
                                      physics: const BouncingScrollPhysics(),
                                      child: LaTeX(
                                        laTeXCode: Text(
                                          latexText,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontFamily: 'FiraCode', // 使用等宽字体
                                            color: Colors.blueGrey[800],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // 输入区域
                          Expanded(
                            flex: 3,
                            child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: Colors.blue[100]!, width: 1.5),
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: Colors.blue[200]!, width: 1.5),
                                  ),
                                  child: TextField(
                                    controller: laTeXInputController,
                                    maxLines: 8,
                                    style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.blue[900],
                                        height: 1.4),
                                    decoration: InputDecoration(
                                      hintText: '输入LaTeX公式...',
                                      hintStyle: TextStyle(
                                          color: Colors.grey[400],
                                          fontSize: 14,
                                          fontStyle: FontStyle.italic),
                                      border: InputBorder.none,
                                      contentPadding: const EdgeInsets.all(16),
                                      suffixIcon: laTeXInputController
                                              .text.isNotEmpty
                                          ? IconButton(
                                              icon: const Icon(Icons.clear,
                                                  size: 20),
                                              onPressed: () {
                                                laTeXInputController.clear();
                                                innerSetState(
                                                    () => latexText = '');
                                              },
                                            )
                                          : null,
                                    ),
                                    onChanged: (text) =>
                                        innerSetState(() => latexText = text),
                                  ),
                                )),
                          ),

                          const SizedBox(height: 25),
                          Row(
                            children: [
                              Expanded(
                                child: TextButton(
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      side: BorderSide(
                                          color: Colors.grey[300]!), // 线框样式
                                    ),
                                  ),
                                  onPressed: () => Navigator.pop(context),
                                  child: Text('取消',
                                      style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 15,
                                          letterSpacing: 1.2)),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextButton(
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    backgroundColor: Colors.blue[50], // 浅色背景
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed: () {
                                    final questionId =
                                        filteredList[index]['id'];
                                    WrongQuestionBook.instance
                                        .mksureQuestion(questionId);
                                    WrongQuestionBook.instance.updateQuestion(
                                        questionId,
                                        WrongQuestionBook.instance
                                            .getQuestion(questionId)
                                          ..note = latexText);
                                    setState(() {});
                                    Navigator.pop(context);
                                  },
                                  child: Text('保存',
                                      style: TextStyle(
                                          color: Colors.blue[800],
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                          letterSpacing: 1.2)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // 显示删除确认弹窗
  Future<void> _showDeleteConfirmDialog(String questionId) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // 用户必须点击按钮才能关闭对话框
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('删除确认'),
          content: const Text('确定要删除这道错题吗？删除后无法恢复。'),
          actions: <Widget>[
            TextButton(
              child: const Text('取消'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text(
                '删除',
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                WrongQuestionBook.instance.removeWrongQuestion(questionId);
                setState(() {});
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    var screenWidth = MediaQuery.of(context).size.width;
    var screenHeight = MediaQuery.of(context).size.height;

    List<Map<String, dynamic>> list;
    List<Map<String, dynamic>> reFreshData() {
      list = List.from(
          WrongQuestionBook.instance.getWrongQuestionIds().map((action) {
        var q = WrongQuestionBook.instance.getWrongQuestion(action);
        return {
          'id': action,
          'title': q.question["q"],
          "note": q.fromKonwledgePoint.last,
          'description': q.fromDisplayName,
          "data": q,
        };
      }));
      return list;
    }

    list = reFreshData();

    return Column(
      children: [
        // 顶部控制栏
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TDSearchBar(
            placeHolder: "输入关键词",
            style: TDSearchStyle.square,
            onTextChanged: (String text) {
              // Search functionality might need reimplementation for categorized view
            },
          ),
        ),
        
        // 掌握程度说明卡片
        _buildMasteryLegend(),
        
        // 分类方式选择
        _buildCategoryModeSelector(),
        
        // 内容区域
        Expanded(
          child: _buildGridView(list, screenWidth, screenHeight),
        ),
      ],
    );
  }
  
  // 构建分类方式选择器
  Widget _buildCategoryModeSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          const Text(
            '分类方式：',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildCategoryModeButton(
                      text: '按知识点分类',
                      isSelected: _categoryMode == 0,
                      onTap: () => setState(() => _categoryMode = 0),
                    ),
                  ),
                  Expanded(
                    child: _buildCategoryModeButton(
                      text: '按掌握程度分类',
                      isSelected: _categoryMode == 1,
                      onTap: () => setState(() => _categoryMode = 1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // 构建分类方式按钮
  Widget _buildCategoryModeButton({
    required String text,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor : null,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }

  // 构建掌握程度说明
  Widget _buildMasteryLegend() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '掌握程度分级',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildLegendItem(
                color: Colors.redAccent,
                label: '需加强',
                description: '< 40%',
              ),
              _buildLegendItem(
                color: Colors.orange,
                label: '基本掌握',
                description: '40% - 70%',
              ),
              _buildLegendItem(
                color: Colors.green,
                label: '熟练掌握',
                description: '> 70%',
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  // 构建图例项
  Widget _buildLegendItem({
    required Color color,
    required String label,
    required String description,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              description,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  // 构建网格视图
  Widget _buildGridView(
    List<Map<String, dynamic>> list,
    double screenWidth,
    double screenHeight,
  ) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.quiz_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              '暂无错题',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '继续学习，加油！',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }
    
    // 根据分类模式进行分组
    final Map<String, List<Map<String, dynamic>>> groups = {};
    
    for (var question in list) {
      String category;
      if (_categoryMode == 0) {
        // 按知识点分类
        category = question['note'] as String;
      } else {
        // 按掌握程度分类
        final questionId = question['id'] as String;
        final mastery = _calculateQuestionMastery(questionId);
        
        if (mastery < 0.4) {
          category = '需加强 (< 40%)';
        } else if (mastery < 0.7) {
          category = '基本掌握 (40% - 70%)';
        } else {
          category = '熟练掌握 (> 70%)';
        }
      }
      
      if (groups[category] == null) {
        groups[category] = [];
      }
      groups[category]!.add(question);
    }
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: groups.entries.map((entry) {
        final categoryName = entry.key;
        final questions = entry.value;
        
        if (questions.isEmpty) return const SizedBox.shrink();
        
        Color categoryColor;
        if (_categoryMode == 1) {
          // 按掌握程度分类时使用掌握程度颜色
          if (categoryName.contains('需加强')) {
            categoryColor = Colors.redAccent;
          } else if (categoryName.contains('基本掌握')) {
            categoryColor = Colors.orange;
          } else {
            categoryColor = Colors.green;
          }
        } else {
          // 按知识点分类时使用主题色
          categoryColor = Theme.of(context).primaryColor;
        }
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 分类标题
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: categoryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: categoryColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(
                              width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: categoryColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$categoryName (${questions.length}题)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: categoryColor,
                    ),
                  ),
                ],
              ),
            ),
            
            // 题目网格
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 60, // 每个卡片最大宽度60px，自动计算每行数量
                childAspectRatio: 1,
                crossAxisSpacing: 8, // 横向间距
                mainAxisSpacing: 16, // 纵向间距
              ),
              itemCount: questions.length,
              itemBuilder: (context, index) {
                final question = questions[index];
                final questionId = question['id'] as String;
                final mastery = _calculateQuestionMastery(questionId);
                // 计算在原始列表中的索引
                final originalIndex = list.indexWhere((q) => q['id'] == questionId);
                
                return InkWell(
                  onTap: () {
                    // 显示题目详情
                        Navigator.of(context).push(
                          TDSlidePopupRoute(
                            slideTransitionFrom: SlideTransitionFrom.center,
                            builder: (_) {
                          SingleQuestionData q = question['data'];
                              return TDPopupCenterPanel(
                                radius: 15,
                                backgroundColor: Colors.transparent,
                                closeClick: () {
                                  Navigator.maybePop(context);
                                },
                                child: SizedBox(
                                  width: screenWidth - 80,
                                  height: screenHeight - 150,
                                  child: buildQuestionCard(
                                      context,
                                      q.getKonwledgePoint(),
                                      q.question['q']!,
                                      q.question['w'],
                                      WrongQuestionBook.instance
                                          .getQuestion(q.question['id']!)
                                          .note,
                                      q,
                                      _findQuestionBankByFromId(q.fromId)),
                                ),
                              );
                            },
                          ),
                        );
                      },
                  child: Container(
                    decoration: BoxDecoration(
                      color: _getMasteryColor(mastery),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: _getMasteryColor(mastery).withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${originalIndex + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                              fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${(mastery * 100).round()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                          ),
                        ],
                      ),
                ),
              );
            },
          ),
            
            const SizedBox(height: 32),
      ],
        );
      }).toList(),
    );
  }

  // 根据题目的fromId查找对应的题库
  QuestionBank? _findQuestionBankByFromId(String fromId) {
    try {
      // 导入LearningPlanManager以访问已加载的题库
      final questionBanks = LearningPlanManager.instance.questionBanks;
      
      // 在已加载的题库中查找匹配的题库
      for (var bank in questionBanks) {
        if (bank.id == fromId) {
          return bank;
        }
      }
      
      // 如果在已加载的题库中找不到，返回null
      // 这种情况下，VideoContentWidget会正常处理null的情况
      return null;
    } catch (e) {
      print('Error finding question bank by fromId $fromId: $e');
      return null;
    }
  }

}
