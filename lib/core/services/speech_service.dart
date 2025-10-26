// Bỏ import 'package:google_speech/google_speech.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

class SpeechService {
  final SpeechToText _speech = SpeechToText();
  bool _isListening = false;
  bool _isAvailable = false;
  String _lastWords = '';

  Future<bool> initialize() async {
    print('🎤 [SpeechService] Initializing...');

    // 1. Kiểm tra quyền microphone
    final status = await Permission.microphone.request();
    print('🎤 [SpeechService] Microphone permission: $status');

    if (status != PermissionStatus.granted) {
      print('❌ [SpeechService] Microphone permission denied');
      _isAvailable = false;
      return false;
    }

    // 2. Khởi tạo dịch vụ speech_to_text
    try {
      _isAvailable = await _speech.initialize(
        onStatus: (status) => print('🎤 [SpeechService] Status: $status'),
        onError: (error) => print('❌ [SpeechService] Error: $error'),
      );
      print('✅ [SpeechService] Initialized: $_isAvailable');
      return _isAvailable;
    } catch (e) {
      print('❌ [SpeechService] Initialization exception: $e');
      _isAvailable = false;
      return false;
    }
  }

  Future<void> startListening({
    required Function(String) onResult,
    String localeId = 'vi-VN',
  }) async {
    if (!_isAvailable || _isListening) return;

    print('🎤 [SpeechService] Starting to listen...');
    _lastWords = ''; // Xóa kết quả cũ
    _isListening = true;

    try {
      await _speech.listen(
        onResult: (SpeechRecognitionResult result) {
          // Callback này được gọi liên tục khi người dùng nói
          _lastWords = result.recognizedWords;
          onResult(_lastWords); // Cập nhật text lên UI (HomeScreen)

          // Tự động dừng khi người dùng ngừng nói
          if (result.finalResult) {
            print('🎤 [SpeechService] Final result: $_lastWords');
            _isListening = false;
          }
        },
        localeId: localeId,
        listenFor: const Duration(seconds: 30), // Thời gian nghe tối đa
        pauseFor: const Duration(seconds: 3), // Dừng nếu im lặng 3 giây
        onSoundLevelChange: (level) =>
            print('🎤 [SpeechService] Mic level: $level'),
      );
    } catch (e) {
      print('❌ [SpeechService] Listen error: $e');
      _isListening = false;
      await stopListening();
    }
  }

  Future<void> stopListening() async {
    if (!_isListening) return;

    print('🎤 [SpeechService] Stopping manually...');
    try {
      await _speech.stop();
    } catch (e) {
      print('❌ [SpeechService] Stop error: $e');
    }
    _isListening = false;
  }

  bool get isListening => _isListening;

  // Sửa lại getter này để nó trả về trạng thái thật
  bool get isAvailable => _isAvailable;

  void dispose() {
    print('🎤 [SpeechService] Disposing...');
    _speech.stop();
  }
}
