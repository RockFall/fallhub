import 'dart:convert';

/// Intent → authority → world (MD 08 M46). No networking.

sealed class HabitatIntent {
  const HabitatIntent({
    required this.id,
    required this.actorId,
    required this.sourceId,
    required this.atSim,
  });

  final String id;
  final String actorId;
  final String sourceId;
  final double atSim;
}

class ApplyScenePresetIntent extends HabitatIntent {
  const ApplyScenePresetIntent({
    required super.id,
    required super.actorId,
    required super.sourceId,
    required super.atSim,
    required this.presetId,
  });
  final String presetId;
}

class StartRoutineIntent extends HabitatIntent {
  const StartRoutineIntent({
    required super.id,
    required super.actorId,
    required super.sourceId,
    required super.atSim,
    required this.routineId,
    required this.pawnId,
  });
  final String routineId;
  final String pawnId;
}

class TravelToSiteIntent extends HabitatIntent {
  const TravelToSiteIntent({
    required super.id,
    required super.actorId,
    required super.sourceId,
    required super.atSim,
    required this.pawnId,
    required this.destinationSiteId,
  });
  final String pawnId;
  final String destinationSiteId;
}

class EquipLoadoutIntent extends HabitatIntent {
  const EquipLoadoutIntent({
    required super.id,
    required super.actorId,
    required super.sourceId,
    required super.atSim,
    required this.pawnId,
    required this.loadoutId,
  });
  final String pawnId;
  final String loadoutId;
}

class PlaceItemIntent extends HabitatIntent {
  const PlaceItemIntent({
    required super.id,
    required super.actorId,
    required super.sourceId,
    required super.atSim,
    required this.itemId,
    required this.containerId,
  });
  final String itemId;
  final String containerId;
}

class HabitatEvent {
  const HabitatEvent({
    required this.kind,
    required this.atSim,
    this.payload = const {},
  });

  final String kind;
  final double atSim;
  final Map<String, Object?> payload;
}

abstract interface class SimulationAuthority {
  List<HabitatEvent> submit(HabitatIntent intent);
  Map<String, Object?> snapshot();
}

/// Local-only authority — future ServerHabitatAuthority swaps here.
class LocalHabitatAuthority implements SimulationAuthority {
  LocalHabitatAuthority({
    required this.applyPreset,
    required this.startRoutine,
    required this.travelTo,
    required this.equipLoadout,
    required this.placeItem,
  });

  final void Function(String presetId, double atSim) applyPreset;
  final void Function(String routineId, String pawnId) startRoutine;
  final void Function(String pawnId, String siteId, double atSim) travelTo;
  final void Function(String pawnId, String loadoutId) equipLoadout;
  final void Function(String itemId, String containerId) placeItem;

  final List<HabitatIntent> applied = [];
  final List<HabitatEvent> events = [];
  int _seq = 0;

  @override
  List<HabitatEvent> submit(HabitatIntent intent) {
    applied.add(intent);
    final out = <HabitatEvent>[];
    switch (intent) {
      case ApplyScenePresetIntent(:final presetId, :final atSim):
        applyPreset(presetId, atSim);
        out.add(HabitatEvent(
          kind: 'presetApplied',
          atSim: atSim,
          payload: {'presetId': presetId, 'actorId': intent.actorId},
        ));
      case StartRoutineIntent(:final routineId, :final pawnId, :final atSim):
        startRoutine(routineId, pawnId);
        out.add(HabitatEvent(
          kind: 'routineStarted',
          atSim: atSim,
          payload: {'routineId': routineId, 'pawnId': pawnId},
        ));
      case TravelToSiteIntent(
          :final pawnId,
          :final destinationSiteId,
          :final atSim
        ):
        travelTo(pawnId, destinationSiteId, atSim);
        out.add(HabitatEvent(
          kind: 'travelStarted',
          atSim: atSim,
          payload: {'pawnId': pawnId, 'siteId': destinationSiteId},
        ));
      case EquipLoadoutIntent(:final pawnId, :final loadoutId, :final atSim):
        equipLoadout(pawnId, loadoutId);
        out.add(HabitatEvent(
          kind: 'loadoutEquipped',
          atSim: atSim,
          payload: {'pawnId': pawnId, 'loadoutId': loadoutId},
        ));
      case PlaceItemIntent(:final itemId, :final containerId, :final atSim):
        placeItem(itemId, containerId);
        out.add(HabitatEvent(
          kind: 'itemPlaced',
          atSim: atSim,
          payload: {'itemId': itemId, 'containerId': containerId},
        ));
    }
    events.addAll(out);
    _seq++;
    return out;
  }

  @override
  Map<String, Object?> snapshot() => {
        'seq': _seq,
        'intents': applied.length,
        'events': [
          for (final e in events)
            {'kind': e.kind, 'atSim': e.atSim, ...e.payload},
        ],
      };

  String snapshotJson() => jsonEncode(snapshot());
}
