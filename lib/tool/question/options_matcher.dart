import 'package:flutter/material.dart';
import 'package:extended_text/extended_text.dart';
import 'package:latext/latext.dart';
import 'dart:math' show min;

/// 选项类，用于表示多选题的选项
class ChoiceOption {
  final String label; // A, B, C, D等
  final String content; // 选项内容
  final bool isCorrect; // 是否为正确答案
  final String answerInfo; // 答案识别相关调试信息
  bool isSelected = false; // 用户是否选择了此选项

  ChoiceOption({
    required this.label,
    required this.content,
    required this.isCorrect,
    this.isSelected = false,
    this.answerInfo = '',
  });
}

/// 用于记录选项匹配的辅助类
class OptionMatch {
  final String label;       // 选项标签 (A, B, C, D)
  final String content;     // 选项内容
  final int start;          // 匹配开始位置
  final int end;            // 匹配结束位置
  final String originalText; // 原始匹配文本
  final String type;        // 匹配类型

  OptionMatch({
    required this.label,
    required this.content,
    required this.start,
    required this.end,
    required this.originalText,
    required this.type,
  });
}

/// 选项识别结果类
class ChoiceOptionsResult {
  final List<ChoiceOption> options;
  final String cleanedQuestion;

  ChoiceOptionsResult({
    required this.options,
    required this.cleanedQuestion,
  });
}

/// 选项匹配工具类
class OptionsMatcher {
  /// 识别并处理选项
  static ChoiceOptionsResult extractChoiceOptions(String question, String? answer) {
    // 定义不同的ABCD选项格式
    final List<Map<String, dynamic>> optionFormats = [
      {
        'pattern': r'([A-D])[.、．]\s*([^\n\r]+?)(?=\s+[B-D][.、．]|\s*$)',  // A. B. 格式，确保在下一个选项或结尾处停止
        'type': 'standard'
      },
      {
        'pattern': r'（([A-D])）\s*([^\n\r]+?)(?=\s+（[B-D]）|\s*$)',        // （A）（B）格式
        'type': 'chinese_parenthesis'
      },
      {
        'pattern': r'\(([A-D])\)\s*([^\n\r]+?)(?=\s+\([B-D]\)|\s*$)',       // (A)(B)格式
        'type': 'parenthesis'
      },
      {
        'pattern': r'([A-D])（([^（）\n\r]+?)）',                             // A（内容）格式
        'type': 'label_with_chinese_parenthesis'
      },
      {
        'pattern': r'([A-D])\(([^()\n\r]+?)\)',                             // A(内容)格式
        'type': 'label_with_parenthesis'
      },
    ];
    
    // 识别题目中的选项
    List<OptionMatch> optionMatches = [];
    String activePattern = '';
    
    // 尝试每种格式
    for (final format in optionFormats) {
      final pattern = format['pattern'] as String;
      final regex = RegExp(pattern);
      final matches = regex.allMatches(question);
      
      if (matches.isNotEmpty) {
        // 找到匹配，记录所有匹配的选项
        for (final match in matches) {
          final label = match.group(1) ?? '';
          final content = match.group(2) ?? '';
          // 记录匹配位置和原始文本，以便后续从题目中删除
          optionMatches.add(OptionMatch(
            label: label,
            content: content,
            start: match.start,
            end: match.end,
            originalText: question.substring(match.start, match.end),
            type: format['type'] as String,
          ));
        }
        activePattern = pattern;
        break; // 一旦找到匹配的格式，就停止尝试其他格式
      }
    }
    
    // 如果没找到选项，返回原始题目
    if (optionMatches.isEmpty) {
      return ChoiceOptionsResult(options: [], cleanedQuestion: question);
    }
    
    // 从答案中提取正确选项（支持多种正确答案格式）
    String correctOption = '';
    String answerDebugInfo = ''; // 用于调试
    
    if (answer != null) {
      // 增加更多答案格式支持
      final correctAnswerPatterns = [
        RegExp(r'正确[选答]案[:：]?\s*([A-D])'),      // 正确答案: A 格式
        RegExp(r'[选答]案[:：]?\s*([A-D])'),          // 答案: A 格式
        RegExp(r'[选答]案是\s*([A-D])'),             // 答案是A格式
        RegExp(r'答[：:]\s*([A-D])'),                // 答：A 格式
        RegExp(r'[（\(]([A-D])[）\)]'),              // (A)或（A）格式
        RegExp(r'答案[为是:：]?[：:\s]*([A-D])'),     // 答案为A 或 答案是A
        RegExp(r'选([A-D])'),                        // 选A
        RegExp(r'([A-D])(?=是?正确)'),               // A正确 或 A是正确
        RegExp(r'([A-D])(?=选?项)'),                 // A选项 或 A项
        // 寻找单独的A/B/C/D字母，通常出现在答案开头或结尾
        RegExp(r'^([A-D])$'),                       // 整行只有一个字母
        RegExp(r'^([A-D])[^A-Za-z]'),               // 以A开头，后跟非字母
        RegExp(r'[^A-Za-z]([A-D])$'),               // 以A结尾，前面是非字母
      ];
      
      // 先直接在答案中寻找 A B C D
      for (final letter in ['A', 'B', 'C', 'D']) {
        if (answer.contains(letter)) {
          // 只是记录可能的答案，后面再进一步分析
          if (correctOption.isEmpty) correctOption = letter;
          answerDebugInfo += '$letter, ';
        }
      }
      
      // 使用正则表达式进一步分析
      for (final pattern in correctAnswerPatterns) {
        final correctMatch = pattern.firstMatch(answer);
        if (correctMatch != null && correctMatch.groupCount >= 1) {
          correctOption = correctMatch.group(1) ?? '';
          answerDebugInfo = '通过模式 ${pattern.pattern} 匹配到答案: $correctOption';
          break;
        }
      }
      
      // 如果没找到正确答案，尝试分析整个答案文本
      if (correctOption.isEmpty) {
        // 分析答案内容，查找更复杂的模式
        final lowerAnswer = answer.toLowerCase();
        if (lowerAnswer.contains('正确答案') || lowerAnswer.contains('答案是') || 
            lowerAnswer.contains('答：') || lowerAnswer.contains('答:')) {
          
          // 有明确答案标记，但正则没匹配到，打印调试信息
          print('答案识别失败，原始答案内容: $answer');
          answerDebugInfo = '无法从答案中提取正确选项';
        } else {
          answerDebugInfo = '答案文本中未包含明确的正确答案标记';
        }
      }
    } else {
      answerDebugInfo = '答案为空';
    }
    
    // 创建选项列表
    final List<ChoiceOption> options = [];
    final Set<String> processedLabels = {}; // 防止重复添加选项
    
    // 按匹配的顺序处理选项
    for (final match in optionMatches) {
      // 确保选项标签和内容都不为空，且标签未被处理过
      if (match.label.isNotEmpty && match.content.isNotEmpty && !processedLabels.contains(match.label)) {
        processedLabels.add(match.label);
        options.add(ChoiceOption(
          label: match.label,
          content: match.content,
          isCorrect: match.label == correctOption,
          answerInfo: answerDebugInfo,  // 添加调试信息
        ));
      }
    }
    
    // 按A、B、C、D顺序排序选项
    options.sort((a, b) => a.label.compareTo(b.label));
    
    // 如果没有成功解析出选项，返回原始题目
    if (options.isEmpty) {
      return ChoiceOptionsResult(options: [], cleanedQuestion: question);
    }
    
    // 使用记录的匹配位置从题目中移除选项文本
    // 为避免索引偏移问题，从后往前移除
    optionMatches.sort((a, b) => b.start.compareTo(a.start));
    
    String cleanedQuestion = question;
    for (final match in optionMatches) {
      final before = cleanedQuestion.substring(0, match.start);
      final after = cleanedQuestion.substring(match.end);
      cleanedQuestion = before + after;
    }
    
    // 清理额外的空行
    cleanedQuestion = cleanedQuestion.replaceAll(RegExp(r'\n\s*\n'), '\n');
    cleanedQuestion = cleanedQuestion.trim();
    
    // 打印调试信息
    print('题目识别了 ${options.length} 个选项，正确答案: $correctOption, 信息: $answerDebugInfo');
    if (answer != null) {
      print('答案原文: ${answer.substring(0, min(50, answer.length))}${answer.length > 50 ? '...' : ''}');
    }
    
    return ChoiceOptionsResult(options: options, cleanedQuestion: cleanedQuestion);
  }

  /// 构建选项UI组件
  static Widget buildChoiceOptionsUI(List<ChoiceOption> options, BuildContext context, TextStyle? equationStyle) {
    // 如果没有选项，返回空容器
    if (options.isEmpty) {
      return const SizedBox.shrink();
    }
    
    // 查找是否有正确选项被识别出来
    final hasCorrectOption = options.any((option) => option.isCorrect);
    
    // 使用StatefulBuilder来管理选项状态
    return StatefulBuilder(
      builder: (context, setState) {
        return Container(
          margin: const EdgeInsets.only(top: 12, bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 添加答案识别状态提示
              if (!hasCorrectOption)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.yellow.shade100,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.orange.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 14, color: Colors.orange.shade700),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '未能识别出正确答案，请查看解析',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              
              // 选项列表
              ...options.map((option) {
                // 根据选择状态和正确性决定颜色
                Color backgroundColor = Colors.white;
                Color borderColor = Colors.grey.shade300;
                
                // 如果选项被选中了，显示正确或错误的状态
                if (option.isSelected) {
                  if (option.isCorrect) {
                    backgroundColor = Colors.green.shade50;
                    borderColor = Colors.green;
                  } else {
                    backgroundColor = Colors.red.shade50;
                    borderColor = Colors.red;
                  }
                }
                
                return InkWell(
                  onTap: () {
                    setState(() {
                      option.isSelected = !option.isSelected;
                      
                      // 如果是单选题模式，取消其他选项的选中状态
                      if (option.isSelected) {
                        for (var other in options) {
                          if (other != option) {
                            other.isSelected = false;
                          }
                        }
                      }
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 6), 
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), 
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: borderColor, width: 1.0),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 选项标签 (A/B/C/D)
                        Container(
                          width: 22, 
                          height: 22, 
                          margin: const EdgeInsets.only(right: 8, top: 1), 
                          decoration: BoxDecoration(
                            color: option.isSelected 
                                ? (option.isCorrect ? Colors.green : Colors.red) 
                                : Colors.grey.shade200,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            option.label,
                            style: TextStyle(
                              color: option.isSelected ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.bold,
                              fontSize: 12, 
                            ),
                          ),
                        ),
                        
                        // 选项内容
                        Expanded(
                          child: LaTexT(
                            laTeXCode: ExtendedText(
                              option.content,
                              style: TextStyle(
                                fontSize: 13, 
                                height: 1.3, 
                                color: Colors.grey.shade800,
                              ),
                            ),
                            equationStyle: equationStyle ?? const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              fontFamily: 'CMU',
                              fontStyle: FontStyle.italic,
                            ),
                            delimiter: r'$',
                            displayDelimiter: r'$$',
                          ),
                        ),
                        
                        // 正确/错误图标
                        if (option.isSelected)
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Icon(
                              option.isCorrect ? Icons.check_circle : Icons.cancel,
                              color: option.isCorrect ? Colors.green : Colors.red,
                              size: 20,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
} 