class RatingModel {
  final int id;
  final int userId;
  final int movieId;
  final String movieTitle;
  final double rating;
  final String? comment;
  final DateTime? timestamp;

  const RatingModel({
    required this.id,
    required this.userId,
    required this.movieId,
    this.movieTitle = '',
    required this.rating,
    this.comment,
    this.timestamp,
  });

  factory RatingModel.fromMap(Map<String, dynamic> map) {
    return RatingModel(
      id: map['id'] as int,
      userId: map['user_id'] as int,
      movieId: map['movie_id'] as int,
      movieTitle: map['movie_title'] as String? ?? '',
      rating: (map['rating'] as num).toDouble(),
      comment: map['comment'] as String?,
      timestamp: map['timestamp'] != null
          ? DateTime.tryParse(map['timestamp'] as String)
          : null,
    );
  }
}

class MovieReviewModel {
  final int id;
  final int userId;
  final String userName;
  final int movieId;
  final double rating;
  final String comment;
  final DateTime? timestamp;

  const MovieReviewModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.movieId,
    required this.rating,
    required this.comment,
    this.timestamp,
  });

  factory MovieReviewModel.fromMap(Map<String, dynamic> map) {
    return MovieReviewModel(
      id: map['id'] as int,
      userId: map['user_id'] as int,
      userName: map['user_name'] as String? ?? 'User',
      movieId: map['movie_id'] as int,
      rating: (map['rating'] as num).toDouble(),
      comment: map['comment'] as String? ?? '',
      timestamp: map['timestamp'] != null
          ? DateTime.tryParse(map['timestamp'] as String)
          : null,
    );
  }
}
