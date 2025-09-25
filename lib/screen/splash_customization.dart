import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import '../tool/study_data.dart';

class SplashCustomizationPage extends StatefulWidget {
  const SplashCustomizationPage({super.key});

  @override
  _SplashCustomizationPageState createState() => _SplashCustomizationPageState();
}

class _SplashCustomizationPageState extends State<SplashCustomizationPage> {
  late bool _useExtractedColor;
  Color? _customColor;
  Color? _extractedColor;
  bool _isExtracting = false;

  @override
  void initState() {
    super.initState();
    _useExtractedColor = StudyData.instance.useExtractedSplashColor;
    _customColor = StudyData.instance.customSplashColor;
    _extractedColor = StudyData.instance.extractedLogoColor;
  }

  void _saveSettings() {
    StudyData.instance.useExtractedSplashColor = _useExtractedColor;
    StudyData.instance.customSplashColor = _customColor;
  }

  Future<void> _reExtractColor() async {
    setState(() {
      _isExtracting = true;
    });

    try {
      final imageProvider = AssetImage('assets/logo.png');
      final paletteGenerator = await PaletteGenerator.fromImageProvider(
        imageProvider,
        maximumColorCount: 20,
      );

      Color? dominantColor;
      
      // 优先选择有活力的颜色
      if (paletteGenerator.vibrantColor != null) {
        dominantColor = paletteGenerator.vibrantColor!.color;
      } 
      // 其次选择明亮的有活力颜色
      else if (paletteGenerator.lightVibrantColor != null) {
        dominantColor = paletteGenerator.lightVibrantColor!.color;
      }
      // 然后选择深色有活力颜色
      else if (paletteGenerator.darkVibrantColor != null) {
        dominantColor = paletteGenerator.darkVibrantColor!.color;
      }
      // 最后选择主导色
      else if (paletteGenerator.dominantColor != null) {
        dominantColor = paletteGenerator.dominantColor!.color;
      }
      
      if (dominantColor != null) {
        setState(() {
          _extractedColor = dominantColor;
        });
        StudyData.instance.extractedLogoColor = dominantColor;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('颜色提取失败: $e'))
      );
    } finally {
      setState(() {
        _isExtracting = false;
      });
    }
  }

  Color _getPreviewColor() {
    if (_useExtractedColor) {
      return _customColor ?? _extractedColor ?? StudyData.instance.themeColor;
    } else {
      return StudyData.instance.themeColor;
    }
  }

  Widget _buildPreview() {
    final backgroundColor = _getPreviewColor();
    
    return Container(
      height: 200,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
                         // 模拟Logo
             SizedBox(
               width: 60,
               height: 60,
               child: Image.asset(
                 'assets/logo.png',
                 filterQuality: FilterQuality.high,
               ),
             ),
            const SizedBox(height: 16),
            Text(
              '启动页面预览',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          _saveSettings();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: TDNavBar(
          title: '启动页面自定义',
          onBack: () {
            _saveSettings();
            Navigator.of(context).pop();
          },
          rightBarItems: [
            TDNavBarItem(
              icon: Icons.check,
              action: () {
                _saveSettings();
                TDToast.showSuccess('设置已保存', context: context);
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            children: [
              // 预览区域
              _buildPreview(),
              
                    // 使用提取颜色开关
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: SwitchListTile(
                    contentPadding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                      title: const Text('使用图标提取颜色'),
                    subtitle: Text('自动从应用图标提取边缘颜色作为背景',
                        style: TextStyle(color: Colors.grey[600])),
                      value: _useExtractedColor,
                      onChanged: (value) {
                        setState(() {
                          _useExtractedColor = value;
                        });
                      },
                  ),
                    ),
                    
                    if (_useExtractedColor) ...[
                  // 颜色自定义卡片
                  Card(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      // 提取的颜色显示
                      ListTile(
                            contentPadding: EdgeInsets.zero,
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _extractedColor ?? Colors.grey,
                            borderRadius: BorderRadius.circular(8),
                                border:
                                    Border.all(color: Colors.grey.shade300),
                          ),
                        ),
                            title: const Text('图标提取颜色'),
                            subtitle: Text(_extractedColor != null
                                ? '已提取颜色: #${_extractedColor!.value.toRadixString(16).toUpperCase()}'
                                : '未提取到颜色'),
                        trailing: _isExtracting 
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                            )
                          : IconButton(
                              icon: const Icon(Icons.refresh),
                              onPressed: _reExtractColor,
                              tooltip: '重新提取颜色',
                            ),
                      ),
                          const SizedBox(height: 16),
                          const Divider(),
                      const SizedBox(height: 16),
                      
                      // 自定义颜色选择
                          Text(
                        '自定义颜色',
                            style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                          Text(
                            '选择一个颜色来自定义启动页面背景',
                            style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 16),
                      
                      // 颜色选择器
                              ColorPicker(
                                color: _customColor ?? _extractedColor ?? Colors.blue,
                                onColorChanged: (Color color) {
                                  setState(() {
                                    _customColor = color;
                                  });
                                },
                                width: 40,
                                height: 40,
                                borderRadius: 8,
                                spacing: 8,
                                runSpacing: 8,
                                wheelDiameter: 165,
                                showColorCode: true,
                                colorCodeHasColor: true,
                                pickersEnabled: const <ColorPickerType, bool>{
                                  ColorPickerType.both: false,
                                  ColorPickerType.primary: true,
                                  ColorPickerType.accent: false,
                                  ColorPickerType.bw: false,
                                  ColorPickerType.custom: true,
                                  ColorPickerType.wheel: true,
                                },
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _customColor != null
                                      ? () {
                                        setState(() {
                                          _customColor = null;
                                        });
                                        }
                                      : null,
                                      icon: const Icon(Icons.clear),
                                      label: const Text('清除自定义颜色'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ] else ...[
                      // 主题色说明
                      Container(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade600),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '使用主题色',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue.shade800,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '启动页面将使用应用的主题色作为背景',
                                    style: TextStyle(
                                      color: Colors.blue.shade700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    
                const SizedBox(height: 16),
                    
                    // 重置按钮
                    Center(
                  child: OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            _useExtractedColor = true;
                            _customColor = null;
                          });
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('重置为默认设置'),
                      ),
                    ),
                const SizedBox(height: 16),
                  ],
                ),
          ),
        ),
      ),
    );
  }
} 