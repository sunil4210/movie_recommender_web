import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:movie_recommender_web/core/components/button.dart';
import 'package:movie_recommender_web/core/components/forms/app_form_field.dart';
import 'package:movie_recommender_web/core/constants/asset_constants.dart';
import 'package:movie_recommender_web/widgets/svg_icon.dart';
import 'package:movie_recommender_web/core/extensions/theme_extensions.dart';
import 'package:movie_recommender_web/core/router/app_router.dart';
import 'package:movie_recommender_web/core/utils/email_validator.dart';
import 'package:movie_recommender_web/notifiers/auth/auth_notifier.dart';
import 'package:movie_recommender_web/notifiers/auth/auth_state.dart';
import 'package:movie_recommender_web/services/toast_service.dart';
import 'package:movie_recommender_web/theme/app_color.dart';
import 'package:movie_recommender_web/widgets/app_logo.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    await ref
        .read(authNotifierProvider.notifier)
        .register(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
        );
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
        ToastService.instance.show(
          context: context,
          title: 'Account created successfully!',
          toastType: ToastType.success,
        );
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
                    const SizedBox(height: 24),
                    _buildRegisterButton(),
                    const SizedBox(height: 20),
                    _buildLoginLink(),
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
      'Sign Up',
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
            controller: _firstNameController,
            labelText: 'First Name',
            hintText: 'Enter your first name',
            autovalidateMode: AutovalidateMode.onUserInteraction,
            prefixIcon: const Icon(Icons.person_outlined, color: AppColors.grey500, size: 20),
            validator: (String? value) {
              if (value == null || value.trim().isEmpty) return 'First name is required';
              return null;
            },
          ),
          const SizedBox(height: 20),
          AppFormField(
            controller: _lastNameController,
            labelText: 'Last Name',
            hintText: 'Enter your last name',
            autovalidateMode: AutovalidateMode.onUserInteraction,
            prefixIcon: const Icon(Icons.person_outlined, color: AppColors.grey500, size: 20),
            validator: (String? value) {
              if (value == null || value.trim().isEmpty) return 'Last name is required';
              return null;
            },
          ),
          const SizedBox(height: 20),
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
              if (value.length < 8) return 'Minimum 8 characters';
              if (!RegExp(r'[A-Z]').hasMatch(value)) return 'Include at least one uppercase letter';
              if (!RegExp(r'[a-z]').hasMatch(value)) return 'Include at least one lowercase letter';
              if (!RegExp(r'[0-9]').hasMatch(value)) return 'Include at least one number';
              return null;
            },
          ),
          const SizedBox(height: 20),
          AppFormField(
            controller: _confirmPasswordController,
            labelText: 'Confirm Password',
            obscureText: _obscureConfirmPassword,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            hintText: 'Re-enter your password',
            prefixIcon: const Icon(Icons.lock_outlined, color: AppColors.grey500, size: 20),
            suffixIcon: IconButton(
              onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
              icon: SvgIcon(
                _obscureConfirmPassword ? SvgPaths.eyeOff : SvgPaths.eye,
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

  Widget _buildRegisterButton() {
    return SizedBox(
      width: double.infinity,
      child: PrimaryButton(
        title: 'Sign Up',
        onTap: _handleRegister,
        loading: _isLoading,
        borderRadius: 8,
        buttonElevation: 0,
      ),
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Already have an account? ', style: context.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
        GestureDetector(
          onTap: () => context.pop(),
          child: Text(
            'Log In.',
            style: context.textTheme.bodySmall?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
