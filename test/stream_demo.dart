import 'package:flutter/material.dart';

void main() {
  runApp(const StreamDemoApp());
}

class StreamDemoApp extends StatelessWidget {
  const StreamDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '流式显示演示',
      home: const StreamDemoPage(),
    );
  }
}

class StreamDemoPage extends StatefulWidget {
  const StreamDemoPage({super.key});

  @override
  State<StreamDemoPage> createState() => _StreamDemoPageState();
}

class _StreamDemoPageState extends State<StreamDemoPage> {
  String _displayText = '';
  int _chunkCount = 0;

  Future<void> _startStreamDemo() async {
    setState(() {
      _displayText = '';
      _chunkCount = 0;
    });

    final text = '这是一个流式显示的演示，内容会逐字逐段显示出来，模拟大模型的流式返回效果。';
    
    for (int i = 0; i < text.length; i++) {
      await Future.delayed(const Duration(milliseconds: 50));
      
      if (mounted) {
        setState(() {
          _displayText = text.substring(0, i + 1);
          _chunkCount = i + 1;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('流式显示演示'),
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _startStreamDemo,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
                child: const Text(
                  '开始流式演示',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '流式显示结果：',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Chunk: $_chunkCount',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Text(
                      _displayText,
                      style: const TextStyle(fontSize: 16, height: 1.5),
                    ),
                    if (_displayText.isEmpty)
                      const Text(
                        '点击上方按钮开始演示',
                        style: TextStyle(
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                '文本长度: ${_displayText.length} 字符',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
