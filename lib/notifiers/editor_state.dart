enum ToolbarPosition { top, bottom, left, right, none }

class EditorState {
  final bool showStructure;
  final bool showAI;
  final ToolbarPosition toolbarPosition;
  final bool loading;

  EditorState({
    this.showStructure = false,
    this.showAI = false,
    this.toolbarPosition = ToolbarPosition.none,
    this.loading = false,
  });

  EditorState copyWith({
    bool? showStructure,
    bool? showAI,
    ToolbarPosition? toolbarPosition,
    bool? loading,
  }) {
    return EditorState(
      showStructure: showStructure ?? this.showStructure,
      showAI: showAI ?? this.showAI,
      toolbarPosition: toolbarPosition ?? this.toolbarPosition,
      loading: loading ?? this.loading,
    );
  }
}
