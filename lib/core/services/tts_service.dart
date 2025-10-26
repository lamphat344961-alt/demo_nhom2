import 'package:flutter_tts/flutter_tts.dart';

class TTSService {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;
  bool _isSpeaking = false;

  Future<void> initialize() async {
    print('🔊 [TTSService] Initializing...');

    try {
      // Configure TTS
      await _flutterTts.setLanguage('vi-VN'); // Vietnamese
      await _flutterTts.setSpeechRate(0.5); // Speed (0.0 - 1.0)
      await _flutterTts.setVolume(1.0); // Volume (0.0 - 1.0)
      await _flutterTts.setPitch(1.0); // Pitch (0.5 - 2.0)

      // Set up handlers
      _flutterTts.setStartHandler(() {
        print('🔊 [TTSService] Started speaking');
        _isSpeaking = true;
      });

      _flutterTts.setCompletionHandler(() {
        print('🔊 [TTSService] Completed speaking');
        _isSpeaking = false;
      });

      _flutterTts.setErrorHandler((msg) {
        print('❌ [TTSService] Error: $msg');
        _isSpeaking = false;
      });

      _isInitialized = true;
      print('✅ [TTSService] Initialized successfully');
    } catch (e) {
      print('❌ [TTSService] Initialization error: $e');
      _isInitialized = false;
    }
  }

  Future<void> speak(String text) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (text.isEmpty) {
      print('⚠️ [TTSService] Empty text, skipping');
      return;
    }

    print(
      '🔊 [TTSService] Speaking: ${text.substring(0, text.length > 50 ? 50 : text.length)}...',
    );

    try {
      await _flutterTts.speak(text);
    } catch (e) {
      print('❌ [TTSService] Speak error: $e');
    }
  }

  Future<void> stop() async {
    print('🔊 [TTSService] Stopping...');
    await _flutterTts.stop();
    _isSpeaking = false;
  }

  Future<void> pause() async {
    print('🔊 [TTSService] Pausing...');
    await _flutterTts.pause();
  }

  Future<void> setLanguage(String language) async {
    print('🔊 [TTSService] Setting language to: $language');
    await _flutterTts.setLanguage(language);
  }

  Future<void> setSpeechRate(double rate) async {
    print('🔊 [TTSService] Setting speech rate to: $rate');
    await _flutterTts.setSpeechRate(rate);
  }

  Future<void> setVolume(double volume) async {
    print('🔊 [TTSService] Setting volume to: $volume');
    await _flutterTts.setVolume(volume);
  }

  Future<List<dynamic>> getLanguages() async {
    return await _flutterTts.getLanguages;
  }

  bool get isInitialized => _isInitialized;
  bool get isSpeaking => _isSpeaking;

  void dispose() {
    print('🔊 [TTSService] Disposing...');
    _flutterTts.stop();
  }
}
