import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/localization/app_strings.dart';
import '../../application/ambient_weather.dart';
import '../../flame/habitat_game.dart';
import '../../flame/habitat_map.dart';

/// Bottom-right stack: optional selection name on top, then clock / temp / weather.
class HabitatAmbientHud extends ConsumerStatefulWidget {
  const HabitatAmbientHud({super.key, required this.game, this.selection});

  final HabitatGame game;
  final HabitatSelection? selection;

  @override
  ConsumerState<HabitatAmbientHud> createState() => _HabitatAmbientHudState();
}

class _HabitatAmbientHudState extends ConsumerState<HabitatAmbientHud> {
  late DateTime _now;
  Timer? _clock;

  static const _style = TextStyle(
    color: Colors.white,
    fontSize: 12,
    height: 1.25,
    fontWeight: FontWeight.w500,
    shadows: [
      Shadow(
        color: Color(0xCC000000),
        blurRadius: 4,
        offset: Offset(0, 1),
      ),
    ],
  );

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _clock = Timer.periodic(const Duration(seconds: 20), (_) {
      if (!mounted) return;
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  String _outdoorTempLabel(AmbientWeather? w) {
    final t = w?.temperatureC;
    if (t == null) return AppStrings.habitatAmbientTempPlaceholder;
    return '${t.round()}°C';
  }

  String _indoorTempLabel() {
    final indoor = widget.game.indoorTemperatureC.round();
    return '${AppStrings.habitatIndoorTemp} $indoor°C';
  }

  String _climateLabel(AmbientWeather? w) {
    if (w == null || w.isPlaceholder || w.weatherCode == null) {
      return AppStrings.habitatAmbientWeatherPlaceholder;
    }
    return ambientWeatherLabel(w.weatherCode);
  }

  String _floorLabel(HabitatFloor f) => switch (f) {
        HabitatFloor.wood => AppStrings.habitatFloorWood,
        HabitatFloor.carpet => AppStrings.habitatFloorCarpet,
        HabitatFloor.concrete => AppStrings.habitatFloorConcrete,
      };

  String? get _selectionLine {
    return switch (widget.selection) {
      null => null,
      HabitatPawnSelection(:final pawn) => pawn.displayName,
      HabitatPropSelection(:final prop) => prop.name,
      HabitatCellSelection(:final cell) => _cellLabel(cell),
    };
  }

  String _cellLabel((int, int) cell) {
    final map = widget.game.map;
    final (x, y) = cell;
    if (map.doorCell == cell) return AppStrings.habitatEditToolDoor;
    if (map.isWallCell(x, y)) return AppStrings.habitatEditToolWall;
    return _floorLabel(map.floorAt(x, y));
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(ambientWeatherProvider);
    final weather = async.asData?.value;
    final time = DateFormat.Hm().format(_now);
    final selectionLine = _selectionLine;

    return IgnorePointer(
      child: Align(
        alignment: Alignment.bottomRight,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (selectionLine != null)
                Text(
                  selectionLine,
                  textAlign: TextAlign.right,
                  style: _style,
                ),
              Text(time, textAlign: TextAlign.right, style: _style),
              Text(
                _outdoorTempLabel(weather),
                textAlign: TextAlign.right,
                style: _style,
              ),
              Text(
                _indoorTempLabel(),
                textAlign: TextAlign.right,
                style: _style,
              ),
              Text(
                _climateLabel(weather),
                textAlign: TextAlign.right,
                style: _style,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
