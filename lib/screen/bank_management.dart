import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/screen/question.dart';
import 'package:flutter_application_1/tool/page_intent_trans.dart';
import 'package:flutter_application_1/tool/question/question_bank.dart';
import 'package:flutter_application_1/tool/question/question_controller.dart';
import 'package:flutter_application_1/tool/study_data.dart';
import 'package:flutter_application_1/tool/question/wrong_question_book.dart';
import 'package:flutter_application_1/widget/import_progress_dialog.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import 'package:path/path.dart' as path;

class BankManagementScreen extends StatefulWidget {
  const BankManagementScreen({super.key});
  
  @override
  State<BankManagementScreen> createState() => _BankManagementScreenState();
}

class _BankManagementScreenState extends State<BankManagementScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  List<String> selectIds = QuestionBank.getAllLoadedQuestionBankIds();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: TDNavBar(
        title: '题库管理',
        onBack: () => Navigator.of(context).pop(),
      ),
      body: Column(
        children: [
          TDTabBar(
            controller: _tabController,
            tabs: const [
              TDTab(text: '题库选择'),
              TDTab(text: '题库管理'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildBankChooseTab(),
                _buildBankManagerTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 题库选择标签页
  Widget _buildBankChooseTab() {
    return Column(
      children: [
        Expanded(
          child: FutureBuilder(
            future: QuestionBank.getAllImportedQuestionBanks(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }
              
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        "加载失败",
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "${snapshot.error}",
                        style: TextStyle(color: Colors.grey[500]),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }
              
              final questionBanks = snapshot.data ?? [];
              
              if (questionBanks.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.library_books_outlined, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        "暂无题库",
                        style: TextStyle(fontSize: 16, color: Colors.grey[600], fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "请先导入题库文件",
                        style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => _importQuestionBank(),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('导入题库', style: TextStyle(fontSize: 14)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        ),
                      ),
                    ],
                  ),
                );
              }
              
              return ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  Text(
                    "选择要使用的题库",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...questionBanks.map((bank) => _buildQuestionBankCard(bank)),
                ],
              );
            },
          ),
        ),
        _buildBottomActionBar(),
      ],
    );
  }

  Widget _buildQuestionBankCard(dynamic bank) {
    final isSelected = selectIds.contains(bank.id);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected ? Theme.of(context).primaryColor : Colors.grey[200]!,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            setState(() {
              if (isSelected) {
                selectIds.remove(bank.id);
              } else {
                selectIds.add(bank.id);
              }
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? Theme.of(context).primaryColor.withOpacity(0.1)
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    isSelected ? Icons.check_circle : Icons.library_books_outlined,
                    color: isSelected 
                        ? Theme.of(context).primaryColor
                        : Colors.grey[600],
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bank.displayName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isSelected 
                              ? Theme.of(context).primaryColor
                              : Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        bank.id,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: Theme.of(context).primaryColor,
                    size: 18,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomActionBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: selectIds.isNotEmpty 
                      ? Theme.of(context).primaryColor 
                      : Colors.grey[400],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                onPressed: selectIds.isNotEmpty ? () async {
                  TDToast.showLoadingWithoutText(context: context);
                  await _saveLoadedOption();
                  TDToast.dismissLoading();
                  
                  // 直接设置为智能推荐模式并跳转到question页面
                  StudyData.instance.studyType = StudyType.recommandMode;
                  StudyData.instance.currentPlanId = -1; // 使用所有计划
                  
                  Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const QuestionScreen(title: '')),
                      (route) => route.isFirst);
                } : null,
                icon: const Icon(Icons.play_arrow, size: 16),
                label: Text('开始学习 (${selectIds.length})', style: const TextStyle(fontSize: 14)),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              onPressed: () => _importQuestionBank(),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('导入', style: TextStyle(fontSize: 14)),
            ),
          ],
        ),
      ),
    );
  }

  // 题库管理标签页
  Widget _buildBankManagerTab() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _buildWrongQuestionSection(),
        const SizedBox(height: 16),
        _buildImportedBanksSection(),
      ],
    );
  }

  Widget _buildWrongQuestionSection() {
    final wrongCount = WrongQuestionBook.instance.getWrongQuestionIds().length;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.error_outline,
                    color: Colors.red[600],
                    size: 16,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '我的错题本',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '错题数量: $wrongCount',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: wrongCount > 10 ? () async {
                    var saveFilePath = await FilePicker.platform.saveFile(
                      dialogTitle: "请选择保存路径",
                      fileName: "wrong_questions.zip",
                    );
                    if (saveFilePath == null) return;
                    WrongQuestionBook.instance.exportWrongQuestion(saveFilePath);
                    TDToast.showSuccess('导出成功', context: context);
                  } : null,
                  icon: const Icon(Icons.download, size: 16),
                  label: const Text('导出', style: TextStyle(fontSize: 13)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              Container(width: 1, height: 32, color: Colors.grey[200]),
              Expanded(
                child: TextButton.icon(
                  onPressed: wrongCount > 0 ? () {
                    showGeneralDialog(
                      context: context,
                      pageBuilder: (BuildContext buildContext,
                          Animation<double> animation,
                          Animation<double> secondaryAnimation) {
                        return TDAlertDialog(
                            title: "清空错题本",
                            content: "确定清空错题本吗？清空的错题将无法恢复！",
                            rightBtnAction: () {
                              WrongQuestionBook.instance.clearWrongQuestion();
                              Navigator.of(context).pop();
                              setState(() {});
                            });
                      },
                    );
                  } : null,
                  icon: const Icon(Icons.clear_all, size: 16),
                  label: const Text('清空', style: TextStyle(fontSize: 13)),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red[600],
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImportedBanksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '已导入题库',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => _importQuestionBank(),
              icon: const Icon(Icons.add, size: 14),
              label: const Text('导入新题库', style: TextStyle(fontSize: 13)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        FutureBuilder(
          future: QuestionBank.getAllImportedQuestionBanks(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            
            if (snapshot.hasError) {
              return Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    "加载失败: ${snapshot.error}",
                    style: TextStyle(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            
            final questionBanks = snapshot.data ?? [];
            
            if (questionBanks.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.folder_open, size: 48, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        '暂无已导入的题库',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              );
            }
            
            return Column(
              children: questionBanks.map((bank) => _buildBankManagementCard(bank)).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBankManagementCard(dynamic bank) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                Icons.library_books,
                color: Theme.of(context).primaryColor,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bank.displayName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '版本: ${bank.version}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    bank.id,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'delete') {
                  _deleteQuestionBank(bank);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red, size: 16),
                      SizedBox(width: 6),
                      Text('删除', style: TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
              ],
              child: Icon(Icons.more_vert, color: Colors.grey[600], size: 18),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteQuestionBank(dynamic bank) {
    showGeneralDialog(
      context: context,
      pageBuilder: (BuildContext buildContext,
          Animation<double> animation,
          Animation<double> secondaryAnimation) {
        return TDAlertDialog(
            title: "删除题库",
            content: "确定删除题库\"${bank.displayName}\"吗？删除的题库将无法恢复！",
            rightBtnAction: () async {
              Navigator.of(context).pop();
              await QuestionBank.deleteQuestionBank(bank.id);
              setState(() {});
              TDToast.showSuccess('题库已删除', context: context);
            });
      },
    );
  }

  Future<void> _saveLoadedOption() async {
    List<Future> futures = [];
    var lastSelectIds = QuestionBank.getAllLoadedQuestionBankIds();
    for (var id in lastSelectIds) {
      if (!selectIds.contains(id)) {
        futures.add((await QuestionBank.getQuestionBankById(id)).removeFromData());
      }
    }
    for (var id in selectIds) {
      if (!lastSelectIds.contains(id)) {
        futures.add((await QuestionBank.getQuestionBankById(id)).loadIntoData());
      }
    }
    await Future.wait(futures);
    // 自动设置为智能推荐模式
    StudyData.instance.studyType = StudyType.recommandMode;
    StudyData.instance.studySection = null;

    // Update learning plan based on the newly selected question banks
    LearningPlanManager.instance.updateLearningPlan();
  }

  Future<void> _importQuestionBank() async {
    var fromFilePath = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.custom,
        allowedExtensions: ["zip", "rar", "7z"],
        dialogTitle: "选择题库文件 (支持 .zip, .rar, .7z 格式)");
    if (fromFilePath == null) return;

    await _importWithProgress(File(fromFilePath.files.single.path!));
  }

  Future<void> _importWithProgress(File file) async {
    final fileSizeMB = await file.length() / 1024 / 1024;
    final fileName = path.basename(file.path);

    // 创建进度流控制器
    late StreamController<double> progressController;
    progressController = StreamController<double>.broadcast();

    bool importCompleted = false;
    String? errorMessage;

    // 显示进度弹窗
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => ImportProgressDialog(
          fileName: fileName,
          fileSizeMB: fileSizeMB,
          progressStream: progressController.stream,
          onCancel: fileSizeMB > 500
              ? () {
                  // 对于大文件提供取消选项
                  Navigator.of(context).pop();
                  progressController.close();
                }
              : null,
        ),
      );
    }

    try {
      // 执行导入
      await QuestionBank.importQuestionBank(file, onProgress: (progress) {
        if (!progressController.isClosed) {
          progressController.add(progress);
        }
      });

      importCompleted = true;

      // 等待一小段时间显示完成状态
      await Future.delayed(const Duration(milliseconds: 800));
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      progressController.close();

      // 关闭进度弹窗
      if (mounted) {
        Navigator.of(context).pop();
      }
    }

    // 显示结果
    if (mounted) {
      if (importCompleted) {
        TDToast.showSuccess('导入完毕', context: context);
        setState(() {}); // 刷新列表
      } else {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('导入失败'),
            content: SingleChildScrollView(child: Text(errorMessage ?? '未知错误')),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('好的'),
              ),
            ],
          ),
        );
      }
    }
  }
} 