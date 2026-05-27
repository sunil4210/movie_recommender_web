import 'package:flutter/material.dart';

class AppColors {
  // Blue-themed primary colors
  static const Color primary = Color(0xFF2196F3);
  static const Color primaryLight = Color(0xFF64B5F6);
  static const Color primaryDark = Color(0xFF1565C0);

  static const Color accent = Color(0xFF42A5F5);
  static const Color accentLight = Color(0xFF90CAF9);

  // Dark backgrounds
  static const Color background = Color(0xFF0A0A0A);
  static const Color backgroundElevated = Color(0xFF141414);
  static const Color backgroundCard = Color(0xFF1F1F1F);
  static const Color backgroundModal = Color(0xFF181818);
  static const Color scaffoldBackground = Color(0xFF0A0A0A);

  // Text colors (light on dark)
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF999999);
  static const Color textTertiary = Color(0xFF757575);
  static const Color textDisabled = Color(0xFF555555);
  static const Color textColor = Color(0xFFFFFFFF);
  static const Color titleColor = Color(0xFFFFFFFF);
  static const Color subtitleColor = Color(0xFF999999);

  // Grey scale (dark theme adapted)
  static const Color grey50 = Color(0xFF1A1A1A);
  static const Color grey100 = Color(0xFF222222);
  static const Color grey200 = Color(0xFF2A2A2A);
  static const Color grey300 = Color(0xFF333333);
  static const Color grey400 = Color(0xFF555555);
  static const Color grey500 = Color(0xFF757575);
  static const Color grey600 = Color(0xFF999999);
  static const Color grey700 = Color(0xFFB3B3B3);
  static const Color grey800 = Color(0xFFCCCCCC);
  static const Color grey900 = Color(0xFFE5E5E5);
  static const Color grey = Color(0xFF757575);
  static const Color lightGrey = Color(0xFF222222);
  static const Color mediumGrey = Color(0xFF555555);
  static const Color darkGrey = Color(0xFFB3B3B3);

  // Status colors
  static const Color success500 = Color(0xFF46D369);
  static const Color success700 = Color(0xFF2EA44F);
  static const Color error = Color(0xFFEF5350);
  static const Color errorLight = Color(0xFFFF5252);
  static const Color warningColor = Color(0xFFFFB800);
  static const Color warningLight = Color(0xFFFFD54F);
  static const Color info = Color(0xFF42A5F5);

  // Borders (subtle on dark)
  static const Color border = Color(0xFF333333);
  static const Color borderLight = Color(0xFF2A2A2A);
  static const Color borderDark = Color(0xFF444444);
  static const Color borderColor = Color(0xFF333333);

  // Chips
  static const Color chipBackground = Color(0xFF2A2A2A);
  static const Color chipBackgroundActive = Color(0xFF2196F3);
  static const Color chipText = Color(0xFF999999);
  static const Color chipTextActive = Color(0xFFFFFFFF);

  // Hover/Focus
  static const Color hoverOverlay = Color(0x1AFFFFFF);
  static const Color hoverCard = Color(0xFF222222);
  static const Color focusRing = Color(0xFF2196F3);

  // Rating
  static const Color ratingFilled = Color(0xFFFFD700);
  static const Color ratingEmpty = Color(0xFF444444);
  static const Color ratingHalf = Color(0xFFFFE44D);

  // Buttons
  static const Color buttonPrimary = Color(0xFF2196F3);
  static const Color buttonPrimaryHover = Color(0xFF42A5F5);
  static const Color buttonPrimaryPressed = Color(0xFF1565C0);
  static const Color buttonSecondary = Color(0xFF2A2A2A);
  static const Color buttonSecondaryHover = Color(0xFF333333);
  static const Color defaultInactiveButtonColor = Color(0xFF444444);

  // Gradients
  static const List<Color> gradientPrimary = [Color(0xFF2196F3), Color(0xFF1565C0)];
  static const List<Color> gradientDark = [Color(0xFF000000), Color(0xFF141414)];
  static const List<Color> gradientPosterOverlay = [Color(0x00000000), Color(0xCC000000)];

  static Color backdropOverlay = const Color(0xFF000000).withValues(alpha: 0.7);
  static Color bottomSheetBarrier = const Color(0xFF000000).withValues(alpha: 0.6);

  // Shimmer
  static const Color shimmerBase = Color(0xFF1C1C1C);
  static const Color shimmerHighlight = Color(0xFF2A2A2A);

  // Base
  static const Color colorBlack = Color(0xFF000000);
  static const Color colorWhite = Color(0xFFFFFFFF);

  // Genre colors (vibrant for dark background)
  static const Color genreAction = Color(0xFFE53935);
  static const Color genreComedy = Color(0xFFFFB300);
  static const Color genreDrama = Color(0xFFAB47BC);
  static const Color genreSciFi = Color(0xFF00BCD4);
  static const Color genreHorror = Color(0xFF546E7A);
  static const Color genreRomance = Color(0xFFEC407A);
  static const Color genreThriller = Color(0xFFFF7043);
  static const Color genreAnimation = Color(0xFF66BB6A);

  static Color getGenreColor(String genre) {
    switch (genre.toLowerCase()) {
      case 'action':
        return genreAction;
      case 'comedy':
        return genreComedy;
      case 'drama':
        return genreDrama;
      case 'sci-fi':
      case 'science fiction':
        return genreSciFi;
      case 'horror':
        return genreHorror;
      case 'romance':
        return genreRomance;
      case 'thriller':
        return genreThriller;
      case 'animation':
        return genreAnimation;
      default:
        return grey600;
    }
  }
}

class AppShadows {
  static List<BoxShadow> small = [
    BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 4, offset: const Offset(0, 2)),
  ];

  static List<BoxShadow> medium = [
    BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 4)),
  ];

  static List<BoxShadow> large = [
    BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 16, offset: const Offset(0, 8)),
  ];

  static List<BoxShadow> cardHover = [
    BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 8)),
  ];
}
