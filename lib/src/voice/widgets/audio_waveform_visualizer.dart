import 'dart:math';
import 'package:flutter/material.dart';
import '../../shared/constants/app_colors.dart';

class AudioWaveformVisualizer extends StatefulWidget {
  final bool isRecording;
  final double barHeight;
  final Color? waveColor;

  const AudioWaveformVisualizer({
    super.key,
    required this.isRecording,
    this.barHeight = 50.0,
    this.waveColor,
  });

  @override
  State<AudioWaveformVisualizer> createState() => _AudioWaveformVisualizerState();
}

class _AudioWaveformVisualizerState extends State<AudioWaveformVisualizer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    if (widget.isRecording) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(AudioWaveformVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRecording != oldWidget.isRecording) {
      if (widget.isRecording) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isRecording) {
      return SizedBox(
        height: widget.barHeight,
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(12, (index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 2.5),
                width: 4,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.borderDark,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SizedBox(
          height: widget.barHeight,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(16, (index) {
              final randomFactor = _random.nextDouble();
              final height = (0.2 + randomFactor * 0.8) * widget.barHeight;

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 2.5),
                width: 4.5,
                height: height,
                decoration: BoxDecoration(
                  color: widget.waveColor ?? AppColors.micActive,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
