// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';
import 'dart:ui_web' as ui_web;
import 'package:flutter/widgets.dart';

class WebcamController {
  html.VideoElement? _videoElement;
  html.MediaStream? _mediaStream;
  late final String viewType;
  bool isInitialized = false;
  bool _isFactoryRegistered = false;

  WebcamController() {
    viewType = 'webcam-view-${DateTime.now().microsecondsSinceEpoch}';
  }

  Future<bool> initialize() async {
    if (isInitialized && _videoElement != null && _mediaStream != null) {
      return true;
    }

    try {
      _videoElement = html.VideoElement()
        ..autoplay = true
        ..muted = true
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'cover'
        ..style.borderRadius = '12px';
      _videoElement!.setAttribute('playsinline', 'true');

      if (!_isFactoryRegistered) {
        ui_web.platformViewRegistry.registerViewFactory(
          viewType,
          (int id) => _videoElement!,
        );
        _isFactoryRegistered = true;
      }

      final mediaDevices = html.window.navigator.mediaDevices;
      if (mediaDevices == null) {
        isInitialized = false;
        return false;
      }

      html.MediaStream? mediaStream;
      // 1. Try back/environment camera first (ideal for scanning papers/prescriptions)
      try {
        mediaStream = await mediaDevices.getUserMedia({
          'video': {'facingMode': 'environment'},
        });
      } catch (_) {
        mediaStream = null;
      }

      // 2. Fallback to any available video camera (desktops, laptops, USB webcams)
      if (mediaStream == null) {
        try {
          mediaStream = await mediaDevices.getUserMedia({
            'video': true,
          });
        } catch (_) {
          mediaStream = null;
        }
      }

      if (mediaStream != null) {
        _mediaStream = mediaStream;
        _videoElement!.srcObject = mediaStream;
        try {
          await _videoElement!.play();
        } catch (_) {}
        isInitialized = true;
        return true;
      }

      isInitialized = false;
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
    if (_videoElement == null || !isInitialized) return null;
    try {
      // If video metadata is still settling, wait briefly for frame dimensions
      if (_videoElement!.videoWidth == 0) {
        await Future.delayed(const Duration(milliseconds: 250));
      }

      final width = _videoElement!.videoWidth > 0 ? _videoElement!.videoWidth : 1280;
      final height = _videoElement!.videoHeight > 0 ? _videoElement!.videoHeight : 720;
      final canvas = html.CanvasElement(width: width, height: height);
      final ctx = canvas.context2D;

      // Scale video element to canvas to avoid letterboxing/cropping
      ctx.drawImageScaled(_videoElement!, 0, 0, width, height);

      final dataUrl = canvas.toDataUrl('image/jpeg', 0.92);
      final commaIndex = dataUrl.indexOf(',');
      final base64String = commaIndex != -1 ? dataUrl.substring(commaIndex + 1) : dataUrl;
      return Uint8List.fromList(base64Decode(base64String));
    } catch (e) {
      return null;
    }
  }

  void dispose() {
    try {
      _mediaStream?.getTracks().forEach((track) => track.stop());
      _videoElement?.pause();
      _videoElement?.srcObject = null;
      _videoElement?.remove();
    } catch (_) {}
    _mediaStream = null;
    _videoElement = null;
    isInitialized = false;
  }
}
