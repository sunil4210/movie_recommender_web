import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:movie_recommender_web/core/constants/app_constants.dart';
import 'package:movie_recommender_web/core/constants/asset_constants.dart';
import 'package:movie_recommender_web/theme/app_color.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({
    this.size = 64,
    this.fontSize = 28,
    this.showText = true,
    super.key,
  });

  final double size;
  final double fontSize;
  final bool showText;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(size * 0.22),
          child: SvgPicture.asset(
            SvgPaths.logo,
            width: size,
            height: size,
          ),
        ),
        if (showText) ...[
          const SizedBox(height: 16),
          Text(
            AppConstants.appName,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
              letterSpacing: 1,
            ),
          ),
        ],
      ],
    );
  }
}
