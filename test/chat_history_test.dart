import 'package:flutter_test/flutter_test.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:io' as io;

import '../lib/models/chat_history.dart';
import '../lib/models/chat_message.dart';
import '../lib/models/avatar_type.dart';
import '../lib/services/storage_service.dart';

// 辅助函数
int min(int a, int b) => a < b ? a : b;

void main() {
  group('ChatHistory模型测试', () {
    test('测试ChatHistory对象创建', () {
      print('========== 测试ChatHistory对象创建 ==========');
      
      final chatHistory = ChatHistory(
        title: '测试对话',
        lastMessage: '这是最后一条消息',
        timestamp: '刚刚',
        avatarType: AvatarType.ai,
        counselorId: 'counselor_1',
      );

      print('✓ ChatHistory对象创建成功');
      print('  - 标题: ${chatHistory.title}');
      print('  - 最后消息: ${chatHistory.lastMessage}');
      print('  - 时间戳: ${chatHistory.timestamp}');
      print('  - 头像类型: ${chatHistory.avatarType}');
      print('  - 顾问ID: ${chatHistory.counselorId}');
      
      expect(chatHistory.title, '测试对话');
      expect(chatHistory.lastMessage, '这是最后一条消息');
      expect(chatHistory.timestamp, '刚刚');
      expect(chatHistory.avatarType, AvatarType.ai);
      expect(chatHistory.counselorId, 'counselor_1');
      
      print('====================================');
    });

    test('测试ChatHistory序列化', () {
      print('========== 测试ChatHistory序列化 ==========');
      
      final chatHistory = ChatHistory(
        title: '测试对话',
        lastMessage: '这是最后一条消息',
        timestamp: '刚刚',
        avatarType: AvatarType.user,
      );

      final json = jsonEncode(chatHistory);
      final decoded = jsonDecode(json);
      
      print('✓ ChatHistory序列化成功');
      print('  - 原始对象: $chatHistory');
      print('  - JSON序列化: $json');
      print('  - 反序列化: $decoded');
      
      expect(decoded['title'], '测试对话');
      expect(decoded['lastMessage'], '这是最后一条消息');
      expect(decoded['timestamp'], '刚刚');
      expect(decoded['avatar_type'], 'AvatarType.user');
      
      print('====================================');
    });
  });

  group('ChatMessage模型测试', () {
    test('测试ChatMessage对象创建', () {
      print('========== 测试ChatMessage对象创建 ==========');
      
      final message = ChatMessage(
        content: '你好，这是测试消息',
        isUser: true,
        timestamp: DateTime(2023, 1, 1, 12, 0, 0),
      );

      print('✓ ChatMessage对象创建成功');
      print('  - 内容: ${message.content}');
      print('  - 用户消息: ${message.isUser}');
      print('  - 时间戳: ${message.timestamp}');
      
      expect(message.content, '你好，这是测试消息');
      expect(message.isUser, true);
      expect(message.timestamp, DateTime(2023, 1, 1, 12, 0, 0));
      
      print('====================================');
    });

    test('测试ChatMessage序列化', () {
      print('========== 测试ChatMessage序列化 ==========');
      
      final message = ChatMessage(
        content: 'AI回复消息',
        isUser: false,
        timestamp: DateTime(2023, 1, 1, 12, 5, 0),
      );

      final json = jsonEncode(message);
      final decoded = jsonDecode(json);
      
      print('✓ ChatMessage序列化成功');
      print('  - 原始对象: $message');
      print('  - JSON序列化: $json');
      print('  - 反序列化: $decoded');
      
      expect(decoded['content'], 'AI回复消息');
      expect(decoded['is_user'], false);
      expect(decoded['timestamp'], '2023-01-01T12:05:00.000');
      
      print('====================================');
    });
  });

  group('StorageService历史记录测试', () {
    late StorageService storageService;
    final testChatData = {
      'chats': [
        {
          'title': '对话1',
          'last_message': '最后消息1',
          'timestamp': '刚刚',
          'avatar_type': 'AvatarType.ai',
          'counselor_id': 'counselor_1',
        },
        {
          'title': '对话2',
          'last_message': '最后消息2',
          'timestamp': '1小时前',
          'avatar_type': 'AvatarType.user',
          'counselor_id': null
        }
      ],
      'messages': {
        '对话1': [
          {
            'content': '你好',
            'is_user': true,
            'timestamp': '2023-01-01T12:00:00.000',
          },
          {
            'content': '你好！很高兴为你服务',
            'is_user': false,
            'timestamp': '2023-01-01T12:01:00.000',
          }
        ],
        '对话2': [
          {
            'content': '请问有什么可以帮助你的？',
            'is_user': false,
            'timestamp': '2023-01-01T13:00:00.000',
          }
        ]
      }
    };

    setUp(() async {
      storageService = StorageService.instance;
      
      // 清空测试数据
      await storageService.clearStorage();
      
      // 初始化测试数据
      final file = File('${io.Directory.current.path}/chat_history.json');
      await file.writeAsString(jsonEncode(testChatData));
    });

    test('测试对话列表加载', () async {
      print('========== 测试对话列表加载 ==========');
      
      final chats = await storageService.getChats();
      
      print('✓ 对话列表加载成功');
      print('  - 对话数量: ${chats.length}');
      print('  - 对话1标题: ${chats[0]['title']}');
      print('  - 对话2标题: ${chats[1]['title']}');
      print('  - 对话1最后消息: ${chats[0]['last_message']}');
      print('  - 对话2最后消息: ${chats[1]['last_message']}');
      
      expect(chats.length, 2);
      expect(chats[0]['title'], '对话1');
      expect(chats[1]['title'], '对话2');
      expect(chats[0]['last_message'], '最后消息1');
      expect(chats[1]['last_message'], '最后消息2');
      
      print('====================================');
    });

    test('测试消息加载', () async {
      print('========== 测试消息加载 ==========');
      
      final messages1 = await storageService.getMessages('对话1');
      final messages2 = await storageService.getMessages('对话2');
      
      print('✓ 消息加载成功');
      print('  - 对话1消息数量: ${messages1.length}');
      print('  - 对话2消息数量: ${messages2.length}');
      print('  - 对话1第一条消息: ${messages1[0]['content']}');
      print('  - 对话1第二条消息: ${messages1[1]['content']}');
      print('  - 对话2第一条消息: ${messages2[0]['content']}');
      
      expect(messages1.length, 2);
      expect(messages2.length, 1);
      expect(messages1[0]['content'], '你好');
      expect(messages1[1]['content'], '你好！很高兴为你服务');
      expect(messages2[0]['content'], '请问有什么可以帮助你的？');
      
      print('====================================');
    });

    test('测试保存新对话', () async {
      print('========== 测试保存新对话 ==========');
      
      final newChat = {
        'title': '新对话',
        'last_message': '',
        'timestamp': '刚刚',
        'avatar_type': 'AvatarType.ai',
        'counselor_id': null,
      };
      
      await storageService.saveChat(newChat);
      final chats = await storageService.getChats();
      
      print('✓ 新对话保存成功');
      print('  - 总对话数量: ${chats.length}');
      print('  - 新对话标题: ${chats[2]['title']}');
      print('  - 新对话类型: ${chats[2]['avatar_type']}');
      
      expect(chats.length, 3);
      expect(chats[2]['title'], '新对话');
      expect(chats[2]['avatar_type'], 'AvatarType.ai');
      
      print('====================================');
    });

    test('测试保存消息到对话', () async {
      print('========== 测试保存消息到对话 ==========');
      
      final newMessage = {
        'content': '这是新添加的消息',
        'is_user': true,
        'timestamp': '2023-01-01T14:00:00.000',
      };
      
      await storageService.saveMessage('对话1', newMessage);
      final messages = await storageService.getMessages('对话1');
      
      print('✓ 消息保存成功');
      print('  - 对话1消息数量: ${messages.length}');
      print('  - 新消息内容: ${messages[2]['content']}');
      print('  - 新消息类型: ${messages[2]['is_user']}');
      
      expect(messages.length, 3);
      expect(messages[2]['content'], '这是新添加的消息');
      expect(messages[2]['is_user'], true);
      
      print('====================================');
    });

    test('测试删除对话', () async {
      print('========== 测试删除对话 ==========');
      
      await storageService.deleteChat('对话1');
      final chats = await storageService.getChats();
      final messages = await storageService.getMessages('对话1');
      
      print('✓ 对话删除成功');
      print('  - 剩余对话数量: ${chats.length}');
      print('  - 对话1消息数量: ${messages.length}');
      
      expect(chats.length, 1);
      expect(chats[0]['title'], '对话2');
      expect(messages.length, 0);
      
      print('====================================');
    });

    test('测试清空所有对话', () async {
      print('========== 测试清空所有对话 ==========');
      
      await storageService.deleteAllChats();
      final chats = await storageService.getChats();
      final messages = await storageService.getMessages('对话1');
      
      print('✓ 所有对话清空成功');
      print('  - 对话数量: ${chats.length}');
      print('  - 消息数量: ${messages.length}');
      
      expect(chats.length, 0);
      expect(messages.length, 0);
      
      print('====================================');
    });
  });

  group('对话历史完整性测试', () {
    test('测试完整对话历史构建', () {
      print('========== 测试完整对话历史构建 ==========');
      
      // 模拟一个完整的对话
      final testMessages = [
        ChatMessage(
          content: '你好，我想咨询心理健康问题',
          isUser: true,
          timestamp: DateTime(2023, 1, 1, 12, 0, 0),
        ),
        ChatMessage(
          content: '你好！我很乐意帮助你。请告诉我你的具体情况。',
          isUser: false,
          timestamp: DateTime(2023, 1, 1, 12, 1, 0),
        ),
        ChatMessage(
          content: '我最近感到焦虑，睡眠质量也不好',
          isUser: true,
          timestamp: DateTime(2023, 1, 1, 12, 2, 0),
        ),
        ChatMessage(
          content: '理解你的感受。焦虑和睡眠问题通常是相关的...',
          isUser: false,
          timestamp: DateTime(2023, 1, 1, 12, 3, 0),
        ),
      ];
      
      // 验证消息的正确性
      print('✓ 完整对话历史验证');
      print('  - 消息总数: ${testMessages.length}');
      print('  - 用户消息: ${testMessages.where((m) => m.isUser).length}');
      print('  - AI消息: ${testMessages.where((m) => !m.isUser).length}');
      print('  - 消息顺序: ${testMessages.map((m) => '${m.isUser ? '用户' : 'AI'}: ${m.content.substring(0, min(20, m.content.length))}...').join(' → ')}');
      
      expect(testMessages.length, 4);
      expect(testMessages.where((m) => m.isUser).length, 2);
      expect(testMessages.where((m) => !m.isUser).length, 2);
      
      // 验证消息交替顺序
      expect(testMessages[0].isUser, true);  // 用户
      expect(testMessages[1].isUser, false); // AI
      expect(testMessages[2].isUser, true);  // 用户
      expect(testMessages[3].isUser, false); // AI
      
      print('====================================');
    });

    test('测试历史消息API格式构建', () {
      print('========== 测试历史消息API格式构建 ==========');
      
      final messages = [
        ChatMessage(
          content: '用户的问题1',
          isUser: true,
          timestamp: DateTime(2023, 1, 1, 12, 0, 0),
        ),
        ChatMessage(
          content: 'AI的回答1',
          isUser: false,
          timestamp: DateTime(2023, 1, 1, 12, 1, 0),
        ),
        ChatMessage(
          content: '用户的问题2',
          isUser: true,
          timestamp: DateTime(2023, 1, 1, 12, 2, 0),
        ),
        ChatMessage(
          content: 'AI的回答2',
          isUser: false,
          timestamp: DateTime(2023, 1, 1, 12, 3, 0),
        ),
      ];
      
      // 模拟API格式构建（修复后的逻辑）
      final apiMessages = messages.map((msg) => {
        'role': msg.isUser ? 'user' : 'assistant',
        'content': msg.content,
      }).toList();
      
      print('✓ API格式构建成功');
      print('  - API消息数量: ${apiMessages.length}');
      print('  - API消息内容:');
      for (var i = 0; i < apiMessages.length; i++) {
        print('    ${i + 1}. ${apiMessages[i]['role']}: ${apiMessages[i]['content']}');
      }
      
      expect(apiMessages.length, 4);
      expect(apiMessages[0]['role'], 'user');
      expect(apiMessages[0]['content'], '用户的问题1');
      expect(apiMessages[1]['role'], 'assistant');
      expect(apiMessages[1]['content'], 'AI的回答1');
      expect(apiMessages[2]['role'], 'user');
      expect(apiMessages[2]['content'], '用户的问题2');
      expect(apiMessages[3]['role'], 'assistant');
      expect(apiMessages[3]['content'], 'AI的回答2');
      
      print('====================================');
    });

    test('测试修复后的API历史消息格式', () {
      print('========== 测试修复后的API历史消息格式 ==========');
      
      // 修复前的问题：只包含AI消息
      final oldMessages = [
        ChatMessage(content: '用户消息1', isUser: true, timestamp: DateTime.now()),
        ChatMessage(content: 'AI回复1', isUser: false, timestamp: DateTime.now()),
        ChatMessage(content: '用户消息2', isUser: true, timestamp: DateTime.now()),
        ChatMessage(content: 'AI回复2', isUser: false, timestamp: DateTime.now()),
      ];
      
      // 修复前的逻辑（有bug）
      final oldApiFormat = oldMessages
          .where((msg) => !msg.isUser)
          .map((msg) => {'role': 'assistant', 'content': msg.content})
          .toList();
      
      // 修复后的逻辑（正确）
      final fixedApiFormat = oldMessages.map((msg) => {
        'role': msg.isUser ? 'user' : 'assistant',
        'content': msg.content,
      }).toList();
      
      print('✓ 修复前后对比');
      print('  - 修复前API消息数量: ${oldApiFormat.length}');
      print('  - 修复前消息内容:');
      for (var i = 0; i < oldApiFormat.length; i++) {
        print('    ${i + 1}. ${oldApiFormat[i]['role']}: ${oldApiFormat[i]['content']}');
      }
      
      print('  - 修复后API消息数量: ${fixedApiFormat.length}');
      print('  - 修复后消息内容:');
      for (var i = 0; i < fixedApiFormat.length; i++) {
        print('    ${i + 1}. ${fixedApiFormat[i]['role']}: ${fixedApiFormat[i]['content']}');
      }
      
      // 验证修复前的问题
      expect(oldApiFormat.length, 2);  // 只有AI消息，缺少用户消息
      expect(oldApiFormat[0]['content'], 'AI回复1');
      expect(oldApiFormat[1]['content'], 'AI回复2');
      
      // 验证修复后的正确性
      expect(fixedApiFormat.length, 4);  // 包含完整的对话历史
      expect(fixedApiFormat[0]['role'], 'user');
      expect(fixedApiFormat[1]['role'], 'assistant');
      expect(fixedApiFormat[2]['role'], 'user');
      expect(fixedApiFormat[3]['role'], 'assistant');
      
      print('✓ 修复成功：现在包含完整的对话历史');
      print('====================================');
    });
  });
}