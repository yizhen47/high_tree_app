import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import '../tool/study_data.dart';

class BackgroundCustomizationPage extends StatefulWidget {
  const BackgroundCustomizationPage({super.key});

  @override
  _BackgroundCustomizationPageState createState() => _BackgroundCustomizationPageState();
}

class _BackgroundCustomizationPageState extends State<BackgroundCustomizationPage> {
  late bool _useCustomBackground;
  late double _scale;
  late double _offsetX;
  late double _offsetY;
  late int _fitIndex;
  
  final List<String> _fitOptions = [
    '覆盖 (Cover)',
    '包含 (Contain)', 
    '填充 (Fill)',
    '适应宽度 (Fit Width)',
    '适应高度 (Fit Height)',
    '缩小适应 (Scale Down)',
  ];

  @override
  void initState() {
    super.initState();
    _useCustomBackground = StudyData.instance.useCustomBackground;
    _scale = StudyData.instance.backgroundScale;
    _offsetX = StudyData.instance.backgroundOffsetX;
    _offsetY = StudyData.instance.backgroundOffsetY;
    _fitIndex = StudyData.instance.backgroundFitIndex;
  }

  void _saveSettings() {
    StudyData.instance.useCustomBackground = _useCustomBackground;
    StudyData.instance.backgroundScale = _scale;
    StudyData.instance.backgroundOffsetX = _offsetX;
    StudyData.instance.backgroundOffsetY = _offsetY;
    StudyData.instance.backgroundFitIndex = _fitIndex;
  }

  Widget _buildPreview() {
    final backgroundPath = StudyData.instance.customBackgroundPath;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.preview,
                  size: 20,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  '背景预览',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '实时预览背景效果',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(
                  children: [
                    // 背景层
                    if (_useCustomBackground && backgroundPath != null && File(backgroundPath).existsSync())
                      Transform.scale(
                        scale: _scale,
                        child: Transform.translate(
                          offset: Offset(_offsetX * 50, _offsetY * 50),
                          child: Container(
                            width: double.infinity,
                            height: double.infinity,
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: FileImage(File(backgroundPath)),
                                fit: StudyData.instance.backgroundFit,
                              ),
                            ),
                          ),
                        ),
                      )
                    else
                      Container(
                        width: double.infinity,
                        height: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.blue.shade300,
                              Colors.blue.shade500,
                            ],
                          ),
                        ),
                      ),
                    // 预览文字
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '背景预览',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
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
      onPopInvoked: (didPop) {
        if (didPop) {
          _saveSettings();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: TDNavBar(
          title: '背景自定义',
          onBack: () {
            _saveSettings();
            Navigator.of(context).pop();
          },
          rightBarItems: [
            TDNavBarItem(
              icon: TDIcons.check,
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
                
                // 启用自定义背景开关
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: SwitchListTile(
                    contentPadding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                    title: const Text('启用自定义背景'),
                    subtitle: Text('开启后将使用自定义背景图片',
                        style: TextStyle(color: Colors.grey[600])),
                    value: _useCustomBackground,
                    onChanged: (value) {
                      setState(() {
                        _useCustomBackground = value;
                      });
                    },
                  ),
                ),
                
                // 图片选择卡片
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.photo_library,
                            color: Theme.of(context).primaryColor,
                            size: 20,
                          ),
                        ),
                        title: const Text('选择背景图片'),
                        subtitle: Text(
                          StudyData.instance.customBackgroundPath != null 
                            ? '已选择图片' 
                            : '点击选择支持的图片格式',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        trailing: StudyData.instance.customBackgroundPath != null
                            ? Icon(Icons.check_circle, color: Colors.green[600])
                            : const Icon(Icons.chevron_right),
                        onTap: () async {
                          FilePickerResult? result = await FilePicker.platform.pickFiles(
                            type: FileType.custom,
                            allowedExtensions: ['jpg', 'png', 'jpeg', 'webp'],
                          );
                          if (result != null && result.files.single.path != null) {
                            StudyData.instance.customBackgroundPath = result.files.single.path!;
                            setState(() {});
                            TDToast.showSuccess('图片选择成功', context: context);
                          }
                        },
                      ),
                      
                      if (StudyData.instance.customBackgroundPath != null)
                        const Divider(height: 1),
                      
                      if (StudyData.instance.customBackgroundPath != null)
                        ListTile(
                          contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.clear,
                              color: Colors.red,
                              size: 20,
                            ),
                          ),
                          title: const Text('清除背景图片'),
                          subtitle: Text(
                            '移除已选择的背景图片',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: const Text('确认清除'),
                                  content: const Text('确定要清除已选择的背景图片吗？'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(),
                                      child: const Text('取消'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        StudyData.instance.customBackgroundPath = null;
                                        setState(() {});
                                        Navigator.of(context).pop();
                                        TDToast.showSuccess('背景图片已清除', context: context);
                                      },
                                      child: const Text('确定'),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                    ],
                  ),
                ),
                
                if (StudyData.instance.customBackgroundPath != null) ...[
                  // 调整设置卡片
                  Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 缩放比例
                          Text(
                            '缩放比例',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Slider(
                            value: _scale,
                            min: 0.5,
                            max: 3.0,
                            divisions: 25,
                            label: '${(_scale * 100).round()}%',
                            onChanged: (value) {
                              setState(() {
                                _scale = value;
                              });
                            },
                          ),
                          Text(
                            '当前缩放: ${(_scale * 100).round()}%',
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // 水平偏移
                          Text(
                            '水平位置',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Slider(
                            value: _offsetX,
                            min: -1.0,
                            max: 1.0,
                            divisions: 20,
                            label: _offsetX == 0 ? '居中' : (_offsetX > 0 ? '向右' : '向左'),
                            onChanged: (value) {
                              setState(() {
                                _offsetX = value;
                              });
                            },
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // 垂直偏移
                          Text(
                            '垂直位置',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Slider(
                            value: _offsetY,
                            min: -1.0,
                            max: 1.0,
                            divisions: 20,
                            label: _offsetY == 0 ? '居中' : (_offsetY > 0 ? '向下' : '向上'),
                            onChanged: (value) {
                              setState(() {
                                _offsetY = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // 适配模式卡片
                  Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ExpansionTile(
                      title: Text(
                        '适配模式',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      subtitle: Text(
                        '当前: ${_fitOptions[_fitIndex]}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      children: List.generate(_fitOptions.length, (index) {
                        return RadioListTile<int>(
                          title: Text(_fitOptions[index]),
                          value: index,
                          groupValue: _fitIndex,
                          onChanged: (value) {
                            setState(() {
                              _fitIndex = value!;
                            });
                          },
                        );
                      }),
                    ),
                  ),
                ],
                
                const SizedBox(height: 16),
                
                // 重置按钮
                Center(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('重置设置'),
                            content: const Text('确定要重置所有背景设置为默认值吗？'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('取消'),
                              ),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _scale = 1.0;
                                    _offsetX = 0.0;
                                    _offsetY = 0.0;
                                    _fitIndex = 0;
                                  });
                                  Navigator.of(context).pop();
                                  TDToast.showSuccess('设置已重置', context: context);
                                },
                                child: const Text('确定'),
                              ),
                            ],
                          );
                        },
                      );
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