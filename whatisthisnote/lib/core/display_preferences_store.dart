import 'package:shared_preferences/shared_preferences.dart';

import 'display_preferences.dart';

/// Loads and saves the user's [DisplayPreferences].
abstract interface class DisplayPreferencesStore {
  Future<DisplayPreferences> load();

  Future<void> save(DisplayPreferences preferences);
}

/// Real store, backed by `shared_preferences` (Android, iOS, web, Windows,
/// macOS, Linux).
class SharedPreferencesDisplayPreferencesStore
    implements DisplayPreferencesStore {
  static const String _namingKey = 'display_naming';
  static const String _staffLabelKey = 'display_show_staff_label';
  static const String _enharmonicKey = 'display_show_enharmonic';

  @override
  Future<DisplayPreferences> load() async {
    final preferences = await SharedPreferences.getInstance();
    return DisplayPreferences(
      naming: _namingFromName(preferences.getString(_namingKey)),
      showStaffLabel: preferences.getBool(_staffLabelKey) ?? true,
      showEnharmonic: preferences.getBool(_enharmonicKey) ?? false,
    );
  }

  @override
  Future<void> save(DisplayPreferences preferences) async {
    final store = await SharedPreferences.getInstance();
    await store.setString(_namingKey, preferences.naming.name);
    await store.setBool(_staffLabelKey, preferences.showStaffLabel);
    await store.setBool(_enharmonicKey, preferences.showEnharmonic);
  }
}

/// Resolves a stored naming-system name, falling back to scientific for
/// missing or unknown values.
NamingSystem _namingFromName(String? name) {
  for (final system in NamingSystem.values) {
    if (system.name == name) return system;
  }
  return NamingSystem.scientific;
}

/// In-memory store used by tests and as a safe default when no platform
/// storage is available. Starts from the built-in defaults.
class InMemoryDisplayPreferencesStore implements DisplayPreferencesStore {
  InMemoryDisplayPreferencesStore({DisplayPreferences? preferences})
    : _preferences = preferences ?? const DisplayPreferences();

  DisplayPreferences _preferences;

  @override
  Future<DisplayPreferences> load() async => _preferences;

  @override
  Future<void> save(DisplayPreferences preferences) async =>
      _preferences = preferences;
}
