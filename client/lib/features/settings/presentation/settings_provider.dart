import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/di/injection.dart';
import '../../auth/data/auth_repository.dart';
import '../data/settings_repository.dart';

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier(getIt<SettingsRepository>(), getIt<AuthRepository>());
});

class SettingsState {
  final bool isLoading;
  final Map<String, dynamic>? settings;
  final String? error;
  final bool sidebarExpanded;

  const SettingsState({
    this.isLoading = false,
    this.settings,
    this.error,
    this.sidebarExpanded = true,
  });

  SettingsState copyWith({
    bool? isLoading,
    Map<String, dynamic>? settings,
    String? error,
    bool? sidebarExpanded,
  }) {
    return SettingsState(
      isLoading: isLoading ?? this.isLoading,
      settings: settings ?? this.settings,
      error: error,
      sidebarExpanded: sidebarExpanded ?? this.sidebarExpanded,
    );
  }

  ThemeMode get themeMode {
    final value = settings?['theme'] as String? ?? 'LIGHT';
    switch (value) {
      case 'LIGHT':
        return ThemeMode.light;
      case 'DARK':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  bool get reviewNotificationEnabled => settings?['reviewNotificationEnabled'] as bool? ?? true;
  String get reviewNotificationTime => settings?['reviewNotificationTime'] as String? ?? '09:00';
  bool get focusNotificationEnabled => settings?['focusNotificationEnabled'] as bool? ?? true;
  int get focusDuration => settings?['focusDuration'] as int? ?? 25;
  int get breakDuration => settings?['breakDuration'] as int? ?? 5;
  int get longBreakDuration => settings?['longBreakDuration'] as int? ?? 15;
  bool get sidebarExpandedValue => !(settings?['sidebarCollapsed'] as bool? ?? false);
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  final SettingsRepository _repository;
  final AuthRepository _auth;

  SettingsNotifier(this._repository, this._auth) : super(const SettingsState()) {
    loadSettings();
  }

  Future<void> loadSettings() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _repository.getSettings();
      state = state.copyWith(isLoading: false, settings: data);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> updateSettings(Map<String, dynamic> updates) async {
    try {
      final data = await _repository.updateSettings(updates);
      state = state.copyWith(settings: data);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    String value;
    switch (mode) {
      case ThemeMode.light:
        value = 'LIGHT';
        break;
      case ThemeMode.dark:
        value = 'DARK';
        break;
      default:
        value = 'LIGHT';
    }
    await updateSettings({'theme': value});
  }

  Future<void> setReviewNotification(bool enabled) async {
    await updateSettings({'reviewNotificationEnabled': enabled});
  }

  Future<void> setFocusNotification(bool enabled) async {
    await updateSettings({'focusNotificationEnabled': enabled});
  }

  Future<void> setReviewNotificationTime(String time) async {
    await updateSettings({'reviewNotificationTime': time});
  }

  Future<void> setFocusDuration(int minutes) async {
    await updateSettings({'focusDuration': minutes});
  }

  Future<void> setBreakDuration(int minutes) async {
    await updateSettings({'breakDuration': minutes});
  }

  Future<void> setLongBreakDuration(int minutes) async {
    await updateSettings({'longBreakDuration': minutes});
  }

  Future<void> setSidebarExpanded(bool expanded) async {
    await updateSettings({'sidebarCollapsed': !expanded});
  }

  Future<void> logout() async {
    await _auth.logout();
  }

  Future<void> syncNow() async {
    try {
      final data = await _repository.syncSettings();
      state = state.copyWith(settings: data);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}