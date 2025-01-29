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
  bool dragging = false;

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    final toolbarPosition =
        ref.watch(editorNotifierProvider.select((v) => v.toolbarPosition));
    var padding = EdgeInsets.only(
        left: toolbarPosition == ToolbarPosition.left ? 90 : 10,
        right: toolbarPosition == ToolbarPosition.right ? 90 : 10,
        top: toolbarPosition == ToolbarPosition.top ? 90 : 10,
        bottom: toolbarPosition == ToolbarPosition.bottom ? 90 : 10);
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SizedBox.expand(),
          Padding(
            padding: padding,
            child: QuillEditor(
              configurations:
                  QuillEditorConfigurations(placeholder: "Write something..."),
              controller:
                  ref.read(editorNotifierProvider.notifier).quillController,
              focusNode: ref.read(editorNotifierProvider.notifier).focusNode,
              scrollController:
                  ref.read(editorNotifierProvider.notifier).scrollController,
            ),
          ),
          PositionedToolbarWidget(
            onDragEnd: () {
              setState(() {
                dragging = false;
              });
            },
            onDragStart: () {
              setState(() {
                dragging = true;
              });
            },
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
                ref
                    .read(editorNotifierProvider.notifier)
                    .changeToolbarPosition(ToolbarPosition.left);
                return true;
              }, builder: (c, _, __) {
                if (dragging && toolbarPosition == ToolbarPosition.left) {
                  return ToolbarWidget(
                      position: toolbarPosition,
                      controller: ref
                          .read(editorNotifierProvider.notifier)
                          .quillController,
                      onDragEnd: () {},
                      onDragStart: () {});
                }

                return Container(
                  width: 10,
                  height: height,
                  color: containerColor,
                );
              })),
          Positioned(
              right: 0,
              child: DragTarget<String>(onLeave: (data) {
                ref
                    .read(editorNotifierProvider.notifier)
                    .changeToolbarPosition(ToolbarPosition.none);
              }, onAcceptWithDetails: (details) {
                setState(() {
                  dragging = false;
                });
              }, onWillAcceptWithDetails: (details) {
                ref
                    .read(editorNotifierProvider.notifier)
                    .changeToolbarPosition(ToolbarPosition.right);
                return true;
              }, builder: (c, _, __) {
                if (dragging && toolbarPosition == ToolbarPosition.right) {
                  return ToolbarWidget(
                      position: toolbarPosition,
                      controller: ref
                          .read(editorNotifierProvider.notifier)
                          .quillController,
                      onDragEnd: () {},
                      onDragStart: () {});
                }

                return Container(
                  width: 10,
                  height: height,
                  color: containerColor,
                );
              })),
          Positioned(
              top: 0,
              child: DragTarget<String>(onLeave: (data) {
                ref
                    .read(editorNotifierProvider.notifier)
                    .changeToolbarPosition(ToolbarPosition.none);
              }, onWillAcceptWithDetails: (details) {
                ref
                    .read(editorNotifierProvider.notifier)
                    .changeToolbarPosition(ToolbarPosition.top);
                return true;
              }, builder: (c, _, __) {
                if (dragging && toolbarPosition == ToolbarPosition.top) {
                  return ToolbarWidget(
                      position: toolbarPosition,
                      controller: ref
                          .read(editorNotifierProvider.notifier)
                          .quillController,
                      onDragEnd: () {},
                      onDragStart: () {});
                }

                return Container(
                  width: width,
                  height: 10,
                  color: containerColor,
                );
              })),
          Positioned(
              bottom: 0,
              child: DragTarget<String>(onLeave: (data) {
                ref
                    .read(editorNotifierProvider.notifier)
                    .changeToolbarPosition(ToolbarPosition.none);
              }, onWillAcceptWithDetails: (details) {
                ref
                    .read(editorNotifierProvider.notifier)
                    .changeToolbarPosition(ToolbarPosition.bottom);
                return true;
              }, builder: (c, _, __) {
                if (dragging && toolbarPosition == ToolbarPosition.bottom) {
                  return ToolbarWidget(
                      position: toolbarPosition,
                      controller: ref
                          .read(editorNotifierProvider.notifier)
                          .quillController,
                      onDragEnd: () {},
                      onDragStart: () {});
                }

                return Container(
                  width: width,
                  height: 10,
                  color: containerColor,
                );
              })),
        ],
      ),
    );
  }
}

class ToolbarWidget extends StatelessWidget {
  const ToolbarWidget(
      {super.key,
      required this.position,
      required this.controller,
      required this.onDragEnd,
      required this.onDragStart});
  final ToolbarPosition position;
  final QuillController controller;
  final VoidCallback onDragEnd;
  final VoidCallback onDragStart;

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
          configurations: QuillToolbarConfig.simple(
            alignment: WrapAlignment.start,
            crossAlignment: WrapCrossAlignment.start,
          ),
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
      onDragEnd: (details) {
        onDragEnd();
      },
      onDragStarted: () {
        onDragStart();
      },
      data: "drag",
      feedback: child,
      childWhenDragging: Container(
        width: 1,
        height: 1,
        color: Colors.transparent,
      ),
      child: child,
    );

    return child;
  }
}

class PositionedToolbarWidget extends ConsumerWidget {
  const PositionedToolbarWidget(
      {super.key,
      required this.position,
      required this.controller,
      required this.onDragEnd,
      required this.onDragStart});

  final ToolbarPosition position;
  final QuillController controller;
  final VoidCallback onDragEnd;
  final VoidCallback onDragStart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var child = ToolbarWidget(
      controller: controller,
      position: position,
      onDragEnd: onDragEnd,
      onDragStart: onDragStart,
    );
    if (position == ToolbarPosition.left) {
      return Positioned(
          height: ref
              .read(editorNotifierProvider.notifier)
              .getCurrentHeight(context),
          left: 0,
          child: Center(
            child: child,
          ));
    } else if (position == ToolbarPosition.right) {
      return Positioned(
        right: 0,
        height:
            ref.read(editorNotifierProvider.notifier).getCurrentHeight(context),
        child: Center(
          child: child,
        ),
      );
    } else if (position == ToolbarPosition.top) {
      return Positioned(
          width: ref
              .read(editorNotifierProvider.notifier)
              .getCurrentWidth(context),
          top: 0,
          child: Center(
            child: child,
          ));
    } else {
      return Positioned(
        bottom: 0,
        width:
            ref.read(editorNotifierProvider.notifier).getCurrentWidth(context),
        child: Center(
          child: child,
        ),
      );
    }
  }
}
