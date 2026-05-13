import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTheme {
  static ThemeData get light {
    return ThemeData(
      colorSchemeSeed: AppColors.mutedSage,
      scaffoldBackgroundColor: AppColors.warmGold,
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.mutedSage,
        selectionColor: AppColors.richBrown,
        selectionHandleColor: AppColors.mutedSage,
      ),
    );
  }
}
