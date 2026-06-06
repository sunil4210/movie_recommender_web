import 'package:flutter/material.dart';
import 'package:movie_recommender_web/models/movie_model.dart';
import 'package:movie_recommender_web/theme/app_color.dart';
import 'package:movie_recommender_web/widgets/movie_poster.dart';
import 'package:movie_recommender_web/widgets/trailer_dialog.dart';

class MovieCard extends StatefulWidget {
  const MovieCard({
    required this.movie,
    this.onTap,
    this.width = 140,
    this.height = 200,
    this.showTitle = true,
    this.showSubtitle = true,
    this.subtitle,
    super.key,
  });

  final MovieModel movie;
  final VoidCallback? onTap;
  final double width;
  final double height;
  final bool showTitle;
  final bool showSubtitle;
  final String? subtitle;

  @override
  State<MovieCard> createState() => _MovieCardState();
}

class _MovieCardState extends State<MovieCard> {
  bool _hovered = false;

  void _openTrailer() {
    TrailerDialog.show(
      context,
      movieId: widget.movie.id,
      movieTitle: widget.movie.title,
    );
  }

  @override
  Widget build(BuildContext context) {
    final MovieModel movie = widget.movie;

    return RepaintBoundary(
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: SizedBox(
            width: widget.width,
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: widget.width,
                height: widget.height,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: AppColors.backgroundCard,
                  boxShadow: _hovered ? AppShadows.medium : AppShadows.small,
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildPosterImage(),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      height: widget.height * 0.4,
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: AppColors.gradientPosterOverlay,
                          ),
                        ),
                      ),
                    ),
                    if (movie.avgRating > 0)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star, color: AppColors.ratingFilled, size: 12),
                              const SizedBox(width: 2),
                              Text(
                                movie.avgRating.toStringAsFixed(1),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    // Hover overlay with trailer + details CTAs — only renders
                    // on web/desktop when the pointer is over the card.
                    Positioned.fill(
                      child: IgnorePointer(
                        ignoring: !_hovered,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 180),
                          opacity: _hovered ? 1.0 : 0.0,
                          child: ColoredBox(
                            color: Colors.black.withValues(alpha: 0.55),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _HoverActionButton(
                                    icon: Icons.info_outline_rounded,
                                    label: 'View Details',
                                    onTap: widget.onTap ?? () {},
                                  ),
                                  const SizedBox(height: 8),
                                  _HoverActionButton(
                                    icon: Icons.play_arrow_rounded,
                                    label: 'View Trailer',
                                    onTap: _openTrailer,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.showTitle) ...[
                const SizedBox(height: 8),
                Text(
                  movie.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
              if (widget.showSubtitle) ...[
                const SizedBox(height: 2),
                Text(
                  widget.subtitle ??
                      (movie.genres.isNotEmpty ? movie.genres.first : ''),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
          ),
        ),
      ),
    );
  }

  Widget _buildPosterImage() {
    return MoviePoster(
      url: widget.movie.posterUrl,
      blurHash: widget.movie.blurHash,
      width: widget.width,
      height: widget.height,
      fallbackBuilder: (_) => _buildGradientPlaceholder(),
    );
  }

  Widget _buildGradientPlaceholder() {
    final MovieModel movie = widget.movie;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.getGenreColor(
              movie.genres.isNotEmpty ? movie.genres.first : '',
            ).withValues(alpha: 0.8),
            AppColors.primaryDark.withValues(alpha: 0.9),
          ],
        ),
      ),
      child: Center(
        child: Text(
          movie.title.isNotEmpty ? movie.title[0].toUpperCase() : 'M',
          style: TextStyle(
            fontSize: widget.height * 0.3,
            fontWeight: FontWeight.bold,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
      ),
    );
  }
}

class _HoverActionButton extends StatefulWidget {
  const _HoverActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  State<_HoverActionButton> createState() => _HoverActionButtonState();
}

class _HoverActionButtonState extends State<_HoverActionButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final Color bg = _hovering
        ? Colors.white.withValues(alpha: 0.24)
        : Colors.white.withValues(alpha: 0.12);
    final Color border = Colors.white.withValues(alpha: _hovering ? 0.55 : 0.32);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 140),
          scale: _hovering ? 1.04 : 1.0,
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            constraints: const BoxConstraints(minWidth: 130),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: border, width: 1.2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(widget.icon, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text(
                  widget.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MovieCardLarge extends StatelessWidget {
  const MovieCardLarge({
    required this.movie,
    this.onTap,
    super.key,
  });

  final MovieModel movie;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: AppColors.grey200,
          boxShadow: AppShadows.medium,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            MoviePoster(
              url: movie.posterUrl,
              blurHash: movie.blurHash,
              width: double.infinity,
              height: 200,
              fallbackBuilder: (_) => _buildGradientFallback(),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.8),
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      movie.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      movie.genres.join(' | '),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradientFallback() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.getGenreColor(
              movie.genres.isNotEmpty ? movie.genres.first : '',
            ).withValues(alpha: 0.6),
            AppColors.primaryDark,
          ],
        ),
      ),
      child: Center(
        child: Text(
          movie.title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
