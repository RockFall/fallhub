import 'health_condition.dart';

/// Stub safety policy (ADR-023): disclaimer only; no urgency term matching.
abstract final class HealthSafetyPolicy {
  static const disclaimer =
      'Registro pessoal local. Não diagnostica, não prescreve e não substitui '
      'atendimento profissional. Procure ajuda se os sintomas forem graves.';

  static const seekCareHint =
      'Se os sintomas forem graves ou persistentes, procure atendimento.';

  static void validateTitle(String title) {
    if (title.trim().isEmpty) {
      throw ArgumentError.value(title, 'title', 'must not be empty');
    }
  }

  static void validateSeverity(int? severity) {
    if (severity == null) return;
    if (severity < 1 || severity > 5) {
      throw ArgumentError.value(
        severity,
        'severityUserReported',
        'must be between 1 and 5',
      );
    }
  }

  static HealthConditionStatus nextStatusOnArchive() =>
      HealthConditionStatus.archived;
}
