import 'package:shared_preferences/shared_preferences.dart';

/// Persists whether the first-run coach mark has already been shown.
abstract interface class OnboardingStore {
  Future<bool> hasSeenCoachMark();

  Future<void> markCoachMarkSeen();
}

/// Real store, backed by `shared_preferences` (Android, iOS, web, Windows,
/// macOS, Linux).
class SharedPreferencesOnboardingStore implements OnboardingStore {
  static const String _key = 'onboarding_coach_mark_seen';

  @override
  Future<bool> hasSeenCoachMark() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(_key) ?? false;
  }

  @override
  Future<void> markCoachMarkSeen() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_key, true);
  }
}

/// In-memory store used by tests and as a safe default when no platform
/// storage is available. Defaults to "seen" so the coach mark stays out of
/// the way unless a test opts in.
class InMemoryOnboardingStore implements OnboardingStore {
  InMemoryOnboardingStore({this.seen = true});

  bool seen;

  @override
  Future<bool> hasSeenCoachMark() async => seen;

  @override
  Future<void> markCoachMarkSeen() async => seen = true;
}
