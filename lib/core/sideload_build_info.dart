/// Metadados injetados no APK de sideload (`--dart-define` no CI).
abstract final class SideloadBuildInfo {
  static const gitSha = String.fromEnvironment('GIT_SHA');
  static const gitRef = String.fromEnvironment('GIT_REF');
  static const builtAt = String.fromEnvironment('BUILD_TIME');

  static bool get isCiBuild => gitSha.isNotEmpty;

  static String get shortSha {
    if (gitSha.isEmpty) return '';
    return gitSha.length <= 7 ? gitSha : gitSha.substring(0, 7);
  }
}
