import 'package:flutter/material.dart';

class AnimatedListItem extends StatelessWidget {
  const AnimatedListItem({super.key, required this.index, required this.child});
  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final delayMs = 50 * index.clamp(0, 20);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      // emulate a delay by starting at 0 and holding opacity/offset via a padded animated parent
      builder: (context, value, _) {
        return AnimatedPadding(
          duration: Duration(milliseconds: delayMs),
          padding: EdgeInsets.zero,
          child: Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, (1 - value) * 12),
              child: child,
            ),
          ),
        );
      },
    );
  }
}


