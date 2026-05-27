import 'package:flutter/material.dart';
import 'package:movie_recommender_web/theme/app_color.dart';
import 'package:toastification/toastification.dart';

enum ToastType { success, error, warning, info }

class ToastConfig {
  ToastConfig({
    this.duration = const Duration(seconds: 2),
    this.alignment = Alignment.topRight,
  });
  final Duration duration;
  final AlignmentGeometry? alignment;
}

class ToastService {
  ToastService._();

  static final ToastService _instance = ToastService._();
  static ToastService get instance => _instance;

  void show({
    required BuildContext context,
    required String title,
    required ToastType toastType,
    ToastConfig? config,
    String? description,
  }) {
    final Color typeColor = _getPrimaryColorBasedOnType(toastType);

    toastification.show(
      context: context,
      type: _mapToastType(toastType),
      style: ToastificationStyle.flatColored,
      autoCloseDuration: config?.duration ?? const Duration(seconds: 2),
      title: Text(
        title,
        style: TextStyle(
          color: typeColor,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
      description: description != null
          ? Text(
              description,
              style: TextStyle(color: typeColor.withValues(alpha: 0.8), fontSize: 12),
            )
          : null,
      alignment: config?.alignment,
      animationDuration: const Duration(milliseconds: 300),
      showIcon: true,
      primaryColor: typeColor,
      backgroundColor: typeColor.withValues(alpha: 0.1),
      foregroundColor: typeColor,
      borderSide: BorderSide(color: typeColor.withValues(alpha: 0.3), width: 1),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      margin: const EdgeInsets.all(8),
      borderRadius: BorderRadius.circular(8),
      showProgressBar: false,
      pauseOnHover: false,
      dragToClose: true,
    );
  }

  ToastificationType _mapToastType(ToastType type) {
    switch (type) {
      case ToastType.success:
        return ToastificationType.success;
      case ToastType.error:
        return ToastificationType.error;
      case ToastType.warning:
        return ToastificationType.warning;
      case ToastType.info:
        return ToastificationType.info;
    }
  }

  Color _getPrimaryColorBasedOnType(ToastType type) {
    return switch (type) {
      ToastType.success => AppColors.success500,
      ToastType.error => AppColors.error,
      ToastType.warning => AppColors.warningColor,
      ToastType.info => AppColors.primary,
    };
  }
}
