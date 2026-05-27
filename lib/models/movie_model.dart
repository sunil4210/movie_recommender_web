class MovieModel {
  final int id;
  final String title;
  final List<String> genres;
  final int? releaseYear;
  final double avgRating;
  final int totalRatings;
  final String? posterUrl;
  final String? blurHash;

  const MovieModel({
    required this.id,
    required this.title,
    required this.genres,
    this.releaseYear,
    this.avgRating = 0.0,
    this.totalRatings = 0,
    this.posterUrl,
    this.blurHash,
  });

  /// For backwards compatibility with pages using movieId as String
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
    );
  }

  /// Parse from recommendation endpoint response
  factory MovieModel.fromRecommendation(Map<String, dynamic> map) {
    return MovieModel(
      id: map['movie_id'] as int,
      title: map['title'] as String,
      genres: List<String>.from(map['genres'] ?? []),
      avgRating: (map['predicted_rating'] as num?)?.toDouble() ?? 0.0,
      posterUrl: map['poster_url'] as String?,
      blurHash: map['blur_hash'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'genres': genres,
      'year': releaseYear,
      'average_rating': avgRating,
      'total_ratings': totalRatings,
      'poster_url': posterUrl,
      'blur_hash': blurHash,
    };
  }
}
