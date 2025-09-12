import 'package:flutter/material.dart';

// 确保所有数学符号使用一致的数学模式渲染配置
final latexStyleConfig = LatexStyleConfiguration(
  fontSize: 16,
  fontWeight: FontWeight.w400,
  textStyle: const TextStyle(
    fontWeight: FontWeight.w100,
    fontSize: 16,
    fontFamily: 'CMU', // 直接在textStyle中指定数学字体
    fontStyle: FontStyle.italic, // 确保使用斜体
  ),
  textScaleFactor: 1.2,
  displayMode: true, // 改为true试试看是否能影响公式渲染
  mathFontFamily: 'CMU', // 使用Computer Modern字体家族，这是LaTeX标准数学字体
  forceItalics: true, // 确保数学模式中的变量使用斜体
);

// LaTeX 括号转换函数
String convertLatexDelimiters(String text) {
  // 将 \( ... \) 转换为 $ ... $
  text = text.replaceAllMapped(RegExp(r'\\?\\\((.*?)\\?\\\)', dotAll: true), (match) {
    return '\$${match.group(1)}\$';
  });
  
  // 将 \[ ... \] 转换为 $$ ... $$
  text = text.replaceAllMapped(RegExp(r'\\?\\\[(.*?)\\?\\\]', dotAll: true), (match) {
    return '\$\$${match.group(1)}\$\$';
  });
  
  // 处理一些常见的LaTeX控制序列
  text = text.replaceAll(r'\hspace*{3em}', ' '); // 水平间距
  text = text.replaceAll(r'\hspace{3em}', ' '); // 水平间距
  text = text.replaceAllMapped(RegExp(r'\\hspace\*?\{[^}]*\}'), (match) => ' '); // 通用水平间距
  
  // 处理图片包含语句 - 转换为简单文本描述
  text = text.replaceAllMapped(
    RegExp(r'\\begin\{center\}\\includegraphics\[.*?\]\{.*?\}\\end\{center\}'),
    (match) => '[图片]',
  );
  
  // 处理includegraphics命令
  text = text.replaceAllMapped(
    RegExp(r'\\includegraphics\[.*?\]\{.*?\}'),
    (match) => '[图片]',
  );
  
  // 处理begin/end环境
  text = text.replaceAll(r'\begin{center}', '');
  text = text.replaceAll(r'\end{center}', '');
  
  // 处理\ding命令 - 将装饰符号转换为简单的符号
  text = text.replaceAllMapped(RegExp(r'\\ding\{(\d+)\}'), (match) {
    int? num = int.tryParse(match.group(1) ?? '');
    if (num != null) {
      // 根据Zapf Dingbats字体的实际编号映射
      switch (num) {
        // 172-181 是编号序列（从1开始）
        case 172: return '1'; // 数字1
        case 173: return '2'; // 数字2  
        case 174: return '3'; // 数字3
        case 175: return '4'; // 数字4
        case 176: return '5'; // 数字5
        case 177: return '6'; // 数字6
        case 178: return '7'; // 数字7
        case 179: return '8'; // 数字8
        case 180: return '9'; // 数字9
        case 181: return '10'; // 数字10
        
        // 182-191 继续编号序列
        case 182: return '11';
        case 183: return '12';
        case 184: return '13';
        case 185: return '14';
        case 186: return '15';
        case 187: return '16';
        case 188: return '17';
        case 189: return '18';
        case 190: return '19';
        case 191: return '20';
        
        // 192-201 是圆圈数字
        case 192: return '①'; // 圆圈数字1
        case 193: return '②'; // 圆圈数字2
        case 194: return '③'; // 圆圈数字3
        case 195: return '④'; // 圆圈数字4
        case 196: return '⑤'; // 圆圈数字5
        case 197: return '⑥'; // 圆圈数字6
        case 198: return '⑦'; // 圆圈数字7
        case 199: return '⑧'; // 圆圈数字8
        case 200: return '⑨'; // 圆圈数字9
        case 201: return '⑩'; // 圆圈数字10
        
        // 其他常用符号
        case 51: return '✓'; // 对勾
        case 55: return '✗'; // 叉号
        case 108: return '●'; // 实心圆点
        case 109: return '○'; // 空心圆点
        case 110: return '■'; // 实心方块
        case 111: return '□'; // 空心方块
        
        default: return '•'; // 默认使用项目符号
      }
    }
    return '•'; // 解析失败时默认符号
  });
  
  return text;
}

// 样式配置类
class LatexStyleConfiguration {
  final double fontSize;
  final FontWeight fontWeight;
  final TextStyle textStyle;
  final double textScaleFactor;
  final bool displayMode;
  final String mathFontFamily;
  final bool forceItalics;

  LatexStyleConfiguration({
    required this.fontSize,
    required this.fontWeight,
    required this.textStyle,
    required this.textScaleFactor,
    required this.displayMode,
    required this.mathFontFamily,
    required this.forceItalics,
  });
} 