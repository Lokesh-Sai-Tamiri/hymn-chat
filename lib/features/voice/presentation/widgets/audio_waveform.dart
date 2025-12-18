import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';

/// Animated audio waveform widget
class AudioWaveform extends StatefulWidget {
  final bool isRecording;
  final double amplitude; // 0.0 to 1.0
  final Color color;
  final double height;
  final int barCount;

  const AudioWaveform({
    super.key,
    required this.isRecording,
    this.amplitude = 0.0,
    this.color = AppColors.primary,
    this.height = 40,
    this.barCount = 30,
  });

  @override
  State<AudioWaveform> createState() => _AudioWaveformState();
}

class _AudioWaveformState extends State<AudioWaveform>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final List<double> _barHeights = [];
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    )..repeat();
    
    // Initialize bar heights
    for (int i = 0; i < widget.barCount; i++) {
      _barHeights.add(0.1);
    }
  }

  @override
  void didUpdateWidget(AudioWaveform oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isRecording && widget.amplitude > 0) {
      // Shift bars to the left and add new amplitude
      _barHeights.removeAt(0);
      _barHeights.add(widget.amplitude);
    } else if (!widget.isRecording) {
      // Reset to idle state gradually
      for (int i = 0; i < _barHeights.length; i++) {
        _barHeights[i] = _barHeights[i] * 0.9;
        if (_barHeights[i] < 0.05) _barHeights[i] = 0.05;
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return CustomPaint(
          size: Size(double.infinity, widget.height),
          painter: _WaveformPainter(
            barHeights: _barHeights,
            color: widget.color,
            isRecording: widget.isRecording,
            animationValue: _animationController.value,
          ),
        );
      },
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final List<double> barHeights;
  final Color color;
  final bool isRecording;
  final double animationValue;

  _WaveformPainter({
    required this.barHeights,
    required this.color,
    required this.isRecording,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final barWidth = (size.width / barHeights.length) * 0.6;
    final gap = (size.width / barHeights.length) * 0.4;
    final centerY = size.height / 2;

    for (int i = 0; i < barHeights.length; i++) {
      double height;
      
      if (isRecording) {
        // Use actual amplitude data
        height = barHeights[i] * size.height * 0.9;
      } else {
        // Idle animation - gentle sine wave
        final phase = (animationValue * 2 * math.pi) + (i * 0.3);
        height = (math.sin(phase) * 0.15 + 0.2) * size.height;
      }
      
      // Ensure minimum height
      height = math.max(height, 4);

      final x = i * (barWidth + gap);
      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(x + barWidth / 2, centerY),
          width: barWidth,
          height: height,
        ),
        const Radius.circular(2),
      );

      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter oldDelegate) {
    return oldDelegate.barHeights != barHeights ||
        oldDelegate.isRecording != isRecording ||
        oldDelegate.animationValue != animationValue;
  }
}

/// Simple idle waveform line (static display when not recording)
class IdleWaveformLine extends StatelessWidget {
  final Color color;
  final double height;

  const IdleWaveformLine({
    super.key,
    this.color = AppColors.textSecondary,
    this.height = 2,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: color.withOpacity(0.3),
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }
}

