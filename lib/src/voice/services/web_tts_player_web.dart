// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:async';
import 'dart:html' as html;
import 'package:flutter/foundation.dart';

class WebTTSPlayer {
  static html.AudioElement? _currentAudio;
  static StreamSubscription? _endSub;
  static StreamSubscription? _errSub;
  static int _currentSpeechId = 0;

  static Future<void> stop() async {
    _currentSpeechId++;
    try {
      _endSub?.cancel();
      _endSub = null;
      _errSub?.cancel();
      _errSub = null;

      if (_currentAudio != null) {
        _currentAudio!.pause();
        _currentAudio!.removeAttribute('src');
        _currentAudio = null;
      }

      final synth = html.window.speechSynthesis;
      if (synth != null) {
        synth.cancel();
      }
    } catch (e) {
      debugPrint('WebTTSPlayer stop error: $e');
    }
  }

  static Future<void> speak(
    String text, {
    required String lang,
    VoidCallback? onComplete,
  }) async {
    await stop();

    final cleanText = text.trim();
    if (cleanText.isEmpty) {
      onComplete?.call();
      return;
    }

    final speechId = _currentSpeechId;
    final chunks = _splitIntoChunks(cleanText, 160);
    _playChunks(chunks, 0, lang, speechId, onComplete);
  }

  static List<String> _splitIntoChunks(String text, int maxLength) {
    if (text.length <= maxLength) return [text];
    final List<String> chunks = [];
    final sentences = text.split(RegExp(r'(?<=[.!?|।\n])\s+'));
    String currentChunk = '';

    for (final s in sentences) {
      final trimmed = s.trim();
      if (trimmed.isEmpty) continue;

      if (currentChunk.isEmpty) {
        currentChunk = trimmed;
      } else if ((currentChunk.length + trimmed.length + 1) <= maxLength) {
        currentChunk += ' $trimmed';
      } else {
        chunks.add(currentChunk);
        currentChunk = trimmed;
      }
    }

    if (currentChunk.isNotEmpty) {
      chunks.add(currentChunk);
    }

    return chunks.isEmpty ? [text] : chunks;
  }

  static void _playChunks(
    List<String> chunks,
    int index,
    String lang,
    int speechId,
    VoidCallback? onComplete,
  ) {
    if (speechId != _currentSpeechId) return;

    if (index >= chunks.length) {
      onComplete?.call();
      return;
    }

    final chunk = chunks[index];
    final langCode = _normalizeLangCode(lang);
    final encoded = Uri.encodeComponent(chunk);
    final url = 'https://translate.google.com/translate_tts?ie=UTF-8&tl=$langCode&client=tw-ob&q=$encoded';

    try {
      final audio = html.AudioElement(url)
        ..autoplay = false
        ..preload = 'auto';
      _currentAudio = audio;

      void cleanup() {
        _endSub?.cancel();
        _endSub = null;
        _errSub?.cancel();
        _errSub = null;
      }

      _endSub = audio.onEnded.listen((_) {
        cleanup();
        if (speechId == _currentSpeechId) {
          _playChunks(chunks, index + 1, lang, speechId, onComplete);
        }
      });

      _errSub = audio.onError.listen((_) {
        cleanup();
        if (speechId == _currentSpeechId) {
          debugPrint('WebTTSPlayer audio error for lang $langCode. Trying browser SpeechSynthesis fallback.');
          _fallbackBrowserSpeech(chunks.sublist(index).join(' '), lang, speechId, onComplete);
        }
      });

      final playFuture = audio.play();
      playFuture.catchError((err) {
        cleanup();
        if (speechId == _currentSpeechId) {
          debugPrint('WebTTSPlayer audio play caught error: $err. Trying browser SpeechSynthesis fallback.');
          _fallbackBrowserSpeech(chunks.sublist(index).join(' '), lang, speechId, onComplete);
        }
      });
    } catch (e) {
      debugPrint('WebTTSPlayer exception: $e. Using fallback speech synthesis.');
      _fallbackBrowserSpeech(chunks.sublist(index).join(' '), lang, speechId, onComplete);
    }
  }

  static void _fallbackBrowserSpeech(
    String text,
    String lang,
    int speechId,
    VoidCallback? onComplete,
  ) {
    if (speechId != _currentSpeechId) return;

    try {
      final synth = html.window.speechSynthesis;
      if (synth == null) {
        onComplete?.call();
        return;
      }

      if (synth.paused == true) {
        synth.resume();
      }
      synth.cancel();

      Future.delayed(const Duration(milliseconds: 50), () {
        if (speechId != _currentSpeechId) return;

        final utterance = html.SpeechSynthesisUtterance(text);
        final locale = _normalizeLocale(lang);
        utterance.lang = locale;
        utterance.rate = 1.0;

        final voices = synth.getVoices();
        if (voices.isNotEmpty) {
          final prefix = lang.toLowerCase();
          final matchingVoice = voices.firstWhere(
            (v) => (v.lang?.toLowerCase().startsWith(prefix) ?? false),
            orElse: () => voices.first,
          );
          utterance.voice = matchingVoice;
        }

        utterance.onEnd.listen((_) {
          if (speechId == _currentSpeechId) {
            onComplete?.call();
          }
        });

        utterance.onError.listen((_) {
          if (speechId == _currentSpeechId) {
            onComplete?.call();
          }
        });

        synth.speak(utterance);
      });
    } catch (e) {
      debugPrint('WebTTSPlayer fallback speech exception: $e');
      onComplete?.call();
    }
  }

  static String _normalizeLangCode(String lang) {
    switch (lang.toLowerCase()) {
      case 'hi':
      case 'hi-in':
        return 'hi';
      case 'ta':
      case 'ta-in':
        return 'ta';
      case 'te':
      case 'te-in':
        return 'te';
      case 'bn':
      case 'bn-in':
        return 'bn';
      default:
        return 'en';
    }
  }

  static String _normalizeLocale(String lang) {
    switch (lang.toLowerCase()) {
      case 'hi':
      case 'hi-in':
        return 'hi-IN';
      case 'ta':
      case 'ta-in':
        return 'ta-IN';
      case 'te':
      case 'te-in':
        return 'te-IN';
      case 'bn':
      case 'bn-in':
        return 'bn-IN';
      default:
        return 'en-IN';
    }
  }
}
