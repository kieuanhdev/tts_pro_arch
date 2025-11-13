import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

enum TtsState { playing, paused, stopped }

class TtsController with ChangeNotifier {
  late FlutterTts _flutterTts;

  TtsState _ttsState = TtsState.stopped;

  List<Map<String, dynamic>> _voices = [];
  Map<String, dynamic>? _selectedVoice;

  double _speechRate = 0.5;
  double _pitch = 1.0;
  
  // Debounce timers để tránh notifyListeners quá thường xuyên
  Timer? _speechRateTimer;
  Timer? _pitchTimer;

  // AUDIOBOOK STATE
  List<String> _chunks = [];
  int _currentChunk = 0;
  int _currentCharIndex = 0;

  // GETTERS
  TtsState get ttsState => _ttsState;
  List<Map<String, dynamic>> get voices => _voices;
  Map<String, dynamic>? get selectedVoice => _selectedVoice;
  double get speechRate => _speechRate;
  double get pitch => _pitch;

  List<String> get chunks => _chunks;
  int get currentChunk => _currentChunk;

  TtsController() {
    _flutterTts = FlutterTts();
    _initTts();
  }

  Future<void> _initTts() async {
    var voicesDynamic = await _flutterTts.getVoices;

    _voices = (voicesDynamic as List)
        .map((e) => Map<String, dynamic>.from(e))
        .where((v) => v.containsKey('name') && v.containsKey('locale'))
        .toList();

    _selectedVoice = _voices.isNotEmpty ? _voices.first : null;

    _flutterTts.setStartHandler(() {
      _ttsState = TtsState.playing;
      notifyListeners();
    });

    _flutterTts.setCompletionHandler(() async {
      if (_currentChunk < _chunks.length - 1) {
        _currentChunk++;
        _currentCharIndex = 0;
        // KHÔNG notify ở đây vì start handler sẽ notify khi chunk mới bắt đầu
        // Điều này tránh rebuild 2 lần liên tiếp (completion + start)
        await _readChunk();
      } else {
        _ttsState = TtsState.stopped;
        notifyListeners();
      }
    });

    _flutterTts.setErrorHandler((msg) {
      // ignore: avoid_print
      print('TTS Error: $msg');
      _ttsState = TtsState.stopped;
      notifyListeners();
    });

    notifyListeners();
  }

  // Fallback không dùng regex → chạy mọi máy
  List<String> _splitSentencesFallback(String text) {
    final List<String> out = [];
    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);

      if ('.!?'.contains(text[i])) {
        out.add(buffer.toString().trim());
        buffer.clear();
      }
    }

    if (buffer.isNotEmpty) {
      out.add(buffer.toString().trim());
    }

    return out.where((e) => e.isNotEmpty).toList();
  }

  // CHIA TEXT CAO CẤP
  List<String> _splitText(String text) {
    text = text.trim();
    if (text.isEmpty) return [];

    List<String> sentences = [];

    try {
      final splitter = RegExp(r'(?<=[.!?])\s+');
      sentences = text
          .split(splitter)
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    } catch (_) {
      sentences = _splitSentencesFallback(text);
    }

    const int maxLen = 220;
    final List<String> merged = [];
    var buffer = '';

    for (final sentence in sentences) {
      if (buffer.isEmpty) {
        buffer = sentence;
      } else if ((buffer.length + 1 + sentence.length) <= maxLen) {
        buffer = '$buffer $sentence';
      } else {
        merged.add(buffer.trim());
        buffer = sentence;
      }
    }
    if (buffer.isNotEmpty) merged.add(buffer.trim());

    final List<String> finalChunks = [];
    for (final chunk in merged) {
      if (chunk.length <= maxLen) {
        finalChunks.add(chunk);
      } else {
        final words = chunk.split(RegExp(r'\s+'));
        var current = '';

        for (final word in words) {
          if (current.isEmpty) {
            current = word;
          } else if ((current.length + 1 + word.length) <= maxLen) {
            current = '$current $word';
          } else {
            finalChunks.add(current.trim());
            current = word;
          }
        }
        if (current.isNotEmpty) finalChunks.add(current.trim());
      }
    }

    return finalChunks;
  }

  Future<void> _readChunk() async {
    if (_chunks.isEmpty) return;

    if (_selectedVoice != null) {
      await _flutterTts.setVoice(
        _selectedVoice!.map((key, value) => MapEntry(key, value.toString())),
      );
    }

    await _flutterTts.setSpeechRate(_speechRate);
    await _flutterTts.setPitch(_pitch);

    final chunk = _chunks[_currentChunk];
    final toRead = chunk.substring(_currentCharIndex);

    await _flutterTts.speak(toRead);
  }

  // PLAY
  Future<void> speak(String text) async {
    text = text.trim();
    if (text.isEmpty) return;

    _chunks = _splitText(text);
    _currentChunk = 0;
    _currentCharIndex = 0;

    _ttsState = TtsState.playing;
    notifyListeners();

    await _readChunk();
  }

  // PAUSE
  Future<void> pause() async {
    if (_ttsState != TtsState.playing) return;

    await _flutterTts.stop();

    _currentCharIndex = (_chunks[_currentChunk].length * 0.3).toInt();

    _ttsState = TtsState.paused;
    notifyListeners();
  }

  // RESUME
  Future<void> resume() async {
    if (_ttsState != TtsState.paused) return;

    _ttsState = TtsState.playing;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 120));
    await _readChunk();
  }

  // STOP
  Future<void> stop() async {
    await _flutterTts.stop();
    _ttsState = TtsState.stopped;
    _currentChunk = 0;
    _currentCharIndex = 0;
    notifyListeners();
  }

  // NEXT / PREV
  Future<void> jumpToNextChunk() async {
    if (_currentChunk >= _chunks.length - 1) return;

    await _flutterTts.stop();
    _currentChunk++;
    _currentCharIndex = 0;
    _ttsState = TtsState.playing;
    notifyListeners();
    await _readChunk();
  }

  Future<void> jumpToPreviousChunk() async {
    if (_currentChunk <= 0) return;

    await _flutterTts.stop();
    _currentChunk--;
    _currentCharIndex = 0;
    _ttsState = TtsState.playing;
    notifyListeners();
    await _readChunk();
  }

  // SETTERS
  void setVoice(Map<String, dynamic>? voice) {
    if (voice == null) return;
    _selectedVoice = voice;
    notifyListeners();
  }

  void setSpeechRate(double value) {
    _speechRate = value;
    _speechRateTimer?.cancel();
    _speechRateTimer = Timer(const Duration(milliseconds: 100), notifyListeners);
  }

  void setPitch(double value) {
    _pitch = value;
    _pitchTimer?.cancel();
    _pitchTimer = Timer(const Duration(milliseconds: 100), notifyListeners);
  }

  @override
  void dispose() {
    _speechRateTimer?.cancel();
    _pitchTimer?.cancel();
    _flutterTts.stop();
    super.dispose();
  }
}
