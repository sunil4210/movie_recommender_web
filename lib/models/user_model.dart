/// Immutable representation of an authenticated user.
///
/// User identity is **first name + last name + email** — there is no username field.
/// The backend stores an internal `username` column (auto-generated at signup) but
/// the frontend never reads or shows it.
class UserModel {
  final int id;
  final String email;
  final String? firstName;
  final String? lastName;
  final int? age;
  final String? gender;
  final int totalRatings;
  final List<String> favoriteGenres;
  final DateTime? createdAt;

  const UserModel({
    required this.id,
    required this.email,
    this.firstName,
    this.lastName,
    this.age,
    this.gender,
    this.totalRatings = 0,
    this.favoriteGenres = const [],
    this.createdAt,
  });

  /// Best human-readable name to display in the UI.
  /// Fallback chain: "First Last" → "First" → email local part.
  String get displayName {
    if (firstName != null && firstName!.isNotEmpty) {
      if (lastName != null && lastName!.isNotEmpty) {
        return '$firstName $lastName';
      }
      return firstName!;
    }
    return email.split('@').first;
  }

  /// 1-2 character initials for avatar placeholders.
  /// Fallback chain: "FL" → "F" → first letter of email.
  String get initials {
    if (firstName != null && firstName!.isNotEmpty) {
      final String first = firstName![0].toUpperCase();
      if (lastName != null && lastName!.isNotEmpty) {
        return '$first${lastName![0].toUpperCase()}';
      }
      return first;
    }
    return email.isNotEmpty ? email[0].toUpperCase() : 'U';
  }

  /// For backwards compatibility with pages using userId as String
  String get userId => id.toString();

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as int,
      email: map['email'] as String,
      firstName: map['first_name'] as String?,
      lastName: map['last_name'] as String?,
      age: map['age'] as int?,
      gender: map['gender'] as String?,
      totalRatings: (map['total_ratings'] as num?)?.toInt() ?? 0,
      favoriteGenres: List<String>.from(map['favorite_genres'] ?? []),
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'age': age,
      'gender': gender,
      'total_ratings': totalRatings,
      'favorite_genres': favoriteGenres,
    };
  }

  UserModel copyWith({
    int? id,
    String? email,
    String? firstName,
    String? lastName,
    int? age,
    String? gender,
    int? totalRatings,
    List<String>? favoriteGenres,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      totalRatings: totalRatings ?? this.totalRatings,
      favoriteGenres: favoriteGenres ?? this.favoriteGenres,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
