import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:movie_recommender_web/core/constants/asset_constants.dart';
import 'package:movie_recommender_web/widgets/svg_icon.dart';
import 'package:movie_recommender_web/core/router/app_router.dart';
import 'package:movie_recommender_web/theme/app_color.dart';
import 'package:movie_recommender_web/widgets/app_logo.dart';

class AppShell extends StatelessWidget {
  const AppShell({required this.child, super.key});

  final Widget child;

  int _currentIndex(BuildContext context) {
    final String location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith(AppRoutes.home)) return 0;
    if (location.startsWith(AppRoutes.recommendations)) return 1;
    if (location.startsWith(AppRoutes.search)) return 2;
    if (location.startsWith(AppRoutes.favorites)) return 3;
    if (location.startsWith(AppRoutes.profile)) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final int currentIndex = _currentIndex(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Column(
        children: [
          // Top Navbar
          _WebNavBar(currentIndex: currentIndex),
          // Page content
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _WebNavBar extends StatelessWidget {
  const _WebNavBar({required this.currentIndex});

  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: Color(0xFF0A0A0A),
        border: Border(
          bottom: BorderSide(color: Color(0xFF2A2A2A), width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        children: [
          // Left: Logo + Nav Links
          Expanded(
            child: Row(
              children: [
                // Logo
                GestureDetector(
                  onTap: () => context.go(AppRoutes.home),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppLogo(size: 32, fontSize: 22, showText: false),
                      SizedBox(width: 10),
                      Text(
                        'CineMatch',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 40),
                // Nav Links
                _NavLink(
                  label: 'Home',
                  isActive: currentIndex == 0,
                  onTap: () => context.go(AppRoutes.home),
                ),
                const SizedBox(width: 24),
                _NavLink(
                  label: 'Recommendations',
                  isActive: currentIndex == 1,
                  onTap: () => context.go(AppRoutes.recommendations),
                ),
                const SizedBox(width: 24),
                _NavLink(
                  label: 'Movies',
                  isActive: currentIndex == 2,
                  onTap: () => context.go(AppRoutes.search),
                ),
                const SizedBox(width: 24),
                _NavLink(
                  label: 'Favourites',
                  isActive: currentIndex == 3,
                  onTap: () => context.go(AppRoutes.favorites),
                ),
              ],
            ),
          ),
          // Right: Search + Profile buttons
          Row(
            children: [
              _CircleNavButton(
                svgPath: SvgPaths.search,
                onTap: () => context.go(AppRoutes.search),
                isActive: currentIndex == 2,
              ),
              const SizedBox(width: 12),
              _CircleNavButton(
                svgPath: SvgPaths.user,
                onTap: () => context.go(AppRoutes.profile),
                isActive: currentIndex == 4,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NavLink extends StatefulWidget {
  const _NavLink({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  State<_NavLink> createState() => _NavLinkState();
}

class _NavLinkState extends State<_NavLink> {
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
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: widget.isActive || _hovering
                ? AppColors.textPrimary
                : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _CircleNavButton extends StatefulWidget {
  const _CircleNavButton({
    required this.svgPath,
    required this.onTap,
    this.isActive = false,
  });

  final String svgPath;
  final VoidCallback onTap;
  final bool isActive;

  @override
  State<_CircleNavButton> createState() => _CircleNavButtonState();
}

class _CircleNavButtonState extends State<_CircleNavButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final bool highlight = _hovering || widget.isActive;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: highlight ? AppColors.primary : const Color(0xFF2A2A2A),
          ),
          child: Center(
            child: SvgIcon(widget.svgPath, size: 20),
          ),
        ),
      ),
    );
  }
}
