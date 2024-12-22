import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:extended_text/extended_text.dart';
import 'package:path/path.dart' as path;
import 'dart:ui' as ui show PlaceholderAlignment;
import 'package:flutter/material.dart';

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
    var pack = fpath.split(":");
    var f = File(path.join(
        _nowSingleUsedMathImagePath, pack[0], "assets", "images", pack[1]));

    if (f.existsSync()) {
      var img = FileImage(f);

      return MyImageSpan(
        img,
        actualText: fpath,
        start: start,
        fit: BoxFit.fitHeight,
        filterQuality: FilterQuality.medium,
      );
    } else {
      return TextSpan(
        text: pack[1],
        style: const TextStyle(
          color: Colors.red,
        ),
      );
    }
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

class MyImageSpan extends ExtendedWidgetSpan {
  MyImageSpan(
    ImageProvider image, {
    Key? key,
    double? imageWidth,
    double? imageHeight,
    EdgeInsets? margin,
    super.start,
    super.alignment = ui.PlaceholderAlignment.middle,
    super.actualText = null,
    super.baseline,
    BoxFit fit = BoxFit.scaleDown,
    ImageLoadingBuilder? loadingBuilder,
    ImageFrameBuilder? frameBuilder,
    String? semanticLabel,
    bool excludeFromSemantics = false,
    Color? color,
    BlendMode? colorBlendMode,
    AlignmentGeometry imageAlignment = Alignment.center,
    ImageRepeat repeat = ImageRepeat.noRepeat,
    Rect? centerSlice,
    bool matchTextDirection = false,
    bool gaplessPlayback = false,
    FilterQuality filterQuality = FilterQuality.low,
    GestureTapCallback? onTap,
    HitTestBehavior behavior = HitTestBehavior.deferToChild,
  }) : super(
          child: Container(
            padding: margin,
            child: GestureDetector(
              onTap: onTap,
              behavior: behavior,
              child: Image(
                key: key,
                image: image,
                width: imageWidth,
                height: imageHeight,
                fit: fit,
                loadingBuilder: loadingBuilder,
                frameBuilder: frameBuilder,
                semanticLabel: semanticLabel,
                excludeFromSemantics: excludeFromSemantics,
                color: color,
                colorBlendMode: colorBlendMode,
                alignment: imageAlignment,
                repeat: repeat,
                centerSlice: centerSlice,
                matchTextDirection: matchTextDirection,
                gaplessPlayback: gaplessPlayback,
                filterQuality: filterQuality,
              ),
            ),
          ),
          deleteAll: true,
        );
}
