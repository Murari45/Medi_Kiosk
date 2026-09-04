import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

enum TTSState { stopped, playing, paused }

class TTSService {
  final FlutterTts _flutterTts = FlutterTts();
  TTSState _state = TTSState.stopped;
  String _currentLanguage = 'en-IN';
  VoidCallback? onSpeechCompleted;

  TTSState get state => _state;
  bool get isSpeaking => _state == TTSState.playing;

  TTSService() {
    _initTTS();
  }

  Future<void> _initTTS() async {
    try {
      await _flutterTts.setSpeechRate(0.48); // Slightly slower for elderly clarity
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);

      _flutterTts.setStartHandler(() {
        _state = TTSState.playing;
      });

      _flutterTts.setCompletionHandler(() {
        _state = TTSState.stopped;
        onSpeechCompleted?.call();
      });

      _flutterTts.setCancelHandler(() {
        _state = TTSState.stopped;
      });

      _flutterTts.setErrorHandler((msg) {
        _state = TTSState.stopped;
        debugPrint('TTS Error: $msg');
      });
    } catch (e) {
      debugPrint('TTS initialization warning: $e');
    }
  }

  Future<void> setLanguage(String langCode) async {
    switch (langCode) {
      case 'hi':
        _currentLanguage = 'hi-IN';
        break;
      case 'ta':
        _currentLanguage = 'ta-IN';
        break;
      case 'te':
        _currentLanguage = 'te-IN';
        break;
      case 'bn':
        _currentLanguage = 'bn-IN';
        break;
      default:
        _currentLanguage = 'en-IN';
    }

    try {
      await _flutterTts.setLanguage(_currentLanguage);
    } catch (e) {
      debugPrint('Could not set TTS language $_currentLanguage: $e');
    }
  }

  Future<void> speak(String text, {String? langCode, VoidCallback? onComplete}) async {
    if (text.trim().isEmpty) return;

    if (onComplete != null) {
      onSpeechCompleted = onComplete;
    }

    if (langCode != null) {
      await setLanguage(langCode);
    }

    try {
      await _flutterTts.stop();
      _state = TTSState.playing;
      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint('TTS speak error: $e');
      _state = TTSState.stopped;
      onSpeechCompleted?.call();
    }
  }

  Future<void> stop() async {
    try {
      await _flutterTts.stop();
      _state = TTSState.stopped;
    } catch (_) {}
  }
}
