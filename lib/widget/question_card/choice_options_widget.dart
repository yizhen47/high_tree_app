import 'package:flutter/material.dart';
import 'package:extended_text/extended_text.dart';
import 'package:flutter_application_1/widget/latex.dart';
import 'package:latext/latext.dart';
import 'package:flutter_application_1/tool/question/question_bank.dart';
import 'latex_config.dart';

class ChoiceOptionsWidget extends StatefulWidget {
  final List<dynamic> options;
  final SingleQuestionData? questionData;

  const ChoiceOptionsWidget({
    Key? key,
    required this.options,
    this.questionData,
  }) : super(key: key);

  @override
  State<ChoiceOptionsWidget> createState() => _ChoiceOptionsWidgetState();
}

class _ChoiceOptionsWidgetState extends State<ChoiceOptionsWidget> {
  final ValueNotifier<Set<String>> selectedOptions = ValueNotifier({});
  final ValueNotifier<bool> answerChecked = ValueNotifier(false);

  @override
  Widget build(BuildContext context) {
    if (widget.questionData == null) return const SizedBox.shrink();

    final dynamic correctAnswer = widget.questionData!.question['answer'];
    final bool isMultipleChoice = correctAnswer is List;

    void handleTap(String key) {
      if (answerChecked.value) return; // 答案已检查，不允许修改

      final currentSelection = Set<String>.from(selectedOptions.value);
      if (isMultipleChoice) {
        if (currentSelection.contains(key)) {
          currentSelection.remove(key);
        } else {
          currentSelection.add(key);
        }
      } else {
        currentSelection.clear();
        currentSelection.add(key);
      }
      selectedOptions.value = currentSelection;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        ...widget.options.map((option) {
          final String key = option['key'].toString();
          final String value = option['value'].toString();

          return ValueListenableBuilder<Set<String>>(
            valueListenable: selectedOptions,
            builder: (context, selected, _) {
              final bool isSelected = selected.contains(key);

              return ValueListenableBuilder<bool>(
                valueListenable: answerChecked,
                builder: (context, checked, _) {
                  Color? tileColor;
                  Color borderColor = Colors.grey.shade300;
                  Color keyColor = Colors.white;
                  Color keyBackgroundColor = Colors.grey.shade400;

                  if (checked) {
                    final bool isCorrect = isMultipleChoice
                        ? (correctAnswer as List).contains(key)
                        : correctAnswer == key;

                    if (isCorrect) {
                      // 正确答案显示绿色
                      tileColor = Colors.green.withOpacity(0.1);
                      borderColor = Colors.green.shade300;
                      keyBackgroundColor = Colors.green;
                    } else if (isSelected && !isCorrect) {
                      // 用户选错的答案显示红色
                      tileColor = Colors.red.withOpacity(0.1);
                      borderColor = Colors.red.shade300;
                      keyBackgroundColor = Colors.red;
                    }
                  } else if (isSelected) {
                    // 用户选中但还未检查答案
                    tileColor = Theme.of(context).primaryColor.withOpacity(0.1);
                    borderColor = Theme.of(context).primaryColor;
                    keyBackgroundColor = Theme.of(context).primaryColor;
                  }

                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 8),
                    color: tileColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: borderColor, width: 1),
                    ),
                    child: InkWell(
                      onTap: () => handleTap(key),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: keyBackgroundColor,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                key,
                                style: TextStyle(
                                  color: keyColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: LaTeX(
                                laTeXCode: ExtendedText(convertLatexDelimiters(value)),
                                equationStyle: TextStyle(
                                  fontSize: 13,
                                  fontWeight: latexStyleConfig.fontWeight,
                                  fontFamily: latexStyleConfig.mathFontFamily,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        }).toList(),
        const SizedBox(height: 16),
        ValueListenableBuilder(
          valueListenable: answerChecked,
          builder: (context, checked, _) {
            if (checked) {
              final bool isCorrect = isMultipleChoice
                  ? Set.from(correctAnswer).containsAll(selectedOptions.value) &&
                      selectedOptions.value.containsAll(Set.from(correctAnswer))
                  : selectedOptions.value.firstOrNull == correctAnswer;

              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isCorrect ? Icons.check_circle : Icons.cancel,
                    color: isCorrect ? Colors.green : Colors.red,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isCorrect ? '回答正确' : '回答错误',
                    style: TextStyle(
                      color: isCorrect ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              );
            }
            return ElevatedButton(
              onPressed: () {
                if (selectedOptions.value.isNotEmpty) {
                  answerChecked.value = true;
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('请先选择一个选项'),
                    duration: Duration(seconds: 2),
                  ));
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('检查答案', style: TextStyle(color: Colors.white)),
            );
          },
        )
      ],
    );
  }
} 