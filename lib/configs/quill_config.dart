import 'package:ai_text_editor/embeds/image/image_builder.dart';
import 'package:ai_text_editor/embeds/roll/roll_builder.dart';
import 'package:ai_text_editor/embeds/table/table_builder.dart';
import 'package:ai_text_editor/utils/some_shortcuts.dart';
import 'package:flutter_quill/flutter_quill.dart';

class QuillConfig {
  QuillConfig._();

  static QuillEditorConfigurations get config => QuillEditorConfigurations(
          characterShortcutEvents: [
            ...standardCharactersShortcutEvents,
            SomeShortcuts.aiInstEvent
          ],
          spaceShortcutEvents: [
            ...standardSpaceShorcutEvents,
            SomeShortcuts.aiShowUp
          ],
          embedBuilders: [
            CustomTableEmbedBuilder(),
            CustomRollEmbedBuilder(),
            CustomImageEmbedBuilder(),
          ],
          searchConfigurations: const QuillSearchConfigurations(
            searchEmbedMode: SearchEmbedMode.plainText,
          ),
          placeholder: "Write something...");
}
