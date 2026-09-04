import 'package:flutter/material.dart';
import '../../shared/constants/app_colors.dart';

class VoicePointerOverlay extends StatefulWidget {
  final bool isVisible;
  final String label;
  final Alignment targetAlignment;

  const VoicePointerOverlay({
    super.key,
    required this.isVisible,
    required this.label,
    this.targetAlignment = Alignment.center,
  });

  @override
  State<VoicePointerOverlay> createState() => _VoicePointerOverlayState();
}

class _VoicePointerOverlayState extends State<VoicePointerOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _bounceAnimation = Tween<double>(begin: 0.0, end: 16.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) return const SizedBox.shrink();

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _bounceAnimation,
        builder: (context, child) {
          return Align(
            alignment: widget.targetAlignment,
            child: Transform.translate(
              offset: Offset(0, -_bounceAnimation.value),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.pointerAccent,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.pointerAccent.withValues(alpha: 0.45),
                      blurRadius: 12,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.touch_app_rounded, color: Colors.white, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      widget.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
