import 'package:flutter/material.dart';

class TypingIndicator extends StatefulWidget {
  final Color? bubbleColor;
  final Color? dotColor;
  final double? dotSize;
  final Duration? animationDuration;

  const TypingIndicator({
    super.key,
    this.bubbleColor,
    this.dotColor,
    this.dotSize,
    this.animationDuration,
  });

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration ?? const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _animations = List.generate(3, (index) {
      return Tween<double>(begin: 0, end: 6).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(index * 0.2, 1.0, curve: Curves.easeInOutSine),
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: widget.bubbleColor ?? Colors.grey[300],
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (index) {
          return AnimatedBuilder(
            animation: _animations[index],
            builder: (context, child) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Opacity(
                  opacity: (1 - _animations[index].value / 6),
                  child: Container(
                    width: widget.dotSize ?? 8,
                    height: widget.dotSize ?? 8,
                    decoration: BoxDecoration(
                      color: widget.dotColor ?? Colors.grey[600],
                      shape: BoxShape.circle,
                    ),
                    transform: Matrix4.translationValues(
                      0,
                      -_animations[index].value,
                      0,
                    ),
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
