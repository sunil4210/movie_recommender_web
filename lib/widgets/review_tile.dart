import 'package:flutter/material.dart';
import 'package:movie_recommender_web/models/rating_model.dart';
import 'package:movie_recommender_web/theme/app_color.dart';

/// Card representing a single user's review of a movie.
///
/// Set [isMine] to badge the tile as the viewer's own review (used as a
/// pinned card on the reviews list page and the details "Your Rating" card).
class ReviewTile extends StatelessWidget {
  const ReviewTile({
    required this.review,
    this.isMine = false,
    this.trailing,
    super.key,
  });

  final MovieReviewModel review;
  final bool isMine;
  final Widget? trailing;

  String _initials() {
    final String name = review.userName.trim();
    if (name.isEmpty) return 'U';
    final List<String> parts = name.split(RegExp(r"\s+"));
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  String _timeAgo(DateTime? ts) {
    if (ts == null) return '';
    final Duration diff = DateTime.now().toUtc().difference(ts.toUtc());
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}mo ago';
    return '${(diff.inDays / 365).floor()}y ago';
  }

  @override
  Widget build(BuildContext context) {
    final Color accent = AppColors.getGenreColor(
        review.userName.isNotEmpty ? review.userName[0] : 'A');
    final Color border = isMine
        ? AppColors.primary.withValues(alpha: 0.45)
        : const Color(0xFF2A2A2A);
    final Color bg = isMine
        ? AppColors.primary.withValues(alpha: 0.08)
        : const Color(0xFF151515);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withValues(alpha: 0.18),
              border: Border.all(color: accent.withValues(alpha: 0.35)),
            ),
            alignment: Alignment.center,
            child: Text(
              _initials(),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: accent,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            review.userName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          if (isMine)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary
                                    .withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppColors.primary
                                      .withValues(alpha: 0.4),
                                ),
                              ),
                              child: const Text(
                                'You',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Text(
                      _timeAgo(review.timestamp),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    for (int i = 1; i <= 5; i++)
                      Icon(
                        i <= review.rating.round()
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: i <= review.rating.round()
                            ? AppColors.ratingFilled
                            : AppColors.grey400,
                        size: 14,
                      ),
                    const SizedBox(width: 6),
                    Text(
                      review.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (review.comment.trim().isNotEmpty)
                  Text(
                    review.comment,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      height: 1.5,
                    ),
                  )
                else
                  const Text(
                    'Rated — no written review',
                    style: TextStyle(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: AppColors.textSecondary,
                    ),
                  ),
                if (trailing != null) ...[
                  const SizedBox(height: 10),
                  trailing!,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
