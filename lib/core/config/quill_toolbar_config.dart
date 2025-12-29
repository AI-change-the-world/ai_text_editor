import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

class QuillToolbarConfig {
  QuillToolbarConfig._();

  static QuillSimpleToolbarConfig simple({
    WrapAlignment? alignment,
    WrapCrossAlignment? crossAlignment,
  }) {
    return QuillSimpleToolbarConfig(
      toolbarIconAlignment: alignment ?? WrapAlignment.center,
      toolbarIconCrossAlignment: crossAlignment ?? WrapCrossAlignment.center,
      showFontSize: false,
      showFontFamily: false,
      showSearchButton: false,
      showClipboardPaste: false,
      showClipboardCopy: false,
      showClipboardCut: false,
      showBackgroundColorButton: false,
    );
  }
}
