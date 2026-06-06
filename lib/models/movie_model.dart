class MovieModel {
  final int id;
  final String title;
  final List<String> genres;
  final int? releaseYear;
  final double avgRating;
  final int totalRatings;
  final String? posterUrl;
  final String? blurHash;
  final String? overview;

  const MovieModel({
    required this.id,
    required this.title,
    required this.genres,
    this.releaseYear,
    this.avgRating = 0.0,
    this.totalRatings = 0,
    this.posterUrl,
    this.blurHash,
    this.overview,
  });

  /// String form of [id]. Several pages use the movie id as a path param
  /// (e.g. `/movie/42`) which must be a string for go_router.
  String get movieId => id.toString();

  factory MovieModel.fromMap(Map<String, dynamic> map) {
    return MovieModel(
      id: map['id'] as int,
      title: map['title'] as String,
      genres: List<String>.from(map['genres'] ?? []),
      releaseYear: map['year'] as int?,
      avgRating: (map['average_rating'] as num?)?.toDouble() ?? 0.0,
      totalRatings: (map['total_ratings'] as num?)?.toInt() ?? 0,
      posterUrl: map['poster_url'] as String?,
      blurHash: map['blur_hash'] as String?,
      overview: map['overview'] as String?,
    );
  }

  /// Recommendation rows use a different shape — `movie_id` instead of `id`,
  /// and `predicted_rating` instead of `average_rating`.
  factory MovieModel.fromRecommendation(Map<String, dynamic> map) {
    return MovieModel(
      id: map['movie_id'] as int,
      title: map['title'] as String,
      genres: List<String>.from(map['genres'] ?? []),
      avgRating: (map['predicted_rating'] as num?)?.toDouble() ?? 0.0,
      posterUrl: map['poster_url'] as String?,
      blurHash: map['blur_hash'] as String?,
      overview: map['overview'] as String?,
    );
  }
}
