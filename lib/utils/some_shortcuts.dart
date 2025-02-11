// ignore_for_file: depend_on_referenced_packages, use_build_context_synchronously

import 'dart:convert';

import 'package:ai_text_editor/components/select_or_input_file_url_dialog.dart';
import 'package:ai_text_editor/embeds/image/image_embed.dart';
import 'package:ai_text_editor/embeds/roll/roll_embed.dart';
import 'package:ai_text_editor/embeds/table/table_builder.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:ai_packages_core/ai_packages_core.dart';
import 'package:ai_text_editor/embeds/table/table_embed.dart';
import 'package:ai_text_editor/models/ai_model.dart';
import 'package:ai_text_editor/notifiers/editor_notifier.dart';
import 'package:ai_text_editor/utils/logger.dart';
import 'package:ai_text_editor/utils/toast_utils.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SomeShortcuts {
  SomeShortcuts._();

  static const String aiShowUpCharacter = "ai>";
  static const String instruct = "<";

  static WidgetRef? ref;
  static setRef(WidgetRef r) {
    ref = r;
  }

  static final SpaceShortcutEvent aiShowUp = SpaceShortcutEvent(
    character: aiShowUpCharacter,
    handler: (node, controller) => handleAiShowUp(
      controller: controller,
      character: aiShowUpCharacter,
    ),
  );

  static final CharacterShortcutEvent aiInstEvent = CharacterShortcutEvent(
    key: "ai instruct",
    character: instruct,
    handler: (controller) => handleInstruct(
      controller: controller,
      character: instruct,
    ),
  );

  static bool handleAiShowUp({
    required QuillController controller,
    required String character,
  }) {
    assert(character.trim().isNotEmpty && character != '\n',
        'Expected character that cannot be empty, a whitespace or a new line. Got $character');

    final selection = controller.selection;
    controller.updateSelection(
        controller.selection.copyWith(
            baseOffset: selection.baseOffset - character.length,
            extentOffset: selection.baseOffset - character.length),
        ChangeSource.local);
    // print(controller.selection.baseOffset);

    controller.replaceText(
        controller.selection.baseOffset, character.length, '', null);

    ref?.read(editorNotifierProvider.notifier).toggleAi();

    /// for test; remove later
    ///
    // GlobalModel.model.chat([
    //   ChatMessage(
    //       role: "user",
    //       content: "hello",
    //       createAt: DateTime.now().millisecondsSinceEpoch)
    // ]).then((v) {
    //   ref
    //       ?.read(editorNotifierProvider.notifier)
    //       .insertDataToEditor(v, controller.selection);
    // });
    // GlobalModel.model.streamChat([
    //   ChatMessage(
    //       role: "user",
    //       content: "hello",
    //       createAt: DateTime.now().millisecondsSinceEpoch)
    // ]).listen((v) {
    //   ref
    //       ?.read(editorNotifierProvider.notifier)
    //       .insertDataToEditor(v, controller.selection);
    // });

    return true;
  }

  static final RegExp instReg = RegExp(r'^<inst>');
  static final RegExp tableReg = RegExp(r'^<table>');
  static final RegExp rollReg = RegExp(r'^<roll>');
  static final RegExp imageReg = RegExp(r'^<image>');

  // ignore: unintended_html_in_doc_comment
  /// ai instruct:  <inst>something<
  static bool handleInstruct(
      {required QuillController controller, required String character}) {
    final selection = controller.selection;
    if (!selection.isCollapsed || selection.end < 5) {
      return false;
    }

    final plainText = controller.document.toPlainText();

    if (plainText.isEmpty) {
      return false;
    }

    var lastCharIndex = -1;
    for (var i = selection.end - 1; i >= 0; i--) {
      if (plainText[i] == '\n' && lastCharIndex == -1) return false;

      if (plainText[i] == character) {
        lastCharIndex = i;
        break;
      }
    }
    if (lastCharIndex == -1) return false;

    var subString = plainText.substring(lastCharIndex, selection.end);
    logger.d("instruction: $subString");

    /// TODO: will be other instructions
    ///
    /// handle ai instruction
    if (instReg.hasMatch(subString)) {
      if (GlobalModel.model == null) {
        ToastUtils.error(null, title: "Model not set");
        return false;
      }

      ref?.read(editorNotifierProvider.notifier).setLoading(true);
      ref
          ?.read(editorNotifierProvider.notifier)
          .insertDataToEditor("</inst>", controller.selection);

      String generated = "";
      Future.delayed(Duration(milliseconds: 300)).then((_) {
        controller.document
            .replace(lastCharIndex, subString.length + "</inst>".length, "");
        controller.updateSelection(
            controller.selection.copyWith(
                baseOffset: lastCharIndex + 1, extentOffset: lastCharIndex + 1),
            ChangeSource.local);

        GlobalModel.model!.streamChat([
          ChatMessage(
              role: "user",
              content: subString.replaceAll("<inst>", ""),
              createAt: DateTime.now().millisecondsSinceEpoch)
        ]).listen(
          (v) {
            generated += v;
            ref
                ?.read(editorNotifierProvider.notifier)
                .insertDataToEditor(v, controller.selection);
          },
          onError: (e) {
            ToastUtils.error(null, title: "Error", description: e.toString());
            ref?.read(editorNotifierProvider.notifier).setLoading(false);
          },
          onDone: () {
            ToastUtils.info(null,
                title: "${generated.length} characters generated",
                descryption: "replacing markdown to normal text");

            ref
                ?.read(editorNotifierProvider.notifier)
                .addHistory(subString.replaceAll("<inst>", ""), generated);

            Future.delayed(Duration(milliseconds: 300)).then((_) {
              ref?.read(editorNotifierProvider.notifier).convertMarkdownToQuill(
                    generated,
                  );
            });
          },
        );
      });

      return true;
    } else if (tableReg.hasMatch(subString)) {
      ref?.read(editorNotifierProvider.notifier).insertDataToEditor(
          "/table>", controller.selection,
          updateSelection: false);

      Future.delayed(Duration(milliseconds: 300)).then((_) async {
        controller.document
            .replace(lastCharIndex, subString.length + "</table>".length, "");
        controller.updateSelection(
            controller.selection.copyWith(
                baseOffset: lastCharIndex + 1, extentOffset: lastCharIndex + 1),
            ChangeSource.local);
        final s = subString.replaceAll("<table>", "");
        List list = s.split(",");
        if (s == "") {
          await showGeneralDialog(
              barrierColor: Colors.white,
              context: ref!.context,
              pageBuilder: (c, _, __) {
                return AnimatedDialog(
                  rowCount: 1,
                  colCount: 1,
                  values: [""],
                  height: 200,
                  top: MediaQuery.of(ref!.context).size.width,
                );
              }).then((v) {
            if (v == null) {
              return false;
            }
            // print(v);
            (v as Map)['uuid'] = Uuid().v4();
            final block = CustomTableEmbed(customTableEmbedType, jsonEncode(v));

            controller.replaceText(
                controller.selection.baseOffset, 0, block, null);

            ref?.read(editorNotifierProvider.notifier).insertDataToEditor(
                  "\n",
                  controller.selection.copyWith(
                      baseOffset: controller.selection.baseOffset + 1,
                      extentOffset: controller.selection.baseOffset + 1),
                );
            return true;
          });
        } else {
          if (list.length != 2) {
            return false;
          }
          if (int.tryParse(list[0]) == null || int.tryParse(list[1]) == null) {
            return false;
          }

          if (int.parse(list[0]) < 1 || int.parse(list[1]) < 1) {
            return false;
          }

          var rowCount = int.parse(list[0]);
          var colCount = int.parse(list[1]);

          var m = {
            "uuid": Uuid().v4(),
            "rowCount": rowCount,
            "colCount": colCount,
            "values": List<String>.generate(rowCount * colCount, (index) => "")
          };

          final block = CustomTableEmbed(customTableEmbedType, jsonEncode(m));

          controller.replaceText(
              controller.selection.baseOffset, 0, block, null);

          ref?.read(editorNotifierProvider.notifier).insertDataToEditor(
                "\n",
                controller.selection.copyWith(
                    baseOffset: controller.selection.baseOffset + 1,
                    extentOffset: controller.selection.baseOffset + 1),
              );
          return true;
        }
      });
    } else if (rollReg.hasMatch(subString)) {
      final block = CustomRollEmbed(customRollEmbedType, "");
      controller.document.replace(lastCharIndex, subString.length, "");
      controller.updateSelection(
          controller.selection.copyWith(
              baseOffset: lastCharIndex + 1, extentOffset: lastCharIndex + 1),
          ChangeSource.local);
      controller.replaceText(controller.selection.baseOffset, 0, block, null);
      controller.updateSelection(
          controller.selection.copyWith(
              baseOffset: controller.selection.baseOffset + 1,
              extentOffset: controller.selection.baseOffset + 1),
          ChangeSource.local);
      return true;
    } else if (imageReg.hasMatch(subString)) {
      ref?.read(editorNotifierProvider.notifier).insertDataToEditor(
          "/image>", controller.selection,
          updateSelection: false);

      Future.delayed(Duration(milliseconds: 300)).then((_) {
        controller.document
            .replace(lastCharIndex, subString.length + "</image>".length, "");
        controller.updateSelection(
            controller.selection.copyWith(
                baseOffset: lastCharIndex + 1, extentOffset: lastCharIndex + 1),
            ChangeSource.local);
        showGeneralDialog(
            barrierColor: Colors.transparent,
            context: ref!.context,
            pageBuilder: (c, _, __) {
              return Center(
                child: SelectOrInputFileUrlDialog(),
              );
            }).then((v) {
          if (v == null) {
            return false;
          }
          (v as Map)['uuid'] = Uuid().v4();
          final block = CustomImageEmbed(customImageEmbedType, jsonEncode(v));
          controller.replaceText(
              controller.selection.baseOffset, 0, block, null);

          ref?.read(editorNotifierProvider.notifier).insertDataToEditor(
                "\n",
                controller.selection.copyWith(
                    baseOffset: controller.selection.baseOffset + 1,
                    extentOffset: controller.selection.baseOffset + 1),
              );
          return true;
        });
      });
    }

    return false;
  }
}
