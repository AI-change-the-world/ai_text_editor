import 'package:flutter/material.dart';

class FadedText extends StatefulWidget {
  const FadedText({super.key, this.text = "unsaved"});
  final String text;

  @override
  State<FadedText> createState() => _FadedTextState();
}

class _FadedTextState extends State<FadedText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _animation = Tween(begin: 0.0, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: FadeTransition(
        opacity: _animation,
        child: SizedBox(
          width: 80,
          height: 25,
          child: Center(
            child: Text(widget.text),
          ),
        ),
      ),
    );
  }
}
