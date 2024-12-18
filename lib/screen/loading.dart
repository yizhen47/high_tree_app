import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/tool/question_bank.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';


class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key, required this.title});
  final String title;
  @override
  State<LoadingScreen> createState() => _InnerState();
}

//这里是在一个页面中加了PageView，PageView可以载入更多的StatefulWidget或者StatelessWidget（也就是页面中加载其他页面作为子控件）
class _InnerState extends State<LoadingScreen> {
  List<String> selectIds = QuestionBank.getAllLoadedQuestionBankIds();
  List<String> lastSelectIds = QuestionBank.getAllLoadedQuestionBankIds();
  //这修改页面2的内容
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TDNavBar(title: ' ', onBack: () {}),
      body: Column(
        children: [
          const TDLoading(
            size: TDLoadingSize.small,
            icon: TDLoadingIcon.circle,
          ),
          const TDLoading(
            size: TDLoadingSize.small,
            icon: TDLoadingIcon.activity,
          ),
          TDLoading(
            size: TDLoadingSize.small,
            icon: TDLoadingIcon.point,
            iconColor: TDTheme.of(context).brandNormalColor,
          ),
        ],
      ),
    );
  }
}
