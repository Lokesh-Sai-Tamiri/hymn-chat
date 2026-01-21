import 'package:flutter/material.dart';

class AnimatedAIIcon extends StatefulWidget {
  final bool isSelected;

  const AnimatedAIIcon({super.key, required this.isSelected});

  @override
  State<AnimatedAIIcon> createState() => _AnimatedAIIconState();
}

class _AnimatedAIIconState extends State<AnimatedAIIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Glowing background (only if selected or just always subtle?)
            // Let's make it always colorful but brighter when selected
            if (widget.isSelected)
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SweepGradient(
                    colors: const [
                      Colors.blue,
                      Colors.purple,
                      Colors.pink,
                      Colors.orange,
                      Colors.blue,
                    ],
                    transform: GradientRotation(
                      _controller.value * 2 * 3.14159,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withOpacity(0.5),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),

            // Icon with simple white or gradient
            // If not selected, we can show a colorful static icon
            // If selected, maybe just white on top of the glow?
            ShaderMask(
              shaderCallback: (bounds) {
                return SweepGradient(
                  colors: const [
                    Colors.blue,
                    Colors.purple,
                    Colors.pink,
                    Colors.orange,
                    Colors.blue,
                  ],
                  transform: GradientRotation(_controller.value * 2 * 3.14159),
                ).createShader(bounds);
              },
              child: const Icon(
                Icons.auto_awesome,
                size: 28,
                color: Colors.white, // Required for ShaderMask
              ),
            ),
          ],
        );
      },
    );
  }
}
