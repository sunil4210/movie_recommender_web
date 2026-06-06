# CineMatch - Movie Recommender Web App

A Flutter web application for personalized movie recommendations, powered by a User-User Collaborative Filtering backend.

## Features

- **Personalized Recommendations** - User-User CF suggestions ("users with similar taste also liked these")
- **Dedicated Recommendations Tab** - Full-grid view of personalized picks
- **Time-Based Greeting** - "Good morning/afternoon/evening, {first name}" on home
- **Search & Filter** - Search movies by title and filter by genre (selected genre is shown on each result card)
- **Movie Details** - View movie info, ratings, similar movies, and the first 5 user reviews
- **Rate Movies** - Rate movies (1-5 stars) to improve recommendations
- **Reviews** - Write an optional comment with each rating; details page shows a "Your Rating" card with Edit; full reviews list with sort (newest/oldest/highest/lowest) lives at `/movie/:movieId/reviews` and pins the viewer's own review at the top
- **Favorites** - Save and manage favorite movies; "MY LIST" button on home routes here
- **User Profiles** - First name + last name + email registration (no username); profile edit + change password
- **Email OTP Auth** - Signup requires email verification via a 6-digit code; "Forgot password" flow uses the same OTP screen to reset the password
- **Onboarding** - New user onboarding flow to collect initial ratings
- **Responsive UI** - Material Design with custom theming

## Tech Stack

- **Framework**: Flutter 3.9+ (Web)
- **State Management**: Riverpod
- **Routing**: GoRouter (with auth guards)
- **HTTP Client**: http + pretty_http_logger
- **UI**: Google Fonts, Flutter SVG, Toastification

## Prerequisites

- Flutter SDK 3.9.2+
- Dart SDK 3.9.2+
- Chrome browser (for web development)
- Backend server running (see [backend README](../backend/README.md))

## Setup & Run

### 1. Navigate to the frontend directory

```bash
cd movie_recommender_web
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Start the backend server

The app connects to `http://localhost:8000/api` by default. Make sure the backend is running:

```bash
cd ../backend
source venv/bin/activate
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### 4. Run the app

The app is configured to always run on **port 3000**.

```bash
./run.sh
```

or equivalently:

```bash
flutter run -d chrome --web-port=3000 --web-hostname=localhost
```

In VS Code, use the **"Flutter Web (Chrome :3000)"** launch configuration (see `.vscode/launch.json`).

App opens at `http://localhost:3000`.

### 5. Build for production

```bash
flutter build web
```

The build output will be in `build/web/`.

## Configuration

### API Base URL

The backend URL is configured in `lib/core/constants/api_constants.dart`:

```dart
static const String baseUrl = 'http://localhost:8000/api';
```

Update this if your backend runs on a different host or port.

## Project Structure

```
movie_recommender_web/
├── lib/
│   ├── main.dart                   # App entry point
│   ├── core/
│   │   ├── constants/              # API, app, and asset constants
│   │   ├── utils/                  # Validators and utilities
│   │   ├── exceptions/             # Error handling (Failure, AsyncResult)
│   │   ├── extensions/             # Context, string, theme extensions
│   │   ├── components/             # Reusable UI (buttons, forms, dialogs)
│   │   └── router/                 # GoRouter config with auth guards
│   ├── models/                     # Data models (Movie, User, Rating, MovieReview)
│   ├── notifiers/                  # Riverpod state management
│   │   ├── auth/                   # Auth state and notifier
│   │   ├── movie/                  # Movie state and notifier
│   │   └── favorites/              # Favorites state and notifier
│   ├── pages/                      # Feature screens
│   │   ├── auth/                   # Login, register, forgot password, verify-OTP, reset-password
│   │   ├── home/                   # Home with recommendations
│   │   ├── movie/                  # Movie details + dedicated reviews page
│   │   ├── search/                 # Search page
│   │   ├── favorites/              # Favorites list
│   │   ├── profile/                # User profile
│   │   ├── onboarding/             # New user onboarding
│   │   ├── filter/                 # Genre filtering
│   │   └── shell/                  # Bottom navigation shell
│   ├── services/                   # API services
│   │   ├── auth_service.dart       # Auth API calls
│   │   ├── database_service.dart   # Movie/rating/favorites API
│   │   └── toast_service.dart      # Toast notifications
│   ├── theme/                      # App theme and colors
│   └── widgets/                    # Reusable widgets
├── test/                           # Widget tests
├── assets/
│   ├── data/                       # Local JSON data
│   ├── svgs/                       # SVG assets
│   └── images/                     # Image assets
└── pubspec.yaml                    # Dependencies
```

## Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| flutter_riverpod | ^2.6.1 | State management |
| go_router | ^14.8.1 | Declarative routing |
| google_fonts | ^6.2.1 | Custom typography |
| flutter_svg | ^2.0.17 | SVG rendering |
| toastification | ^2.3.0 | Toast notifications |
| http | ^1.2.1 | HTTP client |
| pretty_http_logger | ^1.0.5 | HTTP request logging|
