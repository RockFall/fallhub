import 'package:equatable/equatable.dart';

import 'enums.dart';

class AppPreferences extends Equatable {
  const AppPreferences({
    required this.densityMode,
    required this.themeMode,
    required this.weekStartsOnMonday,
    required this.use24HourFormat,
    required this.sectorsEnabled,
    required this.onboardingCompleted,
    required this.biometricLockEnabled,
    required this.sessionTimeoutMinutes,
  });

  final DensityMode densityMode;
  final ThemeModePreference themeMode;
  final bool weekStartsOnMonday;
  final bool use24HourFormat;
  final List<String> sectorsEnabled;
  final bool onboardingCompleted;
  final bool biometricLockEnabled;
  final int sessionTimeoutMinutes;

  factory AppPreferences.defaults() {
    return const AppPreferences(
      densityMode: DensityMode.management,
      themeMode: ThemeModePreference.dark,
      weekStartsOnMonday: true,
      use24HourFormat: true,
      sectorsEnabled: [],
      onboardingCompleted: false,
      biometricLockEnabled: false,
      sessionTimeoutMinutes: 0,
    );
  }

  AppPreferences copyWith({
    DensityMode? densityMode,
    ThemeModePreference? themeMode,
    bool? weekStartsOnMonday,
    bool? use24HourFormat,
    List<String>? sectorsEnabled,
    bool? onboardingCompleted,
    bool? biometricLockEnabled,
    int? sessionTimeoutMinutes,
  }) {
    return AppPreferences(
      densityMode: densityMode ?? this.densityMode,
      themeMode: themeMode ?? this.themeMode,
      weekStartsOnMonday: weekStartsOnMonday ?? this.weekStartsOnMonday,
      use24HourFormat: use24HourFormat ?? this.use24HourFormat,
      sectorsEnabled: sectorsEnabled ?? this.sectorsEnabled,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      biometricLockEnabled: biometricLockEnabled ?? this.biometricLockEnabled,
      sessionTimeoutMinutes:
          sessionTimeoutMinutes ?? this.sessionTimeoutMinutes,
    );
  }

  @override
  List<Object?> get props => [
        densityMode,
        themeMode,
        weekStartsOnMonday,
        use24HourFormat,
        sectorsEnabled,
        onboardingCompleted,
        biometricLockEnabled,
        sessionTimeoutMinutes,
      ];
}
