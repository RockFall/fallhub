import 'package:equatable/equatable.dart';

import 'financial_account.dart';
import 'id_generator.dart';
import 'ledger_transaction.dart';

/// Raw notification as captured on-device (ADR-011).
class CapturedNotification extends Equatable {
  const CapturedNotification({
    required this.id,
    required this.profileId,
    required this.packageName,
    required this.title,
    required this.text,
    required this.postedAt,
    required this.nativeKey,
    required this.extractorKind,
    required this.createdAt,
    this.appLabel,
    this.ledgerTransactionId,
  });

  final EntityId id;
  final EntityId profileId;
  final String packageName;
  final String? appLabel;
  final String title;
  final String text;
  final DateTime postedAt;
  final String nativeKey;
  final NotificationExtractorKind extractorKind;
  final EntityId? ledgerTransactionId;
  final DateTime createdAt;

  String get combinedText => '$title\n$text'.trim();

  NotificationExtractInput get extractInput => NotificationExtractInput(
        packageName: packageName,
        title: title,
        text: text,
        postedAt: postedAt,
        appLabel: appLabel,
      );

  bool get bookedAsFinance => ledgerTransactionId != null;

  CapturedNotification copyWith({
    EntityId? ledgerTransactionId,
    NotificationExtractorKind? extractorKind,
    bool clearLedgerTransactionId = false,
  }) {
    return CapturedNotification(
      id: id,
      profileId: profileId,
      packageName: packageName,
      title: title,
      text: text,
      postedAt: postedAt,
      nativeKey: nativeKey,
      extractorKind: extractorKind ?? this.extractorKind,
      createdAt: createdAt,
      appLabel: appLabel,
      ledgerTransactionId: clearLedgerTransactionId
          ? null
          : (ledgerTransactionId ?? this.ledgerTransactionId),
    );
  }

  @override
  List<Object?> get props => [
        id,
        profileId,
        packageName,
        appLabel,
        title,
        text,
        postedAt,
        nativeKey,
        extractorKind,
        ledgerTransactionId,
        createdAt,
      ];
}

enum NotificationExtractorKind {
  ignored,
  unknown,
  finance,
}

/// Platform payload before persistence (Android listener / tests).
class NotificationCapturePayload extends Equatable {
  const NotificationCapturePayload({
    required this.nativeKey,
    required this.packageName,
    required this.title,
    required this.text,
    required this.postedAt,
    this.appLabel,
  });

  final String nativeKey;
  final String packageName;
  final String? appLabel;
  final String title;
  final String text;
  final DateTime postedAt;

  NotificationExtractInput get extractInput => NotificationExtractInput(
        packageName: packageName,
        title: title,
        text: text,
        postedAt: postedAt,
        appLabel: appLabel,
      );

  factory NotificationCapturePayload.fromJson(Map<Object?, Object?> json) {
    final postedRaw = json['postedAtMs'];
    final postedMs = postedRaw is int
        ? postedRaw
        : postedRaw is num
            ? postedRaw.toInt()
            : int.tryParse('$postedRaw') ?? 0;
    return NotificationCapturePayload(
      nativeKey: '${json['nativeKey'] ?? ''}',
      packageName: '${json['packageName'] ?? ''}',
      appLabel: json['appLabel'] == null ? null : '${json['appLabel']}',
      title: '${json['title'] ?? ''}',
      text: '${json['text'] ?? ''}',
      postedAt: DateTime.fromMillisecondsSinceEpoch(postedMs, isUtc: true),
    );
  }

  @override
  List<Object?> get props =>
      [nativeKey, packageName, appLabel, title, text, postedAt];
}

/// Input for extractors — no persistence ids required.
class NotificationExtractInput extends Equatable {
  const NotificationExtractInput({
    required this.packageName,
    required this.title,
    required this.text,
    required this.postedAt,
    this.appLabel,
  });

  final String packageName;
  final String? appLabel;
  final String title;
  final String text;
  final DateTime postedAt;

  String get combined => '$title\n$text';

  @override
  List<Object?> get props => [packageName, appLabel, title, text, postedAt];
}

class FinanceSpendCandidate extends Equatable {
  const FinanceSpendCandidate({
    required this.amountMinor,
    required this.currency,
    required this.direction,
    required this.accountType,
    required this.description,
    required this.occurredAt,
    required this.confidence,
  });

  final int amountMinor;
  final String currency;
  final TransactionDirection direction;
  final FinancialAccountType accountType;
  final String description;
  final DateTime occurredAt;
  final double confidence;

  @override
  List<Object?> get props => [
        amountMinor,
        currency,
        direction,
        accountType,
        description,
        occurredAt,
        confidence,
      ];
}

/// Result of persisting one captured notification (OTP may be skipped).
class NotificationIngestResult extends Equatable {
  const NotificationIngestResult({
    required this.skipped,
    this.notification,
    this.transaction,
    this.duplicate = false,
  });

  factory NotificationIngestResult.skipped() =>
      const NotificationIngestResult(skipped: true);

  final bool skipped;
  final CapturedNotification? notification;
  final LedgerTransaction? transaction;
  final bool duplicate;

  @override
  List<Object?> get props => [skipped, notification, transaction, duplicate];
}
