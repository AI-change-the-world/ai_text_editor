import 'package:ai_text_editor/utils/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppBody extends ConsumerWidget {
  const AppBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Row(
        spacing: 20,
        children: [
          Expanded(
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
                  onTap: () {},
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
                  onTap: () {},
                  child: Row(
                    spacing: 10,
                    children: [
                      Icon(
                        Icons.file_open,
                        size: Styles.menuBarIconSize,
                        color: Styles.textButtonColor,
                      ),
                      Text(
                        "Open file ...",
                        style: TextStyle(color: Styles.textButtonColor),
                      )
                    ],
                  ),
                ),
              ),
            ],
          )),
          Expanded(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 10,
            children: [
              Text(
                "Recent",
                style: TextStyle(fontSize: 24),
              ),
            ],
          ))
        ],
      ),
    );
  }
}
