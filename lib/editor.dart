import 'package:ai_text_editor/notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Editor extends ConsumerStatefulWidget {
  const Editor({super.key});

  @override
  ConsumerState<Editor> createState() => _EditorState();
}

class _EditorState extends ConsumerState<Editor> {
  // final FocusNode focusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          QuillSimpleToolbar(
            controller:
                ref.read(editorNotifierProvider.notifier).quillController,
            configurations: const QuillSimpleToolbarConfigurations(),
          ),
          Expanded(
              child: QuillEditor(
            configurations:
                QuillEditorConfigurations(placeholder: "Write something..."),
            controller:
                ref.read(editorNotifierProvider.notifier).quillController,
            focusNode: ref.read(editorNotifierProvider.notifier).focusNode,
            scrollController:
                ref.read(editorNotifierProvider.notifier).scrollController,
          ))
        ],
      ),
    );
  }
}
