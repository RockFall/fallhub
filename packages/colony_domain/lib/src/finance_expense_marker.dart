import 'package:equatable/equatable.dart';

import 'id_generator.dart';

/// Trechos que o usuário exige no texto da notificação para marcar despesa.
class FinanceExpenseMarkerConfig extends Equatable {
  const FinanceExpenseMarkerConfig({
    required this.profileId,
    required this.slices,
    required this.updatedAt,
  });

  final EntityId profileId;

  /// Trechos já normalizados. Lista vazia = detecção automática.
  final List<String> slices;
  final DateTime updatedAt;

  void validate() {
    for (final slice in slices) {
      if (slice != slice.trim() ||
          slice.length < FinanceExpenseMarkerPolicy.minSliceLength) {
        throw ArgumentError.value(
          slice,
          'slices',
          'cada trecho precisa de pelo menos '
          '${FinanceExpenseMarkerPolicy.minSliceLength} caracteres',
        );
      }
    }
  }

  @override
  List<Object?> get props => [profileId, slices, updatedAt];
}

/// Resultado de ler o campo de texto da tela de finanças.
class FinanceExpenseSliceParse extends Equatable {
  const FinanceExpenseSliceParse({
    required this.slices,
    required this.rejectedShort,
  });

  final List<String> slices;
  final bool rejectedShort;

  bool get ok => !rejectedShort;

  @override
  List<Object?> get props => [slices, rejectedShort];
}

/// Casa um pedaço de texto com o título e o corpo da notificação.
abstract final class FinanceExpenseMarkerPolicy {
  static const minSliceLength = 2;

  /// Uma linha por trecho. Linha vazia é ignorada.
  /// [rejectedShort] fica verdadeiro se alguma linha não vazia for curta demais.
  static FinanceExpenseSliceParse parseField(String raw) {
    final slices = <String>[];
    var rejectedShort = false;
    for (final line in raw.split(RegExp(r'\r?\n'))) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      if (trimmed.length < minSliceLength) {
        rejectedShort = true;
        continue;
      }
      final folded = fold(trimmed);
      final duplicate = slices.any((existing) => fold(existing) == folded);
      if (!duplicate) slices.add(trimmed);
    }
    return FinanceExpenseSliceParse(
      slices: slices,
      rejectedShort: rejectedShort,
    );
  }

  static String encodeField(List<String> slices) => slices.join('\n');

  static List<String> normalize(List<String> slices) {
    return parseField(slices.join('\n')).slices;
  }

  /// Verdadeiro quando [notificationText] contém algum trecho.
  /// Lista vazia não casa: a detecção automática fica por conta do extrator.
  static bool matches(String notificationText, List<String> slices) {
    if (slices.isEmpty) return false;
    final haystack = fold(notificationText);
    for (final slice in slices) {
      final needle = fold(slice.trim());
      if (needle.length < minSliceLength) continue;
      if (haystack.contains(needle)) return true;
    }
    return false;
  }

  /// Minúsculas, sem acento, para o trecho "cartao" achar "Cartão".
  static String fold(String value) {
    final lower = value.toLowerCase();
    final buffer = StringBuffer();
    for (final rune in lower.runes) {
      final char = String.fromCharCode(rune);
      buffer.write(_folds[char] ?? char);
    }
    return buffer.toString();
  }

  static const _folds = {
    'á': 'a',
    'à': 'a',
    'â': 'a',
    'ã': 'a',
    'ä': 'a',
    'é': 'e',
    'è': 'e',
    'ê': 'e',
    'ë': 'e',
    'í': 'i',
    'ì': 'i',
    'î': 'i',
    'ï': 'i',
    'ó': 'o',
    'ò': 'o',
    'ô': 'o',
    'õ': 'o',
    'ö': 'o',
    'ú': 'u',
    'ù': 'u',
    'û': 'u',
    'ü': 'u',
    'ç': 'c',
    'ñ': 'n',
  };
}
