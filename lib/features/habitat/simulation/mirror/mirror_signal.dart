/// Origin of a value that may later be driven by real-world data.
///
/// `simulated` must never silently promote to `externalObserved`.
enum MirrorSignalSource {
  simulated,
  manual,
  userDeclared,
  externalObserved,
  externalDerived,
  systemDerived,
  unknown,
}

/// Habitat value with provenance and confidence (MD 08 §5).
///
/// Pure Dart — no Flutter. Simulation and UI consume this contract so future
/// adapters can replace the source without rewriting directors.
class MirrorSignal<T> {
  MirrorSignal({
    required this.id,
    required this.value,
    required this.source,
    required this.observedAt,
    required double confidence,
    this.validUntil,
    this.sourceRef,
    List<String> transformationChain = const [],
    this.isSensitive = false,
  })  : confidence = MirrorSignal.clampConfidence(confidence),
        transformationChain = List.unmodifiable(transformationChain);

  final String id;
  final T value;
  final MirrorSignalSource source;
  final DateTime observedAt;
  final DateTime? validUntil;

  /// Always in `0..1` (clamped on construction).
  final double confidence;

  /// Opaque reference to an external record (adapter id, future).
  final String? sourceRef;

  /// Ordered derivation steps / input signal ids.
  final List<String> transformationChain;

  final bool isSensitive;

  static double clampConfidence(double c) {
    if (c.isNaN) return 0;
    if (c < 0) return 0;
    if (c > 1) return 1;
    return c;
  }

  /// Copy with a new value / metadata; chain can only grow or stay.
  MirrorSignal<T> copyWith({
    T? value,
    MirrorSignalSource? source,
    DateTime? observedAt,
    DateTime? validUntil,
    double? confidence,
    String? sourceRef,
    List<String>? transformationChain,
    bool? isSensitive,
    bool clearValidUntil = false,
  }) {
    return MirrorSignal<T>(
      id: id,
      value: value ?? this.value,
      source: source ?? this.source,
      observedAt: observedAt ?? this.observedAt,
      validUntil: clearValidUntil ? null : (validUntil ?? this.validUntil),
      confidence: confidence ?? this.confidence,
      sourceRef: sourceRef ?? this.sourceRef,
      transformationChain: transformationChain ?? this.transformationChain,
      isSensitive: isSensitive ?? this.isSensitive,
    );
  }

  /// Derive a new signal from this one, appending [step] to the chain.
  MirrorSignal<R> derive<R>({
    required String id,
    required R value,
    required MirrorSignalSource source,
    required DateTime observedAt,
    required double confidence,
    required String step,
    DateTime? validUntil,
    String? sourceRef,
    bool isSensitive = false,
  }) {
    return MirrorSignal<R>(
      id: id,
      value: value,
      source: source,
      observedAt: observedAt,
      validUntil: validUntil,
      confidence: confidence,
      sourceRef: sourceRef,
      transformationChain: [...transformationChain, step],
      isSensitive: isSensitive,
    );
  }

  @override
  String toString() =>
      'MirrorSignal<$T>(id=$id, source=$source, confidence=$confidence)';
}
