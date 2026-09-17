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

  Timer? _listenTimeoutTimer;

  Future<void> startListening({
    required Function(String recognizedWords, bool isFinal) onResult,
    Function(double soundLevel)? onSoundLevel,
    Duration listenFor = const Duration(seconds: 15),
    Duration pauseFor = const Duration(seconds: 4),
  }) async {
    _listenTimeoutTimer?.cancel();

    if (!_isAvailable) {
      final initialized = await initialize();
      if (!initialized) {
        // When microphone is not available or denied, avoid hanging in listening state
        _status = STTStatus.idle;
        onResult('', true);
        return;
      }
    }

    _status = STTStatus.listening;

    // Safety timeout: guarantees intake progresses if user stays silent or browser STT drops stream
    _listenTimeoutTimer = Timer(listenFor + const Duration(milliseconds: 500), () {
      if (_status == STTStatus.listening) {
        stopListening();
        onResult('', true);
      }
    });

    try {
      await _speech.listen(
        onResult: (result) {
          onResult(result.recognizedWords, result.finalResult);
          if (result.finalResult) {
            _listenTimeoutTimer?.cancel();
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
      _listenTimeoutTimer?.cancel();
      _status = STTStatus.error;
      onResult('', true);
    }
  }

  Future<void> stopListening() async {
    _listenTimeoutTimer?.cancel();
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

  /// Automatically identifies the language spoken by the patient from their voice transcript
  static String detectSpokenLanguage(String text, [String fallbackLang = 'en']) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return fallbackLang;

    // 1. Script-based Unicode detection
    if (RegExp(r'[\u0900-\u097F]').hasMatch(trimmed)) return 'hi'; // Devanagari (Hindi)
    if (RegExp(r'[\u0B80-\u0BFF]').hasMatch(trimmed)) return 'ta'; // Tamil
    if (RegExp(r'[\u0C00-\u0C7F]').hasMatch(trimmed)) return 'te'; // Telugu
    if (RegExp(r'[\u0980-\u09FF]').hasMatch(trimmed)) return 'bn'; // Bengali

    // 2. Phonetic / Transliteration keyword detection
    final lower = ' ${trimmed.toLowerCase()} ';

    const hindiWords = [
      'dard', 'seene', 'pet', 'sar', 'sir', 'bukhar', 'chakkar', 'ulti', 'jalan',
      'subah', 'raat', 'aaj', 'kal', 'bohot', 'bahut', 'thoda', 'zyada', 'kam',
      'nahi', 'hai', 'tha', 'raha', 'rahi', 'hota', 'hoti', 'lagta', 'pata',
      'kuch', 'bhi', 'kahan', 'kab', 'kaise', 'accha', 'theek', 'bura',
      'vata', 'pitta', 'kapha', 'dosha', 'agni', 'khana', 'pachan', 'shuru',
      'pareshani', 'takleef', 'kamzor', 'kamzori', 'sukoon', 'aaram'
    ];
    for (final kw in hindiWords) {
      if (lower.contains(' $kw ')) return 'hi';
    }

    const tamilWords = [
      'vali', 'thalai', 'vayiru', 'kaichal', 'marbu', 'illa', 'irukku',
      'neram', 'nalaiku', 'romba', 'konjam', 'sari', 'theriyum', 'theriyadhu', 'epadi'
    ];
    for (final kw in tamilWords) {
      if (lower.contains(' $kw ')) return 'ta';
    }

    const teluguWords = [
      'noppi', 'tala', 'kadupu', 'jwaram', 'gunde', 'ledu', 'undi',
      'chala', 'konchem', 'bavundi', 'telusu', 'teliyadu', 'eppudu'
    ];
    for (final kw in teluguWords) {
      if (lower.contains(' $kw ')) return 'te';
    }

    const bengaliWords = [
      'byatha', 'matha', 'pet', 'jwor', 'buke', 'nei', 'ache',
      'khub', 'ektu', 'bhalo', 'jani', 'janina', 'kobe'
    ];
    for (final kw in bengaliWords) {
      if (lower.contains(' $kw ')) return 'bn';
    }

    return fallbackLang;
  }
}
