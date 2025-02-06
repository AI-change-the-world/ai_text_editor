enum ToolbarPosition { top, bottom, left, right, none }

class EditorChatHistory {
  final String q;
  final String a;
  final int baseOffset;
  final int createAt = DateTime.now().millisecondsSinceEpoch;

  EditorChatHistory({
    required this.q,
    required this.a,
    required this.baseOffset,
  });
}

class EditorState {
  final bool showStructure;
  final bool showAI;
  final ToolbarPosition toolbarPosition;
  final bool loading;
  final String? currentFilePath;
  final List<EditorChatHistory> chatHistory;

  EditorState({
    this.showStructure = false,
    this.showAI = false,
    this.toolbarPosition = ToolbarPosition.none,
    this.loading = false,
    this.chatHistory = const [],
    this.currentFilePath,
  });

  EditorState copyWith({
    bool? showStructure,
    bool? showAI,
    ToolbarPosition? toolbarPosition,
    bool? loading,
    List<EditorChatHistory>? chatHistory,
    bool? saved,
    String? currentFilePath,
    double? currentPosition,
  }) {
    return EditorState(
      showStructure: showStructure ?? this.showStructure,
      showAI: showAI ?? this.showAI,
      toolbarPosition: toolbarPosition ?? this.toolbarPosition,
      loading: loading ?? this.loading,
      chatHistory: chatHistory ?? this.chatHistory,
      currentFilePath: currentFilePath ?? this.currentFilePath,
    );
  }
}
