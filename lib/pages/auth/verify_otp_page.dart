import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:movie_recommender_web/core/components/button.dart';
import 'package:movie_recommender_web/core/components/forms/app_form_field.dart';
import 'package:movie_recommender_web/core/extensions/theme_extensions.dart';
import 'package:movie_recommender_web/core/router/app_router.dart';
import 'package:movie_recommender_web/notifiers/auth/auth_notifier.dart';
import 'package:movie_recommender_web/notifiers/auth/auth_state.dart';
import 'package:movie_recommender_web/services/toast_service.dart';
import 'package:movie_recommender_web/theme/app_color.dart';
import 'package:movie_recommender_web/widgets/app_logo.dart';

/// Shared 6-digit OTP screen used by both signup verification and password
/// reset. `purpose` controls which backend endpoint is called and where the
/// user is sent on success.
class VerifyOtpPage extends ConsumerStatefulWidget {
  const VerifyOtpPage({
    super.key,
    required this.email,
    required this.purpose,
  });

  final String email;

  /// 'signup' → verifies email + logs in.
  /// 'reset'  → just validates the code locally and routes to reset-password.
  final String purpose;

  @override
  ConsumerState<VerifyOtpPage> createState() => _VerifyOtpPageState();
}

class _VerifyOtpPageState extends ConsumerState<VerifyOtpPage> {
  static const int _resendCooldownSeconds = 60;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _codeController = TextEditingController();
  bool _isSubmitting = false;
  int _resendIn = _resendCooldownSeconds;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _startResendCooldown();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _ticker?.cancel();
    super.dispose();
  }

  void _startResendCooldown() {
    _ticker?.cancel();
    setState(() => _resendIn = _resendCooldownSeconds);
    _ticker = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_resendIn <= 1) {
        t.cancel();
        setState(() => _resendIn = 0);
      } else {
        setState(() => _resendIn -= 1);
      }
    });
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    final String code = _codeController.text.trim();

    if (widget.purpose == 'signup') {
      final bool ok = await ref
          .read(authNotifierProvider.notifier)
          .verifyEmailOtp(email: widget.email, code: code);
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      if (ok) {
        ToastService.instance.show(
          context: context,
          title: 'Email verified!',
          toastType: ToastType.success,
        );
        // Redirect rules in the router will take it from here.
      }
    } else {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      context.go(
        AppRoutes.resetPassword,
        extra: <String, String>{'email': widget.email, 'code': code},
      );
    }
  }

  Future<void> _handleResend() async {
    if (_resendIn > 0) return;
    final bool ok = await ref
        .read(authNotifierProvider.notifier)
        .resendOtp(email: widget.email, purpose: widget.purpose);
    if (!mounted) return;
    if (ok) {
      _startResendCooldown();
      ToastService.instance.show(
        context: context,
        title: 'A new code has been sent.',
        toastType: ToastType.success,
      );
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
                    _buildHeader(),
                    const SizedBox(height: 32),
                    _buildForm(),
                    const SizedBox(height: 24),
                    _buildSubmitButton(authState),
                    const SizedBox(height: 20),
                    _buildResendRow(),
                    const SizedBox(height: 20),
                    _buildBackLink(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final bool isReset = widget.purpose == 'reset';
    return Column(
      children: [
        Text(
          isReset ? 'Enter reset code' : 'Verify your email',
          style: context.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'We sent a 6-digit code to',
          style: context.textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          widget.email,
          style: context.textTheme.bodyMedium?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: AppFormField(
        controller: _codeController,
        labelText: 'Verification code',
        hintText: '••••••',
        keyboardType: TextInputType.number,
        textCapitalization: TextCapitalization.none,
        maxLength: 6,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        inputFormatters: <TextInputFormatter>[
          FilteringTextInputFormatter.digitsOnly,
        ],
        prefixIcon: const Icon(
          Icons.password_outlined,
          color: AppColors.grey500,
          size: 20,
        ),
        validator: (String? value) {
          final String v = (value ?? '').trim();
          if (v.isEmpty) return 'Code is required';
          if (v.length != 6) return 'Code must be 6 digits';
          return null;
        },
      ),
    );
  }

  Widget _buildSubmitButton(AuthState authState) {
    return SizedBox(
      width: double.infinity,
      child: PrimaryButton(
        title: widget.purpose == 'reset' ? 'CONTINUE' : 'VERIFY',
        onTap: _handleSubmit,
        loading: _isSubmitting || authState.isLoading,
        borderRadius: 8,
        buttonElevation: 0,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildResendRow() {
    final bool canResend = _resendIn == 0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Didn't get the code? ",
          style: context.textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        GestureDetector(
          onTap: canResend ? _handleResend : null,
          child: Text(
            canResend ? 'Resend' : 'Resend in ${_resendIn}s',
            style: context.textTheme.bodySmall?.copyWith(
              color: canResend ? AppColors.primary : AppColors.textTertiary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBackLink() {
    return GestureDetector(
      onTap: () => context.go(AppRoutes.login),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.arrow_back, color: AppColors.textTertiary, size: 16),
          const SizedBox(width: 8),
          Text(
            'Back to Login',
            style: context.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
