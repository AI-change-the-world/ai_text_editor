import 'package:ai_text_editor/components/dialogs/confirm_dialog.dart';
import 'package:ai_text_editor/components/others/animated_text.dart';
import 'package:ai_text_editor/data/datasources/objectbox/entities/model_profile.dart';
import 'package:ai_text_editor/features/settings/widgets/ai_model_settings.dart';
import 'package:ai_text_editor/init.dart';
import 'package:ai_text_editor/notifiers/app_body_notifier.dart';
import 'package:ai_text_editor/notifiers/editor_notifier.dart';
import 'package:ai_text_editor/notifiers/models_notifier.dart';
import 'package:ai_text_editor/utils/logger.dart';
import 'package:ai_text_editor/utils/styles.dart';
import 'package:ai_text_editor/utils/toast_utils.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

const XTypeGroup typeGroup = XTypeGroup(
  label: 'files',
  extensions: APPConfig.supportFormats,
);

class AppBody extends ConsumerStatefulWidget {
  const AppBody({super.key});

  @override
  ConsumerState<AppBody> createState() => _AppBodyState();
}

class _AppBodyState extends ConsumerState<AppBody> {
  static List<String> items = ["title", "uuid"];
  String selectedItem = items.first;

  @override
  Widget build(BuildContext context) {
    final recentDocs = ref.watch(recentDocumentsProvider);
    final models = ref.watch(modelsProvider);
    logger.d(
        "find docs: ${recentDocs.length}, current model ${models.currentTag}");

    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 20,
        children: [
          Text.rich(TextSpan(
              text: "Welcome to ${APPConfig.appName}\n",
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              children: [
                TextSpan(
                    text: "Enjoy writing with AI",
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.normal))
              ])),
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 10,
              children: [
                Text(
                  "Start",
                  style: TextStyle(fontSize: 24),
                ),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () {
                      context.go('/editor');
                    },
                    child: Row(
                      spacing: 10,
                      children: [
                        Icon(
                          Icons.file_present,
                          size: Styles.menuBarIconSize,
                          color: Styles.textButtonColor,
                        ),
                        Text(
                          "New file ...",
                          style: TextStyle(color: Styles.textButtonColor),
                        )
                      ],
                    ),
                  ),
                ),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () {
                      // TODO: Show recent documents dialog
                      if (recentDocs.isNotEmpty) {
                        final doc = recentDocs.first;
                        ref
                            .read(editorNotifierProvider.notifier)
                            .loadFromObjectBox(doc.uuid)
                            .then((_) {
                          context.go('/editor');
                        }).catchError((e) {
                          ToastUtils.error(context,
                              title: "Failed to load: $e");
                        });
                      }
                    },
                    child: Row(
                      spacing: 10,
                      children: [
                        Icon(
                          Icons.file_open,
                          size: Styles.menuBarIconSize,
                          color: Styles.textButtonColor,
                        ),
                        Text(
                          "Open recent ...",
                          style: TextStyle(color: Styles.textButtonColor),
                        )
                      ],
                    ),
                  ),
                ),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () {
                      showGeneralDialog(
                          barrierColor: Colors.white.withValues(alpha: 0.1),
                          barrierDismissible: true,
                          barrierLabel: "confirm dialog",
                          context: context,
                          pageBuilder: (c, _, __) {
                            return Center(
                              child: ConfirmDialog(
                                  content:
                                      "⚠️ This feature is not stable, may cause some problems. Currently support file types: \n${APPConfig.supportFormats.join(", ")}."),
                            );
                          }).then((v) {
                        if (v == true) {
                          openFile(acceptedTypeGroups: [typeGroup])
                              .then((f) async {
                            if (f != null) {
                              // TODO: Import file to workspace
                            }
                          });
                        }
                      });
                    },
                    child: Row(
                      spacing: 10,
                      children: [
                        Icon(
                          Icons.import_export,
                          size: Styles.menuBarIconSize,
                          color: Styles.textButtonColor,
                        ),
                        Text(
                          "Import file ... (experimental)",
                          style: TextStyle(color: Styles.textButtonColor),
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 10,
              children: [
                Row(
                  children: [
                    Text(
                      "Recent Documents",
                      style: TextStyle(fontSize: 24),
                    ),
                    SizedBox(width: 20),
                    SizedBox(
                      width: 125,
                      height: 30,
                      child: DropdownButtonFormField2<String>(
                        isExpanded: true,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.all(0),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        customButton: SizedBox(
                          width: 100,
                          height: 30,
                          child: Center(
                            child: Row(
                              spacing: 5,
                              children: [
                                SizedBox(width: 5),
                                Text(selectedItem),
                                Spacer(),
                                Icon(
                                  Icons.arrow_drop_down,
                                  color: Colors.black45,
                                )
                              ],
                            ),
                          ),
                        ),
                        value: selectedItem,
                        items: items
                            .map((item) => DropdownMenuItem<String>(
                                  value: item,
                                  child: Text(
                                    item,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value == null || value == selectedItem) {
                            return;
                          }
                          setState(() {
                            selectedItem = value.toString();
                          });
                        },
                        buttonStyleData: const ButtonStyleData(
                          padding: EdgeInsets.only(right: 8),
                        ),
                        iconStyleData: const IconStyleData(
                          icon: Icon(
                            Icons.arrow_drop_down,
                            color: Colors.black45,
                          ),
                          iconSize: 16,
                        ),
                        dropdownStyleData: DropdownStyleData(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        menuItemStyleData: const MenuItemStyleData(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                        ),
                      ),
                    )
                  ],
                ),
                Expanded(
                  child: ListView.builder(
                    itemBuilder: (c, i) {
                      final doc = recentDocs[i];
                      return MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () {
                            ref
                                .read(editorNotifierProvider.notifier)
                                .loadFromObjectBox(doc.uuid)
                                .then((_) {
                              context.go('/editor');
                            }).catchError((e) {
                              ToastUtils.error(context,
                                  title: "Failed to load document");
                              logger.e("Failed to load document: $e");
                            });
                          },
                          child: Container(
                            margin: EdgeInsets.only(top: 5, bottom: 5),
                            child: Row(
                              spacing: 10,
                              children: [
                                Icon(
                                  Icons.description,
                                  size: Styles.menuBarIconSize,
                                  color: Styles.textButtonColor,
                                ),
                                Expanded(
                                  child: Text(
                                    selectedItem == "title"
                                        ? doc.title
                                        : doc.uuid,
                                    maxLines: 1,
                                    softWrap: true,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        color: Styles.textButtonColor),
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    itemCount: recentDocs.length,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 10,
              children: [
                Row(
                  spacing: 10,
                  children: [
                    Text(
                      "Models",
                      style: TextStyle(fontSize: 24),
                    ),
                    InkWell(
                      onTap: () async {
                        final result = await showDialog<bool>(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => const ModelProfileDialog(),
                        );
                        if (result == true) {
                          ref.read(modelsProvider.notifier).refresh();
                        }
                      },
                      child: Icon(
                        Icons.add_box,
                        color: Colors.green,
                      ),
                    )
                  ],
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 10,
                      children: [
                        ...models.models
                            .where((m) => m.taskType == AITask.chat)
                            .map((e) => AnimatedText(
                                  text: (e.name.isNotEmpty
                                          ? e.name
                                          : e.modelName) +
                                      (models.currentTag == e.tag
                                          ? " (in use)"
                                          : ""),
                                  onTap: () {
                                    if (models.currentTag != e.tag) {
                                      ref
                                          .read(modelsProvider.notifier)
                                          .setCurrentModel(e);
                                    }
                                  },
                                ))
                      ],
                    ),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
