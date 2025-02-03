// ignore_for_file: public_member_api_docs, sort_constructors_first, depend_on_referenced_packages
import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;

//create just an instance and void duplicate instance
final FontsLoader _instance = FontsLoader._();

///A simple class that charge all fonts available in this example
class FontsLoader {
  late final List<pw.Font> _pdffonts; // save valid pdf type fonts
  late final EmojisFonts emojiFont;
  late final SpecialUnicodeFonts unicodeFont;

  bool _configured = false;

  FontsLoader._() {
    unicodeFont = SpecialUnicodeFonts();
    emojiFont = EmojisFonts();
    _pdffonts = <pw.Font>[];
  }

  factory FontsLoader() {
    return _instance;
  }

  List<pw.Font> allFonts() {
    if (_configured) {
      return _pdffonts;
    }
    throw notConfiguredFonts();
  }

  pw.Font normalFont() {
    if (_configured) {
      return _pdffonts[1];
    }
    throw notConfiguredFonts();
  }

  pw.Font boldFont() {
    if (_configured) return _pdffonts[0];
    throw notConfiguredFonts();
  }

  Exception notConfiguredFonts() {
    return Exception('The fonts must be initalized before of take it');
  }

  Future<void> loadFonts() async {
    //times
    _pdffonts.add(pw.Font.ttf(
        await rootBundle.load("assets/fonts/SourceHanSansCN-Bold.ttf")));
    _pdffonts.add(pw.Font.ttf(
        await rootBundle.load("assets/fonts/SourceHanSansCN-Regular.ttf")));
    _configured = true;
  }
}

/// TODO
class EmojisFonts {
  late final pw.Font emojisFonts;
  late final String keyFont;
  EmojisFonts() {
    init();
  }
  void init() async {
    keyFont = "NotoEmojis";
    emojisFonts = pw.Font.ttf(
        await rootBundle.load("assets/fonts/NotoEmoji-VariableFont_wght.ttf"));
  }
}

class SpecialUnicodeFonts {
  late final pw.Font unicode;
  SpecialUnicodeFonts() {
    init();
  }
  void init() async {
    unicode = pw.Font.symbol();
  }
}
