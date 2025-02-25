import 'package:ai_text_editor/utils/styles.dart';
import 'package:flutter/material.dart';

class AnimatedText extends StatefulWidget {
  const AnimatedText(
      {super.key, required this.text, this.decoration, this.onTap});
  final String text;
  final Widget? decoration;
  final VoidCallback? onTap;

  @override
  State<AnimatedText> createState() => _AnimatedTextState();
}

class _AnimatedTextState extends State<AnimatedText> {
  final color = Colors.blueAccent.withAlpha(128);
  double value = 0;
  bool animated = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          if (!animated) {
            setState(() {
              animated = true;
              value = value == 0.0 ? 1.0 : 0.0;
            });
          }
          Future.delayed(Duration(seconds: 2)).then((_) {
            widget.onTap?.call();
          });
        },
        child: TweenAnimationBuilder<double>(
          onEnd: () {
            setState(() {
              animated = false;
            });
          },
          builder: (context, v, c) {
            if (!animated) {
              return FittedBox(
                child: Row(
                  spacing: 10,
                  children: [
                    widget.decoration ??
                        Icon(
                          Icons.bolt,
                          size: Styles.menuBarIconSize,
                          color: Styles.textButtonColor,
                        ),
                    Text(widget.text,
                        style: TextStyle(color: Styles.textButtonColor))
                  ],
                ),
              );
            }

            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  stops: [0, v, 1],
                  colors: [
                    color,
                    v != 0 && v != 1 ? color.withValues(alpha: 0) : color,
                    color,
                  ],
                ),
              ),
              child: FittedBox(
                child: Row(
                  spacing: 10,
                  children: [
                    widget.decoration ??
                        Icon(
                          Icons.bolt,
                          size: Styles.menuBarIconSize,
                          color: Styles.textButtonColor,
                        ),
                    Text(widget.text,
                        style: TextStyle(color: Styles.textButtonColor))
                  ],
                ),
              ),
            );
          },
          duration: const Duration(seconds: 2),
          tween: Tween<double>(begin: 0.0, end: value),
        ),
      ),
    );
  }
}
