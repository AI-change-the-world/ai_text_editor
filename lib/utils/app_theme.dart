import 'package:flutter/material.dart';

/// 应用主题扩展
/// 定义应用中使用的所有自定义颜色
class AppColors extends ThemeExtension<AppColors> {
  // 主色调
  final Color primary;
  final Color primaryLight;
  final Color primaryDark;

  // 背景色
  final Color background;
  final Color surface;
  final Color surfaceVariant;
  final Color card;

  // 文字颜色
  final Color textPrimary;
  final Color textSecondary;
  final Color textHint;

  // 边框和分割线
  final Color border;
  final Color divider;

  // 状态颜色
  final Color success;
  final Color warning;
  final Color error;

  // 侧边栏
  final Color sidebarBackground;
  final Color sidebarItemHover;
  final Color sidebarItemSelected;

  // 卡片和弹窗
  final Color dialogBackground;
  final Color cardHover;

  // 输入框
  final Color inputBackground;
  final Color inputBorder;
  final Color inputFocusBorder;

  const AppColors({
    required this.primary,
    required this.primaryLight,
    required this.primaryDark,
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.card,
    required this.textPrimary,
    required this.textSecondary,
    required this.textHint,
    required this.border,
    required this.divider,
    required this.success,
    required this.warning,
    required this.error,
    required this.sidebarBackground,
    required this.sidebarItemHover,
    required this.sidebarItemSelected,
    required this.dialogBackground,
    required this.cardHover,
    required this.inputBackground,
    required this.inputBorder,
    required this.inputFocusBorder,
  });

  /// 浅色主题颜色
  static const light = AppColors(
    primary: Color(0xFF3B82F6),
    primaryLight: Color(0xFFDBEAFE),
    primaryDark: Color(0xFF1D4ED8),
    background: Color(0xFFFFFFFF),
    surface: Color(0xFFF9FAFB),
    surfaceVariant: Color(0xFFF3F4F6),
    card: Color(0xFFFFFFFF),
    textPrimary: Color(0xFF1F2937),
    textSecondary: Color(0xFF6B7280),
    textHint: Color(0xFF9CA3AF),
    border: Color(0xFFE5E7EB),
    divider: Color(0xFFE5E7EB),
    success: Color(0xFF10B981),
    warning: Color(0xFFF59E0B),
    error: Color(0xFFEF4444),
    sidebarBackground: Color(0xFFFFFFFF),
    sidebarItemHover: Color(0xFFF3F4F6),
    sidebarItemSelected: Color(0xFFDBEAFE),
    dialogBackground: Color(0xFFFFFFFF),
    cardHover: Color(0xFFF9FAFB),
    inputBackground: Color(0xFFF9FAFB),
    inputBorder: Color(0xFFE5E7EB),
    inputFocusBorder: Color(0xFF3B82F6),
  );

  /// 深色主题颜色
  static const dark = AppColors(
    primary: Color(0xFF60A5FA),
    primaryLight: Color(0xFF1E3A5F),
    primaryDark: Color(0xFF93C5FD),
    background: Color(0xFF111827),
    surface: Color(0xFF1F2937),
    surfaceVariant: Color(0xFF374151),
    card: Color(0xFF1F2937),
    textPrimary: Color(0xFFF9FAFB),
    textSecondary: Color(0xFF9CA3AF),
    textHint: Color(0xFF6B7280),
    border: Color(0xFF374151),
    divider: Color(0xFF374151),
    success: Color(0xFF34D399),
    warning: Color(0xFFFBBF24),
    error: Color(0xFFF87171),
    sidebarBackground: Color(0xFF1F2937),
    sidebarItemHover: Color(0xFF374151),
    sidebarItemSelected: Color(0xFF1E3A5F),
    dialogBackground: Color(0xFF1F2937),
    cardHover: Color(0xFF374151),
    inputBackground: Color(0xFF374151),
    inputBorder: Color(0xFF4B5563),
    inputFocusBorder: Color(0xFF60A5FA),
  );

  @override
  AppColors copyWith({
    Color? primary,
    Color? primaryLight,
    Color? primaryDark,
    Color? background,
    Color? surface,
    Color? surfaceVariant,
    Color? card,
    Color? textPrimary,
    Color? textSecondary,
    Color? textHint,
    Color? border,
    Color? divider,
    Color? success,
    Color? warning,
    Color? error,
    Color? sidebarBackground,
    Color? sidebarItemHover,
    Color? sidebarItemSelected,
    Color? dialogBackground,
    Color? cardHover,
    Color? inputBackground,
    Color? inputBorder,
    Color? inputFocusBorder,
  }) {
    return AppColors(
      primary: primary ?? this.primary,
      primaryLight: primaryLight ?? this.primaryLight,
      primaryDark: primaryDark ?? this.primaryDark,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceVariant: surfaceVariant ?? this.surfaceVariant,
      card: card ?? this.card,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textHint: textHint ?? this.textHint,
      border: border ?? this.border,
      divider: divider ?? this.divider,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      sidebarBackground: sidebarBackground ?? this.sidebarBackground,
      sidebarItemHover: sidebarItemHover ?? this.sidebarItemHover,
      sidebarItemSelected: sidebarItemSelected ?? this.sidebarItemSelected,
      dialogBackground: dialogBackground ?? this.dialogBackground,
      cardHover: cardHover ?? this.cardHover,
      inputBackground: inputBackground ?? this.inputBackground,
      inputBorder: inputBorder ?? this.inputBorder,
      inputFocusBorder: inputFocusBorder ?? this.inputFocusBorder,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      primary: Color.lerp(primary, other.primary, t)!,
      primaryLight: Color.lerp(primaryLight, other.primaryLight, t)!,
      primaryDark: Color.lerp(primaryDark, other.primaryDark, t)!,
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceVariant: Color.lerp(surfaceVariant, other.surfaceVariant, t)!,
      card: Color.lerp(card, other.card, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textHint: Color.lerp(textHint, other.textHint, t)!,
      border: Color.lerp(border, other.border, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error: Color.lerp(error, other.error, t)!,
      sidebarBackground:
          Color.lerp(sidebarBackground, other.sidebarBackground, t)!,
      sidebarItemHover:
          Color.lerp(sidebarItemHover, other.sidebarItemHover, t)!,
      sidebarItemSelected:
          Color.lerp(sidebarItemSelected, other.sidebarItemSelected, t)!,
      dialogBackground:
          Color.lerp(dialogBackground, other.dialogBackground, t)!,
      cardHover: Color.lerp(cardHover, other.cardHover, t)!,
      inputBackground: Color.lerp(inputBackground, other.inputBackground, t)!,
      inputBorder: Color.lerp(inputBorder, other.inputBorder, t)!,
      inputFocusBorder:
          Color.lerp(inputFocusBorder, other.inputFocusBorder, t)!,
    );
  }
}

/// 获取当前主题颜色的扩展方法
extension AppColorsExtension on BuildContext {
  AppColors get colors =>
      Theme.of(this).extension<AppColors>() ?? AppColors.light;
}
