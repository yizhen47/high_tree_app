import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;

class AIService {
  // DeepSeek API配置
  static const String _baseUrl = 'https://api.deepseek.com/v1/chat/completions';
  
  // API密钥（Base64编码存储以增加安全性）
  static const String _encodedApiKey = 'c2stYmZiZmVlNjFkZjM1NDU4Yzk3NTRlOTRkZDYxMjA1MmE=';
  static String get _apiKey => String.fromCharCodes(base64.decode(_encodedApiKey));
  
  // 单例模式
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();
  
  /// 向AI发送问题并获取回答（流式输出）
  /// [question] 用户的问题
  /// [context] 可选的上下文信息（如题目内容）
  /// [onStream] 流式回调函数，接收每个数据块
  /// 返回完整的AI回答
  Future<String> askQuestionStream(
    String question, {
    String? context,
    void Function(String chunk)? onStream,
  }) async {
    try {
      // 构建请求消息
      List<Map<String, String>> messages = [];
      
      // 优化的系统提示词
      String systemPrompt;
      if (context != null && context.isNotEmpty) {
        systemPrompt = '''你是一个专业的学习助手。请基于提供的题目内容回答用户问题。

要求：
- 用自然、流畅的语言回答，避免分点列举
- 回答要简洁明了，直击要点
- 如果是解题问题，重点说明解题思路和关键步骤
- 语气要亲切，像老师在面对面指导学生

题目内容：
$context''';
      } else {
        systemPrompt = '''你是一个专业的学习助手，请用自然、流畅的语言回答学生的问题。

要求：
- 避免分点列举，用连贯的自然语言表达
- 回答要简洁明了，直击要点
- 语气要亲切，像老师在面对面指导学生''';
      }
      
      messages.add({
        'role': 'system',
        'content': systemPrompt
      });
      
      // 添加用户问题
      messages.add({
        'role': 'user',
        'content': question
      });
      
      // 构建请求体
      final requestBody = {
        'model': 'deepseek-chat',
        'messages': messages,
        'temperature': 0.7,
        'max_tokens': 2000,
        'stream': true,
      };
      
      // 发送HTTP请求
      final request = http.Request('POST', Uri.parse(_baseUrl));
      request.headers.addAll({
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      });
      request.body = json.encode(requestBody);
      
      final streamedResponse = await request.send();
      
      if (streamedResponse.statusCode == 200) {
        String fullResponse = '';
        
        await for (final chunk in streamedResponse.stream.transform(utf8.decoder)) {
          // 处理SSE格式的数据
          final lines = chunk.split('\n');
          for (final line in lines) {
            if (line.startsWith('data: ')) {
              final data = line.substring(6).trim();
              if (data == '[DONE]') {
                break;
              }
              
              try {
                final jsonData = json.decode(data);
                final content = jsonData['choices']?[0]?['delta']?['content'];
                if (content != null && content is String) {
                  fullResponse += content;
                  onStream?.call(content);
                }
              } catch (e) {
                // 忽略JSON解析错误，继续处理下一行
              }
            }
          }
        }
        
        return fullResponse.isNotEmpty ? fullResponse : '抱歉，AI没有返回有效回答。';
      } else {
        // 处理错误响应
        print('HighTree-Debug: AI API request failed with status: ${streamedResponse.statusCode}');
        
        if (streamedResponse.statusCode == 401) {
          return '错误：API密钥无效，请检查配置。';
        } else if (streamedResponse.statusCode == 429) {
          return '错误：请求过于频繁，请稍后重试。';
        } else if (streamedResponse.statusCode >= 500) {
          return '错误：服务器暂时不可用，请稍后重试。';
        } else {
          return '错误：请求失败（状态码：${streamedResponse.statusCode}）';
        }
      }
    } catch (e) {
      print('HighTree-Debug: AI service error: $e');
      return '错误：网络连接失败，请检查网络设置。';
    }
  }

  /// 向AI发送问题并获取回答（非流式，保持兼容性）
  /// [question] 用户的问题
  /// [context] 可选的上下文信息（如题目内容）
  /// 返回AI的回答
  Future<String> askQuestion(String question, {String? context}) async {
    try {
      // 构建请求消息
      List<Map<String, String>> messages = [];
      
      // 使用优化的系统提示词
      String systemPrompt;
      if (context != null && context.isNotEmpty) {
        systemPrompt = '''你是一个学习助手，用简洁自然的语言回答问题。

回答要求：
- 用口语化的表达，就像面对面聊天一样
- 回答要简短精炼，控制在2-3句话内
- 数学公式用LaTeX格式，如 \$x^2 + y^2 = z^2\$
- 不要用markdown格式，不要分点列举
- 直接说重点，别绕弯子

题目：$context''';
      } else {
        systemPrompt = '''你是一个学习助手，用简洁自然的语言回答学生问题。

回答要求：
- 用口语化的表达，就像面对面聊天一样
- 回答要简短精炼，控制在2-3句话内
- 数学公式用LaTeX格式，如 \$x^2 + y^2 = z^2\$
- 不要用markdown格式，不要分点列举
- 直接说重点，别绕弯子''';
      }
      
      messages.add({
        'role': 'system',
        'content': systemPrompt
      });
      
      // 添加用户问题
      messages.add({
        'role': 'user',
        'content': question
      });
      
      // 构建请求体
      final requestBody = {
        'model': 'deepseek-chat',
        'messages': messages,
        'temperature': 0.7,
        'max_tokens': 2000,
        'stream': false,
      };
      
      // 发送HTTP请求
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: json.encode(requestBody),
      );
      
      if (response.statusCode == 200) {
        final responseData = json.decode(utf8.decode(response.bodyBytes));
        
        // 提取AI回答
        if (responseData['choices'] != null && 
            responseData['choices'].isNotEmpty &&
            responseData['choices'][0]['message'] != null) {
          return responseData['choices'][0]['message']['content'] ?? '抱歉，AI没有返回有效回答。';
        } else {
          return '抱歉，AI回答格式异常。';
        }
      } else {
        // 处理错误响应
        print('HighTree-Debug: AI API request failed with status: ${response.statusCode}');
        print('HighTree-Debug: Response body: ${response.body}');
        
        if (response.statusCode == 401) {
          return '错误：API密钥无效，请检查配置。';
        } else if (response.statusCode == 429) {
          return '错误：请求过于频繁，请稍后重试。';
        } else if (response.statusCode >= 500) {
          return '错误：服务器暂时不可用，请稍后重试。';
        } else {
          return '错误：请求失败（状态码：${response.statusCode}）';
        }
      }
    } catch (e) {
      print('HighTree-Debug: AI service error: $e');
      return '错误：网络连接失败，请检查网络设置。';
    }
  }
  
  /// 获取题目解析
  /// [questionText] 题目内容
  /// [options] 选项（如果是选择题）
  /// [difficulty] 难度级别
  Future<String> getQuestionAnalysis(String questionText, {List<String>? options, String? difficulty}) async {
    String prompt = '请分析以下题目：\n\n$questionText';
    
    if (options != null && options.isNotEmpty) {
      prompt += '\n\n选项：\n';
      for (int i = 0; i < options.length; i++) {
        prompt += '${String.fromCharCode(65 + i)}. ${options[i]}\n';
      }
    }
    
    if (difficulty != null) {
      prompt += '\n\n难度：$difficulty';
    }
    
    prompt += '\n\n请提供详细的解题思路和步骤。';
    
    return await askQuestion(prompt);
  }
  
  /// 获取知识点解释
  /// [knowledgePoint] 知识点名称
  /// [questionContext] 相关题目上下文
  Future<String> explainKnowledgePoint(String knowledgePoint, {String? questionContext}) async {
    String prompt = '请详细解释以下知识点：$knowledgePoint';
    
    if (questionContext != null && questionContext.isNotEmpty) {
      prompt += '\n\n相关题目背景：\n$questionContext';
      prompt += '\n\n请结合这个题目背景来解释该知识点。';
    }
    
    return await askQuestion(prompt);
  }
  
  /// 获取学习建议
  /// [weakPoints] 薄弱知识点列表
  /// [studyLevel] 学习阶段（如：初中、高中、大学）
  Future<String> getStudySuggestions(List<String> weakPoints, {String? studyLevel}) async {
    String prompt = '学生在以下知识点方面比较薄弱：\n';
    for (String point in weakPoints) {
      prompt += '- $point\n';
    }
    
    if (studyLevel != null) {
      prompt += '\n学习阶段：$studyLevel';
    }
    
    prompt += '\n\n请提供针对性的学习建议和练习方法。';
    
    return await askQuestion(prompt);
  }
  
  /// 检查API密钥是否已配置
  bool isApiKeyConfigured() {
    try {
      final decodedKey = _apiKey;
      return decodedKey.isNotEmpty && decodedKey.startsWith('sk-');
    } catch (e) {
      return false;
    }
  }
} 