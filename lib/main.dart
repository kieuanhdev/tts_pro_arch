import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tts_pro_arch/features/tts_home/controller/tts_controller.dart';
import 'package:tts_pro_arch/features/tts_home/view/tts_home_screen.dart';

void main() {
  runApp(
    // Cung cấp "Bộ não" (TtsController) cho toàn bộ ứng dụng
    ChangeNotifierProvider(
      create: (context) => TtsController(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TTS Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: const TtsHomeScreen(),
    );
  }
}
