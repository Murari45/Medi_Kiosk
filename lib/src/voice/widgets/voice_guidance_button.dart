import 'package:flutter/material.dart';
import '../../shared/constants/app_colors.dart';
import '../services/tts_service.dart';
import '../../app/di.dart';

class VoiceGuidanceButton extends StatefulWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback onPressed;
  final String voiceDescription;
  final Color backgroundColor;
  final Color foregroundColor;
  final bool isLarge;
  final String? langCode;

  const VoiceGuidanceButton({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    required this.onPressed,
    required this.voiceDescription,
    this.backgroundColor = AppColors.primary,
    this.foregroundColor = Colors.white,
    this.isLarge = false,
    this.langCode,
  });

  @override
  State<VoiceGuidanceButton> createState() => _VoiceGuidanceButtonState();
}

class _VoiceGuidanceButtonState extends State<VoiceGuidanceButton> {
  bool _isSpeakingGuidance = false;

  void _speakGuidance() async {
    final tts = getIt<TTSService>();
    setState(() => _isSpeakingGuidance = true);
    await tts.speak(
      widget.voiceDescription,
      langCode: widget.langCode,
      onComplete: () {
        if (mounted) setState(() => _isSpeakingGuidance = false);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: widget.backgroundColor.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Row(
          children: [
            // Main card area: clicking navigates directly to intake
            Expanded(
              child: InkWell(
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                onTap: widget.onPressed,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: widget.isLarge ? 20.0 : 14.0,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(widget.icon, color: widget.foregroundColor, size: widget.isLarge ? 28 : 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.title,
                              style: TextStyle(
                                color: widget.foregroundColor,
                                fontSize: widget.isLarge ? 17 : 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (widget.subtitle != null) ...[
                              const SizedBox(height: 3),
                              Text(
                                widget.subtitle!,
                                style: TextStyle(
                                  color: widget.foregroundColor.withValues(alpha: 0.88),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Dedicated Speaker Button (Disjoint touch target, never conflicts with card tap)
            Padding(
              padding: const EdgeInsets.only(right: 12.0, left: 4.0),
              child: Tooltip(
                message: 'Listen',
                child: InkResponse(
                  radius: 24,
                  onTap: _speakGuidance,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: _isSpeakingGuidance
                          ? Colors.amberAccent
                          : Colors.white.withValues(alpha: 0.22),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isSpeakingGuidance ? Icons.volume_up_rounded : Icons.volume_up_outlined,
                      color: _isSpeakingGuidance ? Colors.black87 : widget.foregroundColor,
                      size: widget.isLarge ? 26 : 22,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
