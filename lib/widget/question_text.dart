import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:extended_text/extended_text.dart';
import 'package:path/path.dart' as path;

String _nowSingleUsedMathImagePath = "";
void setCurMathImgPath(String path) {
  _nowSingleUsedMathImagePath = path;
}

class MathIncludeText extends SpecialText {
  static const String flag = "[image:";
  static const String flagEnd = "]";
  final int start;

  /// whether show background for @somebody
  final bool showAtBackground;

  MathIncludeText(TextStyle textStyle, SpecialTextGestureTapCallback? onTap,
      {this.showAtBackground = false, required this.start})
      : super(
          flag,
          MathIncludeText.flagEnd,
          textStyle,
        );

  @override
  InlineSpan finishText() {
    var fpath = toString();
    fpath = fpath.substring(MathIncludeText.flag.length,
        fpath.length - MathIncludeText.flagEnd.length);

    var img = FileImage(File(path.join(_nowSingleUsedMathImagePath, fpath)));
    return ImageSpan(
      img,
      start: start,
      imageWidth: 25.0,
      imageHeight: 25.0,
    );
  }
}

class MathIncludeTextSpanBuilder extends SpecialTextSpanBuilder {
  MathIncludeTextSpanBuilder({this.showAtBackground = false});

  /// whether show background for @somebody
  final bool showAtBackground;

  // @override
  // TextSpan build(String data,
  //     {TextStyle? textStyle, SpecialTextGestureTapCallback? onTap}) {
  //   return super.build(data, textStyle: textStyle, onTap: onTap);
  // }

  @override
  SpecialText? createSpecialText(String? flag,
      {required int index,
      SpecialTextGestureTapCallback? onTap,
      TextStyle? textStyle}) {
    if (flag == null || flag == '') {
      return null;
    }

    ///index is end index of start flag, so text start index should be index-(flag.length-1)
    if (isStart(flag, MathIncludeText.flag)) {
      return MathIncludeText(
        textStyle ??
            const TextStyle(), // Provide a default value if textStyle is null
        onTap,
        start: index - (MathIncludeText.flag.length - 1),
        showAtBackground: showAtBackground,
      );
    }
    return null;
  }
}
