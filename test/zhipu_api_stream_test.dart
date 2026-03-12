import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:heart_1/services/zhipu_api_service.dart';

void main() {
  group('智谱API流式返回测试', () {
    late ZhipuApiService apiService;
    String testApiKey = '';

    setUpAll(() async {
      try {
        final file = File('.key');
        if (await file.exists()) {
          testApiKey = await file.readAsString();
        } else {
          testApiKey = 'placeholder_key';
        }
      } catch (e) {
        testApiKey = 'placeholder_key';
      }
    });

    setUp(() {
      apiService = ZhipuApiService(apiKey: testApiKey);
    });

    test('测试1: 简单问候消息流式返回', () async {
      final message = '你好';
      final stream = apiService.streamSendMessage(message);
      final chunks = <String>[];

      await for (final chunk in stream) {
        chunks.add(chunk);
      }

      final fullResponse = chunks.join();
      
      expect(chunks.isNotEmpty, true, reason: '应该收到至少一个chunk');
      expect(fullResponse.isNotEmpty, true, reason: '完整响应不应为空');
      expect(fullResponse.contains('你好') || fullResponse.length > 10, true, 
          reason: '回复应该相关或内容足够长');
    });

    test('测试2: 代码相关问题流式返回', () async {
      final message = '用Dart写一个hello world';
      final stream = apiService.streamSendMessage(message);
      final chunks = <String>[];

      await for (final chunk in stream) {
        chunks.add(chunk);
      }

      final fullResponse = chunks.join();
      
      expect(chunks.isNotEmpty, true);
      expect(fullResponse.isNotEmpty, true);
      expect(fullResponse.toLowerCase().contains('dart') || 
             fullResponse.contains('print') || 
             fullResponse.contains('main'), true);
    });

    test('测试3: 长文本流式返回', () async {
      final message = '请介绍一下Flutter的优势和特点，至少列举5点';
      final stream = apiService.streamSendMessage(message);
      final chunks = <String>[];

      await for (final chunk in stream) {
        chunks.add(chunk);
      }

      final fullResponse = chunks.join();
      
      expect(chunks.length, greaterThan(1), reason: '长文本应该有多个chunk');
      expect(fullResponse.length, greaterThan(50), reason: '回复应该足够长');
    });

    test('测试4: 流式返回完整性验证', () async {
      final message = '请说一句关于编程的名言';
      final stream = apiService.streamSendMessage(message);
      final chunks = <String>[];

      await for (final chunk in stream) {
        chunks.add(chunk);
      }

      final fullResponse = chunks.join();
      
      expect(fullResponse.isNotEmpty, true);
      expect(fullResponse.length, greaterThan(5), reason: '名言应该有内容');
      expect(RegExp(r'[\u4e00-\u9fa5]').hasMatch(fullResponse), true, 
          reason: '应该包含中文字符');
    });

    test('测试5: 带历史上下文的流式返回', () async {
      final message = '继续刚才的话题';
      final history = [
        {'role': 'user', 'content': '什么是Flutter？'},
        {'role': 'assistant', 'content': 'Flutter是Google开发的开源UI框架'},
      ];
      
      final stream = apiService.streamSendMessage(message, history: history);
      final chunks = <String>[];

      await for (final chunk in stream) {
        chunks.add(chunk);
      }

      expect(chunks.isNotEmpty, true);
    });

    test('测试6: 流式返回性能测试', () async {
      final message = '你好';
      final stream = apiService.streamSendMessage(message);
      final chunks = <String>[];
      final startTime = DateTime.now();
      final timestamps = <DateTime>[];

      await for (final chunk in stream) {
        timestamps.add(DateTime.now());
        chunks.add(chunk);
      }

      final totalTime = DateTime.now().difference(startTime).inMilliseconds;
      
      expect(totalTime, lessThan(60000), reason: '总耗时应该小于60秒');
      expect(chunks.isNotEmpty, true);
      
      if (timestamps.isNotEmpty && timestamps.length > 1) {
        final avgInterval = totalTime / timestamps.length;
        expect(avgInterval, lessThan(1000), 
            reason: '平均chunk间隔应该小于1秒');
      }
    });
  });
}
