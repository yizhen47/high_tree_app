import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/screen/about.dart';
import 'package:flutter_application_1/tool/study_data.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import 'package:yako_theme_switch/yako_theme_switch.dart';
import 'package:rebirth/rebirth.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});
  @override
  State<SettingScreen> createState() => _InnerState();
}

//这里是在一个页面中加了PageView，PageView可以载入更多的StatefulWidget或者StatelessWidget（也就是页面中加载其他页面作为子控件）
class _InnerState extends State<SettingScreen> {
  Color dialogPickerColor =
      Colors.blueAccent; // Define the dialogPickerColor variable
  Map<ColorSwatch<Object>, String> colorsNameMap =
      {}; // Define the colorsNameMap variable
  Future<bool> colorPickerDialog() async {
    return ColorPicker(
      // 使用 dialogPickerColor 作为起始和活动颜色。
      color: dialogPickerColor,
      // 使用回调更新 dialogPickerColor。
      onColorChanged: (Color color) => (dialogPickerColor = color),
      width: 40,
      height: 40,
      borderRadius: 4,
      colorCodeHasColor: true,
      actionButtons: const ColorPickerActionButtons(
          dialogOkButtonLabel: "确认",
          dialogOkButtonType: ColorPickerActionButtonType.outlined,
          dialogCancelButtonLabel: "取消"),
      spacing: 5,
      runSpacing: 5,
      wheelDiameter: 155,
      heading: Text(
        '选择颜色',
        style: Theme.of(context).textTheme.titleSmall,
      ),
      subheading: Text(
        '选择颜色深度',
        style: Theme.of(context).textTheme.titleSmall,
      ),
      wheelSubheading: Text(
        '选择的颜色深度',
        style: Theme.of(context).textTheme.titleSmall,
      ),
      showMaterialName: true,
      showColorName: true,
      showColorCode: true,
      copyPasteBehavior: const ColorPickerCopyPasteBehavior(
        longPressMenu: true,
      ),
      materialNameTextStyle: Theme.of(context).textTheme.bodySmall,
      colorNameTextStyle: Theme.of(context).textTheme.bodySmall,
      colorCodeTextStyle: Theme.of(context).textTheme.bodySmall,
      pickersEnabled: const <ColorPickerType, bool>{
        ColorPickerType.both: false,
        ColorPickerType.primary: true,
        ColorPickerType.accent: true,
        ColorPickerType.bw: false,
        ColorPickerType.custom: true,
        ColorPickerType.wheel: true,
      },
      customColorSwatchesAndNames: colorsNameMap,
    ).showPickerDialog(
      context,
      backgroundColor: Colors.white,
      // 版本 3.0.0 中的新功能，自定义过渡支持。
      transitionBuilder: (BuildContext context, Animation<double> a1,
          Animation<double> a2, Widget widget) {
        final double curvedValue =
            Curves.easeInOutBack.transform(a1.value) - 1.0;
        return Transform(
          transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
          child: Opacity(
            opacity: a1.value,
            child: widget,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 400),
      constraints:
          const BoxConstraints(minHeight: 460, minWidth: 300, maxWidth: 320),
    ).then((onValue) {
      if (onValue) {
        showGeneralDialog(
          context: context,
          pageBuilder: (BuildContext buildContext, Animation<double> animation,
              Animation<double> secondaryAnimation) {
            return TDAlertDialog(
              title: "重启",
              content: "重启应用以应用主题色",
              rightBtnAction: () {
                StudyData.instance.setThemeColor(dialogPickerColor);

                // ignore: use_build_context_synchronously
                WidgetRebirth.createRebirth(context: context);
              },
            );
          },
        );
      }
      return onValue;
    });
  }

  @override
  Widget build(BuildContext context) {
    dialogPickerColor = Theme.of(context).primaryColor;
    return Scaffold(
      appBar: TDNavBar(title: '设置', onBack: () {}),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical, // 水平滚动
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Padding(
                    padding: EdgeInsets.fromLTRB(15, 5, 10, 5),
                    child: Text(
                      "个性化(未完成)",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                    )),
                TDCellGroup(
                  cells: [
                    TDCell(
                      leftIcon: Icons.sunny,
                      title: "白天与黑夜",
                      rightIconWidget: YakoThemeSwitch(
                        enabled: StudyData.instance.getNightMode(),
                        onChanged: ({bool? changed}) {
                          StudyData.instance.setNightMode(!(changed ?? false));
                          setState(() {
                            
                          });
                        },
                        width: 45,
                        animationDuration: const Duration(milliseconds: 300),
                        enabledToggleBorderRadius: 8,
                      ),
                    ),
                    TDCell(
                        leftIcon: Icons.mode_night_outlined,
                        title: "跟随系统",
                        rightIconWidget: TDSwitch(
                          isOn: StudyData.instance.getNightModeFollowSystem(),
                          onChanged: (bool changed) {
                            StudyData.instance
                                .setNightModeFollowSystem(changed);
                            setState(() {});
                            return false;
                          },
                        ),
                        onClick: (_) {}),
                    TDCell(
                        leftIcon: Icons.color_lens,
                        title: "主题色",
                        onClick: (_) {
                          colorPickerDialog();
                        }),
                  ],
                ),
                const Padding(
                    padding: EdgeInsets.fromLTRB(15, 5, 10, 5),
                    child: Text(
                      "其他",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                    )),
                TDCellGroup(
                  cells: [
                    TDCell(
                        leftIcon: Icons.info_outline,
                        title: "关于",
                        onClick: (_) {
                          Navigator.push(
                              context,
                              CupertinoPageRoute(
                                  builder: (context) => const AboutScreen()));
                        }),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
