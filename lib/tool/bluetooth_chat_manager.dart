import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

/// 聊天消息类
class ChatMessage {
  final String id;
  final String senderName;
  final String content;
  final DateTime timestamp;
  final ChatMessageType type;
  
  ChatMessage({
    required this.id,
    required this.senderName,
    required this.content,
    required this.timestamp,
    this.type = ChatMessageType.text,
  });
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'senderName': senderName,
    'content': content,
    'timestamp': timestamp.millisecondsSinceEpoch,
    'type': type.index,
  };
  
  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: json['id'],
    senderName: json['senderName'],
    content: json['content'],
    timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
    type: ChatMessageType.values[json['type'] ?? 0],
  );
}

enum ChatMessageType {
  text,
  attendance,
  file,
  system,
}

/// 学生信息类
class StudentInfo {
  final String id;
  final String name;
  final BluetoothDevice device;
  final DateTime joinTime;
  bool isAttended;
  
  StudentInfo({
    required this.id,
    required this.name,
    required this.device,
    required this.joinTime,
    this.isAttended = false,
  });
}

/// 蓝牙聊天管理器
class BluetoothChatManager {
  static final BluetoothChatManager _instance = BluetoothChatManager._internal();
  factory BluetoothChatManager() => _instance;
  BluetoothChatManager._internal();
  
  final FlutterBlePeripheral _peripheral = FlutterBlePeripheral();
  
  // 状态变量
  bool _isTeacherMode = false;
  bool _isInitialized = false;
  String _classId = "";
  String _teacherName = "";
  String _studentName = "";
  
  // 蓝牙相关
  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _writeCharacteristic;
  BluetoothCharacteristic? _readCharacteristic;
  final Map<String, StudentInfo> _connectedStudents = {};
  final List<ChatMessage> _chatMessages = [];
  
  // 服务和特征UUID（自定义）
  static const String serviceUUID = "12345678-1234-1234-1234-123456789abc";
  static const String chatCharacteristicUUID = "87654321-4321-4321-4321-cba987654321";
  
  // 回调函数
  Function(ChatMessage)? onNewMessage;
  Function(StudentInfo)? onStudentJoined;
  Function(String)? onStudentLeft;
  Function(String)? onStatusChanged;
  Function(StudentInfo)? onStudentAttended;
  
  // Getters
  bool get isTeacherMode => _isTeacherMode;
  bool get isInitialized => _isInitialized;
  String get classId => _classId;
  List<ChatMessage> get chatMessages => List.unmodifiable(_chatMessages);
  Map<String, StudentInfo> get connectedStudents => Map.unmodifiable(_connectedStudents);
  
  /// 初始化蓝牙权限
  Future<bool> initialize() async {
    try {
      // 检查蓝牙适配器状态
      if (await FlutterBluePlus.isSupported == false) {
        _updateStatus("设备不支持蓝牙");
        return false;
      }

      // 检查蓝牙是否开启
      var state = await FlutterBluePlus.adapterState.first;
      if (state != BluetoothAdapterState.on) {
        _updateStatus("蓝牙未开启，请在系统设置中开启蓝牙后重新点击初始化");
        return false;
      }
      
      // 请求蓝牙权限（Android 12+需要）
      if (await Permission.bluetoothScan.isDenied) {
        await Permission.bluetoothScan.request();
      }
      if (await Permission.bluetoothConnect.isDenied) {
        await Permission.bluetoothConnect.request();
      }
      if (await Permission.bluetoothAdvertise.isDenied) {
        await Permission.bluetoothAdvertise.request();
      }
      if (await Permission.location.isDenied) {
        await Permission.location.request();
      }
      
      _isInitialized = true;
      _updateStatus("蓝牙初始化成功");
      return true;
    } catch (e) {
      _updateStatus("蓝牙初始化失败: $e");
      return false;
    }
  }
  
  /// 启动教师模式（广播模式）
  Future<bool> startTeacherMode(String classId, String teacherName) async {
    if (!_isInitialized) {
      bool initResult = await initialize();
      if (!initResult) return false;
    }
    
    try {
      _isTeacherMode = true;
      _classId = classId;
      _teacherName = teacherName;
      
      _updateStatus("教师模式已启动\n课堂ID: $classId\n等待学生连接...");
      
      // 添加系统消息
      _addSystemMessage("课堂 '$classId' 已开始，老师: $teacherName");
      
      // 开始广播（在flutter_blue_plus中，这通常通过设备名称实现）
      await _startAdvertising();
      
      return true;
    } catch (e) {
      _updateStatus("启动教师模式失败: $e");
      return false;
    }
  }
  
  /// 启动学生模式（扫描并连接）
  Future<bool> startStudentMode(String studentName) async {
    if (!_isInitialized) {
      bool initResult = await initialize();
      if (!initResult) return false;
    }
    
    try {
      _isTeacherMode = false;
      _studentName = studentName;
      
      _updateStatus("学生模式已启动，正在搜索可用课堂...");
      
      // 搜索附近的蓝牙设备
      List<BluetoothDevice> devices = await searchForTeacherDevices();
      
      if (devices.isEmpty) {
        _updateStatus("未找到可用的课堂");
        return false;
      }
      
      // 显示可用的课堂列表供用户选择
      // 这里简化处理，连接第一个找到的设备
      return await connectToTeacher(devices.first);
      
    } catch (e) {
      _updateStatus("启动学生模式失败: $e");
      return false;
    }
  }
  
  /// 开始广播（教师模式）
  Future<void> _startAdvertising() async {
    if (!await FlutterBlePeripheral().isSupported) {
      _updateStatus("设备不支持蓝牙广播");
      return;
    }

    if (await FlutterBlePeripheral().isAdvertising) {
      await FlutterBlePeripheral().stop();
    }
    
    final advertiseData = AdvertiseData(
      localName: "ClassRoom-$_classId",
      includeDeviceName: true,
      serviceUuid: serviceUUID,
    );

    try {
      await FlutterBlePeripheral().start(advertiseData: advertiseData);
      _updateStatus("教师设备已开始广播: ClassRoom-$_classId");

    } catch (e) {
      _updateStatus("广播失败: $e");
    }
  }
  
  /// 搜索教师设备
  Future<List<BluetoothDevice>> searchForTeacherDevices() async {
    List<BluetoothDevice> teacherDevices = [];
    StreamSubscription<List<ScanResult>>? subscription;

    // 确保任何之前的扫描都已停止，并给系统一点喘息时间
    if (FlutterBluePlus.isScanningNow) {
      await FlutterBluePlus.stopScan();
      await Future.delayed(const Duration(milliseconds: 200));
    }

    try {
      _updateStatus("正在扫描附近设备...");
      
      final seen = <DeviceIdentifier>{};
      final targetServiceGuid = Guid(serviceUUID);
      
      // 监听扫描结果
      subscription = FlutterBluePlus.scanResults.listen((results) {
        for (final r in results) {
          if (seen.contains(r.device.remoteId)) {
            continue;
          }

          final deviceName = r.device.platformName;
          final serviceUuids = r.advertisementData.serviceUuids;

          // 优先通过Service UUID匹配，或通过名称匹配
          if (serviceUuids.contains(targetServiceGuid) || (deviceName.isNotEmpty && deviceName.startsWith('ClassRoom'))) {
            _updateStatus("发现教师设备: $deviceName (${r.device.remoteId})");
            teacherDevices.add(r.device);
            seen.add(r.device.remoteId);
          }
        }
      }, onError: (e) => _updateStatus("扫描结果监听器错误: $e"));

      // 开始通用扫描
      await FlutterBluePlus.startScan(androidUsesFineLocation: true);
      
      // 让扫描持续5秒
      await Future.delayed(const Duration(seconds: 5));

    } catch (e) {
      _updateStatus("搜索设备失败: $e");
    } finally {
      // 明确停止扫描并取消监听
      await FlutterBluePlus.stopScan();
      await subscription?.cancel();
    }
    
    return teacherDevices;
  }
  
  /// 连接到教师设备
  Future<bool> connectToTeacher(BluetoothDevice device) async {
    try {
      _updateStatus("正在连接到 ${device.platformName}...");
      
      await device.connect(timeout: const Duration(seconds: 15));
      _connectedDevice = device;
      
      // 发现服务
      List<BluetoothService> services = await device.discoverServices();
      BluetoothService? chatService;

      for (BluetoothService service in services) {
        if (service.uuid.toString().toLowerCase() == serviceUUID.toLowerCase()) {
          chatService = service;
          break;
        }
      }

      if (chatService == null) {
        _updateStatus("未找到课堂服务，请确认教师端已开启");
        await device.disconnect();
        return false;
      }
      
      // 查找聊天特征
      for (BluetoothCharacteristic characteristic in chatService.characteristics) {
        if (characteristic.properties.write) {
          _writeCharacteristic = characteristic;
        }
        if (characteristic.properties.notify) {
          _readCharacteristic = characteristic;
          await characteristic.setNotifyValue(true);
          
          // 监听消息
          characteristic.lastValueStream.listen((data) {
            String message = utf8.decode(data);
            _handleReceivedMessage(message);
          });
        }
      }

      if (_writeCharacteristic == null || _readCharacteristic == null) {
        _updateStatus("未找到读写特征，无法通信");
        await device.disconnect();
        return false;
      }
      
      // 发送学生信息
      Map<String, dynamic> joinMessage = {
        'type': 'join',
        'studentName': _studentName,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      
      await _sendData(jsonEncode(joinMessage));
      
      _updateStatus("已连接到课堂: ${device.platformName}");
      return true;
      
    } catch (e) {
      _updateStatus("连接失败: $e");
      return false;
    }
  }
  
  /// 处理接收到的消息
  void _handleReceivedMessage(String message) {
    try {
      Map<String, dynamic> data = jsonDecode(message);
      String type = data['type'] ?? '';
      
      switch (type) {
        case 'chat':
          ChatMessage chatMessage = ChatMessage.fromJson(data);
          _addMessage(chatMessage);
          break;
          
        case 'join':
          if (_isTeacherMode) {
            // 教师收到学生加入消息
            String studentName = data['studentName'] ?? 'Unknown';
            _updateStatus("学生 $studentName 已加入课堂");
          }
          break;
          
        case 'attendance':
          if (_isTeacherMode) {
            String studentName = data['studentName'] ?? 'Unknown';
            // 处理签到
            _updateStatus("学生 $studentName 已签到");
          }
          break;
          
        case 'system':
          String content = data['content'] ?? '';
          _addSystemMessage(content);
          break;
      }
    } catch (e) {
      _updateStatus("处理消息失败: $e");
    }
  }
  
  /// 发送聊天消息
  Future<bool> sendChatMessage(String content) async {
    try {
      String senderName = _isTeacherMode ? _teacherName : _studentName;
      
      ChatMessage message = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderName: senderName,
        content: content,
        timestamp: DateTime.now(),
        type: ChatMessageType.text,
      );
      
      Map<String, dynamic> data = {
        'type': 'chat',
        ...message.toJson(),
      };
      
      await _sendData(jsonEncode(data));
      
      // 添加到本地消息列表
      _addMessage(message);
      
      return true;
    } catch (e) {
      _updateStatus("发送消息失败: $e");
      return false;
    }
  }
  
  /// 学生签到
  Future<bool> attendClass() async {
    if (_isTeacherMode) return false;
    
    try {
      Map<String, dynamic> data = {
        'type': 'attendance',
        'studentName': _studentName,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      
      await _sendData(jsonEncode(data));
      
      // 添加签到消息到聊天
      _addSystemMessage("$_studentName 已签到");
      
      return true;
    } catch (e) {
      _updateStatus("签到失败: $e");
      return false;
    }
  }
  
  /// 发送数据
  Future<void> _sendData(String data) async {
    if (_writeCharacteristic != null) {
      await _writeCharacteristic!.write(utf8.encode(data));
    }
  }
  
  /// 添加消息到聊天记录
  void _addMessage(ChatMessage message) {
    _chatMessages.add(message);
    onNewMessage?.call(message);
  }
  
  /// 添加系统消息
  void _addSystemMessage(String content) {
    ChatMessage message = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderName: "系统",
      content: content,
      timestamp: DateTime.now(),
      type: ChatMessageType.system,
    );
    _addMessage(message);
  }
  
  /// 更新状态
  void _updateStatus(String status) {
    print("BluetoothChat: $status");
    onStatusChanged?.call(status);
  }
  
  /// 停止服务
  Future<void> stop() async {
    if (_isTeacherMode && await FlutterBlePeripheral().isAdvertising) {
      await FlutterBlePeripheral().stop();
    }
    if (_connectedDevice?.isConnected == true) {
      await _connectedDevice!.disconnect();
    }
    
    _connectedStudents.clear();
    _chatMessages.clear();
    _isTeacherMode = false;
    _classId = "";
    _teacherName = "";
    _studentName = "";
    _connectedDevice = null;
    _writeCharacteristic = null;
    _readCharacteristic = null;
    
    _updateStatus("服务已停止");
  }
  
  /// 获取连接的学生列表
  List<StudentInfo> getConnectedStudents() {
    return _connectedStudents.values.toList();
  }
  
  /// 获取已签到的学生数量
  int getAttendedCount() {
    return _connectedStudents.values.where((s) => s.isAttended).length;
  }
} 