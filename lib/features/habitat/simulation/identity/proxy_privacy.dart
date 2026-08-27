import '../identity/pawn_identity.dart';
import '../mirror/mirror_signal.dart';

/// What a person-proxy may expose (MD 08 M45).
enum ProxyDataScope {
  identity,
  appearance,
  knownInterests,
  relationshipContext,
  scheduledPresence,
  sharedMemories,
  publicNotes,
}

/// Forbidden by default for proxies (never treat as real intimate data).
enum ProxyForbiddenSignal {
  realHealth,
  realSleep,
  realMood,
  realLocation,
  privateCalendar,
  privateDeviceState,
}

class ProxyPrivacyPolicy {
  static const allowedByDefault = {
    ProxyDataScope.identity,
    ProxyDataScope.appearance,
    ProxyDataScope.knownInterests,
    ProxyDataScope.relationshipContext,
    ProxyDataScope.scheduledPresence,
    ProxyDataScope.sharedMemories,
    ProxyDataScope.publicNotes,
  };

  /// Conceptual future consent; empty = no multiplayer consent yet.
  final Map<String, Set<String>> consentScopes = {};

  bool allowsScope(String pawnId, ProxyDataScope scope) {
    final extra = consentScopes[pawnId];
    if (extra != null && extra.contains(scope.name)) return true;
    return allowedByDefault.contains(scope);
  }

  /// Reject attaching personal intimate signals to a personProxy.
  bool mayAttachPersonalSignal({
    required PawnIdentityKind kind,
    required bool isSensitiveIntimate,
  }) {
    if (kind != PawnIdentityKind.personProxy) return true;
    return !isSensitiveIntimate;
  }

  String labelForNeed(String needName, {required bool isProxy}) {
    if (!isProxy) return needName;
    return '$needName (simulated character state)';
  }

  /// Redact sensitive values for logs / screenshots.
  String redactLog(MirrorSignal<Object?> signal) {
    if (signal.isSensitive) return '${signal.id}=[redacted]';
    return '${signal.id}=${signal.value}';
  }
}
