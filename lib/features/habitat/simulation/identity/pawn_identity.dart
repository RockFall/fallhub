import '../mirror/mirror_signal.dart';

/// Who the pawn represents in the Habitat (MD 08 M17).
enum PawnIdentityKind {
  self,
  resident,
  personProxy,
  fictional,
  pet,
}

/// Opaque future binding to Fallhub domain entities.
class HabitatIdentityBinding {
  const HabitatIdentityBinding({
    required this.pawnId,
    required this.kind,
    this.externalEntityType,
    this.externalEntityId,
    this.isPrimarySelf = false,
  });

  final String pawnId;
  final PawnIdentityKind kind;
  final String? externalEntityType;
  final String? externalEntityId;
  final bool isPrimarySelf;

  /// Personal embodied signals (sleep/health) only for primary self.
  bool get receivesPersonalEmbodiedSignals =>
      isPrimarySelf && kind == PawnIdentityKind.self;

  HabitatIdentityBinding copyWith({
    PawnIdentityKind? kind,
    String? externalEntityType,
    String? externalEntityId,
    bool? isPrimarySelf,
  }) {
    return HabitatIdentityBinding(
      pawnId: pawnId,
      kind: kind ?? this.kind,
      externalEntityType: externalEntityType ?? this.externalEntityType,
      externalEntityId: externalEntityId ?? this.externalEntityId,
      isPrimarySelf: isPrimarySelf ?? this.isPrimarySelf,
    );
  }
}

class HabitatIdentityRegistry {
  final Map<String, HabitatIdentityBinding> _byId = {};

  HabitatIdentityBinding? operator [](String pawnId) => _byId[pawnId];

  HabitatIdentityBinding ensure(
    String pawnId, {
    PawnIdentityKind? kind,
    bool? isPrimarySelf,
  }) {
    final existing = _byId[pawnId];
    if (existing != null) {
      if (kind != null || isPrimarySelf != null) {
        final next = existing.copyWith(
          kind: kind,
          isPrimarySelf: isPrimarySelf,
        );
        _byId[pawnId] = next;
        return next;
      }
      return existing;
    }
    final created = HabitatIdentityBinding(
      pawnId: pawnId,
      kind: kind ??
          (isPrimarySelf == true
              ? PawnIdentityKind.self
              : PawnIdentityKind.resident),
      isPrimarySelf: isPrimarySelf ?? false,
    );
    _byId[pawnId] = created;
    return created;
  }

  String? get primarySelfId {
    for (final b in _byId.values) {
      if (b.isPrimarySelf) return b.pawnId;
    }
    return null;
  }

  /// Person proxies must not receive personal health/sleep signals by default.
  bool allowPersonalSignals(String pawnId) {
    final b = _byId[pawnId];
    if (b == null) return true;
    if (b.kind == PawnIdentityKind.personProxy) return false;
    if (b.kind == PawnIdentityKind.pet) return false;
    return true;
  }

  MirrorSignal<String> kindSignal(String pawnId) {
    final b = ensure(pawnId);
    return MirrorSignal<String>(
      id: 'identity.kind.$pawnId',
      value: b.kind.name,
      source: MirrorSignalSource.simulated,
      observedAt: DateTime.now().toUtc(),
      confidence: 1,
      isSensitive: b.kind == PawnIdentityKind.personProxy,
    );
  }
}
