import 'package:flutter/material.dart';

class GenreItem {
  const GenreItem({required this.label, required this.icon});
  final String label;
  final IconData icon;
}

const List<GenreItem> kMovieGenres = <GenreItem>[
  GenreItem(label: 'Action', icon: Icons.local_fire_department),
  GenreItem(label: 'Comedy', icon: Icons.sentiment_very_satisfied),
  GenreItem(label: 'Drama', icon: Icons.theater_comedy),
  GenreItem(label: 'Horror', icon: Icons.dark_mode),
  GenreItem(label: 'Romance', icon: Icons.favorite),
  GenreItem(label: 'Sci-Fi', icon: Icons.rocket_launch),
  GenreItem(label: 'Thriller', icon: Icons.psychology),
  GenreItem(label: 'Animation', icon: Icons.animation),
  GenreItem(label: 'Documentary', icon: Icons.live_tv),
  GenreItem(label: 'Adventure', icon: Icons.explore),
];
