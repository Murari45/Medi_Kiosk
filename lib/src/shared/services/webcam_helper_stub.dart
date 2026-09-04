import 'dart:typed_data';
import 'package:flutter/widgets.dart';

class WebcamController {
  final String viewType = 'webcam-view-stub';
  bool isInitialized = false;

  Future<bool> initialize() async {
    return false;
  }

  Widget buildPreview() {
    return const SizedBox.shrink();
  }

  Future<Uint8List?> captureFrame() async {
    return null;
  }

  void dispose() {}
}
