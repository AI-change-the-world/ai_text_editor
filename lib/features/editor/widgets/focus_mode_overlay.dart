import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ai_text_editor/notifiers/editor_notifier.dart';

/// Focus Mode Overlay Widget
/// Requirements: 2.6 - WHEN a user enables focus mode THEN the System SHALL
/// hide all UI elements except the editor and current paragraph
class FocusModeOverlay extends ConsumerStatefulWidget {
  final Widget child;

  const FocusModeOverlay({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<FocusModeOverlay> createState() => _FocusModeOverlayState();
}

class _FocusModeOverlayState extends ConsumerState<FocusModeOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _showExitHint = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Hide the exit hint after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showExitHint = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _exitFocusMode() {
    ref.read(editorNotifierProvider.notifier).toggleFocusMode();
  }

  @override
  Widget build(BuildContext context) {
    final isFocusMode =
        ref.watch(editorNotifierProvider.select((s) => s.focusMode));

    if (isFocusMode) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }

    return Stack(
      children: [
        widget.child,
        if (isFocusMode)
          FadeTransition(
            opacity: _fadeAnimation,
            child: _buildFocusModeUI(context),
          ),
      ],
    );
  }

  Widget _buildFocusModeUI(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): _exitFocusMode,
        SingleActivator(LogicalKeyboardKey.keyF, control: true, shift: true):
            _exitFocusMode,
      },
      child: Focus(
        autofocus: true,
        child: Stack(
          children: [
            // Semi-transparent overlay for dimming effect
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.03),
                ),
              ),
            ),
            // Exit hint at the top
            if (_showExitHint)
              Positioned(
                top: 40,
                left: 0,
                right: 0,
                child: Center(
                  child: AnimatedOpacity(
                    opacity: _showExitHint ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 500),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        '按 Esc 或 Ctrl+Shift+F 退出专注模式',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            // Exit button at the top right (always visible on hover)
            Positioned(
              top: 10,
              right: 10,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: _exitFocusMode,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 20,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
