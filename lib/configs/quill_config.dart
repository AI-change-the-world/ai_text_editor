import 'package:ai_text_editor/embeds/formular/formular_builder.dart';
import 'package:ai_text_editor/embeds/image/image_builder.dart';
import 'package:ai_text_editor/embeds/ref/ref_builder.dart';
import 'package:ai_text_editor/embeds/roll/roll_embed.dart';

import 'package:ai_text_editor/embeds/table/table_builder.dart';
import 'package:ai_text_editor/features/editor/embeds/link/link_builder.dart';
import 'package:ai_text_editor/utils/some_shortcuts.dart';
import 'package:flutter_quill/flutter_quill.dart';

class QuillConfig {
  QuillConfig._();

  static QuillEditorConfig get config => QuillEditorConfig(
          characterShortcutEvents: [
            ...standardCharactersShortcutEvents,
            SomeShortcuts.aiInstEvent,
            SomeShortcuts.slashCommandEvent,
          ],
          spaceShortcutEvents: [
            ...standardSpaceShorcutEvents,
            SomeShortcuts.aiShowUp
          ],
          embedBuilders: [
            CustomTableEmbedBuilder(),
            CustomRollEmbedBuilder(),
            CustomImageEmbedBuilder(),
            CustomRefEmbedBuilder(),
            CustomFormularEmbedBuilder(),
            CustomLinkEmbedBuilder(),
          ],
          searchConfig: const QuillSearchConfig(
            searchEmbedMode: SearchEmbedMode.plainText,
          ),
          placeholder: "Write something...");
}
