import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fallhub/app/localization/app_strings.dart';
import 'package:fallhub/features/colony/application/colony_agenda_style.dart';

void main() {
  test('buildColonyAgendaBlocks maps modes without synthetic Livre', () {
    final day = DateTime(2026, 5, 19);
    final items = [
      ScheduleTimelineItem(
        id: 's',
        startAt: DateTime(2026, 5, 19, 0),
        endAt: DateTime(2026, 5, 19, 7, 30),
        kind: ScheduleTimelineItemKind.block,
        label: 'Sono',
        block: ScheduleBlock(
          id: EntityId('s'),
          profileId: EntityId('p'),
          startAt: DateTime(2026, 5, 19, 0),
          endAt: DateTime(2026, 5, 19, 7, 30),
          mode: ScheduleBlockMode.sleep,
          createdAt: DateTime(2026, 5, 19),
          updatedAt: DateTime(2026, 5, 19),
        ),
      ),
      ScheduleTimelineItem(
        id: 'f',
        startAt: DateTime(2026, 5, 19, 7, 30),
        endAt: DateTime(2026, 5, 19, 12),
        kind: ScheduleTimelineItemKind.block,
        label: 'Foco',
        block: ScheduleBlock(
          id: EntityId('f'),
          profileId: EntityId('p'),
          startAt: DateTime(2026, 5, 19, 7, 30),
          endAt: DateTime(2026, 5, 19, 12),
          mode: ScheduleBlockMode.focus,
          createdAt: DateTime(2026, 5, 19),
          updatedAt: DateTime(2026, 5, 19),
        ),
      ),
    ];

    final blocks = buildColonyAgendaBlocks(
      day: day,
      items: items,
      conflictIds: {'f'},
    );

    expect(
      blocks.first.title,
      AppStrings.scheduleBlockShortLabel(ScheduleBlockMode.sleep),
    );
    expect(blocks.where((b) => b.visualOnly), isEmpty);
    expect(blocks.any((b) => b.warning && b.id == 'f'), isTrue);
    expect(agendaStyleFor(ScheduleBlockMode.sleep).$2, 'moon');
  });

  test('all-day external events are flagged for the home rail', () {
    final day = DateTime(2026, 8, 31);
    final blocks = buildColonyAgendaBlocks(
      day: day,
      items: [
        ScheduleTimelineItem(
          id: 'bday',
          startAt: DateTime(2026, 8, 31),
          endAt: DateTime(2026, 9, 1),
          kind: ScheduleTimelineItemKind.external,
          label: 'Aniversário',
        ),
        ScheduleTimelineItem(
          id: 'aula',
          startAt: DateTime(2026, 8, 31, 19),
          endAt: DateTime(2026, 8, 31, 21),
          kind: ScheduleTimelineItemKind.external,
          label: 'Aula criptografia',
        ),
      ],
      conflictIds: const {},
    );
    expect(blocks.singleWhere((b) => b.id == 'bday').allDay, isTrue);
    expect(blocks.singleWhere((b) => b.id == 'aula').allDay, isFalse);
    expect(
      blocks.singleWhere((b) => b.id == 'bday').timeLabel,
      AppStrings.homeAllDay,
    );
    expect(blocks.singleWhere((b) => b.id == 'bday').iconName, 'cake');
    expect(blocks.singleWhere((b) => b.id == 'aula').iconName, 'cap');
  });

  test('keyword lexicon maps reuniao to briefcase even with accents', () {
    final day = DateTime(2026, 8, 31);
    final blocks = buildColonyAgendaBlocks(
      day: day,
      items: [
        ScheduleTimelineItem(
          id: 'meet',
          startAt: DateTime(2026, 8, 31, 10),
          endAt: DateTime(2026, 8, 31, 11),
          kind: ScheduleTimelineItemKind.external,
          label: 'REUNIÃO rebond',
        ),
      ],
      conflictIds: const {},
    );
    expect(blocks.single.iconName, 'briefcase');
  });

  test('native meeting blocks keep the Aula cap from the short label', () {
    final day = DateTime(2026, 5, 19);
    final blocks = buildColonyAgendaBlocks(
      day: day,
      items: [
        ScheduleTimelineItem(
          id: 'aula',
          startAt: DateTime(2026, 5, 19, 14, 30),
          endAt: DateTime(2026, 5, 19, 16),
          kind: ScheduleTimelineItemKind.block,
          label: 'Reunião',
          block: ScheduleBlock(
            id: EntityId('aula'),
            profileId: EntityId('p'),
            startAt: DateTime(2026, 5, 19, 14, 30),
            endAt: DateTime(2026, 5, 19, 16),
            mode: ScheduleBlockMode.meeting,
            createdAt: DateTime(2026, 5, 19),
            updatedAt: DateTime(2026, 5, 19),
          ),
        ),
      ],
      conflictIds: const {},
    );
    expect(
      blocks.single.title,
      AppStrings.scheduleBlockShortLabel(ScheduleBlockMode.meeting),
    );
    expect(blocks.single.iconName, 'cap');
  });
}
