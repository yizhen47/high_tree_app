import 'package:flutter/material.dart';
import 'package:flutter_application_1/tool/study_data.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

class ModeScreen extends StatefulWidget {
  const ModeScreen({super.key, required this.title});
  final String title;
  @override
  State<ModeScreen> createState() => _InnerState();
}

//这里是在一个页面中加了PageView，PageView可以载入更多的StatefulWidget或者StatelessWidget（也就是页面中加载其他页面作为子控件）
class _InnerState extends State<ModeScreen> {
  Widget _buildThirdTreeSelect(BuildContext context) {
    List<TDSelectOption> options = [];

    for (var i = 1; i <= 10; i++) {
      options.add(TDSelectOption(label: '选项$i', value: i, children: []));

      for (var j = 1; j <= 10; j++) {
        options[i - 1].children.add(
            TDSelectOption(label: '选项$i.$j', value: i * 10 + j, children: []));

        for (var k = 1; k <= 10; k++) {
          options[i - 1].children[j - 1].children.add(
              TDSelectOption(label: '选项$i.$j.$k', value: i * 100 + j * 10 + k));
        }
      }
    }

    return TDTreeSelect(
      options: options,
      // defaultValue: values3,
      onChange: (val, level) {
        print('$val, $level');
      },
    );
  }

  //这修改页面4的内容
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TDNavBar(title: '模式选择', onBack: () {}),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical, //
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(15),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "选择题目难度",
                    style: TextStyle(
                        fontSize: 18,
                        color: Colors.black,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            TDRadioGroup(
              selectId: '${StudyData.instance.getStudyDifficulty().index}',
              cardMode: true,
              direction: Axis.horizontal,
              rowCount: 3,
              directionalTdRadios: [
                TDRadio(
                  id: '${StudyDifficulty.easy.index}',
                  title: StudyDifficulty.easy.displayName,
                  cardMode: true,
                ),
                TDRadio(
                  id: '${StudyDifficulty.normal.index}',
                  title: StudyDifficulty.normal.displayName,
                  cardMode: true,
                ),
                TDRadio(
                  id: '${StudyDifficulty.hard.index}',
                  title: StudyDifficulty.hard.displayName,
                  cardMode: true,
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.all(15),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "选择模式",
                    style: TextStyle(
                        fontSize: 18,
                        color: Colors.black,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            TDRadioGroup(
              selectId: '${StudyData.instance.getStudyType().index}',
              cardMode: true,
              direction: Axis.horizontal,
              rowCount: 3,
              directionalTdRadios: [
                TDRadio(
                  id: '${StudyType.studyMode.index}',
                  title: StudyType.studyMode.getDisplayName(),
                  cardMode: true,
                ),
                TDRadio(
                  id: '${StudyType.testMode.index}',
                  title: StudyType.testMode.getDisplayName(),
                  cardMode: true,
                ),
                TDRadio(
                  id: '${StudyType.recommandMode.index}',
                  title: StudyType.recommandMode.getDisplayName(),
                  cardMode: true,
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.all(15),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "选择章节",
                    style: TextStyle(
                        fontSize: 18,
                        color: Colors.black,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            _buildThirdTreeSelect(context),
          ],
        ),
      ),
    );
  }
}
