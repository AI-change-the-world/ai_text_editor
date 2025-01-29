import 'package:ai_text_editor/notifiers/editor_notifier.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SomeShortcuts {
  SomeShortcuts._();

  static WidgetRef? ref;
  static setRef(WidgetRef r) {
    ref = r;
  }

  static final SpaceShortcutEvent aiShowUp = SpaceShortcutEvent(
    character: "ai>",
    handler: (node, controller) => handleAiShowUp(
      controller: controller,
      character: "ai>",
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

    return true;
  }
}
