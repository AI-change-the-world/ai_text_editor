enum ToolbarPosition { top, bottom, left, right, none }

class EditorState {
  final bool showStructure;
  final bool showAI;
  final ToolbarPosition toolbarPosition;

  EditorState({
    this.showStructure = false,
    this.showAI = false,
    this.toolbarPosition = ToolbarPosition.none,
  });

  EditorState copyWith({
    bool? showStructure,
    bool? showAI,
    ToolbarPosition? toolbarPosition,
  }) {
    return EditorState(
      showStructure: showStructure ?? this.showStructure,
      showAI: showAI ?? this.showAI,
      toolbarPosition: toolbarPosition ?? this.toolbarPosition,
    );
  }
}
