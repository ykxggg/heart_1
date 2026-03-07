import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:matcher/matcher.dart' as matcher;

void main() {
  setUpAll(() {
    if (!kIsWeb) {
      TestWidgetsFlutterBinding.ensureInitialized();
    }
  });

  group('StorageService测试', () {
    test('测试数据目录获取', () async {
      print('========== 测试数据目录获取 ==========');
      
      String dataDir;
      
      if (kIsWeb) {
        dataDir = 'web_storage';
        print('Web平台使用SharedPreferences');
      } else if (defaultTargetPlatform == TargetPlatform.android || 
                 defaultTargetPlatform == TargetPlatform.iOS) {
        dataDir = '/data/data/com.example.app/databases';
        print('移动平台数据目录');
      } else if (defaultTargetPlatform == TargetPlatform.windows || 
                 defaultTargetPlatform == TargetPlatform.macOS ||
                 defaultTargetPlatform == TargetPlatform.linux) {
        dataDir = Directory.current.path;
        print('桌面平台数据目录');
      } else {
        dataDir = '.';
        print('其他平台使用当前目录');
      }
      
      print('数据目录: $dataDir');
      print('====================================');
      
      expect(dataDir, isNotNull);
    });

    test('测试JSON数据结构', () {
      print('========== 测试JSON数据结构 ==========');
      
      final testData = {
        'chats': [
          {
            'title': '测试对话',
            'last_message': '测试消息',
            'timestamp': '刚刚',
            'avatar_type': 'AvatarType.ai',
          }
        ],
        'messages': {
          '测试对话': [
            {
              'content': '你好',
              'is_user': 1,
              'timestamp': 1234567890,
            }
          ]
        }
      };
      
      print('对话数量: ${(testData['chats'] as List?)?.length ?? 0}');
      print('消息组数量: ${(testData['messages'] as Map?)?.length ?? 0}');
      print('====================================');
      
      expect(testData['chats'], isNotNull);
      expect(testData['messages'], isNotNull);
    });

    test('测试Web平台存储', () async {
      print('========== 测试Web平台存储 ==========');
      
      if (kIsWeb) {
        try {
          final prefs = await SharedPreferences.getInstance();
          final testData = {
            'chats': [],
            'messages': {}
          };
          
          await prefs.setString('chat_history', '{"chats":[],"messages":{}}');
          final loaded = prefs.getString('chat_history');
          
          print('✓ Web平台SharedPreferences测试成功');
          print('  - 保存成功');
          print('  - 加载成功');
          print('  - 数据: $loaded');
          
          expect(loaded, isNotNull);
        } catch (e) {
          print('✗ Web平台测试失败: $e');
          fail('Web平台测试失败: $e');
        }
      } else {
        print('ℹ️ 非Web平台，跳过Web平台测试');
        expect(kIsWeb, isFalse);
      }
      
      print('====================================');
    });

    test('测试移动平台文件存储', () async {
      print('========== 测试移动平台文件存储 ==========');
      
      if (kIsWeb) {
        print('ℹ️ Web平台，跳过文件存储测试');
        expect(kIsWeb, isTrue);
        return;
      } else if (defaultTargetPlatform != TargetPlatform.android && 
          defaultTargetPlatform != TargetPlatform.iOS) {
        print('ℹ️ 非移动平台，跳过移动平台测试');
        expect(defaultTargetPlatform, isNot([TargetPlatform.android, TargetPlatform.iOS]));
        return;
      }
      
      try {
        final testFile = File(path.join(Directory.current.path, 'test_chat_history.json'));
        final testData = '{"chats":[],"messages":{}}';
        
        await testFile.writeAsString(testData);
        final loaded = await testFile.readAsString();
        
        print('✓ 移动平台文件存储测试成功');
        print('  - 文件路径: ${testFile.path}');
        print('  - 保存成功');
        print('  - 加载成功');
        print('  - 数据匹配: ${loaded == testData}');
        
        await testFile.delete();
        
        expect(loaded, matcher.equals(testData));
      } catch (e) {
        print('✗ 移动平台测试失败: $e');
        fail('移动平台测试失败: $e');
      }
      
      print('====================================');
    });

    test('测试跨平台兼容性', () {
      print('========== 测试跨平台兼容性 ==========');
      
      final platforms = {
        'Android': TargetPlatform.android,
        'iOS': TargetPlatform.iOS,
        'Windows': TargetPlatform.windows,
        'macOS': TargetPlatform.macOS,
        'Linux': TargetPlatform.linux,
      };
      
      print('支持的平台:');
      platforms.forEach((name, platform) {
        final isCurrent = platform == defaultTargetPlatform;
        final status = isCurrent ? '✓ 当前' : '○ 其他';
        print('$status $name');
      });
      
      if (kIsWeb) {
        print('✓ Web平台');
      }
      
      print('====================================');
      
      expect(defaultTargetPlatform, isNotNull);
    });
  });
}
