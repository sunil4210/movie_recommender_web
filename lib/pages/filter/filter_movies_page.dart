import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:movie_recommender_web/theme/app_color.dart';
import 'package:movie_recommender_web/widgets/circle_button.dart';

class FilterMoviesPage extends StatefulWidget {
  const FilterMoviesPage({super.key});

  @override
  State<FilterMoviesPage> createState() => _FilterMoviesPageState();
}

class _FilterMoviesPageState extends State<FilterMoviesPage> {
  final Set<String> _selectedGenres = {};
  final Set<String> _selectedRatings = {};

  static const List<_GenreOption> _genres = [
    _GenreOption('Action', Icons.local_fire_department),
    _GenreOption('Comedy', Icons.sentiment_very_satisfied),
    _GenreOption('Drama', Icons.theater_comedy),
    _GenreOption('Horror', Icons.dark_mode),
    _GenreOption('Sci-Fi', Icons.rocket_launch),
    _GenreOption('Romance', Icons.favorite),
    _GenreOption('Thriller', Icons.psychology),
    _GenreOption('Animation', Icons.animation),
    _GenreOption('Adventure', Icons.explore),
    _GenreOption('Children\'s', Icons.child_care),
    _GenreOption('Crime', Icons.gavel),
    _GenreOption('Documentary', Icons.videocam),
    _GenreOption('Fantasy', Icons.auto_awesome),
    _GenreOption('Mystery', Icons.search),
    _GenreOption('War', Icons.shield),
    _GenreOption('Musical', Icons.music_note),
    _GenreOption('Western', Icons.landscape),
    _GenreOption('Film-Noir', Icons.contrast),
  ];

  static const List<String> _ratingOptions = ['4+ Stars', '3+ Stars', '2+ Stars'];

  void _resetFilters() {
    setState(() {
      _selectedGenres.clear();
      _selectedRatings.clear();
    });
  }

  void _applyFilters() {
    context.pop(_selectedGenres.toList());
  }

  int get _activeCount => _selectedGenres.length + _selectedRatings.length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                child: SafeArea(
                  bottom: false,
                  child: Row(
                    children: [
                      CircleButton(
                        icon: Icons.arrow_back,
                        onTap: () => context.pop(),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          'Filter Movies',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      if (_activeCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$_activeCount active',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Genre section
                      const _SectionLabel(label: 'Genres'),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: _genres.map((g) {
                          final bool selected = _selectedGenres.contains(g.name);
                          return _FilterChip(
                            label: g.name,
                            icon: g.icon,
                            isSelected: selected,
                            onTap: () {
                              setState(() {
                                if (selected) {
                                  _selectedGenres.remove(g.name);
                                } else {
                                  _selectedGenres.add(g.name);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 32),

                      // Rating section
                      const _SectionLabel(label: 'Minimum Rating'),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: _ratingOptions.map((String r) {
                          final bool selected = _selectedRatings.contains(r);
                          return _FilterChip(
                            label: r,
                            icon: Icons.star_rounded,
                            iconColor: AppColors.ratingFilled,
                            isSelected: selected,
                            onTap: () {
                              setState(() {
                                _selectedRatings.clear();
                                if (!selected) _selectedRatings.add(r);
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom action bar
              Container(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Color(0xFF2A2A2A)),
                  ),
                ),
                child: Row(
                  children: [
                    // Reset
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          onPressed: _activeCount > 0 ? _resetFilters : null,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: BorderSide(
                              color: _activeCount > 0
                                  ? const Color(0xFF3A3A3A)
                                  : const Color(0xFF2A2A2A),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Reset',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Apply
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _applyFilters,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            _activeCount > 0
                                ? 'Apply Filters ($_activeCount)'
                                : 'Show All Movies',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _FilterChip extends StatefulWidget {
  const _FilterChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.iconColor,
  });

  final String label;
  final IconData icon;
  final Color? iconColor;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_FilterChip> createState() => _FilterChipState();
}

class _FilterChipState extends State<_FilterChip> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final Color bg = widget.isSelected
        ? AppColors.primary.withValues(alpha: 0.15)
        : _hovering
            ? const Color(0xFF1E1E1E)
            : const Color(0xFF151515);
    final Color border = widget.isSelected
        ? AppColors.primary.withValues(alpha: 0.4)
        : _hovering
            ? const Color(0xFF3A3A3A)
            : const Color(0xFF2A2A2A);
    final Color fg = widget.isSelected ? Colors.white : AppColors.textSecondary;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 16,
                color: widget.isSelected
                    ? (widget.iconColor ?? AppColors.primary)
                    : (widget.iconColor?.withValues(alpha: 0.5) ?? AppColors.grey400),
              ),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: fg,
                ),
              ),
              if (widget.isSelected) ...[
                const SizedBox(width: 6),
                const Icon(Icons.check, size: 14, color: AppColors.primary),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _GenreOption {
  const _GenreOption(this.name, this.icon);
  final String name;
  final IconData icon;
}
