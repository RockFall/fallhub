import 'package:equatable/equatable.dart';

import 'id_generator.dart';
import 'work_enums.dart';

class Bill extends Equatable {
  const Bill({
    required this.id,
    required this.profileId,
    required this.title,
    required this.repeatMode,
    required this.target,
    required this.createdAt,
    required this.updatedAt,
  });

  final EntityId id;
  final EntityId profileId;
  final String title;
  final BillRepeatMode repeatMode;
  final String target;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory Bill.create({
    required EntityId id,
    required EntityId profileId,
    required String title,
    required BillRepeatMode repeatMode,
    required String target,
    required DateTime createdAt,
  }) {
    return Bill(
      id: id,
      profileId: profileId,
      title: title,
      repeatMode: repeatMode,
      target: target,
      createdAt: createdAt,
      updatedAt: createdAt,
    );
  }

  Bill copyWith({
    String? title,
    BillRepeatMode? repeatMode,
    String? target,
    DateTime? updatedAt,
  }) {
    return Bill(
      id: id,
      profileId: profileId,
      title: title ?? this.title,
      repeatMode: repeatMode ?? this.repeatMode,
      target: target ?? this.target,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props =>
      [id, profileId, title, repeatMode, target, createdAt, updatedAt];
}
