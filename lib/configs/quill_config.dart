import 'package:ai_text_editor/utils/some_shortcuts.dart';
import 'package:flutter_quill/flutter_quill.dart';

class QuillConfig {
  QuillConfig._();

  static QuillEditorConfigurations get config => QuillEditorConfigurations(
      characterShortcutEvents: standardCharactersShortcutEvents,
      spaceShortcutEvents: [
        ...standardSpaceShorcutEvents,
        SomeShortcuts.aiShowUp
      ],
      searchConfigurations: const QuillSearchConfigurations(
        searchEmbedMode: SearchEmbedMode.plainText,
      ),
      placeholder: "Write something...");
}
