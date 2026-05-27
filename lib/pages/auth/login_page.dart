import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movie_recommender_web/core/components/button.dart';
import 'package:movie_recommender_web/core/components/forms/app_form_field.dart';
import 'package:movie_recommender_web/core/constants/asset_constants.dart';
import 'package:movie_recommender_web/widgets/svg_icon.dart';
import 'package:movie_recommender_web/core/extensions/theme_extensions.dart';
import 'package:movie_recommender_web/notifiers/auth/auth_notifier.dart';
import 'package:movie_recommender_web/notifiers/auth/auth_state.dart';
import 'package:go_router/go_router.dart';
import 'package:movie_recommender_web/core/router/app_router.dart';
import 'package:movie_recommender_web/services/toast_service.dart';
import 'package:movie_recommender_web/theme/app_color.dart';
import 'package:movie_recommender_web/widgets/app_logo.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    await ref
        .read(authNotifierProvider.notifier)
        .login(email: _emailController.text.trim(), password: _passwordController.text);
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(authNotifierProvider);

    ref.listen<AuthState>(authNotifierProvider, (AuthState? previous, AuthState next) {
      if (next.status == AuthStatus.error && next.errorMessage != null) {
        ToastService.instance.show(context: context, title: next.errorMessage!, toastType: ToastType.error);
        ref.read(authNotifierProvider.notifier).clearError();
      }

      if (next.isAuthenticated) {
        ToastService.instance.show(context: context, title: 'Welcome back!', toastType: ToastType.success);
        context.go(AppRoutes.home);
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
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const AppLogo(),
                    const SizedBox(height: 32),
                    _buildHeader(),
                    const SizedBox(height: 32),
                    _buildForm(),
                    const SizedBox(height: 12),
                    _buildForgotPassword(),
                    const SizedBox(height: 24),
                    _buildLoginButton(),
                    const SizedBox(height: 20),
                    _buildSignUpSection(),
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
    return Text(
      'Login',
      style: context.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
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
              if (!value.contains('@')) return 'Enter a valid email';
              return null;
            },
          ),
          const SizedBox(height: 20),
          AppFormField(
            controller: _passwordController,
            labelText: 'Password',
            obscureText: _obscurePassword,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            hintText: 'Enter your password',
            prefixIcon: const Icon(Icons.lock_outlined, color: AppColors.grey500, size: 20),
            suffixIcon: IconButton(
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              icon: SvgIcon(
                _obscurePassword ? SvgPaths.eyeOff : SvgPaths.eye,
                size: 20,
                color: AppColors.grey500,
              ),
            ),
            validator: (String? value) {
              if (value == null || value.isEmpty) return 'Password is required';
              if (value.length < 6) return 'Password must be at least 6 characters';
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildForgotPassword() {
    return Align(
      alignment: Alignment.centerRight,
      child: GestureDetector(
        onTap: () => context.push(AppRoutes.forgotPassword),
        child: Text(
          'Forgot Password?',
          style: context.textTheme.bodySmall?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      child: PrimaryButton(
        title: 'Login',
        onTap: _handleLogin,
        loading: _isLoading,
        borderRadius: 8,
        buttonElevation: 0,
      ),
    );
  }

  Widget _buildSignUpSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("Don't have an account? ", style: context.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
        GestureDetector(
          onTap: () => context.push(AppRoutes.register),
          child: Text(
            'Sign up here!',
            style: context.textTheme.bodySmall?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
