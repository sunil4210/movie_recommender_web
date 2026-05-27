import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movie_recommender_web/core/components/button.dart';
import 'package:movie_recommender_web/core/components/forms/app_form_field.dart';
import 'package:movie_recommender_web/core/extensions/theme_extensions.dart';
import 'package:movie_recommender_web/core/utils/email_validator.dart';
import 'package:movie_recommender_web/widgets/app_logo.dart';
import 'package:movie_recommender_web/notifiers/auth/auth_notifier.dart';
import 'package:movie_recommender_web/notifiers/auth/auth_state.dart';
import 'package:movie_recommender_web/services/toast_service.dart';
import 'package:movie_recommender_web/theme/app_color.dart';

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    await ref.read(authNotifierProvider.notifier).sendPasswordResetEmail(email: _emailController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final AuthState authState = ref.watch(authNotifierProvider);

    ref.listen<AuthState>(authNotifierProvider, (AuthState? previous, AuthState next) {
      if (next.status == AuthStatus.error && next.errorMessage != null) {
        ToastService.instance.show(context: context, title: next.errorMessage!, toastType: ToastType.error);
        ref.read(authNotifierProvider.notifier).clearError();
      }

      if (previous?.isLoading == true && next.status == AuthStatus.unauthenticated) {
        setState(() => _emailSent = true);
        ToastService.instance.show(
          context: context,
          title: 'Password reset email sent!',
          description: 'Check your inbox for the reset link.',
          toastType: ToastType.success,
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background image
          Image.network(
            'https://dg3fwljcbubde.cloudfront.net/Landing/landing-bg-ww.jpg',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
          // Dark overlay
          Container(color: Colors.black.withValues(alpha: 0.9)),

          // Content
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: _emailSent ? _buildSuccessView() : _buildFormView(authState),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormView(AuthState authState) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildHeader(),
        const SizedBox(height: 40),
        _buildForm(),
        const SizedBox(height: 24),
        _buildResetButton(authState),
        const SizedBox(height: 32),
        _buildBackToLoginLink(),
      ],
    );
  }

  Widget _buildSuccessView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(color: AppColors.success500.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: const Icon(Icons.mark_email_read_outlined, color: AppColors.success500, size: 40),
        ),
        const SizedBox(height: 24),
        Text(
          'Check your email',
          style: context.textTheme.headlineSmall?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Text(
          'We sent a password reset link to',
          style: context.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          _emailController.text.trim(),
          style: context.textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              'BACK TO LOGIN',
              style: context.textTheme.labelLarge?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () {
            setState(() => _emailSent = false);
          },
          child: Text(
            "Didn't receive the email? Try again",
            style: context.textTheme.bodySmall?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        const AppLogo(),
        const SizedBox(height: 24),
        Text('Reset your password', style: context.textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        Text(
          "Enter your email and we'll send you a reset link",
          style: context.textTheme.bodySmall?.copyWith(color: AppColors.textTertiary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppFormField(
            controller: _emailController,
            labelText: 'Email',
            keyboardType: TextInputType.emailAddress,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            hintText: 'Enter your email',
            prefixIcon: const Icon(Icons.email_outlined, color: AppColors.grey500, size: 20),
            validator: (String? value) {
              if (value == null || value.isEmpty) return 'Email is required';
              if (!EmailValidator.validate(value)) return 'Enter a valid email';
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildResetButton(AuthState authState) {
    return SizedBox(
      width: double.infinity,
      child: PrimaryButton(
        title: 'SEND RESET LINK',
        onTap: _handleResetPassword,
        loading: authState.isLoading,
        borderRadius: 8,
        buttonElevation: 0,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildBackToLoginLink() {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.arrow_back, color: AppColors.textTertiary, size: 16),
          const SizedBox(width: 8),
          Text(
            'Back to Login',
            style: context.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
