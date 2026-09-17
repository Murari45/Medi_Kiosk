import 'package:flutter/foundation.dart';

class WebTTSPlayer {
  static Future<void> stop() async {}

  static Future<void> speak(
    String text, {
    required String lang,
    VoidCallback? onComplete,
  }) async {
    onComplete?.call();
  }
}
