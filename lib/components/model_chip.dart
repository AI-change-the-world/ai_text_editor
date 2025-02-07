import 'package:ai_text_editor/isar/model.dart';
import 'package:ai_text_editor/notifiers/models_notifier.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'add_model_dialog.dart';

class ModelChip extends ConsumerStatefulWidget {
  const ModelChip({super.key, required this.model});
  final Model model;

  @override
  ConsumerState<ModelChip> createState() => _ModelChipState();
}

class _ModelChipState extends ConsumerState<ModelChip> {
  bool isHovering = false;
  double animationValue = 0.0;
  @override
  Widget build(BuildContext context) {
    bool isSelected =
        ref.watch(modelsProvider.select((v) => v.current == widget.model.tag));
    Color color = !isSelected
        ? Colors.blueAccent.withAlpha(128)
        : Colors.greenAccent.withAlpha(128);
    return GestureDetector(
        onTap: () {
          setState(() {
            animationValue = animationValue == 0.0 ? 1.0 : 0.0;
          });
        },
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (event) {
            setState(() {
              isHovering = true;
            });
          },
          onExit: (event) {
            setState(() {
              isHovering = false;
            });
          },
          child: Material(
            borderRadius: BorderRadius.circular(10),
            elevation: isHovering ? 10 : 0,
            child: TweenAnimationBuilder<double>(
              onEnd: () {
                ref
                    .read(modelsProvider.notifier)
                    .addChangeHistory(widget.model);
              },
              duration: const Duration(seconds: 2),
              tween: Tween<double>(begin: 0.0, end: animationValue),
              builder: (ctx, value, c) {
                return Container(
                  padding: EdgeInsets.all(4),
                  width: 200,
                  height: 40,
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: isHovering ? Colors.blueAccent : Colors.grey),
                    borderRadius: BorderRadius.circular(10),
                    // color: isHovering
                    //     ? Colors.blueAccent.withAlpha(128)
                    //     : Colors.white
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      stops: [0, value, 1],
                      colors: [
                        color,
                        value != 0 && value != 1
                            ? color.withValues(alpha: 0)
                            : color,
                        color,
                      ],
                    ),
                  ),
                  child: Row(
                    spacing: 5,
                    children: [
                      Expanded(
                          child: AutoSizeText(
                        widget.model.modelName ?? "Default",
                        maxLines: 1,
                      )),
                      if (isHovering)
                        InkWell(
                          onTap: () {},
                          child: Icon(
                            Icons.edit,
                            size: 16,
                            color: Colors.amberAccent,
                          ),
                        ),
                      if (isHovering)
                        InkWell(
                          onTap: () {
                            ref
                                .read(modelsProvider.notifier)
                                .deleteModel(widget.model);
                          },
                          child: Icon(
                            Icons.delete,
                            size: 16,
                            color: Colors.redAccent,
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ));
  }
}

class AddModelButton extends ConsumerStatefulWidget {
  const AddModelButton({super.key});

  @override
  ConsumerState<AddModelButton> createState() => _AddModelButtonState();
}

class _AddModelButtonState extends ConsumerState<AddModelButton> {
  bool isHovering = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        showGeneralDialog(
            barrierColor: Colors.white.withValues(alpha: 0.5),
            context: context,
            pageBuilder: (c, _, __) {
              return Center(
                child: AddModelDialog(),
              );
            }).then((v) {
          if (v == null) {
            return;
          }
          ref.read(modelsProvider.notifier).addModel(v as Model);
        });
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (event) {
          setState(() {
            isHovering = true;
          });
        },
        onExit: (event) {
          setState(() {
            isHovering = false;
          });
        },
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
              border: Border.all(
                  color: isHovering ? Colors.blueAccent : Colors.grey),
              borderRadius: BorderRadius.circular(10),
              color: isHovering
                  ? Colors.blueAccent.withAlpha(128)
                  : const Color.fromARGB(255, 201, 201, 201)),
          child: Icon(
            Icons.add,
            size: 30,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
