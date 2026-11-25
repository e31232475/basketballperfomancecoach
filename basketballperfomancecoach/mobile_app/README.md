# basketball_performance_coach

Flutter athlete app for Basketball Performance Coach.

## Backend connection

The local Android emulator default API is:

```text
http://10.0.2.2:8001/api
```

That points to the same Laravel backend used by `coach_web`
(`http://127.0.0.1:8001/api` on the host machine), so athlete profile updates
such as `gender` and `profile_photo_url` appear in the coach dashboard.

For another backend, build with:

```text
flutter build apk --dart-define=API_BASE_URL=https://your-domain.example/api
```

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
