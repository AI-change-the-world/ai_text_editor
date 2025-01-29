import 'package:ai_text_editor/editor_notifier.dart';
import 'package:ai_text_editor/editor_state.dart';
import 'package:ai_text_editor/logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'quill_toolbar_config.dart';

class Editor extends ConsumerStatefulWidget {
  const Editor({super.key});

  @override
  ConsumerState<Editor> createState() => _EditorState();
}

class _EditorState extends ConsumerState<Editor> {
  // final FocusNode focusNode = FocusNode();
  late Color containerColor = Colors.transparent;

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    final toolbarPosition =
        ref.watch(editorNotifierProvider.select((v) => v.toolbarPosition));
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SizedBox.expand(),
          QuillEditor(
            configurations:
                QuillEditorConfigurations(placeholder: "Write something..."),
            controller:
                ref.read(editorNotifierProvider.notifier).quillController,
            focusNode: ref.read(editorNotifierProvider.notifier).focusNode,
            scrollController:
                ref.read(editorNotifierProvider.notifier).scrollController,
          ),
          ToolbarWidget(
            controller:
                ref.read(editorNotifierProvider.notifier).quillController,
            position: toolbarPosition,
          ),
          Positioned(
              left: 0,
              child: DragTarget<String>(onLeave: (data) {
                ref
                    .read(editorNotifierProvider.notifier)
                    .changeToolbarPosition(ToolbarPosition.none);
              }, onWillAcceptWithDetails: (details) {
                print("accepted");
                ref
                    .read(editorNotifierProvider.notifier)
                    .changeToolbarPosition(ToolbarPosition.left);
                return true;
              }, builder: (c, _, __) {
                return Container(
                  width: 10,
                  height: height,
                  color: containerColor,
                );
              })),
          Positioned(
              right: 0,
              child: Container(
                width: 10,
                height: height,
                color: containerColor,
              )),
          Positioned(
              top: 0,
              child: Container(
                width: width,
                height: 10,
                color: containerColor,
              )),
          Positioned(
              bottom: 0,
              child: Container(
                width: width,
                height: 10,
                color: containerColor,
              )),
        ],
      ),
    );
  }
}

class ToolbarWidget extends StatelessWidget {
  const ToolbarWidget(
      {super.key, required this.position, required this.controller});
  final ToolbarPosition position;
  final QuillController controller;
  static Size size1 = Size(90, 500);
  static Size size2 = Size(500, 90);

  @override
  Widget build(BuildContext context) {
    logger.d("position: $position");
    Widget child;
    if (position == ToolbarPosition.left || position == ToolbarPosition.right) {
      child = SizedBox.fromSize(
        size: size1,
        child: QuillSimpleToolbar(
          controller: controller,
          configurations: QuillToolbarConfig.simple(),
        ),
      );
    } else if (position == ToolbarPosition.top ||
        position == ToolbarPosition.bottom) {
      child = SizedBox.fromSize(
        size: size2,
        child: QuillSimpleToolbar(
          controller: controller,
          configurations: QuillToolbarConfig.simple(),
        ),
      );
    } else {
      child = Container();
    }

    child = Draggable(
      data: "drag",
      feedback: child,
      childWhenDragging: Container(
        width: 1,
        height: 1,
        color: Colors.transparent,
      ),
      child: child,
    );

    if (position == ToolbarPosition.left) {
      return Positioned(left: 0, child: child);
    } else if (position == ToolbarPosition.right) {
      return Positioned(right: 0, child: child);
    } else if (position == ToolbarPosition.top) {
      return Positioned(top: 0, child: child);
    } else {
      return Positioned(bottom: 0, child: child);
    }
  }
}
