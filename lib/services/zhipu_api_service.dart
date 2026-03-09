import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';

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
