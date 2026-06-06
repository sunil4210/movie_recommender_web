import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movie_recommender_web/notifiers/auth/auth_notifier.dart';
import 'package:movie_recommender_web/services/api_client.dart';
import 'package:movie_recommender_web/services/favorite_service.dart';
import 'package:movie_recommender_web/services/feedback_service.dart';
import 'package:movie_recommender_web/services/movie_service.dart';
import 'package:movie_recommender_web/services/rating_service.dart';
import 'package:movie_recommender_web/services/recommendation_service.dart';

/// Single [ApiClient] for the whole app — auth headers come from the live
/// AuthService, so a login propagates instantly to every feature service.
final Provider<ApiClient> apiClientProvider = Provider<ApiClient>((Ref ref) {
  final auth = ref.read(authServiceProvider);
  return ApiClient(getHeaders: () => auth.authHeaders);
});

final Provider<MovieService> movieServiceProvider =
    Provider<MovieService>((Ref ref) => MovieService(ref.read(apiClientProvider)));

final Provider<RecommendationService> recommendationServiceProvider =
    Provider<RecommendationService>(
  (Ref ref) => RecommendationService(ref.read(apiClientProvider)),
);

final Provider<RatingService> ratingServiceProvider = Provider<RatingService>(
  (Ref ref) => RatingService(ref.read(apiClientProvider)),
);

final Provider<FavoriteService> favoriteServiceProvider =
    Provider<FavoriteService>(
  (Ref ref) => FavoriteService(ref.read(apiClientProvider)),
);

final Provider<FeedbackService> feedbackServiceProvider =
    Provider<FeedbackService>(
  (Ref ref) => FeedbackService(ref.read(apiClientProvider)),
);
