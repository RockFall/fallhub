import 'dart:async';

import 'package:colony_design_system/colony_design_system.dart';
import 'package:flame/game.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/app_strings.dart';
import '../application/ambient_weather.dart';
import '../application/colony_roster.dart';
import '../application/habitat_chrome_provider.dart';
import '../application/habitat_map_store.dart';
import '../application/habitat_zone_store.dart';
import '../flame/habitat_prop_catalog.dart';
import '../flame/habitat_game.dart';
import '../flame/habitat_locations.dart';
import 'widgets/habitat_ambient_hud.dart';
import 'widgets/habitat_editor_bar.dart';
import 'widgets/habitat_location_bar.dart';
import 'widgets/habitat_room_stats_strip.dart';
import 'widgets/habitat_roster_bar.dart';

/// Living Habitat — full-bleed scene; inspect is a tiny HUD readout.
class HabitatScreen extends ConsumerStatefulWidget {
  const HabitatScreen({super.key});

  @override
  ConsumerState<HabitatScreen> createState() => _HabitatScreenState();
}

class _HabitatScreenState extends ConsumerState<HabitatScreen> {
  late HabitatGame _game;
  HabitatSelection? _selection;
  bool _editMode = false;
  bool _switching = false;
  bool _panning = false;
  double _sceneOpacity = 1;
  String _locationId = HabitatLocationIds.bedroom;
  final GlobalKey _gameKey = GlobalKey();
  Timer? _presenceTick;
  Timer? _persistDebounce;
  bool _mapsHydrated = false;
  bool _mapsDirty = false;

  /// Pinch zoom tracked outside Flame so ScaleRecognizer does not steal taps.
  final Map<int, Offset> _pointers = {};
  double? _pinchStartZoom;
  double? _pinchStartDistance;
  Offset? _pinchStartMid;
  Vector2? _pinchStartCam;
  Offset? _primaryDown;
  bool _primaryPanCandidate = false;

  @override
  void initState() {
    super.initState();
    final roster = ref.read(colonyRosterProvider);
    _game = _buildGame(roster);
    unawaited(_hydrateMaps());
    _presenceTick = Timer.periodic(const Duration(milliseconds: 400), (_) {
      if (!mounted || !_game.sceneReady) return;
      _publishChrome();
      // Refresh HUD job status while a pawn is selected.
      if (_selection is HabitatPawnSelection) setState(() {});
    });
  }

  @override
  void dispose() {
    _presenceTick?.cancel();
    _persistDebounce?.cancel();
    unawaited(_persistMapsNow());
    _game.dispose();
    super.dispose();
  }

  Future<void> _hydrateMaps() async {
    if (_mapsHydrated || _mapsDirty) return;
    final saved = await HabitatMapStore.load();
    if (!mounted || _mapsDirty) {
      _mapsHydrated = true;
      return;
    }
    if (saved != null) {
      _game.restoreWorld(
        locationId: saved.locationId,
        maps: saved.maps,
      );
      setState(() {
        _locationId = _game.locationId;
        _selection = null;
      });
      _publishChrome();
    }
    final zones = await HabitatZoneStore.load();
    if (mounted) {
      _game.allowedZones = zones;
    }
    _mapsHydrated = true;
  }

  void _schedulePersistMaps() {
    _mapsDirty = true;
    _persistDebounce?.cancel();
    _persistDebounce = Timer(const Duration(milliseconds: 350), () {
      unawaited(_persistMapsNow());
    });
  }

  Future<void> _persistMapsNow() async {
    await HabitatMapStore.save(
      HabitatWorldSave(
        locationId: _game.locationId,
        maps: _game.exportMaps(),
      ),
    );
    await HabitatZoneStore.save(_game.allowedZones);
  }

  void _publishChrome() {
    ref.read(habitatChromeProvider.notifier).publish(
          HabitatChromeSnapshot(
            locationId: _locationId,
            phaseLabel: _game.presence.phaseLabel,
            muted: _game.presence.muted,
          ),
        );
  }

  HabitatGame _buildGame(List<ColonyMember> roster) {
    return HabitatGame(
      roster: roster,
      onSelectionChanged: (sel) {
        if (!mounted) return;
        setState(() => _selection = sel);
      },
      onContextMenu: ({required selection, required cell, required canvasPosition}) {
        if (!mounted) return;
        _showContextMenu(selection, cell, canvasPosition);
      },
      onSceneReady: () {
        if (!mounted) return;
        _game.syncRoster(ref.read(colonyRosterProvider));
        _refresh();
      },
      onMapsChanged: _schedulePersistMaps,
    );
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _toggleEditMode() {
    setState(() {
      _editMode = !_editMode;
      _game.setEditMode(_editMode);
      if (_editMode) _selection = null;
    });
  }

  Future<void> _switchLocation(String id) async {
    if (_switching || id == _locationId) return;
    setState(() {
      _switching = true;
      _sceneOpacity = 0;
      if (_editMode) {
        _editMode = false;
        _game.setEditMode(false);
      }
    });
    await Future<void>.delayed(const Duration(milliseconds: 140));
    if (!mounted) return;
    _game.switchLocation(id);
    setState(() {
      _locationId = id;
      _selection = null;
      _sceneOpacity = 1;
      _switching = false;
    });
    _publishChrome();
  }

  Offset? _globalFromCanvas(Offset canvasPosition) {
    final box = _gameKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    return box.localToGlobal(canvasPosition);
  }

  void _showContextMenu(
    HabitatSelection? selection,
    (int, int) cell,
    Offset canvasPosition,
  ) {
    final items = <ColonyFloatMenuItem>[];

    // Draft: hold on pawn (or roster). Orders: tap cell/prop while drafted.
    // Context menu keeps secondary actions only.
    switch (selection) {
      case HabitatPawnSelection(:final pawn):
        if (pawn.drafted) {
          items.add(
            ColonyFloatMenuItem(
              label: AppStrings.habitatActionUndraft,
              icon: Icons.directions_walk,
              onSelected: () {
                _game.undraft();
                _refresh();
              },
            ),
          );
        } else {
          items.add(
            ColonyFloatMenuItem(
              label: AppStrings.habitatActionDraft,
              icon: Icons.person_pin_circle_outlined,
              onSelected: () {
                _game.draftPawn(pawn);
                _refresh();
              },
            ),
          );
        }
        items.add(
          ColonyFloatMenuItem(
            label: _game.followFocused
                ? AppStrings.habitatActionUnfollowCam
                : AppStrings.habitatActionFollowCam,
            icon: Icons.videocam_outlined,
            onSelected: () {
              _game.draftPawn(pawn);
              _game.setFollowFocused(!_game.followFocused);
              _refresh();
            },
          ),
        );
        items.add(
          ColonyFloatMenuItem(
            label: AppStrings.habitatActionCustomize,
            icon: Icons.face_retouching_natural,
            onSelected: () => context.go(
              '/colony/pawn-create?memberId=${pawn.memberId}',
            ),
          ),
        );
      case HabitatPropSelection(:final prop):
        items.add(
          ColonyFloatMenuItem(
            label: AppStrings.habitatPropQualityValue(
              HabitatPropCatalog.qualityLabel(prop.quality),
            ),
            icon: Icons.star_outline,
            onSelected: () {
              _game.cyclePropQuality(prop);
              _refresh();
            },
          ),
        );
        if (prop.kind == HabitatPropKinds.instrument) {
          items.add(
            ColonyFloatMenuItem(
              label: AppStrings.musicAtlasFromHabitat,
              icon: Icons.album_outlined,
              onSelected: () => context.go('/research/music-atlas'),
            ),
          );
        }
      case HabitatCellSelection():
      case null:
        if (_game.draftedPawn != null &&
            _game.map.isWalkable(cell.$1, cell.$2)) {
          items.add(
            ColonyFloatMenuItem(
              label: AppStrings.habitatActionGoHere,
              icon: Icons.flag_outlined,
              onSelected: () {
                _game.issueHoldOrder(
                  cell: cell,
                  hit: HabitatCellSelection(cell),
                );
                _refresh();
              },
            ),
          );
        }
    }

    if (items.isEmpty) return;
    showColonyFloatMenu(
      context: context,
      title: AppStrings.habitatFloatMenuTitle,
      items: items,
      anchorGlobal: _globalFromCanvas(canvasPosition),
    );
  }

  @override
  Widget build(BuildContext context) {
    final roster = ref.watch(colonyRosterProvider);
    ref.listen(ambientWeatherProvider, (prev, next) {
      if (!_game.sceneReady) return;
      _game.setOutdoorTemperature(next.asData?.value.temperatureC);
    });
    final weatherNow = ref.watch(ambientWeatherProvider).asData?.value;
    if (_game.sceneReady && weatherNow != null) {
      _game.setOutdoorTemperature(weatherNow.temperatureC);
    }
    ref.listen(colonyRosterProvider, (prev, next) {
      if (!_game.sceneReady) return;
      _game.syncRoster(next);
      _refresh();
    });

    final gameView = ColonySurface(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: AnimatedOpacity(
          opacity: _sceneOpacity,
          duration: const Duration(milliseconds: 160),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Listener(
                onPointerHover: (e) {
                  if (!_editMode) return;
                  final box = _gameKey.currentContext?.findRenderObject()
                      as RenderBox?;
                  if (box == null || !box.hasSize) return;
                  final local = box.globalToLocal(e.position);
                  final world = _game.camera.globalToLocal(
                    Vector2(local.dx, local.dy),
                  );
                  final cell = (
                    (world.x / _game.tileSize).floor(),
                    (world.y / _game.tileSize).floor(),
                  );
                  if (_game.hoverCell == cell) return;
                  _game.setHoverCell(cell);
                },
                onPointerDown: (e) {
                  final box = _gameKey.currentContext?.findRenderObject()
                      as RenderBox?;
                  if (box == null || !box.hasSize) return;
                  final local = box.globalToLocal(e.position);
                  _pointers[e.pointer] = local;
                  final middle = e.buttons & kMiddleMouseButton != 0;
                  final secondary = e.buttons & kSecondaryMouseButton != 0;
                  if (middle || secondary) {
                    _panning = true;
                    _primaryPanCandidate = false;
                    _game.beginPan(local);
                  } else if (e.buttons & kPrimaryButton != 0 &&
                      !_editMode &&
                      _game.canPanCamera &&
                      _pointers.length == 1) {
                    // Drag-to-pan when zoomed in (tap still works under threshold).
                    _primaryDown = local;
                    _primaryPanCandidate = true;
                  }
                  if (_pointers.length == 2) {
                    final pts = _pointers.values.toList();
                    _pinchStartZoom = _game.camera.viewfinder.zoom;
                    _pinchStartDistance = (pts[0] - pts[1]).distance;
                    _pinchStartMid = Offset(
                      (pts[0].dx + pts[1].dx) / 2,
                      (pts[0].dy + pts[1].dy) / 2,
                    );
                    _pinchStartCam = _game.camera.viewfinder.position.clone();
                    _primaryPanCandidate = false;
                    _primaryDown = null;
                  }
                },
                onPointerMove: (e) {
                  final box = _gameKey.currentContext?.findRenderObject()
                      as RenderBox?;
                  if (box == null || !box.hasSize) return;
                  final local = box.globalToLocal(e.position);
                  if (_pointers.containsKey(e.pointer)) {
                    _pointers[e.pointer] = local;
                  }
                  if (_primaryPanCandidate &&
                      !_panning &&
                      _primaryDown != null &&
                      _game.canPanCamera) {
                    final moved = (local - _primaryDown!).distance;
                    if (moved >= 8) {
                      _panning = true;
                      _primaryPanCandidate = false;
                      _game.suppressNextPlayTap();
                      _game.beginPan(_primaryDown!);
                    }
                  }
                  if (_panning) {
                    _game.updatePan(local);
                  }
                  final startZ = _pinchStartZoom;
                  final startD = _pinchStartDistance;
                  final startMid = _pinchStartMid;
                  final startCam = _pinchStartCam;
                  if (startZ != null &&
                      startD != null &&
                      startMid != null &&
                      startCam != null &&
                      startD > 12 &&
                      _pointers.length >= 2) {
                    final pts = _pointers.values.toList();
                    final dist = (pts[0] - pts[1]).distance;
                    final mid = Offset(
                      (pts[0].dx + pts[1].dx) / 2,
                      (pts[0].dy + pts[1].dy) / 2,
                    );
                    _game.camera.viewfinder.zoom = startZ;
                    _game.camera.viewfinder.position = startCam.clone();
                    _game.zoomTo(
                      startZ * (dist / startD),
                      focusCanvas: startMid,
                    );
                    // Two-finger pan within the zoomed clamp.
                    _game.panByScreen(mid - startMid);
                  }
                },
                onPointerUp: (e) {
                  _pointers.remove(e.pointer);
                  if (_pointers.length < 2) {
                    _pinchStartZoom = null;
                    _pinchStartDistance = null;
                    _pinchStartMid = null;
                    _pinchStartCam = null;
                  }
                  _primaryDown = null;
                  _primaryPanCandidate = false;
                  if (!_panning) return;
                  _panning = false;
                  _game.endPan();
                },
                onPointerCancel: (e) {
                  _pointers.remove(e.pointer);
                  _pinchStartZoom = null;
                  _pinchStartDistance = null;
                  _pinchStartMid = null;
                  _pinchStartCam = null;
                  _primaryDown = null;
                  _primaryPanCandidate = false;
                  _panning = false;
                  _game.endPan();
                },
                child: GameWidget(
                  key: _gameKey,
                  game: _game,
                  loadingBuilder: (_) => const ColoredBox(
                    color: Color(0xFF15191D),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(strokeWidth: 2),
                          SizedBox(height: ColonySpacing.md),
                          Text(
                            AppStrings.loading,
                            style: TextStyle(color: ColonyColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ),
                  errorBuilder: (_, error) => ColoredBox(
                    color: const Color(0xFF15191D),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(ColonySpacing.lg),
                        child: Text(
                          '${AppStrings.errorGeneric}\n\n$error',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: ColonyColors.textMuted),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // RimWorld colonist bar + room stats (V9.7) under it.
              Positioned(
                top: ColonySpacing.sm,
                left: ColonySpacing.sm,
                right: ColonySpacing.sm,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Align(
                      alignment: Alignment.topCenter,
                      child: HabitatRosterBar(
                        game: _game,
                        roster: roster,
                        onChanged: _refresh,
                        onRemove: (id) async {
                          final ok = await ref
                              .read(colonyRosterProvider.notifier)
                              .remove(id);
                          if (ok && mounted) {
                            _game.syncRoster(ref.read(colonyRosterProvider));
                            _refresh();
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: ColonySpacing.xs),
                    Align(
                      alignment: Alignment.topCenter,
                      child: HabitatRoomStatsStrip(game: _game),
                    ),
                  ],
                ),
              ),
              if (_editMode)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: HabitatEditorBar(
                    game: _game,
                    onChanged: _refresh,
                    onDone: _toggleEditMode,
                  ),
                )
              else ...[
                Positioned(
                  left: ColonySpacing.sm,
                  bottom: ColonySpacing.sm,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Tooltip(
                        message: AppStrings.habitatActionSweepClean,
                        child: ColonyButton(
                          onPressed: _game.isSweepCleaning
                              ? null
                              : () {
                                  final ok = _game.startSweepClean();
                                  if (!ok) return;
                                  _game.onSweepCleanFinished = () {
                                    final p = _game.focusedPawn ??
                                        (_game.pawns.isEmpty
                                            ? null
                                            : _game.pawns.first);
                                    if (p != null) {
                                      _game.pushBubble(
                                        p,
                                        AppStrings.habitatBubbleSweepDone,
                                      );
                                    }
                                    if (mounted) setState(() {});
                                  };
                                  setState(() {});
                                },
                          variant: _game.isSweepCleaning
                              ? ColonyButtonVariant.action
                              : ColonyButtonVariant.subtle,
                          height: 44,
                          minWidth: 44,
                          padding: EdgeInsets.zero,
                          child: Icon(
                            Icons.cleaning_services_outlined,
                            size: 22,
                            color: _game.isSweepCleaning
                                ? const Color(0xFF7EC8FF)
                                : Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: ColonySpacing.xs),
                      Tooltip(
                        message: _game.beautyOverlayOn
                            ? AppStrings.habitatBeautyOverlayOn
                            : AppStrings.habitatBeautyOverlayOff,
                        child: ColonyButton(
                          onPressed: () {
                            setState(() {
                              _game.setBeautyOverlay(!_game.beautyOverlayOn);
                            });
                          },
                          variant: _game.beautyOverlayOn
                              ? ColonyButtonVariant.action
                              : ColonyButtonVariant.subtle,
                          height: 44,
                          minWidth: 44,
                          padding: EdgeInsets.zero,
                          child: Icon(
                            Icons.palette_outlined,
                            size: 22,
                            color: _game.beautyOverlayOn
                                ? const Color(0xFF3DB86A)
                                : Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: ColonySpacing.xs),
                      Tooltip(
                        message: AppStrings.habitatSelectLocation,
                        child: ColonyButton(
                          onPressed: _switching ? null : _openLocationPicker,
                          variant: ColonyButtonVariant.subtle,
                          height: 44,
                          minWidth: 44,
                          padding: EdgeInsets.zero,
                          child: const Icon(
                            Icons.map,
                            size: 22,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: ColonySpacing.xs),
                      Tooltip(
                        message: AppStrings.habitatEditRoom,
                        child: ColonyButton(
                          onPressed: _toggleEditMode,
                          variant: ColonyButtonVariant.subtle,
                          height: 44,
                          minWidth: 44,
                          padding: EdgeInsets.zero,
                          child: const Icon(
                            Icons.handyman,
                            size: 22,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                HabitatAmbientHud(game: _game, selection: _selection),
              ],
            ],
          ),
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.all(ColonySpacing.md),
      child: gameView,
    );
  }

  void _openLocationPicker() {
    HabitatLocationsUi.showPicker(
      context: context,
      selectedId: _locationId,
      onSelected: _switchLocation,
    );
  }
}
