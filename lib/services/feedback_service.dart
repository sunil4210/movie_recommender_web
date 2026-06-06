import 'package:movie_recommender_web/core/constants/api_constants.dart';
import 'package:movie_recommender_web/core/exceptions/async_result.dart';
import 'package:movie_recommender_web/services/api_client.dart';

/// HTTP wrapper for /api/feedback endpoints (thumbs-up / thumbs-down).
class FeedbackService {
  FeedbackService(this._api);

  final ApiClient _api;

  Future<AsyncResult<void>> submit({
    required int userId,
    required int movieId,
    required String feedbackType,
  }) {
    return runCatching<void>(() async {
      ApiClient.ensureOk(await _api.post(
        Uri.parse(ApiConstants.feedback),
        body: <String, dynamic>{
          'user_id': userId,
          'movie_id': movieId,
          'feedback_type': feedbackType,
        },
      ));
    });
  }
}
