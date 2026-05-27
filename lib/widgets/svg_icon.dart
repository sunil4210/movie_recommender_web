import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:movie_recommender_web/theme/app_color.dart';

class SvgIcon extends StatelessWidget {
  const SvgIcon(
    this.assetPath, {
    this.size = 24,
    this.color,
    super.key,
  });

  final String assetPath;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      assetPath,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(
        color ?? AppColors.textPrimary,
        BlendMode.srcIn,
      ),
    );
  }
}
