import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

enum TtsState { playing, stopped }

class TtsController with ChangeNotifier {
  late FlutterTts _flutterTts;

  TtsState _ttsState = TtsState.stopped;

  // NOTE: flutter_tts không trả Map<String, String>
  // mà trả Map<String, dynamic>.
  List<Map<String, dynamic>> _voices = [];
  Map<String, dynamic>? _selectedVoice;

  double _speechRate = 0.5;
  double _pitch = 1.0;

  // GETTERS
  TtsState get ttsState => _ttsState;
  List<Map<String, dynamic>> get voices => _voices;
  Map<String, dynamic>? get selectedVoice => _selectedVoice;
  double get speechRate => _speechRate;
  double get pitch => _pitch;

  TtsController() {
    _flutterTts = FlutterTts();
    _initTts();
  }

  // INIT
  Future<void> _initTts() async {
    final voicesDynamic = await _flutterTts.getVoices;

    // Convert CHUẨN
    _voices = (voicesDynamic as List)
        .map((e) => Map<String, dynamic>.from(e))
        .where((voice) =>
    voice.containsKey('name') && voice.containsKey('locale'))
        .toList();

    // Chọn mặc định: ưu tiên tiếng Việt
    _selectedVoice = _voices.firstWhere(
          (v) => v['locale'].toString().startsWith('vi'),
      orElse: () => _voices.isNotEmpty ? _voices.first : {},
    );

    // HANDLERS
    _flutterTts.setStartHandler(() {
      _ttsState = TtsState.playing;
      notifyListeners();
    });

    _flutterTts.setCompletionHandler(() {
      _ttsState = TtsState.stopped;
      notifyListeners();
    });

    _flutterTts.setErrorHandler((msg) {
      print("TTS Error: $msg");
      _ttsState = TtsState.stopped;
      notifyListeners();
    });

    notifyListeners();
  }

  // SPEAK
  Future<void> speak(String text) async {
    if (text.isEmpty) return;
    if (_ttsState != TtsState.stopped) return;
    if (_selectedVoice == null) return;

    await _flutterTts.setVoice(
      _selectedVoice!.map((key, value) => MapEntry(key, value.toString())),
    );

    await _flutterTts.setSpeechRate(_speechRate);
    await _flutterTts.setPitch(_pitch);

    await _flutterTts.speak(text);
  }

  // STOP
  Future<void> stop() async {
    if (_ttsState == TtsState.playing) {
      await _flutterTts.stop();
    }
  }

  // SETTERS
  void setVoice(Map<String, dynamic>? voice) {
    if (voice != null) {
      _selectedVoice = voice;
      notifyListeners();
    }
  }

  void setSpeechRate(double value) {
    _speechRate = value;
    notifyListeners();
  }

  void setPitch(double value) {
    _pitch = value;
    notifyListeners();
  }
}
