import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';
import 'dart:ui_web' as ui_web;
import 'package:flutter/widgets.dart';

class WebcamController {
  html.VideoElement? _videoElement;
  html.MediaStream? _mediaStream;
  late final String viewType;
  bool isInitialized = false;

  WebcamController() {
    viewType = 'webcam-view-${DateTime.now().microsecondsSinceEpoch}';
  }

  Future<bool> initialize() async {
    try {
      _videoElement = html.VideoElement()
        ..autoplay = true
        ..muted = true
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'cover'
        ..style.borderRadius = '12px';
      _videoElement!.setAttribute('playsinline', 'true');

      ui_web.platformViewRegistry.registerViewFactory(
        viewType,
        (int id) => _videoElement!,
      );

      final mediaStream = await html.window.navigator.mediaDevices?.getUserMedia({
        'video': {
          'facingMode': 'environment',
        }
      });

      if (mediaStream != null) {
        _mediaStream = mediaStream;
        _videoElement!.srcObject = mediaStream;
        await _videoElement!.play();
        isInitialized = true;
        return true;
      }
      return false;
    } catch (e) {
      isInitialized = false;
      return false;
    }
  }

  Widget buildPreview() {
    return HtmlElementView(viewType: viewType);
  }

  Future<Uint8List?> captureFrame() async {
    if (_videoElement == null) return null;
    try {
      final width = _videoElement!.videoWidth > 0 ? _videoElement!.videoWidth : 1280;
      final height = _videoElement!.videoHeight > 0 ? _videoElement!.videoHeight : 720;
      final canvas = html.CanvasElement(width: width, height: height);
      final ctx = canvas.context2D;
      ctx.drawImage(_videoElement!, 0, 0);

      final dataUrl = canvas.toDataUrl('image/jpeg', 0.92);
      final base64String = dataUrl.split(',').last;
      final decoded = html.window.atob(base64String);
      final bytes = Uint8List(decoded.length);
      for (int i = 0; i < decoded.length; i++) {
        bytes[i] = decoded.codeUnitAt(i);
      }
      return bytes;
    } catch (e) {
      return null;
    }
  }

  void dispose() {
    try {
      _mediaStream?.getTracks().forEach((track) => track.stop());
      _videoElement?.pause();
      _videoElement?.srcObject = null;
    } catch (_) {}
  }
}
