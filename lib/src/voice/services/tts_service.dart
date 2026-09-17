import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'web_tts_player.dart';

enum TTSState { stopped, playing, paused }

class TTSService {
  final FlutterTts _flutterTts = FlutterTts();
  TTSState _state = TTSState.stopped;
  String _currentLanguage = 'en-IN';
  VoidCallback? onSpeechCompleted;
  Timer? _speechTimeoutTimer;

  TTSState get state => _state;
  bool get isSpeaking => _state == TTSState.playing;
  double get currentRate => kIsWeb ? 1.0 : 0.5;

  TTSService() {
    _initTTS();
  }

  Future<void> _initTTS() async {
    try {
      await _flutterTts.setSpeechRate(kIsWeb ? 1.0 : 0.5); // Regular standard speaking rate (1.0x normal speed)
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);

      _flutterTts.setStartHandler(() {
        _state = TTSState.playing;
      });

      _flutterTts.setCompletionHandler(() {
        _speechTimeoutTimer?.cancel();
        _state = TTSState.stopped;
        final callback = onSpeechCompleted;
        onSpeechCompleted = null;
        callback?.call();
      });

      _flutterTts.setCancelHandler(() {
        _speechTimeoutTimer?.cancel();
        _state = TTSState.stopped;
      });

      _flutterTts.setErrorHandler((msg) {
        _speechTimeoutTimer?.cancel();
        _state = TTSState.stopped;
        debugPrint('TTS Error: $msg');
        final callback = onSpeechCompleted;
        onSpeechCompleted = null;
        callback?.call();
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

    _speechTimeoutTimer?.cancel();

    if (onComplete != null) {
      onSpeechCompleted = onComplete;
    }

    if (langCode != null) {
      await setLanguage(langCode);
    }

    // Safety watchdog timer: guarantees state resets if audio/browser speech drops completion event
    final expectedDurationMs = (text.length * 80).clamp(2500, 12000);
    _speechTimeoutTimer = Timer(Duration(milliseconds: expectedDurationMs), () {
      if (_state == TTSState.playing) {
        _state = TTSState.stopped;
        final callback = onSpeechCompleted;
        onSpeechCompleted = null;
        callback?.call();
      }
    });

    if (kIsWeb) {
      try {
        _state = TTSState.playing;
        await WebTTSPlayer.speak(
          text,
          lang: langCode ?? _currentLanguage,
          onComplete: () {
            _speechTimeoutTimer?.cancel();
            _state = TTSState.stopped;
            final callback = onSpeechCompleted;
            onSpeechCompleted = null;
            callback?.call();
          },
        );
      } catch (e) {
        debugPrint('WebTTSPlayer speak error: $e');
        _speechTimeoutTimer?.cancel();
        _state = TTSState.stopped;
        final callback = onSpeechCompleted;
        onSpeechCompleted = null;
        callback?.call();
      }
      return;
    }

    // Native Mobile / Desktop implementation
    try {
      await _flutterTts.setSpeechRate(0.5); // 0.5 is 1.0x normal on mobile
      await _flutterTts.stop();
      _state = TTSState.playing;
      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint('TTS speak error: $e');
      _speechTimeoutTimer?.cancel();
      _state = TTSState.stopped;
      final callback = onSpeechCompleted;
      onSpeechCompleted = null;
      callback?.call();
    }
  }

  Future<void> stop() async {
    _speechTimeoutTimer?.cancel();
    if (kIsWeb) {
      try {
        await WebTTSPlayer.stop();
      } catch (_) {}
    }
    try {
      await _flutterTts.stop();
      _state = TTSState.stopped;
    } catch (_) {}
  }
}

