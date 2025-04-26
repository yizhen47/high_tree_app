import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:wifi_scan/wifi_scan.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_application_1/tool/study_data.dart';

/// A class that manages WiFi connections for attendance system
class HotspotAttendanceManager {
  // Singleton instance
  static final HotspotAttendanceManager _instance = HotspotAttendanceManager._internal();
  
  factory HotspotAttendanceManager() {
    return _instance;
  }
  
  HotspotAttendanceManager._internal();
  
  // Constants
  static const String HOTSPOT_PREFIX = "ClassAttendance_";
  static const int SERVER_PORT = 8989;
  
  // State variables
  bool _isTeacherMode = false;
  bool _isHotspotActive = false;
  ServerSocket? _serverSocket;
  String _classId = "";
  String _teacherName = "";
  
  // Student data
  final Map<String, StudentAttendanceData> _attendedStudents = {};
  
  // For callbacks
  Function(StudentAttendanceData)? onStudentAttended;
  Function(String)? onStatusChanged;
  
  // 新增：会话信息
  DateTime? _sessionStartTime;
  DateTime? _sessionEndTime;
  
  /// Initialize the hotspot manager with required permissions
  Future<bool> initialize() async {
    try {
      // Request permissions
      Map<Permission, PermissionStatus> statuses = await [
        Permission.location,
        Permission.nearbyWifiDevices,
      ].request();
      
      if (statuses[Permission.location]!.isGranted) {
        // Check if WiFi scan is available
        final canScan = await WiFiScan.instance.canStartScan();
        if (canScan != CanStartScan.yes) {
          _updateStatus("WiFi scanning not available: $canScan");
          return false;
        }
        
        _updateStatus("Permissions granted");
        return true;
      } else {
        _updateStatus("Location permission is required");
        return false;
      }
    } catch (e) {
      _updateStatus("Error initializing: $e");
      return false;
    }
  }
  
  /// Start teacher mode - create server and simulate hotspot
  /// 
  /// Note: On most devices, apps cannot directly create hotspots without system privileges.
  /// This implementation simulates the hotspot by showing instructions to the teacher.
  Future<bool> startTeacherMode(String classId, String teacherName) async {
    try {
      if (!await initialize()) {
        return false;
      }
      
      _isTeacherMode = true;
      _classId = classId;
      _teacherName = teacherName;
      _sessionStartTime = DateTime.now(); // 记录会话开始时间
      
      // Generate hotspot name with class ID
      final hotspotName = "$HOTSPOT_PREFIX$classId";
      final hotspotPassword = _generateHotspotPassword();
      
      _updateStatus("Starting attendance session for: $hotspotName");
      
      // Since we cannot programmatically enable hotspot on all devices without root,
      // we'll simulate the hotspot creation and just start the server
      
      // Get current IP address to display to teacher
      final info = NetworkInfo();
      final wifiIP = await info.getWifiIP();
      
      if (wifiIP == null || wifiIP.isEmpty) {
        _updateStatus("Could not get WiFi IP address. Make sure you're connected to WiFi.");
        return false;
      }
      
      _isHotspotActive = true;
      _updateStatus("⚠️ Manual action required: Please create a hotspot named '$hotspotName' with password '$hotspotPassword'");
      _updateStatus("Server started. Your IP: $wifiIP");
      
      // Start server socket to listen for connections
      await _startServer();
      
      return true;
    } catch (e) {
      _updateStatus("Error in teacher mode: $e");
      return false;
    }
  }
  
  /// Stop teacher mode - stop server
  Future<bool> stopTeacherMode() async {
    try {
      if (!_isTeacherMode || !_isHotspotActive) {
        return true;
      }
      
      // Close server socket
      _serverSocket?.close();
      _serverSocket = null;
      
      _isHotspotActive = false;
      _isTeacherMode = false;
      _sessionEndTime = DateTime.now(); // 记录会话结束时间
      _updateStatus("Attendance session ended");
      
      return true;
    } catch (e) {
      _updateStatus("Error stopping teacher mode: $e");
      return false;
    }
  }
  
  /// Start server to listen for student connections
  Future<void> _startServer() async {
    try {
      _serverSocket = await ServerSocket.bind(InternetAddress.anyIPv4, SERVER_PORT);
      _updateStatus("Server listening on port $SERVER_PORT");
      
      _serverSocket!.listen((Socket clientSocket) {
        _handleClientConnection(clientSocket);
      });
    } catch (e) {
      _updateStatus("Server error: $e");
    }
  }
  
  /// Handle incoming student connection
  void _handleClientConnection(Socket clientSocket) {
    _updateStatus("Client connected: ${clientSocket.remoteAddress.address}");
    
    clientSocket.listen(
      (List<int> data) {
        // Decode the data
        final jsonString = utf8.decode(data);
        try {
          final jsonData = jsonDecode(jsonString);
          final studentData = StudentAttendanceData.fromJson(jsonData);
          
          // Store the student data
          _attendedStudents[studentData.studentId] = studentData;
          
          // Notify callback
          if (onStudentAttended != null) {
            onStudentAttended!(studentData);
          }
          
          _updateStatus("Student signed in: ${studentData.studentName}");
          
          // Send acknowledgment
          clientSocket.write(jsonEncode({
            'status': 'success',
            'message': 'Attendance recorded',
            'timestamp': DateTime.now().millisecondsSinceEpoch
          }));
        } catch (e) {
          _updateStatus("Error processing student data: $e");
        }
      },
      onDone: () {
        _updateStatus("Client disconnected");
        clientSocket.close();
      },
      onError: (error) {
        _updateStatus("Client error: $error");
        clientSocket.close();
      },
    );
  }
  
  /// Student attendance method - connect to teacher's WiFi and send data
  Future<AttendanceResult> studentSignIn(String classId) async {
    try {
      if (!await initialize()) {
        return AttendanceResult(success: false, message: "Failed to initialize");
      }
      
      _updateStatus("Looking for teacher's network");
      
      // Trigger a WiFi scan
      final scanResult = await WiFiScan.instance.startScan();
      if (scanResult != CanStartScan.yes) {
        return AttendanceResult(success: false, message: "Failed to scan for networks: $scanResult");
      }
      
      // Get scan results
      final results = await WiFiScan.instance.getScannedResults();
      
      // Find teacher's network
      WiFiAccessPoint? targetNetwork;
      for (var network in results) {
        if (network.ssid.startsWith("$HOTSPOT_PREFIX$classId")) {
          targetNetwork = network;
          break;
        }
      }
      
      if (targetNetwork == null) {
        _updateStatus("Teacher's network not found");
        return AttendanceResult(success: false, message: "Teacher's network not found");
      }
      
      _updateStatus("Found teacher's network: ${targetNetwork.ssid}");
      
      // Since we can't programmatically connect to WiFi without user intervention in most cases,
      // we'll provide instructions for the user to connect manually
      
      final hotspotPassword = _generateHotspotPassword();
      _updateStatus("⚠️ Manual action required: Please connect to the WiFi network '${targetNetwork.ssid}' with password '$hotspotPassword'");
      
      // Wait for user to connect to WiFi
      final completer = Completer<bool>();
      late StreamSubscription<ConnectivityResult> subscription;
      
      subscription = Connectivity().onConnectivityChanged.listen((result) {
        if (result == ConnectivityResult.wifi && !completer.isCompleted) {
          completer.complete(true);
        }
      });
      
      // Add timeout
      Timer(const Duration(seconds: 30), () {
        if (!completer.isCompleted) {
          completer.complete(false);
        }
      });
      
      final connected = await completer.future;
      subscription.cancel();
      
      if (!connected) {
        return AttendanceResult(success: false, message: "Failed to connect to WiFi or timeout");
      }
      
      _updateStatus("Connected to WiFi, attempting to send attendance data");
      
      // Try to get the gateway IP (teacher's IP) or use default
      final info = NetworkInfo();
      final gateway = await info.getWifiGatewayIP() ?? "192.168.43.1"; // Common hotspot IP
      
      // Connect to teacher's server
      Socket? socket;
      try {
        socket = await Socket.connect(gateway, SERVER_PORT, timeout: const Duration(seconds: 5));
      } catch (e) {
        return AttendanceResult(success: false, message: "Could not connect to teacher's device: $e");
      }
      
      // Prepare student data
      final studentData = StudentAttendanceData(
        studentId: StudyData.instance.userName,
        studentName: StudyData.instance.userName,
        classId: classId,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        deviceInfo: await _getDeviceInfo(),
      );
      
      // Send data
      socket.write(jsonEncode(studentData.toJson()));
      
      // Wait for response (with timeout)
      AttendanceResult result;
      try {
        final responseCompleter = Completer<AttendanceResult>();
        
        // Set up timeout
        Timer(const Duration(seconds: 5), () {
          if (!responseCompleter.isCompleted) {
            responseCompleter.complete(AttendanceResult(
              success: false, 
              message: "Connection timed out"
            ));
          }
        });
        
        // Listen for response
        socket.listen(
          (List<int> data) {
            if (!responseCompleter.isCompleted) {
              final jsonString = utf8.decode(data);
              try {
                final jsonData = jsonDecode(jsonString);
                responseCompleter.complete(AttendanceResult(
                  success: true,
                  message: jsonData['message'] ?? "Attendance recorded",
                ));
              } catch (e) {
                responseCompleter.complete(AttendanceResult(
                  success: true,
                  message: "Attendance recorded (response error)",
                ));
              }
            }
          },
          onDone: () {
            if (!responseCompleter.isCompleted) {
              responseCompleter.complete(AttendanceResult(
                success: true,
                message: "Attendance recorded",
              ));
            }
          },
          onError: (error) {
            if (!responseCompleter.isCompleted) {
              responseCompleter.complete(AttendanceResult(
                success: false,
                message: "Connection error: $error",
              ));
            }
          },
        );
        
        result = await responseCompleter.future;
      } finally {
        // Close socket
        socket.close();
        
        // Remind user they may want to disconnect from the teacher's WiFi
        _updateStatus("You can now disconnect from the teacher's WiFi network");
      }
      
      return result;
    } catch (e) {
      _updateStatus("Error in student sign-in: $e");
      return AttendanceResult(success: false, message: "Error: $e");
    }
  }
  
  /// Generate a standard password for the hotspot
  String _generateHotspotPassword() {
    // Simple password generation - in a real app, you might want something more secure
    return "class1234";
  }
  
  /// Get device information for the attendance record
  Future<String> _getDeviceInfo() async {
    try {
      return Platform.operatingSystem + " " + Platform.operatingSystemVersion;
    } catch (e) {
      return "Unknown device";
    }
  }
  
  /// Update status and notify listeners
  void _updateStatus(String status) {
    debugPrint("HotspotAttendance: $status");
    if (onStatusChanged != null) {
      onStatusChanged!(status);
    }
  }
  
  /// Get the list of attended students
  Map<String, StudentAttendanceData> getAttendedStudents() {
    return Map.from(_attendedStudents);
  }
  
  /// Check if attendance session is active
  bool isSessionActive() {
    return _isHotspotActive;
  }
  
  /// 新增：获取当前会话信息
  Map<String, dynamic> getSessionInfo() {
    return {
      'classId': _classId,
      'teacherName': _teacherName, 
      'startTime': _sessionStartTime,
      'endTime': _sessionEndTime,
      'isActive': _isHotspotActive,
      'attendedCount': _attendedStudents.length,
    };
  }
  
  /// 新增：导出签到数据为JSON格式
  String exportAttendanceDataAsJson() {
    final data = {
      'sessionInfo': {
        'classId': _classId,
        'teacherName': _teacherName,
        'startTime': _sessionStartTime?.toIso8601String(),
        'endTime': _sessionEndTime?.toIso8601String(),
      },
      'attendees': _attendedStudents.values.map((student) => student.toJson()).toList(),
    };
    
    return jsonEncode(data);
  }
  
  /// 新增：导出签到数据为CSV格式
  String exportAttendanceDataAsCsv() {
    // CSV 标题行
    final csvData = StringBuffer("学号,姓名,班级,签到时间,设备信息\n");
    
    // 添加每个学生的数据行
    for (var student in _attendedStudents.values) {
      final timestamp = DateTime.fromMillisecondsSinceEpoch(student.timestamp);
      final formattedTime = "${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}";
      
      csvData.write('"${student.studentId}","${student.studentName}","${student.classId}","$formattedTime","${student.deviceInfo}"\n');
    }
    
    return csvData.toString();
  }
  
  /// 新增：清除当前会话数据
  void clearSessionData() {
    _attendedStudents.clear();
    _sessionStartTime = null;
    _sessionEndTime = null;
    _classId = "";
    _teacherName = "";
    _updateStatus("Session data cleared");
  }
  
  /// 新增：手动添加学生签到记录
  void addManualAttendance(String studentId, String studentName) {
    if (studentId.isEmpty || studentName.isEmpty) {
      _updateStatus("Student ID and name cannot be empty");
      return;
    }
    
    final studentData = StudentAttendanceData(
      studentId: studentId,
      studentName: studentName,
      classId: _classId,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      deviceInfo: "Manual entry",
    );
    
    _attendedStudents[studentId] = studentData;
    
    if (onStudentAttended != null) {
      onStudentAttended!(studentData);
    }
    
    _updateStatus("Manually added attendance for: $studentName");
  }
  
  /// 新增：删除学生签到记录
  bool removeAttendance(String studentId) {
    final removed = _attendedStudents.remove(studentId);
    if (removed != null) {
      _updateStatus("Removed attendance record for student ID: $studentId");
      return true;
    } else {
      _updateStatus("No attendance record found for student ID: $studentId");
      return false;
    }
  }
}

/// Student attendance data model
class StudentAttendanceData {
  final String studentId;
  final String studentName;
  final String classId;
  final int timestamp;
  final String deviceInfo;
  
  StudentAttendanceData({
    required this.studentId,
    required this.studentName,
    required this.classId,
    required this.timestamp,
    required this.deviceInfo,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'classId': classId,
      'timestamp': timestamp,
      'deviceInfo': deviceInfo,
    };
  }
  
  static StudentAttendanceData fromJson(Map<String, dynamic> json) {
    return StudentAttendanceData(
      studentId: json['studentId'],
      studentName: json['studentName'],
      classId: json['classId'],
      timestamp: json['timestamp'],
      deviceInfo: json['deviceInfo'],
    );
  }
  
  DateTime getDateTime() {
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }
  
  String getFormattedTime() {
    final dt = getDateTime();
    return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }
}

/// Result of student attendance attempt
class AttendanceResult {
  final bool success;
  final String message;
  
  AttendanceResult({
    required this.success,
    required this.message,
  });
}