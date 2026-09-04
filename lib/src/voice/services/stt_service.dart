import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

enum STTStatus { idle, listening, processing, error }

class STTService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isAvailable = false;
  STTStatus _status = STTStatus.idle;
  String _currentLocaleId = 'en_IN';

  STTStatus get status => _status;
  bool get isListening => _status == STTStatus.listening;

  // Hesitation markers across English & Indic languages
  static final List<String> _hesitationPhrases = [
    'umm', 'uhh', 'maybe', 'not sure', 'i think', 'probably', 'perhaps',
    'shayad', 'pata nahi', 'lagta hai', 'thoda thoda', 'शायद', 'पता नहीं',
    'theriyadhu', 'iru koodum', 'teliyadu', 'anukuntunna', 'janina',
  ];

  Future<bool> initialize() async {
    try {
      _isAvailable = await _speech.initialize(
        onError: (val) {
          debugPrint('STT Error: ${val.errorMsg}');
          _status = STTStatus.idle;
        },
        onStatus: (val) {
          if (val == 'done' || val == 'notListening') {
            _status = STTStatus.idle;
          }
        },
      );
      return _isAvailable;
    } catch (e) {
      debugPrint('STT Init Exception: $e');
      _isAvailable = false;
      return false;
    }
  }

  void setLocale(String langCode) {
    switch (langCode) {
      case 'hi':
        _currentLocaleId = 'hi_IN';
        break;
      case 'ta':
        _currentLocaleId = 'ta_IN';
        break;
      case 'te':
        _currentLocaleId = 'te_IN';
        break;
      case 'bn':
        _currentLocaleId = 'bn_IN';
        break;
      default:
        _currentLocaleId = 'en_IN';
    }
  }

  Future<void> startListening({
    required Function(String recognizedWords, bool isFinal) onResult,
    Function(double soundLevel)? onSoundLevel,
    Duration listenFor = const Duration(seconds: 15),
    Duration pauseFor = const Duration(seconds: 4),
  }) async {
    if (!_isAvailable) {
      final initialized = await initialize();
      if (!initialized) {
        // Fallback for desktop/simulated input
        _status = STTStatus.listening;
        return;
      }
    }

    _status = STTStatus.listening;
    try {
      await _speech.listen(
        onResult: (result) {
          onResult(result.recognizedWords, result.finalResult);
          if (result.finalResult) {
            _status = STTStatus.idle;
          }
        },
        onSoundLevelChange: onSoundLevel,
        listenOptions: stt.SpeechListenOptions(
          listenMode: stt.ListenMode.dictation,
          cancelOnError: false,
          partialResults: true,
          localeId: _currentLocaleId,
        ),
      );
    } catch (e) {
      debugPrint('STT listen error: $e');
      _status = STTStatus.error;
    }
  }

  Future<void> stopListening() async {
    if (_speech.isListening) {
      await _speech.stop();
    }
    _status = STTStatus.idle;
  }

  /// Evaluates whether the patient's transcript indicates high certainty, hesitation, or ambiguity
  static String assessConfidence(String transcript) {
    final lower = transcript.toLowerCase().trim();
    if (lower.isEmpty) return 'unclear';

    for (var phrase in _hesitationPhrases) {
      if (lower.contains(phrase)) {
        return 'not_sure';
      }
    }

    // Short ambiguous words like 'yes maybe', 'dunno'
    if (lower.length < 3 && !['yes', 'no', 'left', 'right', 'head', 'back'].contains(lower)) {
      return 'unclear';
    }

    return 'certain';
  }
}
