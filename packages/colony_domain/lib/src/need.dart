import 'package:equatable/equatable.dart';

import 'enums.dart';
import 'id_generator.dart';
import 'need_enums.dart';

class NeedDefinition extends Equatable {
  const NeedDefinition({
    required this.id,
    required this.profileId,
    required this.name,
    required this.slug,
    required this.calculationMode,
    required this.privacyClass,
    required this.createdAt,
    required this.updatedAt,
    this.preferredMin = 0.5,
    this.preferredMax = 0.85,
    this.validitySeconds = 86400,
    this.isEnabled = true,
    this.isSubjective = true,
    this.sortOrder = 0,
  });

  final EntityId id;
  final EntityId profileId;
  final String name;
  final String slug;
  final CalculationMode calculationMode;
  final double preferredMin;
  final double preferredMax;
  final int validitySeconds;
  final NeedPrivacyClass privacyClass;
  final bool isEnabled;
  final bool isSubjective;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  NeedDefinition copyWith({
    String? name,
    String? slug,
    NeedPrivacyClass? privacyClass,
    bool? isEnabled,
    bool? isSubjective,
    int? sortOrder,
    DateTime? updatedAt,
  }) {
    return NeedDefinition(
      id: id,
      profileId: profileId,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      calculationMode: calculationMode,
      privacyClass: privacyClass ?? this.privacyClass,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      preferredMin: preferredMin,
      preferredMax: preferredMax,
      validitySeconds: validitySeconds,
      isEnabled: isEnabled ?? this.isEnabled,
      isSubjective: isSubjective ?? this.isSubjective,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  List<Object?> get props => [
    id,
    profileId,
    name,
    slug,
    calculationMode,
    preferredMin,
    preferredMax,
    validitySeconds,
    privacyClass,
    isEnabled,
    isSubjective,
    sortOrder,
    createdAt,
    updatedAt,
  ];
}

class NeedReading extends Equatable {
  const NeedReading({
    required this.id,
    required this.needId,
    required this.observedAt,
    required this.sourceType,
    required this.createdAt,
    this.normalizedValue,
    this.rawValue,
    this.rawUnit,
    this.confidence = 1.0,
    this.note,
    this.sourceId,
  });

  final EntityId id;
  final EntityId needId;
  final DateTime observedAt;
  final double? normalizedValue;
  final double? rawValue;
  final String? rawUnit;
  final SourceType sourceType;
  final String? sourceId;
  final double confidence;
  final String? note;
  final DateTime createdAt;

  factory NeedReading.manual({
    required EntityId id,
    required EntityId needId,
    required double normalizedValue,
    required DateTime observedAt,
    required DateTime createdAt,
    String? note,
  }) {
    return NeedReading(
      id: id,
      needId: needId,
      observedAt: observedAt,
      normalizedValue: normalizedValue.clamp(0, 1),
      sourceType: SourceType.manual,
      confidence: 1.0,
      note: note,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    needId,
    observedAt,
    normalizedValue,
    rawValue,
    rawUnit,
    sourceType,
    sourceId,
    confidence,
    note,
    createdAt,
  ];
}

class NeedSnapshot extends Equatable {
  const NeedSnapshot({
    required this.definition,
    this.latestReading,
    required this.freshness,
    required this.confidence,
    required this.sourceSummary,
    required this.statusText,
  });

  final NeedDefinition definition;
  final NeedReading? latestReading;
  final DataFreshness freshness;
  final ConfidenceLevel confidence;
  final String sourceSummary;
  final String statusText;

  double? get normalizedValue => latestReading?.normalizedValue;

  @override
  List<Object?> get props => [
    definition,
    latestReading,
    freshness,
    confidence,
    sourceSummary,
    statusText,
  ];
}

abstract final class NeedSnapshotCalculator {
  static NeedSnapshot build(
    NeedDefinition definition,
    NeedReading? reading,
    DateTime now,
  ) {
    if (reading == null) {
      return NeedSnapshot(
        definition: definition,
        freshness: DataFreshness.unknown,
        confidence: ConfidenceLevel.insufficient,
        sourceSummary: 'Sem registro',
        statusText: 'Desconhecido',
      );
    }

    final age = now.difference(reading.observedAt);
    final validity = Duration(seconds: definition.validitySeconds);
    final freshness = age <= validity
        ? DataFreshness.current
        : age <= validity * 2
        ? DataFreshness.recent
        : DataFreshness.stale;

    final value = reading.normalizedValue;
    final statusText = value == null
        ? 'Desconhecido'
        : _statusLabel(value, definition);

    return NeedSnapshot(
      definition: definition,
      latestReading: reading,
      freshness: freshness,
      confidence: reading.confidence >= 0.8
          ? ConfidenceLevel.high
          : reading.confidence >= 0.5
          ? ConfidenceLevel.medium
          : ConfidenceLevel.low,
      sourceSummary: reading.sourceType == SourceType.manual
          ? 'Informado por você'
          : reading.sourceType.name,
      statusText: statusText,
    );
  }

  static String _statusLabel(double value, NeedDefinition definition) {
    if (value < definition.preferredMin * 0.7) return 'Baixo';
    if (value < definition.preferredMin) return 'Atenção';
    if (value <= definition.preferredMax) return 'Na faixa';
    return 'Alto';
  }
}

class NeedSeed extends Equatable {
  const NeedSeed({
    required this.name,
    required this.slug,
    required this.subjective,
    this.privacyClass = NeedPrivacyClass.standard,
    this.aliases = const [],
  });

  final String name;
  final String slug;
  final bool subjective;
  final NeedPrivacyClass privacyClass;
  final List<String> aliases;

  bool matchesSlug(String value) => value == slug || aliases.contains(value);

  @override
  List<Object?> get props => [name, slug, subjective, privacyClass, aliases];
}

/// Catalog of needs shown on the pawn inspect. Humor is tracked via check-in.
abstract final class DefaultNeedSeeds {
  static const core = <NeedSeed>[
    NeedSeed(name: 'Sono', slug: 'sono', subjective: false),
    NeedSeed(name: 'Alimentação', slug: 'alimentacao', subjective: true),
    NeedSeed(
      name: 'Lazer',
      slug: 'lazer',
      subjective: true,
      aliases: ['descanso'],
    ),
    NeedSeed(
      name: 'Social',
      slug: 'social',
      subjective: true,
      aliases: ['conexao_social'],
    ),
    NeedSeed(name: 'Higiene', slug: 'higiene', subjective: true),
    NeedSeed(name: 'Organização', slug: 'organizacao', subjective: true),
    NeedSeed(name: 'Ar livre', slug: 'ar_livre', subjective: true),
    NeedSeed(
      name: 'Sexo',
      slug: 'sexo',
      subjective: true,
      privacyClass: NeedPrivacyClass.highlySensitive,
    ),
    NeedSeed(name: 'Realização', slug: 'realizacao', subjective: true),
    NeedSeed(
      name: 'Foco',
      slug: 'foco',
      subjective: true,
      aliases: ['foco_mental'],
    ),
    NeedSeed(name: 'Movimento', slug: 'movimento', subjective: false),
    NeedSeed(
      name: 'Ansiedade',
      slug: 'ansiedade',
      subjective: true,
      privacyClass: NeedPrivacyClass.sensitive,
    ),
  ];
}

class NeedHistorySample extends Equatable {
  const NeedHistorySample({
    required this.id,
    required this.observedAt,
    this.value,
    this.note,
  });

  final EntityId id;
  final DateTime observedAt;
  final double? value;
  final String? note;

  @override
  List<Object?> get props => [id, observedAt, value, note];
}

class NeedDayBucket extends Equatable {
  const NeedDayBucket({
    required this.day,
    this.value,
    this.sourceId,
    this.note,
  });

  /// Local calendar day at 00:00.
  final DateTime day;
  final double? value;
  final EntityId? sourceId;
  final String? note;

  @override
  List<Object?> get props => [day, value, sourceId, note];
}

abstract final class NeedHistorySeries {
  static List<NeedDayBucket> lastLocalDays({
    required DateTime nowLocal,
    required List<NeedHistorySample> samples,
    int days = 7,
  }) {
    final today = DateTime(nowLocal.year, nowLocal.month, nowLocal.day);
    final byDay = <DateTime, NeedHistorySample>{};
    for (final sample in samples) {
      final local = sample.observedAt.toLocal();
      final key = DateTime(local.year, local.month, local.day);
      final previous = byDay[key];
      if (previous == null ||
          sample.observedAt.isAfter(previous.observedAt) ||
          sample.observedAt.isAtSameMomentAs(previous.observedAt)) {
        byDay[key] = sample;
      }
    }

    return List.generate(days, (i) {
      final day = today.subtract(Duration(days: days - 1 - i));
      final sample = byDay[day];
      return NeedDayBucket(
        day: day,
        value: sample?.value,
        sourceId: sample?.id,
        note: sample?.note,
      );
    });
  }
}
