import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
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
        appBar: AppBar(
          title: const Text('启动页面自定义'),
          actions: [
            TextButton(
              onPressed: () {
                _saveSettings();
                Navigator.pop(context);
              },
              child: const Text(
                '保存',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              // 预览区域
              _buildPreview(),
              
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 使用提取颜色开关
                    SwitchListTile(
                      title: const Text('使用图标提取颜色'),
                      subtitle: const Text('自动从应用图标提取边缘颜色作为背景'),
                      value: _useExtractedColor,
                      onChanged: (value) {
                        setState(() {
                          _useExtractedColor = value;
                        });
                      },
                    ),
                    
                    if (_useExtractedColor) ...[
                      const Divider(),
                      
                      // 提取的颜色显示
                      ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _extractedColor ?? Colors.grey,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                        ),
                        title: Text('图标提取颜色'),
                        subtitle: Text(_extractedColor != null ? 
                          '已提取颜色: #${_extractedColor!.value.toRadixString(16).toUpperCase()}' : 
                          '未提取到颜色'),
                        trailing: _isExtracting 
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : IconButton(
                              icon: const Icon(Icons.refresh),
                              onPressed: _reExtractColor,
                              tooltip: '重新提取颜色',
                            ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // 自定义颜色选择
                      const Text(
                        '自定义颜色',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '选择自定义颜色将覆盖图标提取的颜色',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // 颜色选择器
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
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
                                heading: Text(
                                  '选择颜色',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                subheading: Text(
                                  '调整颜色以获得理想的启动页面效果',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                wheelSubheading: Text(
                                  '颜色和明暗度选择',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
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
                                    child: ElevatedButton.icon(
                                      onPressed: _customColor != null ? () {
                                        setState(() {
                                          _customColor = null;
                                        });
                                      } : null,
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
                      const Divider(),
                      
                      // 主题色说明
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info, color: Colors.blue.shade600),
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
                    
                    const SizedBox(height: 24),
                    
                    // 重置按钮
                    Center(
                      child: ElevatedButton.icon(
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
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 