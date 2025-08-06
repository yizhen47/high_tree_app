
// 社区页面
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_application_1/tool/bluetooth_chat_manager.dart';
import 'package:flutter_application_1/tool/study_data.dart';
import 'package:provider/provider.dart';

import 'home.dart';

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> with SingleTickerProviderStateMixin {
  // 临时变量用于切换学生/教师角色 (在实际应用中，应从用户账户信息获取)
  bool isTeacher = false;
  
  // 选项卡控制器 (用于学生视图的聊天室/问答选项卡)
  late TabController _tabController;
  
  // 蓝牙聊天相关数据
  List<ChatMessage> _chatMessages = [];
  List<StudentInfo> _connectedStudents = [];
  
  // 模拟问答数据
  final List<Map<String, dynamic>> _qaItems = [
    {
      'question': '如何理解微分方程的特解和通解的关系？',
      'asker': '王同学',
      'time': '昨天',
      'answers': 3,
      'solved': true
    },
    {
      'question': '二次函数的顶点式与一般式如何转换？',
      'asker': '李同学',
      'time': '今天',
      'answers': 2,
      'solved': false
    },
    {
      'question': '向量的点乘和叉乘有什么几何意义？',
      'asker': '张同学',
      'time': '2天前',
      'answers': 5,
      'solved': true
    },
    {
      'question': '如何判断一个数列是否收敛？',
      'asker': '赵同学',
      'time': '3天前',
      'answers': 4,
      'solved': true
    },
  ];
  
  
  // 模拟当前课程信息
  final Map<String, dynamic> _currentClass = {
    'name': '高等数学（上）',
    'teacher': '李教授',
    'time': '周一 8:30-10:00',
    'room': '理教楼 301',
    'studentCount': 42,
    'attendedCount': 0, // 初始化为0，将根据实际签到人数更新
    'id': 'MATH101',
  };
  
  // 蓝牙聊天管理器
  final BluetoothChatManager _bluetoothManager = BluetoothChatManager();
  
  // Status message for bluetooth operations
  String _statusMessage = "";
  bool _operationInProgress = false;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // 设置蓝牙管理器回调
    _bluetoothManager.onStatusChanged = (status) {
      setState(() {
        _statusMessage = status;
      });
    };
    
    _bluetoothManager.onNewMessage = (message) {
      setState(() {
        _chatMessages.add(message);
      });
    };
    
    _bluetoothManager.onStudentJoined = (student) {
      setState(() {
        _connectedStudents.add(student);
        _currentClass['attendedCount'] = _connectedStudents.where((s) => s.isAttended).length;
      });
    };
    
    _bluetoothManager.onStudentAttended = (student) {
      setState(() {
        student.isAttended = true;
        _currentClass['attendedCount'] = _connectedStudents.where((s) => s.isAttended).length;
      });
    };
    
    // 初始化聊天消息 - 创建可修改的副本
    _chatMessages = List.from(_bluetoothManager.chatMessages);
    _connectedStudents = List.from(_bluetoothManager.getConnectedStudents());
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _bluetoothManager.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            flexibleSpace: _buildHeader(),
            actions: [
              // 切换角色按钮 (仅用于演示)
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: IconButton(
                  icon: Icon(
                    isTeacher ? Icons.school : Icons.person,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      isTeacher = !isTeacher;
                      // 停止当前服务并重置状态
                      _bluetoothManager.stop().then((_) {
                          setState(() {
                              _chatMessages = [];
                              _connectedStudents = [];
                              _statusMessage = "";
                              _operationInProgress = false;
                          });
                      });
                    });
                  },
                ),
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.all(12),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildCurrentClassCard(),
                if (_statusMessage.isNotEmpty)
                  _buildStatusCard(),
                const SizedBox(height: 16),
                // 根据角色显示不同内容
                if (isTeacher)
                  _buildTeacherView()
                else
                  _buildStudentView(),
              ]),
            ),
          ),
        ],
      ),
      // 学生视图底部添加消息输入框
      bottomNavigationBar: !isTeacher && _tabController.index == 0
          ? _buildMessageInput()
          : null,
    );
  }
  
  // Build status card for bluetooth operations
  Widget _buildStatusCard() {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: CommonComponents.buildCommonCard(
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _operationInProgress 
                        ? Icons.bluetooth_searching 
                        : Icons.info_outline,
                    color: _operationInProgress 
                        ? AppTheme.primaryColor 
                        : Colors.orange,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _statusMessage,
                      style: TextStyle(
                        fontSize: 12,
                        color: _operationInProgress 
                            ? AppTheme.textPrimary 
                            : Colors.orange,
                      ),
                    ),
                  ),
                  if (_operationInProgress)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return FlexibleSpaceBar(
      background: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 顶部标题
                  Text(
                    isTeacher ? '蓝牙课堂管理' : '蓝牙课堂互动',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // 当前状态
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      isTeacher 
                          ? '当前课堂: ${_currentClass['name']}'
                          : '${_currentClass['name']} - ${_currentClass['teacher']}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  // 当前课程卡片
  Widget _buildCurrentClassCard() {
    return CommonComponents.buildCommonCard(
      Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.bluetooth,
                    color: AppTheme.primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentClass['name'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_currentClass['time']} | ${_currentClass['room']}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // 学生显示连接/签到按钮，老师显示开始/结束课堂按钮
                if (!isTeacher)
                  _buildStudentButtons()
                else
                  _buildTeacherButtons()
              ],
            ),
            if (isTeacher)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      icon: Icons.people,
                      value: '${_currentClass['studentCount']}',
                      label: '总人数',
                    ),
                    _buildStatItem(
                      icon: Icons.check_circle,
                      value: '${_connectedStudents.length}',
                      label: '已连接',
                      color: Colors.blue,
                    ),
                    _buildStatItem(
                      icon: Icons.verified,
                      value: '${_connectedStudents.where((s) => s.isAttended).length}',
                      label: '已签到',
                      color: Colors.green,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  // Student buttons
  Widget _buildStudentButtons() {
    if (!_bluetoothManager.isInitialized) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          onTap: _operationInProgress ? null : _initializeBluetooth,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text(
              _operationInProgress ? '初始化中...' : '初始化蓝牙',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      );
    }
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // 连接状态指示器
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: _operationInProgress ? null : _connectToTeacher,
            borderRadius: BorderRadius.circular(12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.bluetooth_connected,
                  size: 12,
                  color: Colors.blue,
                ),
                const SizedBox(width: 4),
                Text(
                  '连接课堂',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.blue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        // 签到按钮
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
                    ),
          child: InkWell(
            onTap: _operationInProgress ? null : _attendClass,
            borderRadius: BorderRadius.circular(12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle,
                  size: 12,
                  color: Colors.green,
                ),
                const SizedBox(width: 4),
                Text(
                  '签到',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.green,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  // Teacher buttons
  Widget _buildTeacherButtons() {
    if (!_bluetoothManager.isInitialized) {
      return ElevatedButton(
        onPressed: _operationInProgress ? null : _initializeBluetooth,
      style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        textStyle: const TextStyle(fontSize: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
        child: Text(_operationInProgress ? '初始化中...' : '初始化蓝牙'),
    );
  }
  
    // If teacher mode is active, show stop button
    if (_bluetoothManager.isTeacherMode) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.bluetooth_connected, size: 12, color: Colors.green),
                const SizedBox(width: 4),
                Text(
                  '${_connectedStudents.length}人',
                  style: const TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _operationInProgress ? null : _stopTeacherMode,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              textStyle: const TextStyle(fontSize: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('结束课堂'),
          ),
        ],
      );
    } else {
      // If no teacher mode is active, show start button
      return ElevatedButton(
        onPressed: _operationInProgress ? null : _startTeacherMode,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              textStyle: const TextStyle(fontSize: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
        child: const Text('开始课堂'),
      );
    }
  }

  // 学生视图
  Widget _buildStudentView() {
    return Column(
      children: [
        // 选项卡标题
        TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primaryColor,
          tabs: const [
            Tab(text: '蓝牙聊天'),
            Tab(text: '问答区'),
          ],
        ),
        
        // 选项卡内容
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.5, // 设置适当的高度
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildChatRoom(),
              _buildQASection(),
            ],
          ),
        ),
      ],
    );
  }
  
  // 教师视图
  Widget _buildTeacherView() {
    return _buildStudentsList();
  }
  
  // 聊天室
  Widget _buildChatRoom() {
    if (_chatMessages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              '还没有聊天消息',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isTeacher ? '等待学生连接...' : '请先连接到教师的蓝牙',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.only(top: 16),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _chatMessages.length,
      itemBuilder: (context, index) {
        final message = _chatMessages[index];
        final bool isTeacherMessage = message.senderName == _currentClass['teacher'];
        final bool isSystemMessage = message.type == ChatMessageType.system;
        
        if (isSystemMessage) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  message.content,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ),
          );
        }
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: isTeacherMessage 
                ? MainAxisAlignment.start 
                : MainAxisAlignment.end,
            children: [
              if (isTeacherMessage) ...[
                const CircleAvatar(
                  radius: 16,
                  backgroundColor: AppTheme.primaryColor,
                  child: Text('T', style: TextStyle(color: Colors.white, fontSize: 12)),
                ),
                const SizedBox(width: 8),
              ],
              
              Flexible(
                child: Column(
                  crossAxisAlignment: isTeacherMessage 
                      ? CrossAxisAlignment.start 
                      : CrossAxisAlignment.end,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2.0),
                      child: Text(
                        '${message.senderName} · ${_formatMessageTime(message.timestamp)}',
                        style: TextStyle(
                          fontSize: 10,
                          color: isTeacherMessage 
                              ? AppTheme.primaryColor 
                              : AppTheme.textSecondary,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isTeacherMessage 
                            ? AppTheme.primaryColor.withOpacity(0.1) 
                            : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        message.content,
                        style: TextStyle(
                          fontSize: 13,
                          color: isTeacherMessage 
                              ? AppTheme.textPrimary 
                              : AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              if (!isTeacherMessage) ...[
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.grey[300],
                  child: Text(
                    message.senderName.isNotEmpty ? message.senderName[0] : 'S',
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
  
  // 问答区
  Widget _buildQASection() {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 16),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _qaItems.length,
      itemBuilder: (context, index) {
        final item = _qaItems[index];
        
        return CommonComponents.buildCommonCard(
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.question_answer,
                      size: 16,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item['question'],
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${item['asker']} · ${item['time']}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.comment,
                          size: 12,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${item['answers']}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: item['solved'] 
                                ? Colors.green.withOpacity(0.1) 
                                : Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            item['solved'] ? '已解决' : '待解答',
                            style: TextStyle(
                              fontSize: 10,
                              color: item['solved'] ? Colors.green : Colors.orange,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  // 学生列表 (教师视图)
  Widget _buildStudentsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '连接的学生',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
                    ),
                  IconButton(
                    onPressed: () {
                  // 刷新学生列表
                  setState(() {
                    _connectedStudents = _bluetoothManager.getConnectedStudents();
                  });
                    },
                    icon: const Icon(Icons.refresh, size: 18),
                tooltip: '刷新学生列表',
                    color: AppTheme.primaryColor,
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(8),
              ),
            ],
          ),
        ),
        CommonComponents.buildCommonCard(
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    const Expanded(
                      flex: 3,
                      child: Text(
                        '学生',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                    const Expanded(
                      flex: 2,
                      child: Text(
                        '连接时间',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                    const Expanded(
                      flex: 2,
                      child: Text(
                        '签到状态',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              if (_connectedStudents.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32.0),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.bluetooth_disabled,
                          size: 36,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _bluetoothManager.isTeacherMode 
                              ? '等待学生连接...' 
                              : '课堂尚未开始',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ),
                )
              else
                ...List.generate(
                  _connectedStudents.length,
                  (index) => Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(
                                _connectedStudents[index].name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                                child: Text(
                                _formatTime(_connectedStudents[index].joinTime),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _connectedStudents[index].isAttended 
                                      ? Colors.green.withOpacity(0.1)
                                      : Colors.grey.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              child: Text(
                                  _connectedStudents[index].isAttended ? '已签到' : '未签到',
                                style: TextStyle(
                                  fontSize: 12,
                                    color: _connectedStudents[index].isAttended 
                                        ? Colors.green 
                                        : Colors.grey,
                                ),
                              ),
                            ),
                                          ),
                                        ],
                                      ),
                      ),
                      if (index < _connectedStudents.length - 1)
                        const Divider(height: 1, indent: 16, endIndent: 16),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
  
  // 统计项
  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    Color? color,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          size: 18,
          color: color ?? AppTheme.textPrimary,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color ?? AppTheme.textPrimary,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
  
  // 消息输入框
  Widget _buildMessageInput() {
    final TextEditingController messageController = TextEditingController();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -1),
            blurRadius: 3,
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            color: Colors.grey,
            onPressed: () {},
          ),
          Expanded(
            child: TextField(
              controller: messageController,
              decoration: InputDecoration(
                hintText: '发送消息...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                border: InputBorder.none,
              ),
              onSubmitted: (text) {
                _sendMessage(text);
                messageController.clear();
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            color: AppTheme.primaryColor,
            onPressed: () {
              if (messageController.text.trim().isNotEmpty) {
                _sendMessage(messageController.text.trim());
                messageController.clear();
              }
            },
          ),
        ],
      ),
    );
  }

  // 蓝牙操作方法
  Future<void> _initializeBluetooth() async {
    setState(() {
      _operationInProgress = true;
      _statusMessage = "正在初始化蓝牙...";
    });
    
    final success = await _bluetoothManager.initialize();
    
    setState(() {
      _operationInProgress = false;
      if (success) {
        _statusMessage = "蓝牙初始化成功";
      } else {
        _statusMessage = "蓝牙初始化失败";
      }
    });
    
    // Clear status message after a few seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _statusMessage = "";
        });
      }
    });
  }
  
  Future<void> _startTeacherMode() async {
    setState(() {
      _operationInProgress = true;
      _statusMessage = "正在启动教师模式...";
    });
    
    final success = await _bluetoothManager.startTeacherMode(
      _currentClass['id'],
      _currentClass['teacher'],
    );
    
    setState(() {
      _operationInProgress = false;
      if (success) {
        _statusMessage = "教师模式已启动，等待学生连接";
      } else {
        _statusMessage = "启动教师模式失败";
      }
    });
  }
  
  Future<void> _stopTeacherMode() async {
    setState(() {
      _operationInProgress = true;
      _statusMessage = "正在结束课堂...";
    });
    
    await _bluetoothManager.stop();
    
    setState(() {
      _operationInProgress = false;
      _statusMessage = "课堂已结束";
      // 重新初始化列表而不是清空不可修改的列表
      _connectedStudents = [];
      _chatMessages = [];
      _currentClass['attendedCount'] = 0;
    });
    
    // Clear status message after a few seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _statusMessage = "";
        });
      }
    });
  }
  
  void _connectToTeacher() async {
    setState(() {
      _operationInProgress = true;
      _statusMessage = '正在搜索教师设备...';
    });

    List<BluetoothDevice> devices = await _bluetoothManager.searchForTeacherDevices();

    setState(() {
      _operationInProgress = false;
    });

    if (devices.isEmpty) {
      setState(() {
        _statusMessage = '未找到任何教师设备';
      });
      return;
    }

    // Show a dialog to select a teacher device
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('选择一个课堂'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: devices.length,
              itemBuilder: (BuildContext context, int index) {
                return ListTile(
                  title: Text(devices[index].platformName),
                  subtitle: Text(devices[index].remoteId.toString()),
                  onTap: () {
                    Navigator.of(context).pop();
                    _initiateConnection(devices[index]);
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _initiateConnection(BluetoothDevice device) async {
    setState(() {
      _operationInProgress = true;
      _statusMessage = '正在连接到 ${device.platformName}...';
    });

    bool success = await _bluetoothManager.connectToTeacher(device);

    setState(() {
      _operationInProgress = false;
      if (success) {
        _statusMessage = '已成功连接到课堂';
              } else {
        _statusMessage = '连接失败，请重试';
      }
    });
  }

  void _attendClass() async {
    setState(() {
      _operationInProgress = true;
      _statusMessage = "正在签到...";
    });
    
    final success = await _bluetoothManager.attendClass();
    
    setState(() {
      _operationInProgress = false;
      if (success) {
        _statusMessage = "签到成功";
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
            content: Text('签到成功!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      } else {
        _statusMessage = "签到失败";
      }
    });
    
    // Clear status message after a few seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _statusMessage = "";
        });
      }
    });
  }
  
  // 发送消息
  void _sendMessage(String content) {
    if (content.trim().isEmpty) return;
    
    _bluetoothManager.sendChatMessage(content);
    
    // 显示发送成功提示
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('消息已发送'),
        backgroundColor: AppTheme.primaryColor,
        duration: Duration(seconds: 1),
      ),
    );
  }
  
  // 格式化消息时间
  String _formatMessageTime(DateTime timestamp) {
    final now = DateTime.now();
    
    if (timestamp.day == now.day && 
        timestamp.month == now.month && 
        timestamp.year == now.year) {
      // 今天的消息，只显示时间
      return "${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}";
    } else {
      // 其他日期的消息，显示月日
      return "${timestamp.month}/${timestamp.day}";
    }
  }
  
  // 格式化时间
  String _formatTime(DateTime dateTime) {
    return "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
  }
}
