import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform;
import 'screens/chat_screen.dart';

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
