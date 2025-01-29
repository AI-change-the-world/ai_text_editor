import 'package:ai_text_editor/notifiers/editor_notifier.dart';
import 'package:ai_text_editor/utils/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AiWidget extends ConsumerWidget {
  const AiWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(editorNotifierProvider.select((v) => v.showAI));
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      width: state ? Styles.structureWidth : 0,
      child: SingleChildScrollView(),
    );
  }
}
