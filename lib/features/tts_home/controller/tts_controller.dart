import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

// Enum để quản lý trạng thái, giúp giao diện biết khi nào nên
// bật/tắt nút Play/Stop
enum TtsState { playing, stopped }

// Lớp "Bộ não" của chúng ta, nó kế thừa ChangeNotifier
// để có thể "thông báo" (notify) cho giao diện (View) khi có gì đó thay đổi
class TtsController with ChangeNotifier {
  // 1. KHAI BÁO CÁC BIẾN CẦN THIẾT
  late FlutterTts _flutterTts; // Thư viện TTS
  TtsState _ttsState = TtsState.stopped; // Trạng thái ban đầu

  // Dùng `List<Map>` để lưu danh sách giọng nói
  // (ví dụ: {'name': 'vi-vn-x-vif-local', 'locale': 'vi-VN'})
  List<Map<String, String>> _voices = [];
  Map<String, String>? _selectedVoice; // Giọng nói đang được chọn

  // Các biến cho thanh trượt (slider)
  double _speechRate = 0.5; // Tốc độ nói
  double _pitch = 1.0; // Cao độ (tông) giọng

  // 2. GETTERS - CÁC HÀM "ĐỌC" DỮ LIỆU
  // Giao diện (View) sẽ gọi các hàm này để biết trạng thái
  TtsState get ttsState => _ttsState;
  List<Map<String, String>> get voices => _voices;
  Map<String, String>? get selectedVoice => _selectedVoice;
  double get speechRate => _speechRate;
  double get pitch => _pitch;

  // 3. HÀM KHỞI TẠO (CONSTRUCTOR)
  // Hàm này được gọi ngay khi TtsController được tạo (trong main.dart)
  TtsController() {
    _flutterTts = FlutterTts();
    _initTts(); // Gọi hàm setup chính
  }

  // 4. HÀM SETUP CHÍNH
  // Hàm này là async vì nó cần "chờ" thư viện TTS trả về danh sách giọng nói
  Future<void> _initTts() async {
    // Lấy danh sách GIỌNG NÓI (không phải ngôn ngữ)
    var voicesDynamic = await _flutterTts.getVoices;
    // Ép kiểu dữ liệu nhận về cho an toàn
    _voices = voicesDynamic
        .map((voice) => Map<String, String>.from(voice))
        .where(
          (voice) => voice.containsKey('name') && voice.containsKey('locale'),
        )
        .toList();

    // Tìm và đặt giọng nói mặc định (ưu tiên Tiếng Việt)
    // Tìm và đặt giọng nói mặc định (ưu tiên Tiếng Việt)
    Map<String, String>? viVoice; // 1. Khai báo biến là có thể null
    try {
      // 2. Thử tìm, nếu không thấy sẽ văng lỗi (StateError)
      viVoice = _voices.firstWhere((v) => v['locale']!.startsWith('vi'));
    } catch (e) {
      // 3. Nếu văng lỗi (không tìm thấy), gán là null
      viVoice = null;
    }

    if (viVoice != null) {
      _selectedVoice = viVoice; // Đặt làm giọng mặc định nếu tìm thấy
    } else if (_voices.isNotEmpty) {
      _selectedVoice = _voices.first; // Lấy giọng đầu tiên nếu không có TV
    }

    // 5. CÀI ĐẶT CÁC TRÌNH NGHE (HANDLERS)
    // Rất quan trọng: các hàm này tự động cập nhật trạng thái

    // Khi TTS bắt đầu nói
    _flutterTts.setStartHandler(() {
      _ttsState = TtsState.playing;
      notifyListeners(); // Thông báo cho Giao diện "Tôi bắt đầu nói rồi!"
    });

    // Khi TTS nói xong
    _flutterTts.setCompletionHandler(() {
      _ttsState = TtsState.stopped;
      notifyListeners(); // Thông báo "Tôi nói xong rồi!"
    });

    // Khi TTS gặp lỗi
    _flutterTts.setErrorHandler((msg) {
      print("Lỗi TTS: $msg");
      _ttsState = TtsState.stopped;
      notifyListeners(); // Thông báo "Tôi bị lỗi và dừng rồi!"
    });

    // Thông báo lần cuối khi đã setup xong
    // để Giao diện cập nhật danh sách giọng nói
    notifyListeners();
  }

  // 6. CÁC HÀM CÔNG KHAI (PUBLIC METHODS)
  // Giao diện (View) sẽ gọi các hàm này khi người dùng tương tác

  // Hàm để nói
  Future<void> speak(String text) async {
    // Chỉ nói khi có text, đang ở trạng thái Dừng, và đã chọn giọng
    if (text.isNotEmpty &&
        _ttsState == TtsState.stopped &&
        _selectedVoice != null) {
      // Thiết lập tất cả các thông số trước khi nói
      await _flutterTts.setVoice(_selectedVoice!);
      await _flutterTts.setSpeechRate(_speechRate);
      await _flutterTts.setPitch(_pitch);

      await _flutterTts.speak(text);
      // Trạng thái sẽ tự động cập nhật nhờ `setStartHandler`
    }
  }

  // Hàm để dừng
  Future<void> stop() async {
    if (_ttsState == TtsState.playing) {
      await _flutterTts.stop();
      // Trạng thái sẽ tự động cập nhật nhờ `setCompletionHandler`
    }
  }

  // 7. CÁC HÀM SETTER (GỌI TỪ SLIDER/DROPDOWN)
  // Dùng để Giao diện cập nhật lại trạng thái trong Controller

  void setVoice(Map<String, String>? voice) {
    if (voice != null) {
      _selectedVoice = voice;
      notifyListeners(); // Thông báo để Giao diện biết
    }
  }

  void setSpeechRate(double rate) {
    _speechRate = rate;
    notifyListeners();
  }

  void setPitch(double pitch) {
    _pitch = pitch;
    notifyListeners();
  }
}
