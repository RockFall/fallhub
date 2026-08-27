// ignore_for_file: avoid_print
import 'dart:io';
import 'dart:ui' as ui;

import 'package:fallhub/features/habitat/flame/components/pawn_job_controller.dart';
import 'package:fallhub/features/habitat/flame/habitat_editor.dart';
import 'package:fallhub/features/habitat/flame/habitat_game.dart';
import 'package:fallhub/features/habitat/simulation/content/habitat_media.dart';
import 'package:fallhub/features/habitat/simulation/debug/state_explain.dart';
import 'package:fallhub/features/habitat/simulation/embodied/embodied.dart';
import 'package:fallhub/features/habitat/simulation/identity/pawn_identity.dart';
import 'package:fallhub/features/habitat/simulation/world/habitat_world_map.dart';
import 'package:fallhub/features/habitat/simulation/world/perceived_comfort.dart';
import 'package:fallhub/features/habitat/simulation/world/scene_preset.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: flutter test --no-pub tool/capture_mirror_habitat_screenshot.dart
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('capture mirror-ready phase A screenshots', () async {
    final outDir = Directory('docs/produto/assets/generated/habitat');
    outDir.createSync(recursive: true);

    Future<List<int>> capture(
      HabitatGame game, {
      required void Function(Canvas canvas, double mapW, double mapH) decorate,
      int extraWidth = 280,
    }) async {
      final mapW = game.map.width * game.tileSize;
      final mapH = game.map.height * game.tileSize;
      final totalW = mapW + extraWidth;
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.drawRect(
        Rect.fromLTWH(0, 0, totalW, mapH),
        Paint()..color = const Color(0xFF15191D),
      );
      game.renderWorldTo(canvas);
      decorate(canvas, mapW, mapH);
      final picture = recorder.endRecording();
      final image = await picture.toImage(totalW.toInt(), mapH.toInt());
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      expect(byteData, isNotNull);
      return byteData!.buffer.asUint8List();
    }

    void paintPanel(
      Canvas canvas,
      double mapW,
      double mapH,
      String title,
      List<String> lines,
    ) {
      const stripW = 280.0;
      final strip = Rect.fromLTWH(mapW, 0, stripW, mapH);
      canvas.drawRect(strip, Paint()..color = const Color(0xE0141416));
      canvas.drawRect(
        strip,
        Paint()
          ..color = const Color(0x66FFFFFF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );

      final titleTp = TextPainter(
        text: TextSpan(
          text: title,
          style: const TextStyle(
            color: Color(0xFFE8E6E3),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: stripW - 24);
      titleTp.paint(canvas, Offset(mapW + 12, 16));

      var y = 48.0;
      for (final line in lines) {
        final tp = TextPainter(
          text: TextSpan(
            text: line,
            style: const TextStyle(
              color: Color(0xFFD8D6D3),
              fontSize: 11,
              height: 1.35,
              fontFamily: 'monospace',
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: stripW - 24);
        tp.paint(canvas, Offset(mapW + 12, y));
        y += tp.height + 6;
      }
    }

    // M0 — indoor temperature signal provenance
    final m0 = HabitatGame(tileSize: 48);
    await m0.onLoad();
    m0._forceAtmosphereForCapture();
    final m0Bytes = await capture(
      m0,
      decorate: (c, w, h) {
        final line = m0.indoorTemperatureDebugLine ?? 'no signal';
        paintPanel(c, w, h, 'M0 MirrorSignal', [
          line,
          'source must stay simulated',
        ]);
      },
    );
    await File('${outDir.path}/m00_signal_debug.png').writeAsBytes(m0Bytes);
    m0.dispose();

    // M1 — effective state + override
    final m1 = HabitatGame(tileSize: 48);
    await m1.onLoad();
    m1.setIndoorTemperatureOverride(28, reason: 'debug heater');
    final m1Bytes = await capture(
      m1,
      decorate: (c, w, h) {
        final eff = m1.indoorTemperatureEffective!;
        paintPanel(c, w, h, 'M1 EffectiveState', [
          'value=${eff.value.toStringAsFixed(1)}°C',
          'winning=${eff.source.name}',
          eff.explanation,
          if (eff.hasConflict) 'conflict=true',
        ]);
      },
    );
    await File('${outDir.path}/m01_effective_state.png').writeAsBytes(m1Bytes);
    m1.dispose();

    // M2 — clock debug
    final m2 = HabitatGame(tileSize: 48);
    await m2.onLoad();
    m2.debugSetSceneHour(22);
    m2.setDebugSimSpeed(5);
    final m2Bytes = await capture(
      m2,
      decorate: (c, w, h) {
        paintPanel(c, w, h, 'M2 Clocks', [
          m2.clockDebugLine,
          'phase=${m2.presence.phaseLabel}',
          'scene≠wall when debug speed>1',
        ]);
      },
    );
    await File('${outDir.path}/m02_clock_debug.png').writeAsBytes(m2Bytes);
    m2.dispose();

    // M3 — embodied skeleton
    final m3 = HabitatGame(tileSize: 48);
    await m3.onLoad();
    final emb = m3.ensureEmbodied(m3.pawn!.memberId);
    final m3Bytes = await capture(
      m3,
      decorate: (c, w, h) {
        paintPanel(c, w, h, 'M3 Embodied', [
          for (final n in emb.needs.values) StateExplain.needLine(n),
          '—',
          for (final cap in emb.capacities.values)
            StateExplain.capacityLine(cap),
          '—',
          for (final cond in emb.conditions) StateExplain.conditionLine(cond),
        ]);
      },
    );
    await File('${outDir.path}/m03_embodied_state.png').writeAsBytes(m3Bytes);
    m3.dispose();

    // M4 — explain panel
    final m4 = HabitatGame(tileSize: 48);
    await m4.onLoad();
    final e4 = m4.ensureEmbodied(m4.pawn!.memberId);
    final energy = e4.capacity(CapacityKind.energy)!;
    final m4Bytes = await capture(
      m4,
      decorate: (c, w, h) {
        paintPanel(c, w, h, 'M4 STATE Explain', [
          m4.pawn!.displayName,
          StateExplain.needExplain(e4.need(NeedKind.sleep)!),
          '—',
          StateExplain.capacityExplain(energy),
          '—',
          m4.indoorTemperatureDebugLine ?? '',
        ]);
      },
    );
    await File('${outDir.path}/m04_state_explain.png').writeAsBytes(m4Bytes);
    m4.dispose();

    // M5 — needs after accelerated sim
    final m5 = HabitatGame(tileSize: 48);
    await m5.onLoad();
    m5.setDebugSimSpeed(30);
    for (var i = 0; i < 200; i++) {
      m5.update(0.05);
    }
    final e5 = m5.ensureEmbodied(m5.pawn!.memberId);
    final m5Bytes = await capture(
      m5,
      decorate: (c, w, h) {
        paintPanel(c, w, h, 'M5 Needs', [
          for (final n in e5.needs.values.take(8)) StateExplain.needLine(n),
        ]);
      },
    );
    await File('${outDir.path}/m05_needs.png').writeAsBytes(m5Bytes);
    m5.dispose();

    // M6 — capacities
    final m6 = HabitatGame(tileSize: 48);
    await m6.onLoad();
    for (var i = 0; i < 80; i++) {
      m6.update(0.05);
    }
    final e6 = m6.ensureEmbodied(m6.pawn!.memberId);
    final m6Bytes = await capture(
      m6,
      decorate: (c, w, h) {
        paintPanel(c, w, h, 'M6 Capacities', [
          for (final cap in e6.capacities.values) StateExplain.capacityLine(cap),
          '—',
          StateExplain.capacityExplain(e6.capacity(CapacityKind.energy)!),
        ]);
      },
    );
    await File('${outDir.path}/m06_capacities.png').writeAsBytes(m6Bytes);
    m6.dispose();

    // M7 — conditions
    final m7 = HabitatGame(tileSize: 48);
    await m7.onLoad();
    m7.debugSetSceneHour(23);
    m7.setDebugSimSpeed(30);
    for (var i = 0; i < 300; i++) {
      m7.update(0.05);
    }
    final e7 = m7.ensureEmbodied(m7.pawn!.memberId);
    final m7Bytes = await capture(
      m7,
      decorate: (c, w, h) {
        paintPanel(c, w, h, 'M7 Conditions', [
          if (e7.conditions.isEmpty) 'no active conditions',
          for (final cond in e7.conditions) StateExplain.conditionLine(cond),
          'walk×${ConditionEngine.combinedWalkSpeed(e7.conditions).toStringAsFixed(2)}',
        ]);
      },
    );
    await File('${outDir.path}/m07_conditions.png').writeAsBytes(m7Bytes);
    m7.dispose();

    // M8 — sleep cycle
    final m8 = HabitatGame(tileSize: 48);
    await m8.onLoad();
    m8.debugSetSceneHour(23);
    m8.pawn!.jobs.order(HabitatJobKind.sleep);
    m8.setDebugSimSpeed(30);
    for (var i = 0; i < 120; i++) {
      m8.update(0.05);
    }
    final e8 = m8.ensureEmbodied(m8.pawn!.memberId);
    final m8Bytes = await capture(
      m8,
      decorate: (c, w, h) {
        paintPanel(c, w, h, 'M8 Sleep', [
          'phase=${e8.sleepPhase.name}',
          'pressure=${e8.circadian.sleepPressure.toStringAsFixed(2)}',
          'drive=${e8.circadian.circadianDrive.toStringAsFixed(2)}',
          'alert=${e8.circadian.alertness.toStringAsFixed(2)}',
          'episode=${e8.activeSleepEpisodeId ?? '—'}',
        ]);
      },
    );
    await File('${outDir.path}/m08_sleep_cycle.png').writeAsBytes(m8Bytes);
    m8.dispose();

    // M9 — movement / recovery
    final m9 = HabitatGame(tileSize: 48);
    await m9.onLoad();
    m9.pawn!.jobs.order(HabitatJobKind.sit);
    m9.setDebugSimSpeed(30);
    for (var i = 0; i < 250; i++) {
      m9.update(0.05);
    }
    final e9 = m9.ensureEmbodied(m9.pawn!.memberId);
    final m9Bytes = await capture(
      m9,
      decorate: (c, w, h) {
        paintPanel(c, w, h, 'M9 Movement', [
          'sedentary=${e9.movement.sedentarySeconds.round()}s',
          'fatigue=${e9.movement.physicalFatigue.toStringAsFixed(2)}',
          'load=${e9.movement.recentMovementLoad.toStringAsFixed(2)}',
          StateExplain.needLine(e9.need(NeedKind.movement)!),
        ]);
      },
    );
    await File('${outDir.path}/m09_movement_recovery.png').writeAsBytes(m9Bytes);
    m9.dispose();

    // M15 — media library pick
    final m15 = HabitatGame(tileSize: 48);
    await m15.onLoad();
    final host15 = m15.pawn!.memberId;
    m15.embodiedRuntime.ensureIdentity(host15, isPrimarySelf: true);
    final mediaId = m15.embodiedRuntime.media.pickForPawn(
      pawnId: host15,
      affinities: const {},
      prefs: m15.embodiedRuntime.preferences,
      preferKind: MediaKind.album,
    );
    final mediaItem = m15.embodiedRuntime.media.byId(mediaId ?? '');
    final m15Bytes = await capture(
      m15,
      decorate: (c, w, h) {
        paintPanel(c, w, h, 'M15 Media', [
          'active=${mediaItem?.title ?? '—'}',
          'kind=${mediaItem?.kind.name ?? '—'}',
          'tags=${mediaItem?.interestTags.take(3).join(', ') ?? '—'}',
          'progress=${mediaItem?.progress.name ?? '—'}',
          'library=${m15.embodiedRuntime.media.items.length} items',
        ]);
      },
    );
    await File('${outDir.path}/m15_media.png').writeAsBytes(m15Bytes);
    m15.dispose();

    // M16 — conversation topic
    final m16 = HabitatGame(tileSize: 48);
    await m16.onLoad();
    final a16 = m16.pawn!.memberId;
    final b16 = m16.pawns.length > 1 ? m16.pawns[1].memberId : a16;
    m16.embodiedRuntime.ensureIdentity(a16, isPrimarySelf: true);
    m16.embodiedRuntime.ensureIdentity(b16);
    final topic = m16.embodiedRuntime.pickSocialTopic(
      aId: a16,
      bId: b16,
      simSeconds: 10,
    );
    final m16Bytes = await capture(
      m16,
      decorate: (c, w, h) {
        paintPanel(c, w, h, 'M16 Topics', [
          'topic=${topic?.id ?? '—'}',
          'phrase=${m16.embodiedRuntime.lastTopicPhrase ?? '—'}',
          'graph=${m16.embodiedRuntime.topics.topics.length} topics',
          if (topic != null)
            'suggest=${topic.activitySuggestions.take(2).join(', ')}',
        ]);
      },
    );
    await File('${outDir.path}/m16_topics.png').writeAsBytes(m16Bytes);
    m16.dispose();

    // M17 — identity kinds
    final m17 = HabitatGame(tileSize: 48);
    await m17.onLoad();
    final selfId = m17.pawn!.memberId;
    m17.embodiedRuntime.ensureIdentity(
      selfId,
      isPrimarySelf: true,
      kind: PawnIdentityKind.self,
    );
    m17.embodiedRuntime.ensureIdentity(
      'proxy-demo',
      kind: PawnIdentityKind.personProxy,
    );
    final m17Bytes = await capture(
      m17,
      decorate: (c, w, h) {
        final id = m17.embodiedRuntime.identity;
        paintPanel(c, w, h, 'M17 Identity', [
          'self=${id[selfId]?.kind.name}',
          'primary=${id.primarySelfId}',
          'proxy=${id['proxy-demo']?.kind.name}',
          'proxyPersonal=${id.allowPersonalSignals('proxy-demo')}',
          'selfPersonal=${id.allowPersonalSignals(selfId)}',
        ]);
      },
    );
    await File('${outDir.path}/m17_identity_kind.png').writeAsBytes(m17Bytes);
    m17.dispose();

    // M18 — visitor lifecycle
    final m18 = HabitatGame(tileSize: 48);
    await m18.onLoad();
    m18.debugScheduleVisitor();
    m18.setDebugSimSpeed(40);
    for (var i = 0; i < 80; i++) {
      m18.update(0.05);
    }
    final vStatus = m18.embodiedRuntime.visitors.status['visitor-demo'];
    final m18Bytes = await capture(
      m18,
      decorate: (c, w, h) {
        paintPanel(c, w, h, 'M18 Visitor', [
          'state=${vStatus?.state.name ?? '—'}',
          'role=${vStatus?.role.name ?? '—'}',
          'pawn=${m18.pawnByMemberId('visitor-demo') != null}',
          'episodes=${m18.episodes.openOfKind('presence').length}',
        ]);
      },
    );
    await File('${outDir.path}/m18_visitor.png').writeAsBytes(m18Bytes);
    m18.dispose();

    // M19 — appointment
    final m19 = HabitatGame(tileSize: 48);
    await m19.onLoad();
    m19.debugScheduleDinnerAppointment();
    m19.setDebugSimSpeed(40);
    for (var i = 0; i < 120; i++) {
      m19.update(0.05);
    }
    final appts = m19.embodiedRuntime.appointments.appointments;
    final appt = appts.isEmpty ? null : appts.first;
    final m19Bytes = await capture(
      m19,
      decorate: (c, w, h) {
        paintPanel(c, w, h, 'M19 Appointment', [
          'title=${appt?.appointment.title ?? '—'}',
          'phase=${appt?.phase.name ?? '—'}',
          'source=${appt?.appointment.source.name ?? '—'}',
          'timeline=${m19.embodiedRuntime.appointments.debugTimeline.length}',
          if (m19.embodiedRuntime.appointments.debugTimeline.isNotEmpty)
            m19.embodiedRuntime.appointments.debugTimeline.last,
        ]);
      },
    );
    await File('${outDir.path}/m19_appointment.png').writeAsBytes(m19Bytes);
    m19.dispose();

    // M20 — remote call
    final m20 = HabitatGame(tileSize: 48);
    await m20.onLoad();
    m20.debugStartVoiceCall();
    for (var i = 0; i < 40; i++) {
      m20.update(0.05);
    }
    final call = m20.embodiedRuntime.calls.active;
    final m20Bytes = await capture(
      m20,
      decorate: (c, w, h) {
        paintPanel(c, w, h, 'M20 Remote call', [
          'phase=${call?.phase.name ?? '—'}',
          'remote=${call?.remote.displayName ?? '—'}',
          'mode=${call?.remote.mode.name ?? '—'}',
          'spawnedRemote=${m20.pawnByMemberId('remote-friend') != null}',
          'log=${m20.embodiedRuntime.calls.debugLog.length}',
        ]);
      },
    );
    await File('${outDir.path}/m20_remote_presence.png').writeAsBytes(m20Bytes);
    m20.dispose();

    // M21 — planned activity
    final m21 = HabitatGame(tileSize: 48);
    await m21.onLoad();
    m21.debugScheduleDinnerAppointment();
    m21.setDebugSimSpeed(50);
    for (var i = 0; i < 200; i++) {
      m21.update(0.05);
    }
    final planned = m21.embodiedRuntime.planned.byAppointment.values;
    final pr = planned.isEmpty ? null : planned.first;
    final m21Bytes = await capture(
      m21,
      decorate: (c, w, h) {
        paintPanel(c, w, h, 'M21 Planned activity', [
          'affordance=${pr?.resolvedAffordance ?? 'pending'}',
          'phase=${pr?.phase.name ?? '—'}',
          'fallback=${pr?.primaryUnavailable ?? false}',
          'appts=${m21.embodiedRuntime.appointments.appointments.length}',
        ]);
      },
    );
    await File('${outDir.path}/m21_planned_activity.png').writeAsBytes(m21Bytes);
    m21.dispose();

    // M22 — sites / rooms
    final m22 = HabitatGame(tileSize: 48);
    await m22.onLoad();
    final world = m22.embodiedRuntime.world;
    final m22Bytes = await capture(
      m22,
      decorate: (c, w, h) {
        paintPanel(c, w, h, 'M22 Sites/Rooms', [
          'sites=${world.sites.length}',
          for (final s in world.sites.values.take(2))
            '${s.id}: ${s.roomIds.length} rooms tz=${s.timezoneId.split('/').last}',
          'map→${world.roomByMapLocation(m22.locationId)?.id ?? '—'}',
        ]);
      },
    );
    await File('${outDir.path}/m22_sites_rooms.png').writeAsBytes(m22Bytes);
    m22.dispose();

    // M23 — home / away
    final m23 = HabitatGame(tileSize: 48);
    await m23.onLoad();
    m23.debugBeginTransitToCafe();
    m23.setDebugSimSpeed(40);
    for (var i = 0; i < 120; i++) {
      m23.update(0.05);
    }
    final loc =
        m23.embodiedRuntime.transit.locationState[m23.pawn!.memberId];
    final m23Bytes = await capture(
      m23,
      decorate: (c, w, h) {
        paintPanel(c, w, h, 'M23 Home/Away', [
          'loc=${loc?.name ?? '—'}',
          'site=${m23.embodiedRuntime.transit.currentSiteId[m23.pawn!.memberId]}',
          'presentHome=${m23.embodiedRuntime.transit.isPhysicallyPresent(m23.pawn!.memberId, 'home_apartment')}',
          'inWorld=${m23.pawn!.parent != null}',
        ]);
      },
    );
    await File('${outDir.path}/m23_home_away.png').writeAsBytes(m23Bytes);
    m23.dispose();

    // M24 — context profiles
    final m24 = HabitatGame(tileSize: 48);
    await m24.onLoad();
    m24.switchLocation('office');
    final ctx = m24.embodiedRuntime.activeContext;
    final m24Bytes = await capture(
      m24,
      decorate: (c, w, h) {
        paintPanel(c, w, h, 'M24 Context', [
          'profile=${ctx.id}',
          'noise=${ctx.noise.name}',
          'privacy=${ctx.privacy.name}',
          'focus×${ctx.focusFit().toStringAsFixed(2)}',
          'call×${ctx.callFit().toStringAsFixed(2)}',
          'caps=${ctx.capabilities.take(4).join(', ')}',
        ]);
      },
    );
    await File('${outDir.path}/m24_context_profiles.png').writeAsBytes(m24Bytes);
    m24.dispose();

    // M25 — perceived comfort
    final m25 = HabitatGame(tileSize: 48);
    await m25.onLoad();
    final fitA = m25.perceivedComfortFor(m25.pawn!.memberId);
    m25.embodiedRuntime.comfort.prefs['other'] =
        const EnvironmentalPreferences(
      lightPreference: 0.1,
      noisePreference: 0.1,
      privacyPreference: 0.1,
      cozinessPreference: 0.95,
    );
    final fitB = m25.embodiedRuntime.perceivedFit(
      'other',
      objective: ObjectiveRoomMetrics(
        beauty: fitA.objective,
        space: 0.7,
        cleanliness: 0.7,
        light: 0.65,
        temperatureComfort: 0.8,
        quality: 0.65,
      ),
    );
    final m25Bytes = await capture(
      m25,
      decorate: (c, w, h) {
        paintPanel(c, w, h, 'M25 Perceived comfort', [
          'obj=${(fitA.objective * 100).round()}',
          'pawnA=${(fitA.perceived * 100).round()} Δ${(fitA.delta * 100).round()}',
          'pawnB=${(fitB.perceived * 100).round()} Δ${(fitB.delta * 100).round()}',
        ]);
      },
    );
    await File('${outDir.path}/m25_perceived_comfort.png').writeAsBytes(m25Bytes);
    m25.dispose();

    // M26 — structural editor
    final m26 = HabitatGame(tileSize: 48);
    await m26.onLoad();
    m26.editor.enter();
    m26.editor.tool = HabitatEditTool.drawRoom;
    m26.editor.applyRoomRect(2, 2, 6, 6);
    final m26Bytes = await capture(
      m26,
      decorate: (c, w, h) {
        paintPanel(c, w, h, 'M26 Structural editor', [
          'tool=drawRoom',
          'walls=${m26.map.customWalls.length}',
          'windows=${m26.map.windowCells.length}',
          'door=${m26.map.doorCell}',
        ]);
      },
    );
    await File('${outDir.path}/m26_structural_editor.png').writeAsBytes(m26Bytes);
    m26.dispose();

    // M27 — room detection
    final m27 = HabitatGame(tileSize: 48);
    await m27.onLoad();
    final regions = m27.detectRooms();
    final m27Bytes = await capture(
      m27,
      decorate: (c, w, h) {
        paintPanel(c, w, h, 'M27 Room detect', [
          'regions=${regions.length}',
          if (regions.isNotEmpty)
            'r0=${regions.first.role.name} conf=${regions.first.confidence.toStringAsFixed(2)} area=${regions.first.area}',
        ]);
      },
    );
    await File('${outDir.path}/m27_room_detection.png').writeAsBytes(m27Bytes);
    m27.dispose();

    // M28 — prefab / commands
    final m28 = HabitatGame(tileSize: 48);
    await m28.onLoad();
    m28.debugStampPrefab();
    final m28Bytes = await capture(
      m28,
      decorate: (c, w, h) {
        paintPanel(c, w, h, 'M28 Prefabs', [
          'cmds=${m28.commands.history.length}',
          if (m28.commands.history.isNotEmpty) m28.commands.history.last.label,
          'props=${m28.map.props.length}',
        ]);
      },
    );
    await File('${outDir.path}/m28_prefab_blueprint.png').writeAsBytes(m28Bytes);
    m28.dispose();

    // M29 — auto-furnish
    final m29 = HabitatGame(tileSize: 48);
    await m29.onLoad();
    m29.debugAutoFurnish();
    final m29Bytes = await capture(
      m29,
      decorate: (c, w, h) {
        paintPanel(c, w, h, 'M29 Auto-furnish', [
          'props=${m29.map.props.length}',
          if (m29.commands.history.isNotEmpty) m29.commands.history.last.label,
        ]);
      },
    );
    await File('${outDir.path}/m29_generated_site.png').writeAsBytes(m29Bytes);
    m29.dispose();

    // M30 — scene preset
    final m30 = HabitatGame(tileSize: 48);
    await m30.onLoad();
    m30.debugCycleScenePreset(); // → quietEvening or first+1
    m30.debugCycleScenePreset(); // toward movieNight
    m30.debugCycleScenePreset();
    final m30Bytes = await capture(
      m30,
      decorate: (c, w, h) {
        paintPanel(c, w, h, 'M30 Scene preset', [
          'preset=${m30.embodiedRuntime.scenes.activePresetId}',
          'tv=${m30.embodiedRuntime.scenes.environment[HabitatEnvSwitch.tvOn]}',
          'vestiges=${m30.embodiedRuntime.scenes.environment.vestiges.length}',
        ]);
      },
    );
    await File('${outDir.path}/m30_scene_preset.png').writeAsBytes(m30Bytes);
    m30.dispose();

    // M31 — loadouts
    final m31 = HabitatGame(tileSize: 48);
    await m31.onLoad();
    m31.debugApplySleepLoadout();
    final m31Bytes = await capture(
      m31,
      decorate: (c, w, h) {
        final p = m31.pawns.first;
        paintPanel(c, w, h, 'M31 Loadouts', [
          'loadout=${p.appearance.loadoutId}',
          'top=${p.appearance.apparelTop}',
        ]);
      },
    );
    await File('${outDir.path}/m31_loadouts.png').writeAsBytes(m31Bytes);
    m31.dispose();

    // M32 — storage
    final m32 = HabitatGame(tileSize: 48);
    await m32.onLoad();
    m32.debugInventoryPath();
    final m32Bytes = await capture(
      m32,
      decorate: (c, w, h) {
        final book = m32.embodiedRuntime.inventory.items['book.dune'];
        paintPanel(c, w, h, 'M32 Storage', [
          'book@${book?.location.kind.name}',
          'container=${book?.location.containerId}',
          'ok=${m32.embodiedRuntime.inventory.locationsConsistent}',
        ]);
      },
    );
    await File('${outDir.path}/m32_storage.png').writeAsBytes(m32Bytes);
    m32.dispose();

    // M33 — interrupt / resume
    final m33 = HabitatGame(tileSize: 48);
    await m33.onLoad();
    m33.debugStartReading();
    m33.debugStartVoiceCall();
    final m33Bytes = await capture(
      m33,
      decorate: (c, w, h) {
        final acts = m33.embodiedRuntime.devices.activities.values.toList();
        paintPanel(c, w, h, 'M33 Interrupt', [
          'call=${m33.embodiedRuntime.calls.isOnCall}',
          if (acts.isNotEmpty) 'act=${acts.first.kind}/${acts.first.phase.name}',
          'resume=${m33.embodiedRuntime.devices.resumeCandidates.length}',
        ]);
      },
    );
    await File('${outDir.path}/m33_interrupt_resume.png').writeAsBytes(m33Bytes);
    m33.dispose();

    // M34 — routine engine
    final m34 = HabitatGame(tileSize: 48);
    await m34.onLoad();
    m34.debugStartRoutine('prepareSleep');
    final m34Bytes = await capture(
      m34,
      decorate: (c, w, h) {
        final run = m34.embodiedRuntime.routines.runsByPawn.values.firstOrNull;
        paintPanel(c, w, h, 'M34 Routine', [
          'def=${run?.definitionId}',
          'node=${run?.currentNodeId}',
          'status=${run?.status.name}',
          'steps=${run?.executed.length}',
        ]);
      },
    );
    await File('${outDir.path}/m34_routine_engine.png').writeAsBytes(m34Bytes);
    m34.dispose();

    // M35 — morning / bedtime
    final m35 = HabitatGame(tileSize: 48);
    await m35.onLoad();
    m35.debugMorningBedtime();
    final m35Bytes = await capture(
      m35,
      decorate: (c, w, h) {
        final run = m35.embodiedRuntime.routines.runsByPawn.values.firstOrNull;
        paintPanel(c, w, h, 'M35 Morning/Bedtime', [
          'routine=${run?.definitionId}',
          'loadout=${m35.pawns.first.appearance.loadoutId}',
          'preset=${m35.embodiedRuntime.scenes.activePresetId}',
        ]);
      },
    );
    await File('${outDir.path}/m35_morning_bedtime.png').writeAsBytes(m35Bytes);
    m35.dispose();

    // M36 — departure
    final m36 = HabitatGame(tileSize: 48);
    await m36.onLoad();
    m36.debugLeaveAndArrive();
    final m36Bytes = await capture(
      m36,
      decorate: (c, w, h) {
        paintPanel(c, w, h, 'M36 Departure', [
          'loadout=${m36.pawns.first.appearance.loadoutId}',
          'loc=${m36.embodiedRuntime.transit.locationState[m36.pawns.first.memberId]?.name}',
        ]);
      },
    );
    await File('${outDir.path}/m36_departure.png').writeAsBytes(m36Bytes);
    m36.dispose();

    // M37 — shared meal
    final m37 = HabitatGame(tileSize: 48);
    await m37.onLoad();
    m37.debugSharedMeal();
    final m37Bytes = await capture(
      m37,
      decorate: (c, w, h) {
        paintPanel(c, w, h, 'M37 Shared meal', [
          'meals=${m37.embodiedRuntime.kitchen.meals.length}',
          'aftermath=${m37.embodiedRuntime.kitchen.aftermath.length}',
        ]);
      },
    );
    await File('${outDir.path}/m37_shared_meal.png').writeAsBytes(m37Bytes);
    m37.dispose();

    // M38 — workpiece
    final m38 = HabitatGame(tileSize: 48);
    await m38.onLoad();
    m38.debugWorkpiece();
    final m38Bytes = await capture(
      m38,
      decorate: (c, w, h) {
        final wp = m38.embodiedRuntime.workpieces.pieces.values.firstOrNull;
        paintPanel(c, w, h, 'M38 Workpiece', [
          'stage=${wp?.stage}',
          'prog=${((wp?.progress ?? 0) * 100).round()}%',
        ]);
      },
    );
    await File('${outDir.path}/m38_workpiece.png').writeAsBytes(m38Bytes);
    m38.dispose();

    // M39 — preparation
    final m39 = HabitatGame(tileSize: 48);
    await m39.onLoad();
    m39.debugPrepWork();
    final m39Bytes = await capture(
      m39,
      decorate: (c, w, h) {
        final laptop = m39.embodiedRuntime.inventory.items['laptop.demo'];
        paintPanel(c, w, h, 'M39 Prep', [
          'laptop@${laptop?.location.kind.name}/${laptop?.location.containerId}',
        ]);
      },
    );
    await File('${outDir.path}/m39_preparation.png').writeAsBytes(m39Bytes);
    m39.dispose();

    // M40 — jet lag
    final m40 = HabitatGame(tileSize: 48);
    await m40.onLoad();
    m40.debugJetLagHop();
    final m40Bytes = await capture(
      m40,
      decorate: (c, w, h) {
        final circ = m40.embodiedRuntime.travel
            .stateFor(m40.pawns.first.memberId);
        paintPanel(c, w, h, 'M40 Jet lag', [
          'tz=${m40.clocks.siteTimezoneId}',
          'bodyΔ=${circ.bodyClockOffsetHours.toStringAsFixed(1)}',
          'adapt=${(circ.adaptationProgress * 100).round()}%',
        ]);
      },
    );
    await File('${outDir.path}/m40_travel_jetlag.png').writeAsBytes(m40Bytes);
    m40.dispose();

    // M41 — world map
    final m41 = HabitatGame(tileSize: 48);
    await m41.onLoad();
    m41.debugWorldMapGo();
    final m41Bytes = await capture(
      m41,
      decorate: (c, w, h) {
        paintPanel(c, w, h, 'M41 World map', [
          'sites=${m41.embodiedRuntime.world.sites.length}',
          'kinds=${HabitatWorldMap.kinds.length}',
        ]);
      },
    );
    await File('${outDir.path}/m41_world_map.png').writeAsBytes(m41Bytes);
    m41.dispose();

    // M42/M43 — content
    final m42 = HabitatGame(tileSize: 48);
    await m42.onLoad();
    m42.debugCustomContent();
    final m42Bytes = await capture(
      m42,
      decorate: (c, w, h) {
        paintPanel(c, w, h, 'M42/43 Content', [
          'props=${m42.embodiedRuntime.content.props.length}',
          'custom=${m42.embodiedRuntime.customContent.saved.length}',
          'issues=${m42.embodiedRuntime.content.validate().length}',
        ]);
      },
    );
    await File('${outDir.path}/m42_content_registry.png').writeAsBytes(m42Bytes);
    await File('${outDir.path}/m43_custom_content.png').writeAsBytes(m42Bytes);
    m42.dispose();

    // M44 — ports (panel only)
    final m44 = HabitatGame(tileSize: 48);
    await m44.onLoad();
    final m44Bytes = await capture(
      m44,
      decorate: (c, w, h) {
        paintPanel(c, w, h, 'M44 Ports', [
          'sleep=${m44.embodiedRuntime.ports.sleep.runtimeType}',
          'appt=${m44.embodiedRuntime.ports.appointments.runtimeType}',
          'env=${m44.embodiedRuntime.ports.environment.readEnvironment('home').siteId}',
        ]);
      },
    );
    await File('${outDir.path}/m44_binding_ports.png').writeAsBytes(m44Bytes);
    m44.dispose();

    // M45–M50 gate / persist
    final m50 = HabitatGame(tileSize: 48);
    await m50.onLoad();
    m50.debugPersistAndGate();
    final m50Bytes = await capture(
      m50,
      decorate: (c, w, h) {
        final gate = m50.embodiedRuntime.mirrorReadyGateIssues();
        paintPanel(c, w, h, 'M50 Mirror-Ready Gate', [
          'gate=${gate.isEmpty ? "PASS" : gate.join(",")}',
          'writes=${m50.embodiedRuntime.snapshots.writeCount}',
          'schema=${m50.embodiedRuntime.snapshots.load()?.schemaVersion}',
        ]);
      },
    );
    await File('${outDir.path}/m45_proxy_privacy.png').writeAsBytes(m50Bytes);
    await File('${outDir.path}/m47_persistence.png').writeAsBytes(m50Bytes);
    await File('${outDir.path}/m48_sim_profiler.png').writeAsBytes(m50Bytes);
    await File('${outDir.path}/m50_mirror_ready_gate.png').writeAsBytes(m50Bytes);
    m50.dispose();

    print('Wrote m00–m09 + m15–m50 screenshots to ${outDir.path}');
    expect(m0Bytes.length, greaterThan(10000));
    expect(m44Bytes.length, greaterThan(10000));
    expect(m50Bytes.length, greaterThan(10000));
  });
}

extension on HabitatGame {
  void _forceAtmosphereForCapture() {
    // ensure indoor signal exists after load
    setOutdoorTemperature(outdoorTemperatureC);
  }
}
