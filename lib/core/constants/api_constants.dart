/// All HTTP endpoint URLs the app talks to.
///
/// Services MUST go through this class — never hand-roll a path. Keeps
/// `baseUrl` swappable across environments and turns a backend route rename
/// into a one-file change.
class ApiConstants {
  ApiConstants._();

  static const String baseUrl = 'http://localhost:8000/api';

  // Auth
  static String authLogin = '$baseUrl/auth/login';
  static String authSignup = '$baseUrl/auth/signup';
  static String authVerifyEmail = '$baseUrl/auth/verify-email';
  static String authResendOtp = '$baseUrl/auth/resend-otp';
  static String authForgotPassword = '$baseUrl/auth/forgot-password';
  static String authResetPassword = '$baseUrl/auth/reset-password';
  static String authMe = '$baseUrl/auth/me';
  static String authProfile = '$baseUrl/auth/profile';
  static String authChangePassword = '$baseUrl/auth/change-password';

  // Movies
  static String movies = '$baseUrl/movies';
  static String moviesSearch = '$baseUrl/movies/search';
  static String moviesPopular = '$baseUrl/movies/popular';
  static String moviesTrending = '$baseUrl/movies/trending';
  static String movieById(int id) => '$baseUrl/movies/$id';
  static String movieTrailer(int id) => '$baseUrl/movies/$id/trailer';

  // Recommendations
  static String recommendationsFor(int userId) =>
      '$baseUrl/recommendations/$userId';
  static String similarMovies(int userId, int movieId) =>
      '$baseUrl/recommendations/$userId/similar/$movieId';

  // Ratings / Reviews
  static String ratings = '$baseUrl/ratings';
  static String reviewsForMovie(int movieId) =>
      '$baseUrl/ratings/movie/$movieId/reviews';
  static String userMovieRating(int userId, int movieId) =>
      '$baseUrl/ratings/user/$userId/movie/$movieId';

  // Favorites
  static String favorites = '$baseUrl/favorites';
  static String favoritesForUser(int userId) => '$baseUrl/favorites/$userId';
  static String favoriteByUserMovie(int userId, int movieId) =>
      '$baseUrl/favorites/$userId/$movieId';

  // Feedback
  static String feedback = '$baseUrl/feedback';
}
