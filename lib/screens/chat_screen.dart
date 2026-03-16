import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform;
import '../models/chat_message.dart';
import '../models/chat_history.dart';
import '../models/avatar_type.dart';
import '../models/counselor.dart';
import '../services/zhipu_api_service.dart';
import '../services/storage_service.dart';
import '../widgets/ios_style_button.dart';
import '../components/message_bubble.dart';
import '../components/typing_indicator.dart';
import '../components/counselor_selection_dialog.dart';
import '../components/settings_dialog.dart';

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
  Counselor? _selectedCounselor;
  late AnimationController _sidebarAnimationController;
  late Animation<Offset> _sidebarSlideAnimation;
  late Animation<double> _sidebarFadeAnimation;
  late Animation<double> _overlayFadeAnimation;
  final Map<String, List<ChatMessage>> _chatMessagesMap = {};

  late final ZhipuApiService _apiService;
  late final String _apiKey;

  Future<String> _loadApiKey() async {
    try {
      // 首先尝试从assets加载
      try {
        final keyContent = await rootBundle.loadString('assets/.key');
        print('从assets成功加载API密钥');
        if (keyContent.trim().isNotEmpty) {
          return keyContent.trim();
        }
      } catch (e) {
        print('从assets加载API密钥失败: $e');
      }
      
      // 如果assets加载失败，尝试文件系统
      final file = File('.key');
      if (await file.exists()) {
        final content = await file.readAsString();
        if (content.trim().isNotEmpty) {
          print('从文件系统成功加载API密钥');
          return content.trim();
        }
      }
      
      throw Exception('API key not found in assets or file system');
    } catch (e) {
      throw Exception('Failed to load API key: $e');
    }
  }

  Future<void> _showErrorDialogAndExit(String message) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('配置错误'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            const SizedBox(height: 16),
            const Text(
              '请确保在项目根目录创建了 .key 文件，\n'
              '并在文件中填入了正确的API密钥。\n\n'
              '应用程序将退出。',
              style: TextStyle(color: Colors.red),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              exit(1);
            },
            child: const Text('退出'),
          ),
        ],
      ),
    );
  }

  final List<ChatHistory> _chatHistory = [];
  final Map<String, String> _chatSystemPrompts = {};

  List<ChatMessage> get _messages {
    if (_chatHistory.isEmpty) return [];
    return _chatMessagesMap[_chatHistory[_selectedHistoryIndex].title] ?? [];
  }

  @override
  void initState() {
    super.initState();
    
    // 初始化动画控制器
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
    
    // 异步加载API密钥和历史记录
    _loadApiKeyAndHistory();
  }

  Future<void> _loadApiKeyAndHistory() async {
    try {
      _apiKey = await _loadApiKey();
      _apiService = ZhipuApiService(apiKey: _apiKey);
      await _loadHistoryFromDatabase();
    } catch (e) {
      await _showErrorDialogAndExit(e.toString());
    }
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
      final chatSystemPrompts = <String, String>{};
      
      for (final chat in chats) {
        final title = chat['title'] as String;
        final lastMessage = chat['last_message'] as String? ?? '';
        final timestamp = chat['timestamp'] as String? ?? '';
        final avatarTypeStr = chat['avatar_type'] as String? ?? 'AvatarType.ai';
        final counselorId = chat['counselor_id'] as String?;
        
        final avatarType = avatarTypeStr.contains('user') ? AvatarType.user : AvatarType.ai;
        
        final chatHistory = ChatHistory(
          title: title,
          lastMessage: lastMessage,
          timestamp: timestamp,
          avatarType: avatarType,
          counselorId: counselorId,
        );
        
        chatHistoryList.add(chatHistory);
        
        if (counselorId != null) {
          final counselor = counselors.firstWhere((c) => c.id == counselorId, orElse: () => counselors.first);
          final systemPrompt = await counselor.getSystemPrompt();
          chatSystemPrompts[title] = systemPrompt;
        }
        
        final messages = await storageService.getMessages(title);
        final chatMessages = messages.map((msg) {
          return ChatMessage(
            content: msg['content'] as String,
            isUser: msg['is_user'] as bool,
            timestamp: DateTime.parse(msg['timestamp'] as String),
          );
        }).toList();
        
        chatMessagesMap[title] = chatMessages;
      }
      
      setState(() {
        _chatHistory.clear();
        _chatHistory.addAll(chatHistoryList);
        _chatMessagesMap.clear();
        _chatMessagesMap.addAll(chatMessagesMap);
        _chatSystemPrompts.clear();
        _chatSystemPrompts.addAll(chatSystemPrompts);
        _selectedHistoryIndex = 0;
      });
      
      print('历史记录加载完成，当前有 ${_chatHistory.length} 个对话');
    } catch (e) {
      print('加载历史记录失败: $e');
      await _createNewChat();
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _sidebarAnimationController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isTyping) return;

    _messageController.clear();

    final currentTitle = _chatHistory[_selectedHistoryIndex].title;
    final messages = _chatMessagesMap[currentTitle]!;
    final systemPrompt = _chatSystemPrompts[currentTitle];

    setState(() {
      messages.add(ChatMessage(
        content: message,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isTyping = true;
    });

    try {
      final storageService = StorageService.instance;
      await storageService.saveMessage(currentTitle, {
        'content': message,
        'is_user': true,
        'timestamp': DateTime.now().toIso8601String(),
      });

      setState(() {
        final history = _chatHistory[_selectedHistoryIndex];
        _chatHistory[_selectedHistoryIndex] = ChatHistory(
          title: history.title,
          lastMessage: message,
          timestamp: '刚刚',
          avatarType: history.avatarType,
          counselorId: history.counselorId,
        );
      });

      final historyMessages = <Map<String, String>>[];

      if (systemPrompt != null) {
        historyMessages.add({
          'role': 'system',
          'content': systemPrompt,
        });
      }

      historyMessages.addAll(
        messages.map((msg) => {
          'role': msg.isUser ? 'user' : 'assistant',
          'content': msg.content,
        })
      );

      final responseBuffer = StringBuffer();
      await for (final chunk in _apiService.streamSendMessage(
        message,
        history: historyMessages,
      )) {
        responseBuffer.write(chunk);
        
        if (messages.isNotEmpty && !messages.last.isUser) {
          setState(() {
            messages.last.content = responseBuffer.toString();
          });
        } else {
          setState(() {
            messages.add(ChatMessage(
              content: responseBuffer.toString(),
              isUser: false,
              timestamp: DateTime.now(),
            ));
            _isTyping = false;
          });
        }
        
        await _scrollToBottom();
      }

      final aiMessage = messages.firstWhere((msg) => !msg.isUser);
      await storageService.saveMessage(currentTitle, {
        'content': aiMessage.content,
        'is_user': false,
        'timestamp': aiMessage.timestamp.toIso8601String(),
      });

      setState(() {
        _isTyping = false;
      });
    } catch (e) {
      print('发送消息失败: $e');
      setState(() {
        messages.add(ChatMessage(
          content: '抱歉，发送消息时出现错误：$e',
          isUser: false,
          timestamp: DateTime.now(),
        ));
        _isTyping = false;
      });
    }
  }

  Future<void> _scrollToBottom() async {
    if (_scrollController.hasClients) {
      await Future.delayed(const Duration(milliseconds: 100));
      await _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _createNewChat() async {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 1024;
    
    if (isMobile) {
      _sidebarAnimationController.reverse();
    }
    
    _selectedCounselor = null;
    
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => CounselorSelectionDialog(
        onCounselorSelected: (counselor) => _createChatWithCounselor(counselor),
      ),
    );
  }

  Future<void> _createChatWithCounselor(Counselor counselor) async {
    final chatId = '新对话 ${_chatHistory.length + 1}';
    
    try {
      final systemPrompt = await counselor.getSystemPrompt();
      
      final storageService = StorageService.instance;
      await storageService.saveChat({
        'title': chatId,
        'last_message': '',
        'timestamp': '刚刚',
        'avatar_type': AvatarType.ai.toString(),
        'counselor_id': counselor.id,
      });
      
      setState(() {
        _chatHistory.insert(0, ChatHistory(
          title: chatId,
          lastMessage: '',
          timestamp: '刚刚',
          avatarType: AvatarType.ai,
          counselorId: counselor.id,
        ));
        _chatSystemPrompts[chatId] = systemPrompt;
        _chatMessagesMap[chatId] = [
          ChatMessage(
            content: '你好！我是${counselor.name}，${counselor.specialty}。很高兴为你提供帮助！',
            isUser: false,
            timestamp: DateTime.now(),
          ),
        ];
        _selectedHistoryIndex = 0;
        _isTyping = false;
        _isSidebarOpen = false;
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
              Navigator.pop(dialogContext);
              
              try {
                final storageService = StorageService.instance;
                await storageService.deleteChat(chatTitle);
                
                setState(() {
                  _chatHistory.removeAt(index);
                  _chatMessagesMap.remove(chatTitle);
                  
                  if (_selectedHistoryIndex >= _chatHistory.length) {
                    _selectedHistoryIndex = _chatHistory.length - 1;
                  }
                  
                  if (_chatHistory.isEmpty) {
                    _createNewChat();
                  }
                });
              } catch (e) {
                print('删除对话失败: $e');
              }
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  Future<void> _switchToChat(int index) async {
    setState(() {
      _selectedHistoryIndex = index;
    });
    
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 1024;
    if (isMobile) {
      _sidebarAnimationController.reverse();
    }
    
    await _scrollToBottom();
  }

  void _clearAllHistory() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('确认清空'),
        content: const Text('确定要清空所有对话历史吗？此操作不可恢复。'),
        actions: [
          IOSStyleButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          IOSStyleButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              
              try {
                final storageService = StorageService.instance;
                await storageService.deleteAllChats();
                
                setState(() {
                  _chatHistory.clear();
                  _chatMessagesMap.clear();
                  _createNewChat();
                });
              } catch (e) {
                print('清空历史失败: $e');
              }
            },
            child: const Text('清空'),
          ),
        ],
      ),
    );
  }

  Future<void> _showSettings() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => const SettingsDialog(),
    );
    
    if (result == true) {
      await _showKeySavedDialog();
    }
  }

  Future<void> _showKeySavedDialog() async {
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('提示'),
          ],
        ),
        content: const Text('API密钥已保存，重启应用后生效。'),
        actions: [
          IOSStyleButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _toggleSidebar() {
    setState(() {
      _isSidebarOpen = !_isSidebarOpen;
      if (_isSidebarOpen) {
        _sidebarAnimationController.forward();
      } else {
        _sidebarAnimationController.reverse();
      }
    });
  }

  int _calculateTokens(String text) {
    int chineseCharCount = 0;
    int otherCharCount = 0;

    for (int i = 0; i < text.length; i++) {
      int codeUnit = text.codeUnitAt(i);
      if (codeUnit >= 0x4E00 && codeUnit <= 0x9FFF) {
        chineseCharCount++;
      } else {
        otherCharCount++;
      }
    }

    return (chineseCharCount / 1.5).ceil() + otherCharCount;
  }

  int _calculateTotalTokens() {
    int total = 0;
    for (final message in _messages) {
      total += _calculateTokens(message.content);
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            _buildChatArea(),
            if (_isSidebarOpen)
              GestureDetector(
                onTap: _toggleSidebar,
                child: FadeTransition(
                  opacity: _overlayFadeAnimation,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.black.withOpacity(0.6),
                          Colors.black.withOpacity(0.3),
                        ],
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.chevron_left,
                        color: Colors.white.withOpacity(0.5),
                        size: 32,
                      ),
                    ),
                  ),
                ),
              ),
            if (_isSidebarOpen)
              _buildSidebar(),
          ],
        ),
      ),
    );
  }

  Widget _buildChatArea() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 1024;
    
    return Column(
      children: [
        _buildAppBar(),
        Expanded(
          child: isMobile
              ? Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _messages.length + (_isTyping ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index < _messages.length) {
                            return MessageBubble(message: _messages[index]);
                          }
                          return const TypingIndicator();
                        },
                      ),
                    ),
                    _buildInputArea(),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Expanded(
                            child: ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _messages.length + (_isTyping ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index < _messages.length) {
                                  return MessageBubble(message: _messages[index]);
                                }
                                return const TypingIndicator();
                              },
                            ),
                          ),
                          _buildInputArea(),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildAppBar() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 1024;
    
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          if (isMobile) ...[
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: IOSStyleButton(
                onPressed: _toggleSidebar,
                child: Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.menu,
                    color: Colors.grey.shade600,
                    size: 24,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _chatHistory.isNotEmpty
                        ? _chatHistory[_selectedHistoryIndex].title
                        : 'ChatGLM',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (_chatHistory.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_calculateTotalTokens()} tokens',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IOSStyleButton(
              onPressed: _createNewChat,
              child: Container(
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
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextField(
                controller: _messageController,
                decoration: const InputDecoration(
                  hintText: '输入消息...',
                  border: InputBorder.none,
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

  Widget _buildSidebar() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 1024;
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
          Container(
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.shade200,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      '对话历史',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ),
                ),
                IOSStyleButton(
                  onPressed: _toggleSidebar,
                  child: Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.close,
                      color: Colors.grey.shade600,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
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
                    IOSStyleButton(
                      onPressed: _showSettings,
                      child: Icon(
                        Icons.settings,
                        color: Colors.grey.shade600,
                        size: 20,
                      ),
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
                          Icons.delete_outline,
                          color: Colors.red.shade400,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '清空历史',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red.shade400,
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
      child: IOSStyleButton(
        onPressed: () => _switchToChat(index),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF007AFF).withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: history.avatarType == AvatarType.ai
                      ? const Color(0xFF007AFF)
                      : Colors.grey.shade300,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  history.avatarType == AvatarType.ai
                      ? Icons.smart_toy
                      : Icons.person,
                  color: history.avatarType == AvatarType.ai
                      ? Colors.white
                      : Colors.grey,
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
                        fontWeight: FontWeight.w500,
                        color: isSelected
                            ? const Color(0xFF007AFF)
                            : const Color(0xFF1A1A1A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      history.lastMessage.isEmpty
                          ? '暂无消息'
                          : history.lastMessage,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IOSStyleButton(
                onPressed: () => _deleteChat(index),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.close,
                    color: Colors.grey.shade400,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
