import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movie_recommender_web/services/service_providers.dart';
import 'package:movie_recommender_web/services/toast_service.dart';
import 'package:movie_recommender_web/theme/app_color.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

/// Modal dialog that plays a movie's YouTube trailer.
///
/// Fetches the YouTube key from the backend on open. Shows a spinner while
/// loading, a friendly "no trailer" state when the backend returns 404, and
/// the inline player when a key arrives.
class TrailerDialog extends ConsumerStatefulWidget {
  const TrailerDialog({
    required this.movieId,
    required this.movieTitle,
    super.key,
  });

  final int movieId;
  final String movieTitle;

  /// Convenience: show the dialog as a barrier-dimmed modal. Returns when the
  /// user dismisses the dialog.
  static Future<void> show(
    BuildContext context, {
    required int movieId,
    required String movieTitle,
  }) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder: (_) => TrailerDialog(
        movieId: movieId,
        movieTitle: movieTitle,
      ),
    );
  }

  @override
  ConsumerState<TrailerDialog> createState() => _TrailerDialogState();
}

class _TrailerDialogState extends ConsumerState<TrailerDialog> {
  YoutubePlayerController? _controller;
  bool _loading = true;
  bool _notFound = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    final result =
        await ref.read(movieServiceProvider).trailerKey(widget.movieId);

    if (!mounted) return;

    result.when(
      success: (String? key) {
        if (key == null) {
          setState(() {
            _loading = false;
            _notFound = true;
          });
          return;
        }
        setState(() {
          _loading = false;
          _controller = YoutubePlayerController.fromVideoId(
            videoId: key,
            autoPlay: true,
            params: const YoutubePlayerParams(
              showControls: true,
              showFullscreenButton: true,
              strictRelatedVideos: true,
            ),
          );
        });
      },
      failure: (exception) {
        setState(() {
          _loading = false;
          _errorMessage = exception.message;
        });
        ToastService.instance.show(
          context: context,
          title: 'Failed to load trailer',
          toastType: ToastType.error,
        );
      },
    );
  }

  @override
  void dispose() {
    _controller?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double maxWidth =
        MediaQuery.of(context).size.width.clamp(320, 960).toDouble();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        // Absorb taps anywhere inside the dialog chrome so they never bleed
        // through to widgets behind the modal route (e.g. the navbar profile
        // icon when the dialog sits over the top-right corner).
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {},
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF151515),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF2A2A2A)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.6),
                  blurRadius: 40,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(context),
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(16),
                  ),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: ColoredBox(
                      color: Colors.black,
                      child: _buildContent(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 8, 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.play_arrow_rounded,
              color: AppColors.primary,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'TRAILER',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.movieTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _CloseButton(onTap: () => Navigator.of(context).pop()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    if (_notFound) {
      return const _PlaceholderState(
        icon: Icons.movie_filter_outlined,
        title: 'No trailer available',
        message: 'TMDB does not have a trailer on file for this title.',
      );
    }
    if (_errorMessage != null) {
      return _PlaceholderState(
        icon: Icons.error_outline,
        title: 'Could not load trailer',
        message: _errorMessage!,
      );
    }
    if (_controller == null) {
      return const SizedBox.shrink();
    }
    return YoutubePlayer(controller: _controller!);
  }
}

class _CloseButton extends StatefulWidget {
  const _CloseButton({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_CloseButton> createState() => _CloseButtonState();
}

class _CloseButtonState extends State<_CloseButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      // HitTestBehavior.opaque guarantees the whole 36x36 box swallows the
      // tap — important because the dialog can overlap the navbar profile
      // icon on wide screens, and we don't want clicks bleeding through.
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: _hovering
                ? AppColors.error.withValues(alpha: 0.18)
                : Colors.white.withValues(alpha: 0.06),
            shape: BoxShape.circle,
            border: Border.all(
              color: _hovering
                  ? AppColors.error.withValues(alpha: 0.5)
                  : const Color(0xFF2A2A2A),
            ),
          ),
          child: Icon(
            Icons.close_rounded,
            size: 18,
            color: _hovering ? AppColors.error : Colors.white,
          ),
        ),
      ),
    );
  }
}

class _PlaceholderState extends StatelessWidget {
  const _PlaceholderState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white70, size: 40),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
