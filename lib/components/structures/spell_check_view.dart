import 'package:ai_text_editor/models/json_error_model.dart';
import 'package:ai_text_editor/notifiers/editor_notifier.dart';
import 'package:ai_text_editor/utils/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SpellCheckView extends ConsumerStatefulWidget {
  const SpellCheckView({super.key});

  @override
  ConsumerState<SpellCheckView> createState() => _SpellCheckViewState();
}

class _SpellCheckViewState extends ConsumerState<SpellCheckView> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  Widget _buildFadeOutItem(Widget child, Animation<double> animation) {
    return FadeTransition(
      opacity: animation, // 让 item 渐渐消失
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final errors = ref.watch(spellCheckErrorNotifierProvider);
    final state =
        ref.watch(editorNotifierProvider.select((v) => v.showSpellCheck));
    return AnimatedContainer(
      decoration: BoxDecoration(color: Colors.grey[100]),
      duration: Duration(milliseconds: 300),
      width: state ? Styles.structureWidth : 0,
      child: errors.isEmpty
          ? Center(
              child: Text("No error found"),
            )
          : AnimatedList(
              key: _listKey,
              padding: EdgeInsets.all(10),
              initialItemCount: errors.length,
              itemBuilder: (c, i, a) {
                return _ErrorWidget(
                  model: errors[i],
                  onEnter: () {
                    ref
                        .read(editorNotifierProvider.notifier)
                        .highlightText(errors[i].originalText!);
                  },
                  onExit: () {
                    ref.read(editorNotifierProvider.notifier).removeHighlight();
                  },
                  onTap: () {
                    ref
                        .read(editorNotifierProvider.notifier)
                        .replaceCertainText(
                            errors[i].originalText!, errors[i].suggestedFix!);

                    final removedItem = errors[i];

                    _listKey.currentState!.removeItem(
                      i,
                      (context, animation) => _buildFadeOutItem(
                          _ErrorWidget(
                              model: removedItem,
                              onTap: () {},
                              onEnter: () {},
                              onExit: () {}),
                          animation),
                      duration: Duration(milliseconds: 500), // 设置淡出时长
                    );

                    errors.removeAt(i);
                  },
                );
              }),
    );
  }
}

class _ErrorWidget extends StatefulWidget {
  const _ErrorWidget(
      {required this.model,
      required this.onTap,
      required this.onEnter,
      required this.onExit});
  final Errors model;
  final VoidCallback onTap;
  final VoidCallback onEnter;
  final VoidCallback onExit;
  @override
  State<_ErrorWidget> createState() => __ErrorWidgetState();
}

class __ErrorWidgetState extends State<_ErrorWidget> {
  bool isHover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (event) {
        setState(() {
          isHover = true;
        });
        widget.onEnter();
      },
      onExit: (event) {
        setState(() {
          isHover = false;
        });
        widget.onExit();
      },
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => widget.onTap(),
        child: Container(
          padding: EdgeInsets.all(10),
          margin: EdgeInsets.only(top: 5, bottom: 5),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: isHover ? Colors.blueAccent.withAlpha(128) : Colors.white),
          child: Column(
            spacing: 5,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(TextSpan(
                  text: "Type: ",
                  style: TextStyle(fontWeight: FontWeight.bold),
                  children: [TextSpan(text: widget.model.type)])),
              Text("${widget.model.originalText} ❌"),
              Text("${widget.model.suggestedFix} ✅"),
            ],
          ),
        ),
      ),
    );
  }
}
