import 'package:flutter/material.dart';
import 'package:flutter_application_1/tool/question/question_bank.dart';

// 导入重构后的组件
import 'package:flutter_application_1/widget/question_card/question_card_widget.dart';
import 'package:flutter_application_1/widget/question_card/knowledge_card_widget.dart';

// 为了向后兼容，重新导出主要函数
export 'package:flutter_application_1/widget/question_card/question_card_widget.dart' show buildQuestionCard;
export 'package:flutter_application_1/widget/question_card/knowledge_card_widget.dart' show buildKnowledgeCard, showKnowledgeCard;

// 保持原有的函数签名，但实际调用新的组件
Card buildQuestionCardLegacy(
    BuildContext context, 
    final String knowledgepoint,
    final String question, 
    final String? answer, 
    final String? note,
    [final SingleQuestionData? currentQuestionData]) {
  return buildQuestionCard(context, knowledgepoint, question, answer, note, currentQuestionData);
}

Card buildKnowledgeCardLegacy(BuildContext context, final String index,
    final String title, final String knowledge,
    {final String? images}) {
  return buildKnowledgeCard(context, index, title, knowledge, images: images);
}

void showKnowledgeCardLegacy(BuildContext context, Section section) {
  showKnowledgeCard(context, section);
}
