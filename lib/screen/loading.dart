import 'package:flutter/material.dart';
import 'package:flutter_application_1/screen/question.dart';
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
  @override
  void initState() {
    super.initState();
    
    Future.delayed(const Duration(milliseconds: 100), () {
        // ignore: use_build_context_synchronously
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const QuestionScreen(title: '')));
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
     
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
