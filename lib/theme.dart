import 'package:flutter/material.dart';

/// LastCheck 暖色主题：延续小程序版米白 + 棕的视觉。
/// 字体：思源黑体（Source Han Sans SC），正文 Medium、标题 Bold，去 AI 味的轻盈感。
class AppColors {
  static const bg = Color(0xFFF7F4EE);
  static const primary = Color(0xFFB08968);
  static const primaryDark = Color(0xFF8A6A4F);
  static const primarySoft = Color(0xFFEDE3D6);
  static const danger = Color(0xFFA25E4C);
  static const textDark = Color(0xFF4A443E);
  static const textGrey = Color(0xFF9A938A);
  static const card = Colors.white;
  static const success = Color(0xFF6B8E6B);
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: Brightness.light,
    surface: AppColors.card,
  );
  final theme = ThemeData(
    useMaterial3: true,
    fontFamily: 'SourceHanSansSC',
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.bg,
    splashFactory: InkRipple.splashFactory,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bg,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      foregroundColor: AppColors.textDark,
      titleTextStyle: TextStyle(
        color: AppColors.textDark,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    ),
    cardTheme: const CardThemeData(
      color: AppColors.card,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryDark,
        side: const BorderSide(color: AppColors.primarySoft, width: 1.5),
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.textDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );

  // 全局字重上调：正文 Medium、标题 Bold，让界面更利落、更有设计感。
  return theme.copyWith(
    textTheme: theme.textTheme.copyWith(
      bodyLarge:
          theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
      bodyMedium:
          theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
      bodySmall:
          theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
      titleLarge:
          theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      titleMedium:
          theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      titleSmall:
          theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
      labelLarge:
          theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
    ),
  );
}

/// 设计装饰系统（Taste Skill：柔和阴影 + 悬浮岛容器）。
class AppDeco {
  /// 柔和弥散阴影（避免生硬黑边）
  static const softShadow = [
    BoxShadow(color: Color(0x14000000), blurRadius: 24, offset: Offset(0, 8)),
    BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 1)),
  ];

  /// 悬浮岛容器：半透明白 + 大圆角 + 柔和阴影
  static BoxDecoration island({double radius = 24}) => BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: softShadow,
        border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
      );

  /// 卡片容器：白底 + 大圆角 + 轻微浮起
  static BoxDecoration card({double radius = 20}) => BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: const [
          BoxShadow(color: Color(0x10000000), blurRadius: 18, offset: Offset(0, 6)),
        ],
      );
}
