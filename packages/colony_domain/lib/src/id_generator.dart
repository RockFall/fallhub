import 'package:equatable/equatable.dart';

/// Generates time-sortable identifiers (UUID v7 when available, v4 fallback).
abstract class IdGenerator {
  String newId();
}

class UuidIdGenerator implements IdGenerator {
  UuidIdGenerator(this._uuidFactory);

  final String Function() _uuidFactory;

  factory UuidIdGenerator.v7(String Function() factory) = UuidIdGenerator;

  @override
  String newId() => _uuidFactory();
}

class FixedIdGenerator implements IdGenerator {
  FixedIdGenerator(this._ids);

  final List<String> _ids;
  var _index = 0;

  @override
  String newId() {
    if (_index >= _ids.length) {
      throw StateError('FixedIdGenerator exhausted');
    }
    return _ids[_index++];
  }
}

class EntityId extends Equatable {
  const EntityId(this.value);

  final String value;

  @override
  List<Object?> get props => [value];

  @override
  String toString() => value;
}
