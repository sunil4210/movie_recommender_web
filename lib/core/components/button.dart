import 'package:movie_recommender_web/core/extensions/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:movie_recommender_web/theme/app_color.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    required this.title,
    super.key,
    this.prefix,
    this.borderRadius = 4.0,
    this.backgroundColor,
    this.textColor,
    this.onTap,
    this.buttonElevation = 4.0,
    this.loading = false,
    this.disabled = false,
    this.padding,
    this.fontWeight,
    this.loaderSize = 14,
  });
  final String title;
  final double borderRadius;
  final Color? backgroundColor;
  final Color? textColor;
  final Widget? prefix;
  final void Function()? onTap;
  final double buttonElevation;
  final bool loading;
  final bool disabled;
  final double loaderSize;

  /// Overrides default padding
  final EdgeInsets? padding;

  final FontWeight? fontWeight;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(borderRadius);
    Widget suffixWidget = const SizedBox();
    // Progress indicator takes prefix's place when state is [loading].
    if (loading) {
      suffixWidget = Center(
        child: SizedBox(
          width: loaderSize,
          height: loaderSize,
          child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
        ),
      );
    } else if (prefix != null) {
      suffixWidget = prefix!;
    }

    final bool isButtonActive = onTap != null && !loading && !disabled;

    BoxDecoration decoration = const BoxDecoration();
    // Style behavior in precedence order:
    // - use [backgroundColor] if provided,
    // - use mesh gradient asset if enabled,
    // - use default primary color otherwise

    if (backgroundColor == null) {
      const defaultActiveButtonColor = AppColors.primary;
      final defaultInactiveButtonColor = Colors.grey.withValues(alpha: 0.5);

      decoration = BoxDecoration(
        borderRadius: radius,
        color: isButtonActive ? defaultActiveButtonColor : defaultInactiveButtonColor,
      );
    } else if (backgroundColor != null) {
      decoration = BoxDecoration(
        borderRadius: radius,
        color: isButtonActive ? backgroundColor : backgroundColor?.withValues(alpha: 0.7),
      );
    }

    return Material(
      elevation: buttonElevation,
      borderRadius: radius,
      child: Ink(
        decoration: decoration,
        child: InkWell(
          borderRadius: radius,
          onTap: () => (loading || disabled) ? null : onTap?.call(),
          child: Padding(
            padding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (suffixWidget is! SizedBox) SizedBox(width: 14, height: 14, child: suffixWidget),
                Flexible(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      title,
                      style: context.textTheme.labelMedium?.copyWith(
                        color: textColor ?? Colors.white,
                        fontWeight: fontWeight ?? FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                // Offset prefix by also adding same whitespace at the end
                if (suffixWidget is! SizedBox) const SizedBox(width: 14, height: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PrimaryBorderButton extends StatelessWidget {
  const PrimaryBorderButton({
    required this.title,
    this.prefix,
    this.backgroundColor,
    this.textColor,
    this.borderColor,
    this.onTap,
    this.fontWeight,
    this.fontSize,
    super.key,
  });
  final String title;
  final Color? backgroundColor;
  final Color? textColor;
  final Widget? prefix;
  final Color? borderColor;
  final VoidCallback? onTap;
  final FontWeight? fontWeight;
  final double? fontSize;

  @override
  Widget build(BuildContext context) {
    final Color color = backgroundColor ?? Colors.transparent;
    final BorderRadius borderRadius = BorderRadius.circular(8);
    return ClipRRect(
      borderRadius: borderRadius,
      child: Material(
        color: (onTap != null) ? color : color.withValues(alpha: 0.6),
        child: InkWell(
          borderRadius: borderRadius,
          splashColor: (backgroundColor ?? AppColors.primary).withValues(alpha: 0.8),
          onTap: onTap,
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              border: Border.all(color: borderColor ?? AppColors.grey300),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (prefix != null) Container(margin: const EdgeInsets.only(right: 12), child: prefix),
                Flexible(
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: context.textTheme.labelMedium?.copyWith(
                      color: textColor ?? AppColors.grey700,
                      fontWeight: fontWeight ?? FontWeight.w600,
                      fontSize: fontSize,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
