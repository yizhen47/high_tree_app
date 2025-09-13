import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
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
    
    return Container(
      height: 200,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
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
                  offset: Offset(_offsetX * 100, _offsetY * 100),
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
            const Center(
              child: Text(
                '背景预览',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      offset: Offset(1, 1),
                      blurRadius: 3,
                      color: Colors.black54,
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('背景自定义'),
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
            
            // 控制选项
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 启用自定义背景开关
                  SwitchListTile(
                    title: const Text('启用自定义背景'),
                    subtitle: const Text('开启后将使用自定义背景图片'),
                    value: _useCustomBackground,
                    onChanged: (value) {
                      setState(() {
                        _useCustomBackground = value;
                      });
                    },
                  ),
                  
                  const Divider(),
                  
                  // 选择图片按钮
                  ListTile(
                    leading: const Icon(Icons.photo_library),
                    title: const Text('选择背景图片'),
                    subtitle: Text(
                      StudyData.instance.customBackgroundPath != null 
                        ? '已选择图片' 
                        : '点击选择图片',
                    ),
                    trailing: StudyData.instance.customBackgroundPath != null
                        ? const Icon(Icons.check, color: Colors.green)
                        : const Icon(Icons.chevron_right),
                    onTap: () async {
                      FilePickerResult? result = await FilePicker.platform.pickFiles(
                        type: FileType.custom,
                        allowedExtensions: ['jpg', 'png', 'jpeg', 'webp'],
                      );
                      if (result != null && result.files.single.path != null) {
                        StudyData.instance.customBackgroundPath = result.files.single.path!;
                        setState(() {});
                      }
                    },
                  ),
                  
                  if (StudyData.instance.customBackgroundPath != null) ...[
                    // 清除图片按钮
                    ListTile(
                      leading: const Icon(Icons.clear),
                      title: const Text('清除背景图片'),
                      onTap: () {
                        StudyData.instance.customBackgroundPath = null;
                        setState(() {});
                      },
                    ),
                    
                    const Divider(),
                    
                    // 适配模式选择
                    const Text(
                      '适配模式',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...List.generate(_fitOptions.length, (index) {
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
                    
                    const Divider(),
                    
                    // 缩放比例
                    const Text(
                      '缩放比例',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // 水平偏移
                    const Text(
                      '水平位置',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
                    const Text(
                      '垂直位置',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
                    
                    const SizedBox(height: 16),
                    
                    // 重置按钮
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _scale = 1.0;
                            _offsetX = 0.0;
                            _offsetY = 0.0;
                            _fitIndex = 0;
                          });
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('重置设置'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 