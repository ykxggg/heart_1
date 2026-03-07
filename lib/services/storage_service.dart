import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static final StorageService instance = StorageService._init();
  String? _cachedDataDirectory;
  final String _fileName = 'chat_history.json';

  StorageService._init();

  Future<String> get _dataDirectory async {
    if (_cachedDataDirectory != null) return _cachedDataDirectory!;

    if (kIsWeb) {
      _cachedDataDirectory = 'web_storage';
      print('Web平台使用SharedPreferences');
    } else if (defaultTargetPlatform == TargetPlatform.android || 
               defaultTargetPlatform == TargetPlatform.iOS) {
      final directory = await getApplicationDocumentsDirectory();
      _cachedDataDirectory = directory.path;
      print('移动平台数据目录: $_cachedDataDirectory');
    } else if (defaultTargetPlatform == TargetPlatform.windows || 
               defaultTargetPlatform == TargetPlatform.macOS ||
               defaultTargetPlatform == TargetPlatform.linux) {
      final directory = await getApplicationDocumentsDirectory();
      _cachedDataDirectory = directory.path;
      print('桌面平台数据目录: $_cachedDataDirectory');
    } else {
      _cachedDataDirectory = '.';
      print('其他平台使用当前目录');
    }
    
    return _cachedDataDirectory!;
  }

  Future<String> get _filePath async {
    final dir = await _dataDirectory;
    return join(dir, _fileName);
  }

  Future<Map<String, dynamic>> _loadData() async {
    if (kIsWeb) {
      print('Web平台从SharedPreferences加载数据');
      return await _loadFromWeb();
    }

    try {
      final path = await _filePath;
      final file = File(path);
      
      if (!await file.exists()) {
        print('数据文件不存在，创建新文件');
        await file.create(recursive: true);
        return {};
      }

      final jsonString = await file.readAsString();
      if (jsonString.isEmpty) {
        print('数据文件为空');
        return {};
      }

      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      print('数据加载成功，${data.length} 条记录');
      return data;
    } catch (e) {
      print('加载数据失败: $e');
      return {};
    }
  }

  Future<void> _saveData(Map<String, dynamic> data) async {
    if (kIsWeb) {
      print('Web平台保存到SharedPreferences');
      await _saveToWeb(data);
      return;
    }

    try {
      final path = await _filePath;
      final file = File(path);
      final jsonString = jsonEncode(data);
      
      await file.writeAsString(jsonString, flush: true);
      print('数据保存成功到: $path');
    } catch (e) {
      print('保存数据失败: $e');
      throw Exception('保存数据失败: $e');
    }
  }

  Future<Map<String, dynamic>> _loadFromWeb() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('chat_history');
      
      if (jsonString == null || jsonString.isEmpty) {
        return {};
      }
      
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      print('Web平台加载数据失败: $e');
      return {};
    }
  }

  Future<void> _saveToWeb(Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(data);
      await prefs.setString('chat_history', jsonString);
      print('Web平台数据保存成功');
    } catch (e) {
      print('Web平台保存数据失败: $e');
      throw Exception('Web平台保存数据失败: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getChats() async {
    final data = await _loadData();
    final chats = data['chats'] as List<dynamic>? ?? [];
    print('加载了 ${chats.length} 个对话');
    return chats.cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> getMessages(String chatTitle) async {
    final data = await _loadData();
    final messages = data['messages'] as Map<String, dynamic>? ?? {};
    final chatMessages = messages[chatTitle] as List<dynamic>? ?? [];
    print('加载了对话 "$chatTitle" 的 ${chatMessages.length} 条消息');
    return chatMessages.cast<Map<String, dynamic>>();
  }

  Future<void> saveChat(Map<String, dynamic> chat) async {
    final data = await _loadData();
    final chats = data['chats'] as List<dynamic>? ?? [];
    
    final index = chats.indexWhere((c) => c['title'] == chat['title']);
    if (index >= 0) {
      chats[index] = chat;
      print('更新对话: ${chat['title']}');
    } else {
      chats.add(chat);
      print('新增对话: ${chat['title']}');
    }
    
    data['chats'] = chats;
    await _saveData(data);
  }

  Future<void> saveMessage(String chatTitle, Map<String, dynamic> message) async {
    final data = await _loadData();
    final messages = data['messages'] as Map<String, dynamic>? ?? {};
    final chatMessages = messages[chatTitle] as List<dynamic>? ?? [];
    
    chatMessages.add(message);
    messages[chatTitle] = chatMessages;
    data['messages'] = messages;
    
    print('保存消息到对话 "$chatTitle"');
    await _saveData(data);
  }

  Future<void> deleteChat(String title) async {
    final data = await _loadData();
    final chats = data['chats'] as List<dynamic>? ?? [];
    final messages = data['messages'] as Map<String, dynamic>? ?? {};
    
    chats.removeWhere((chat) => chat['title'] == title);
    messages.remove(title);
    
    data['chats'] = chats;
    data['messages'] = messages;
    
    print('删除对话: $title');
    await _saveData(data);
  }

  Future<void> deleteAllChats() async {
    final data = await _loadData();
    
    data['chats'] = [];
    data['messages'] = {};
    
    print('删除所有对话');
    await _saveData(data);
  }

  Future<void> clearStorage() async {
    if (kIsWeb) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('chat_history');
        print('Web平台清除存储');
      } catch (e) {
        print('Web平台清除存储失败: $e');
      }
    } else {
      try {
        final path = await _filePath;
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
          print('删除数据文件: $path');
        }
      } catch (e) {
        print('删除数据文件失败: $e');
      }
    }
  }
}
