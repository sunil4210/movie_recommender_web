class RatingModel {
  final int id;
  final int userId;
  final int movieId;
  final String movieTitle;
  final double rating;
  final DateTime? timestamp;

  const RatingModel({
    required this.id,
    required this.userId,
    required this.movieId,
    this.movieTitle = '',
    required this.rating,
    this.timestamp,
  });

  factory RatingModel.fromMap(Map<String, dynamic> map) {
    return RatingModel(
      id: map['id'] as int,
      userId: map['user_id'] as int,
      movieId: map['movie_id'] as int,
      movieTitle: map['movie_title'] as String? ?? '',
      rating: (map['rating'] as num).toDouble(),
      timestamp: map['timestamp'] != null
          ? DateTime.tryParse(map['timestamp'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'movie_id': movieId,
      'rating': rating,
    };
  }

  String get ratingId => '${userId}_$movieId';
}
