import 'package:ai_text_editor/notifiers/editor_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PositionWidget extends ConsumerWidget {
  const PositionWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = ref.watch(currentPositionProvider);

    if (d == 0) {
      return SizedBox();
    }
    return Material(
      borderRadius: BorderRadius.circular(4),
      elevation: 4,
      child: Container(
        padding: EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: Text(
            "${(d * 100).toStringAsFixed(2)}%",
            style: TextStyle(fontSize: 10),
          ),
        ),
      ),
    );
  }
}
