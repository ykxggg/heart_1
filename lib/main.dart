import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform;
import 'package:dio/dio.dart';
import 'services/storage_service.dart';

void main() {
  if (kIsWeb) {
    print('Web平台使用SharedPreferences存储');
  } else if (defaultTargetPlatform == TargetPlatform.android) {
    print('Android平台使用JSON文件存储');
  } else if (defaultTargetPlatform == TargetPlatform.windows || 
             defaultTargetPlatform == TargetPlatform.macOS ||
             defaultTargetPlatform == TargetPlatform.linux) {
    print('桌面平台使用JSON文件存储');
  } else if (defaultTargetPlatform == TargetPlatform.iOS) {
    print('iOS平台使用JSON文件存储');
  } else {
    print('其他平台使用JSON文件存储');
  }
  runApp(const ChatApp());
}

class ZhipuApiService {
  final Dio _dio = Dio();
  final String _apiKey;
  final String _baseUrl = 'https://open.bigmodel.cn/api/paas/v4/chat/completions';

  ZhipuApiService({required String apiKey}) : _apiKey = apiKey {
    _dio.options.headers = {
      'Authorization': 'Bearer $_apiKey',
      'Content-Type': 'application/json',
    };
  }

  Stream<String> streamSendMessage(String message, {List<Map<String, String>>? history}) async* {
    try {
      final messages = <Map<String, String>>[];
      
      if (history != null) {
        messages.addAll(history);
      }
      
      messages.add({
        'role': 'user',
        'content': message,
      });

      final requestData = {
        'model': 'glm-4.7-flash',
        'messages': messages,
        'thinking': {
          'type': 'disabled',
        },
        'stream': true,
        'max_tokens': 65536,
        'temperature': 1.0,
      };

      print('========== 智谱API 请求 ==========');
      print('URL: $_baseUrl');
      print('请求头: ${_dio.options.headers}');
      print('请求体: ${jsonEncode(requestData)}');
      print('消息数量: ${messages.length}');
      print('============================\n');

      final response = await _dio.post(
        _baseUrl,
        data: requestData,
        options: Options(
          responseType: ResponseType.stream,
          receiveTimeout: const Duration(minutes: 5),
          sendTimeout: const Duration(minutes: 1),
        ),
      );

      print('========== 智谱API 响应 ==========');
      print('状态码: ${response.statusCode}');
      print('响应头: ${response.headers}');
      print('开始接收流式数据...\n');

      final buffer = StringBuffer();
      int chunkCount = 0;

      await for (final chunk in response.data.stream) {
        chunkCount++;
        final decodedChunk = utf8.decode(chunk);
        print('========== Chunk #$chunkCount ==========');
        print('原始字节长度: ${chunk.length}');
        print('解码后内容: $decodedChunk');
        print('===================================\n');
        
        final lines = decodedChunk.split('\n');
        
        for (final line in lines) {
          if (line.trim().isEmpty) continue;
          
          if (line.startsWith('data: ')) {
            final data = line.substring(6).trim();
            print('--- 发现data行: $data');
            
            if (data == '[DONE]') {
              print('\n========== 流式数据接收完成 ==========');
              print('总块数: $chunkCount');
              print('完整响应: ${buffer.toString()}');
              print('====================================\n');
              return;
            }
            
            try {
              final json = jsonDecode(data);
              print('解析后的JSON: $json');
              
              if (json['choices'] != null && 
                  json['choices'].isNotEmpty && 
                  json['choices'][0]['delta'] != null) {
                final content = json['choices'][0]['delta']['content'] ?? '';
                print('>>> 提取到内容: "$content"');
                if (content.isNotEmpty) {
                  buffer.write(content);
                  print('当前buffer长度: ${buffer.length}');
                  yield content;
                }
              }
            } catch (e) {
              print('解析错误: $e');
              print('无法解析的数据: $data');
              continue;
            }
          }
        }
      }
    } on DioException catch (e) {
      print('========== API 错误 ==========');
      print('错误类型: DioException');
      print('错误信息: ${e.message}');
      print('错误类型: ${e.type}');
      print('响应状态码: ${e.response?.statusCode}');
      print('响应数据: ${e.response?.data}');
      print('============================\n');
      
      if (e.response != null) {
        yield 'API错误: ${e.response?.statusCode} - ${e.response?.data}';
      } else {
        yield '网络错误: ${e.message}';
      }
    } catch (e) {
      print('========== 未知错误 ==========');
      print('错误信息: $e');
      print('堆栈跟踪: ${StackTrace.current}');
      print('============================\n');
      
      yield '发送消息失败: $e';
    }
  }
}

class ChatApp extends StatelessWidget {
  const ChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Chat',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF007AFF),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'SF Pro Display',
      ),
      home: const ChatScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  int _selectedHistoryIndex = 0;

  bool _isTyping = false;
  bool _isSidebarOpen = false;
  late AnimationController _sidebarAnimationController;
  late Animation<Offset> _sidebarSlideAnimation;
  late Animation<double> _sidebarFadeAnimation;
  late Animation<double> _overlayFadeAnimation;
  final Map<String, List<ChatMessage>> _chatMessagesMap = {};

  late final ZhipuApiService _apiService;
  final String _apiKey = '80e0fd36f3994cc7b07575132a552436.XfK6MOqMLmIS8OoS';

  final List<ChatHistory> _chatHistory = [];

  List<ChatMessage> get _messages {
    if (_chatHistory.isEmpty) return [];
    return _chatMessagesMap[_chatHistory[_selectedHistoryIndex].title] ?? [];
  }

  @override
  void initState() {
    super.initState();
    _apiService = ZhipuApiService(apiKey: _apiKey);
    _loadHistoryFromDatabase();
    
    _sidebarAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _sidebarSlideAnimation = Tween<Offset>(
      begin: const Offset(-1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _sidebarAnimationController,
      curve: Curves.easeInOutCubic,
    ));
    
    _sidebarFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _sidebarAnimationController,
      curve: const Interval(0.1, 1.0, curve: Curves.easeOut),
    ));
    
    _overlayFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _sidebarAnimationController,
      curve: Curves.easeIn,
    ));
  }

  Future<void> _loadHistoryFromDatabase() async {
    try {
      final storageService = StorageService.instance;
      final chats = await storageService.getChats();
      
      print('========== 加载历史记录 ==========');
      print('从存储加载了 ${chats.length} 个对话');
      
      if (chats.isEmpty) {
        print('存储为空，创建新对话');
        await _createNewChat();
        return;
      }
      
      final chatHistoryList = <ChatHistory>[];
      final chatMessagesMap = <String, List<ChatMessage>>{};
      
      for (final chat in chats) {
        final title = chat['title'] as String;
        final lastMessage = chat['last_message'] as String? ?? '';
        final timestamp = chat['timestamp'] as String? ?? '';
        final avatarTypeStr = chat['avatar_type'] as String? ?? 'AvatarType.ai';
        
        final avatarType = avatarTypeStr.contains('user') ? AvatarType.user : AvatarType.ai;
        
        final chatHistory = ChatHistory(
          title: title,
          lastMessage: lastMessage,
          timestamp: timestamp,
          avatarType: avatarType,
        );
        
        chatHistoryList.add(chatHistory);
        
        final messages = await storageService.getMessages(title);
        final messageList = <ChatMessage>[];
        
        for (final msg in messages) {
          final message = ChatMessage(
            content: msg['content'] as String,
            isUser: (msg['is_user'] as int) == 1,
            timestamp: DateTime.fromMillisecondsSinceEpoch(msg['timestamp'] as int),
          );
          messageList.add(message);
        }
        
        chatMessagesMap[title] = messageList;
        print('对话 "$title" 加载了 ${messageList.length} 条消息');
      }
      
      if (mounted) {
        setState(() {
          _chatHistory.clear();
          _chatHistory.addAll(chatHistoryList);
          _chatMessagesMap.clear();
          _chatMessagesMap.addAll(chatMessagesMap);
          _selectedHistoryIndex = 0;
        });
        print('历史记录加载完成，当前有 ${_chatHistory.length} 个对话');
      }
      print('================================\n');
    } catch (e, stackTrace) {
      print('========== 加载历史记录失败 ==========');
      print('错误类型: ${e.runtimeType}');
      print('错误信息: $e');
      print('堆栈跟踪: $stackTrace');
      print('================================\n');
      
      print('加载失败，创建新对话');
      await _createNewChat();
      
      if (mounted) {
        setState(() {
          _selectedHistoryIndex = 0;
        });
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _sidebarAnimationController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    if (_chatHistory.isEmpty) return;

    final currentTitle = _chatHistory[_selectedHistoryIndex].title;
    final userMessage = _messageController.text;

    print('========== 发送消息 ==========');
    print('当前对话: $currentTitle');
    print('用户消息: $userMessage');
    print('时间: ${DateTime.now()}');
    print('========================\n');

    setState(() {
      _chatMessagesMap[currentTitle]!.add(ChatMessage(
        content: userMessage,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isTyping = false;
      _messageController.clear();
    });

    final assistantMessageIndex = _chatMessagesMap[currentTitle]!.length;
    final messageTimestamp = DateTime.now();

    setState(() {
      _chatMessagesMap[currentTitle]!.add(ChatMessage(
        content: '让我想想',
        isUser: false,
        timestamp: messageTimestamp,
      ));
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      } catch (e) {
        print('滚动控制器错误: $e');
      }
    });

    try {
      final history = _chatMessagesMap[currentTitle]!
          .take(_chatMessagesMap[currentTitle]!.length - 1)
          .map((msg) => {
                'role': msg.isUser ? 'user' : 'assistant',
                'content': msg.content,
              })
          .toList();

      print('========== 历史消息 ==========');
      print('历史消息数量: ${history.length}');
      for (int i = 0; i < history.length; i++) {
        final content = history[i]['content'] ?? '';
        final preview = content.length > 50 ? '${content.substring(0, 50)}...' : content;
        print('${i + 1}. [${history[i]['role']}] $preview');
      }
      print('============================\n');

      final stream = _apiService.streamSendMessage(userMessage, history: history);
      final buffer = StringBuffer();
      int chunkCount = 0;

      print('========== 开始接收流式响应 ==========');
      
      await for (final chunk in stream) {
        chunkCount++;
        buffer.write(chunk);
        final newContent = buffer.toString();
        
        print('>>> 收到chunk #$chunkCount: "${chunk}"');
        print('>>> 当前完整内容长度: ${newContent.length}');
        print('>>> 当前内容: "$newContent"');
        
        if (mounted) {
          print('>>> 准备更新UI...');
          
          if (chunkCount == 1) {
            _isTyping = false;
          }
          
          _chatMessagesMap[currentTitle]![assistantMessageIndex].content = newContent;
          setState(() {});
          
          try {
            if (_scrollController.hasClients) {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 100),
                curve: Curves.easeOut,
              );
            }
          } catch (e) {
            print('滚动控制器错误: $e');
          }
          
          print('>>> UI已更新');
        }
        
        await Future.delayed(const Duration(milliseconds: 10));
      }
      
      print('=====================================\n');
      
      print('========== 消息发送完成 ==========');
      print('最终回复长度: ${buffer.length}');
      print('=====================================\n');
      
      await _saveMessagesToDatabase(currentTitle);
    } catch (e) {
      print('========== 发送失败 ==========');
      print('错误: $e');
      print('=====================================\n');
      
      final assistantMessageIndex = _chatMessagesMap[currentTitle]!.length - 1;
      setState(() {
        _chatMessagesMap[currentTitle]![assistantMessageIndex] = ChatMessage(
          content: '抱歉，发生了错误：$e',
          isUser: false,
          timestamp: DateTime.now(),
        );
        _isTyping = false;
      });
    }
  }

  Future<void> _saveMessagesToDatabase(String title) async {
    try {
      final storageService = StorageService.instance;
      final messages = _chatMessagesMap[title] ?? [];
      
      print('========== 保存消息到存储 ==========');
      print('对话: $title');
      print('消息数量: ${messages.length}');
      
      final lastMessage = messages.isNotEmpty ? messages.last.content : '';
      
      final chatData = {
        'title': title,
        'last_message': lastMessage,
        'timestamp': '刚刚',
        'avatar_type': _chatHistory.firstWhere((chat) => chat.title == title).avatarType.toString(),
      };
      
      await storageService.saveChat(chatData);
      print('更新对话信息完成');
      
      for (final msg in messages) {
        final messageData = {
          'content': msg.content,
          'is_user': msg.isUser ? 1 : 0,
          'timestamp': msg.timestamp.millisecondsSinceEpoch,
        };
        await storageService.saveMessage(title, messageData);
      }
      
      print('消息保存完成，共 ${messages.length} 条消息');
      print('================================');
    } catch (e, stackTrace) {
      print('保存消息失败: $e');
      print('堆栈跟踪: $stackTrace');
    }
  }

  void _clearAllHistory() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('确认清空'),
        content: const Text('确定要清空所有历史对话记录吗？此操作不可恢复。'),
        actions: [
          IOSStyleButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          IOSStyleButton(
            onPressed: () async {
              try {
                Navigator.pop(dialogContext);
                final storageService = StorageService.instance;
                await storageService.deleteAllChats();
                if (mounted) {
                  setState(() {
                    _chatMessagesMap.clear();
                    _chatHistory.clear();
                    _createNewChat();
                  });
                }
              } catch (e) {
                print('清空存储失败: $e');
              }
            },
            child: const Text(
              '确认清空',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createNewChat() async {
    final chatId = '新对话 ${_chatHistory.length + 1}';
    
    try {
      final storageService = StorageService.instance;
      await storageService.saveChat({
        'title': chatId,
        'last_message': '',
        'timestamp': '刚刚',
        'avatar_type': AvatarType.ai.toString(),
      });
      
      setState(() {
        _chatHistory.insert(0, ChatHistory(
          title: chatId,
          lastMessage: '',
          timestamp: '刚刚',
          avatarType: AvatarType.ai,
        ));
        _chatMessagesMap[chatId] = [
          ChatMessage(
            content: '你好！我是ChatGLM，有什么可以帮你的？',
            isUser: false,
            timestamp: DateTime.now(),
          ),
        ];
        _selectedHistoryIndex = 0;
        _isTyping = false;
      });
    } catch (e) {
      print('创建新对话失败: $e');
    }
  }

  Future<void> _deleteChat(int index) async {
    if (index < 0 || index >= _chatHistory.length) return;

    final chat = _chatHistory[index];
    final chatTitle = chat.title;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除对话 "$chatTitle" 吗？此操作不可恢复。'),
        actions: [
          IOSStyleButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          IOSStyleButton(
            onPressed: () async {
              try {
                Navigator.pop(dialogContext);

                final storageService = StorageService.instance;
                await storageService.deleteChat(chatTitle);

                if (mounted) {
                  setState(() {
                    _chatMessagesMap.remove(chatTitle);
                    _chatHistory.removeAt(index);

                    if (_selectedHistoryIndex >= _chatHistory.length) {
                      _selectedHistoryIndex = _chatHistory.length - 1;
                    }

                    if (_chatHistory.isEmpty) {
                      _createNewChat();
                    }
                  });
                }

                if (_isSidebarOpen) {
                  _sidebarAnimationController.reverse().then((_) {
                    if (mounted) {
                      setState(() {
                        _isSidebarOpen = false;
                      });
                    }
                  });
                }
              } catch (e) {
                print('删除对话失败: $e');
              }
            },
            child: const Text(
              '删除',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: Row(
              children: [
                if (!isMobile)
                  _buildSidebar()
                else
                  Container(),
                Expanded(
                  flex: 2,
                  child: _buildChatArea(),
                ),
              ],
            ),
          ),
          if (isMobile && _isSidebarOpen)
            FadeTransition(
              opacity: _overlayFadeAnimation,
              child: GestureDetector(
                onTap: () {
                  _sidebarAnimationController.reverse().then((_) {
                    if (mounted) {
                      setState(() {
                        _isSidebarOpen = false;
                      });
                    }
                  });
                },
                child: Container(
                  width: screenWidth,
                  height: MediaQuery.of(context).size.height,
                  color: Colors.black54,
                ),
              ),
            ),
          if (isMobile && _isSidebarOpen)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: SlideTransition(
                position: _sidebarSlideAnimation,
                child: FadeTransition(
                  opacity: _sidebarFadeAnimation,
                  child: _buildSidebar(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    return Container(
      width: isMobile ? screenWidth * 0.75 : screenWidth * 0.33,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
        boxShadow: isMobile
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(2, 0),
                ),
              ]
            : null,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: IOSStyleButton(
              onPressed: _createNewChat,
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF007AFF),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF007AFF).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.add,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    '新建对话',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _chatHistory.length,
              itemBuilder: (context, index) {
                return _buildChatHistoryItem(_chatHistory[index]);
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person,
                        color: Colors.grey,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      '用户设置',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const Spacer(),
                    IOSStyleButton(
                      onPressed: _clearAllHistory,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          Icons.delete_outline,
                          color: Colors.red.shade400,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.settings,
                      color: Colors.grey.shade600,
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                IOSStyleButton(
                  onPressed: _clearAllHistory,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.red.shade200,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.delete_sweep,
                          color: Colors.red.shade400,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '清空所有对话',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatHistoryItem(ChatHistory history) {
    final index = _chatHistory.indexOf(history);
    final isSelected = index == _selectedHistoryIndex;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: IOSStyleButton(
              onPressed: () {
                setState(() {
                  _selectedHistoryIndex = index;
                  _isTyping = false;
                });
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF007AFF).withOpacity(0.1)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: isSelected
                      ? Border.all(
                          color: const Color(0xFF007AFF),
                          width: 2,
                        )
                      : null,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: history.avatarType == AvatarType.ai
                            ? const Color(0xFF007AFF).withOpacity(0.1)
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        history.avatarType == AvatarType.ai
                            ? Icons.smart_toy
                            : Icons.person,
                        color: history.avatarType == AvatarType.ai
                            ? const Color(0xFF007AFF)
                            : Colors.grey.shade600,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            history.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                              color: isSelected
                                  ? const Color(0xFF007AFF)
                                  : const Color(0xFF1A1A1A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            history.lastMessage,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      history.timestamp,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _deleteChat(index),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.red.shade200,
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.delete_outline,
                color: Colors.red.shade400,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatArea() {
    return Column(
      children: [
        _buildAppBar(),
        Expanded(
          child: Container(
            color: Colors.white,
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index < _messages.length) {
                  return _buildMessageBubble(_messages[index]);
                } else {
                  return _buildTypingIndicator();
                }
              },
            ),
          ),
        ),
        _buildInputArea(),
      ],
    );
  }

  Widget _buildAppBar() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final currentTitle = _chatHistory.isNotEmpty 
        ? _chatHistory[_selectedHistoryIndex].title 
        : 'ChatGLM';
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          if (isMobile)
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: Icon(
                  _isSidebarOpen ? Icons.close : Icons.menu,
                  color: Colors.grey.shade700,
                  size: 20,
                ),
                onPressed: () {
                  if (_isSidebarOpen) {
                    _sidebarAnimationController.reverse().then((_) {
                      if (mounted) {
                        setState(() {
                          _isSidebarOpen = false;
                        });
                      }
                    });
                  } else {
                    setState(() {
                      _isSidebarOpen = true;
                    });
                    _sidebarAnimationController.forward();
                  }
                },
              ),
            ),
          if (isMobile) const SizedBox(width: 12),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF007AFF), Color(0xFF5856D6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF007AFF).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.smart_toy,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            currentTitle,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(8),
            child: Icon(
              Icons.more_horiz,
              color: Colors.grey.shade600,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 8, top: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF007AFF), Color(0xFF5856D6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.smart_toy,
                color: Colors.white,
                size: 18,
              ),
            ),
          ],
          Flexible(
            child: Container(
              key: ValueKey('${message.timestamp.toIso8601String()}-${message.content.length}'),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.5,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: message.isUser
                    ? const Color(0xFF007AFF)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: SelectableText(
                message.content,
                style: TextStyle(
                  fontSize: 15,
                  color: message.isUser ? Colors.white : const Color(0xFF1A1A1A),
                  height: 1.5,
                ),
              ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(left: 8, top: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.person,
                color: Colors.grey,
                size: 18,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            margin: const EdgeInsets.only(right: 8, top: 4),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF007AFF), Color(0xFF5856D6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.smart_toy,
              color: Colors.white,
              size: 18,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Text(
                  'AI正在输入',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF666666),
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  children: List.generate(3, (index) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                      margin: const EdgeInsets.only(left: 4),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        shape: BoxShape.circle,
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.mic,
              color: Colors.grey.shade600,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _messageController,
                decoration: const InputDecoration(
                  hintText: '输入消息...',
                  hintStyle: TextStyle(
                    color: Color(0xFF999999),
                    fontSize: 15,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          IOSStyleButton(
            onPressed: _sendMessage,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF007AFF),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF007AFF).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.send,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class IOSStyleButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final double scale;
  final Duration duration;
  final Color? splashColor;

  const IOSStyleButton({
    super.key,
    required this.child,
    this.onPressed,
    this.scale = 0.95,
    this.duration = const Duration(milliseconds: 150),
    this.splashColor,
  });

  @override
  State<IOSStyleButton> createState() => _IOSStyleButtonState();
}

class _IOSStyleButtonState extends State<IOSStyleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scale,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed != null) {
      _animationController.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onPressed != null) {
      _animationController.reverse();
    }
  }

  void _handleTapCancel() {
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.onPressed,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}

class ChatMessage {
  String content;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.content,
    required this.isUser,
    required this.timestamp,
  });
}

class ChatHistory {
  final String title;
  final String lastMessage;
  final String timestamp;
  final AvatarType avatarType;

  ChatHistory({
    required this.title,
    required this.lastMessage,
    required this.timestamp,
    required this.avatarType,
  });
}

enum AvatarType {
  ai,
  user,
}
