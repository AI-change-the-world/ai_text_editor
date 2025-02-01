import 'package:ai_packages_core/ai_packages_core.dart';
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

        GlobalModel.model.streamChat([
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
    }

    return false;
  }
}
