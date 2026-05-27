import 'package:flutter/material.dart';
import 'package:movie_recommender_web/theme/app_color.dart';

class GenrePill extends StatefulWidget {
  const GenrePill({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    super.key,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<GenrePill> createState() => _GenrePillState();
}

class _GenrePillState extends State<GenrePill> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final Color bg = widget.isSelected
        ? AppColors.primary
        : _hovering
            ? const Color(0xFF1E1E1E)
            : const Color(0xFF141414);
    final Color border = widget.isSelected
        ? AppColors.primary
        : _hovering
            ? const Color(0xFF3A3A3A)
            : const Color(0xFF252525);
    final Color fg = widget.isSelected
        ? Colors.white
        : (_hovering ? Colors.white70 : AppColors.textSecondary);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(widget.icon, size: 15, color: fg),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
