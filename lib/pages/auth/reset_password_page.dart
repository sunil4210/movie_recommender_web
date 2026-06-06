import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:movie_recommender_web/core/components/button.dart';
import 'package:movie_recommender_web/core/components/forms/app_form_field.dart';
import 'package:movie_recommender_web/core/constants/asset_constants.dart';
import 'package:movie_recommender_web/core/extensions/theme_extensions.dart';
import 'package:movie_recommender_web/core/router/app_router.dart';
import 'package:movie_recommender_web/notifiers/auth/auth_notifier.dart';
import 'package:movie_recommender_web/notifiers/auth/auth_state.dart';
import 'package:movie_recommender_web/services/toast_service.dart';
import 'package:movie_recommender_web/theme/app_color.dart';
import 'package:movie_recommender_web/widgets/app_logo.dart';
import 'package:movie_recommender_web/widgets/svg_icon.dart';

/// Final step of the password-reset flow. Reached from [VerifyOtpPage] with
/// the email + already-entered code passed in `state.extra`.
class ResetPasswordPage extends ConsumerStatefulWidget {
  const ResetPasswordPage({
    super.key,
    required this.email,
    required this.code,
  });

  final String email;
  final String code;

  @override
  ConsumerState<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends ConsumerState<ResetPasswordPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    final bool ok = await ref
        .read(authNotifierProvider.notifier)
        .resetPasswordWithOtp(
          email: widget.email,
          code: widget.code,
          newPassword: _passwordController.text,
        );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (ok) {
      ToastService.instance.show(
        context: context,
        title: 'Password updated. Please log in.',
        toastType: ToastType.success,
      );
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AuthState authState = ref.watch(authNotifierProvider);

    ref.listen<AuthState>(authNotifierProvider, (AuthState? prev, AuthState next) {
      if (next.status == AuthStatus.error && next.errorMessage != null) {
        ToastService.instance.show(
          context: context,
          title: next.errorMessage!,
          toastType: ToastType.error,
        );
        ref.read(authNotifierProvider.notifier).clearError();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            'https://dg3fwljcbubde.cloudfront.net/Landing/landing-bg-ww.jpg',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
          Container(color: Colors.black.withValues(alpha: 0.9)),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const AppLogo(),
                    const SizedBox(height: 32),
                    Text(
                      'Set a new password',
                      style: context.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.email,
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildForm(),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: PrimaryButton(
                        title: 'UPDATE PASSWORD',
                        onTap: _handleSubmit,
                        loading: _isSubmitting || authState.isLoading,
                        borderRadius: 8,
                        buttonElevation: 0,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: () => context.go(AppRoutes.login),
                      child: Text(
                        'Back to Login',
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppFormField(
            controller: _passwordController,
            labelText: 'New password',
            hintText: 'Enter new password',
            obscureText: _obscurePassword,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            prefixIcon: const Icon(
              Icons.lock_outlined,
              color: AppColors.grey500,
              size: 20,
            ),
            suffixIcon: IconButton(
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
              icon: SvgIcon(
                _obscurePassword ? SvgPaths.eyeOff : SvgPaths.eye,
                size: 20,
                color: AppColors.grey500,
              ),
            ),
            validator: (String? value) {
              if (value == null || value.isEmpty) return 'Password is required';
              if (value.length < 8) return 'Minimum 8 characters';
              if (!RegExp(r'[A-Z]').hasMatch(value)) return 'Include at least one uppercase letter';
              if (!RegExp(r'[a-z]').hasMatch(value)) return 'Include at least one lowercase letter';
              if (!RegExp(r'[0-9]').hasMatch(value)) return 'Include at least one number';
              return null;
            },
          ),
          const SizedBox(height: 20),
          AppFormField(
            controller: _confirmController,
            labelText: 'Confirm password',
            hintText: 'Re-enter new password',
            obscureText: _obscureConfirm,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            prefixIcon: const Icon(
              Icons.lock_outlined,
              color: AppColors.grey500,
              size: 20,
            ),
            suffixIcon: IconButton(
              onPressed: () =>
                  setState(() => _obscureConfirm = !_obscureConfirm),
              icon: SvgIcon(
                _obscureConfirm ? SvgPaths.eyeOff : SvgPaths.eye,
                size: 20,
                color: AppColors.grey500,
              ),
            ),
            validator: (String? value) {
              if (value == null || value.isEmpty) return 'Please confirm your password';
              if (value != _passwordController.text) return 'Passwords do not match';
              return null;
            },
          ),
        ],
      ),
    );
  }
}
