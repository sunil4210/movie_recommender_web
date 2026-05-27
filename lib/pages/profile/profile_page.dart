import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:movie_recommender_web/core/constants/asset_constants.dart';
import 'package:movie_recommender_web/widgets/svg_icon.dart';
import 'package:movie_recommender_web/core/router/app_router.dart';
import 'package:movie_recommender_web/models/user_model.dart';
import 'package:movie_recommender_web/notifiers/auth/auth_notifier.dart';
import 'package:movie_recommender_web/notifiers/auth/auth_state.dart';
import 'package:movie_recommender_web/services/toast_service.dart';
import 'package:movie_recommender_web/theme/app_color.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  late TextEditingController _firstNameCtrl;
  late TextEditingController _lastNameCtrl;
  final TextEditingController _currentPassCtrl = TextEditingController();
  final TextEditingController _newPassCtrl = TextEditingController();
  final TextEditingController _confirmPassCtrl = TextEditingController();

  bool _editingProfile = false;
  bool _savingProfile = false;
  bool _changingPassword = false;
  bool _savingPassword = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;

  @override
  void initState() {
    super.initState();
    final UserModel? user = ref.read(authNotifierProvider).user;
    _firstNameCtrl = TextEditingController(text: user?.firstName ?? '');
    _lastNameCtrl = TextEditingController(text: user?.lastName ?? '');
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _currentPassCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    setState(() => _savingProfile = true);
    final bool ok = await ref.read(authNotifierProvider.notifier).updateProfile(
          firstName: _firstNameCtrl.text.trim(),
          lastName: _lastNameCtrl.text.trim(),
        );
    if (mounted) {
      setState(() {
        _savingProfile = false;
        if (ok) _editingProfile = false;
      });
      ToastService.instance.show(
        context: context,
        title: ok ? 'Profile updated' : 'Failed to update profile',
        toastType: ok ? ToastType.success : ToastType.error,
      );
    }
  }

  Future<void> _changePassword() async {
    if (_newPassCtrl.text != _confirmPassCtrl.text) {
      ToastService.instance.show(
        context: context,
        title: 'Passwords do not match',
        toastType: ToastType.error,
      );
      return;
    }
    if (_newPassCtrl.text.length < 8) {
      ToastService.instance.show(
        context: context,
        title: 'Password must be at least 8 characters',
        toastType: ToastType.error,
      );
      return;
    }

    setState(() => _savingPassword = true);
    final bool ok = await ref.read(authNotifierProvider.notifier).changePassword(
          currentPassword: _currentPassCtrl.text,
          newPassword: _newPassCtrl.text,
        );
    if (mounted) {
      setState(() => _savingPassword = false);
      if (ok) {
        _currentPassCtrl.clear();
        _newPassCtrl.clear();
        _confirmPassCtrl.clear();
        setState(() => _changingPassword = false);
      }
      ToastService.instance.show(
        context: context,
        title: ok ? 'Password changed' : 'Current password is incorrect',
        toastType: ok ? ToastType.success : ToastType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final AuthState authState = ref.watch(authNotifierProvider);
    final UserModel? user = authState.user;
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(32, 32, 32, 48),
              child: Column(
                children: [
                  // Avatar + name header
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      user.initials,
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user.displayName,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  // Stats row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _StatBadge(label: 'Ratings', value: '${user.totalRatings}'),
                      const SizedBox(width: 12),
                      if (user.favoriteGenres.isNotEmpty)
                        _StatBadge(label: 'Top Genre', value: user.favoriteGenres.first),
                    ],
                  ),
                  if (user.createdAt != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Member since ${_formatDate(user.createdAt!)}',
                      style: const TextStyle(fontSize: 12, color: AppColors.grey500),
                    ),
                  ],

                  const SizedBox(height: 36),

                  // ── Profile Info Section ──
                  _SectionCard(
                    title: 'Profile Information',
                    trailing: _editingProfile
                        ? null
                        : _TextAction(label: 'Edit', onTap: () => setState(() => _editingProfile = true)),
                    children: [
                      if (_editingProfile) ...[
                        _InputField(label: 'First Name', controller: _firstNameCtrl),
                        const SizedBox(height: 16),
                        _InputField(label: 'Last Name', controller: _lastNameCtrl),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: _ActionBtn(
                                label: 'Cancel',
                                outlined: true,
                                onTap: () {
                                  setState(() => _editingProfile = false);
                                  _firstNameCtrl.text = user.firstName ?? '';
                                  _lastNameCtrl.text = user.lastName ?? '';
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _ActionBtn(
                                label: _savingProfile ? 'Saving...' : 'Save',
                                onTap: _savingProfile ? null : _saveProfile,
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        _InfoRow(label: 'First Name', value: user.firstName ?? '-'),
                        _InfoRow(label: 'Last Name', value: user.lastName ?? '-'),
                        _InfoRow(label: 'Email', value: user.email),
                      ],
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ── Change Password Section ──
                  _SectionCard(
                    title: 'Security',
                    trailing: _changingPassword
                        ? null
                        : _TextAction(label: 'Change Password', onTap: () => setState(() => _changingPassword = true)),
                    children: [
                      if (_changingPassword) ...[
                        _InputField(
                          label: 'Current Password',
                          controller: _currentPassCtrl,
                          obscure: _obscureCurrent,
                          onToggleObscure: () => setState(() => _obscureCurrent = !_obscureCurrent),
                        ),
                        const SizedBox(height: 16),
                        _InputField(
                          label: 'New Password',
                          controller: _newPassCtrl,
                          obscure: _obscureNew,
                          onToggleObscure: () => setState(() => _obscureNew = !_obscureNew),
                        ),
                        const SizedBox(height: 16),
                        _InputField(
                          label: 'Confirm New Password',
                          controller: _confirmPassCtrl,
                          obscure: _obscureNew,
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: _ActionBtn(
                                label: 'Cancel',
                                outlined: true,
                                onTap: () {
                                  setState(() => _changingPassword = false);
                                  _currentPassCtrl.clear();
                                  _newPassCtrl.clear();
                                  _confirmPassCtrl.clear();
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _ActionBtn(
                                label: _savingPassword ? 'Saving...' : 'Change Password',
                                onTap: _savingPassword ? null : _changePassword,
                              ),
                            ),
                          ],
                        ),
                      ] else
                        const Text(
                          'Keep your account secure by using a strong password.',
                          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Logout
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await ref.read(authNotifierProvider.notifier).signOut();
                        if (context.mounted) {
                          ToastService.instance.show(
                            context: context,
                            title: 'Logged out',
                            toastType: ToastType.info,
                          );
                          context.go(AppRoutes.login);
                        }
                      },
                      icon: SvgIcon(SvgPaths.logout, size: 18, color: AppColors.primary),
                      label: const Text('Log Out'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const List<String> months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}

// ── Widgets ──

class _StatBadge extends StatelessWidget {
  const _StatBadge({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children, this.trailing});
  final String title;
  final Widget? trailing;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
              const Spacer(),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  const _InputField({required this.label, required this.controller, this.obscure = false, this.onToggleObscure});
  final String label;
  final TextEditingController controller;
  final bool obscure;
  final VoidCallback? onToggleObscure;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        Container(
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFF0A0A0A),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF2A2A2A)),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscure,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            cursorColor: AppColors.primary,
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              suffixIcon: onToggleObscure != null
                  ? IconButton(
                      onPressed: onToggleObscure,
                      icon: Icon(
                        obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: AppColors.grey500,
                        size: 18,
                      ),
                    )
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}

class _TextAction extends StatefulWidget {
  const _TextAction({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  State<_TextAction> createState() => _TextActionState();
}

class _TextActionState extends State<_TextAction> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Text(
          widget.label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: _hovering ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({required this.label, this.outlined = false, this.onTap});
  final String label;
  final bool outlined;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    if (outlined) {
      return SizedBox(
        height: 42,
        child: OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: Color(0xFF3A3A3A)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ),
      );
    }
    return SizedBox(
      height: 42,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
