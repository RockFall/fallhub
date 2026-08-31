import 'package:colony_domain/colony_domain.dart';
import 'package:test/test.dart';

void main() {
  group('foldAgendaText', () {
    test('lowercases and strips Latin accents', () {
      expect(foldAgendaText('REUNIÃO'), 'reuniao');
      expect(foldAgendaText('Aniversário'), 'aniversario');
      expect(foldAgendaText('AULA'), 'aula');
      expect(foldAgendaText('Almoço'), 'almoco');
      expect(foldAgendaText('Criptografia'), 'criptografia');
    });
  });

  group('matchAgendaIcon', () {
    test('detects reuniao ignoring case and accents', () {
      final hit = matchAgendaIcon('Reunião Rebond');
      expect(hit, isNotNull);
      expect(hit!.iconName, 'briefcase');
      expect(hit.mode, ScheduleBlockMode.meeting);
    });

    test('detects aula as a whole word', () {
      final hit = matchAgendaIcon('AULA CRIPTOGRAFIA');
      expect(hit, isNotNull);
      expect(hit!.iconName, 'cap');
    });

    test('does not match aula inside another token', () {
      expect(matchAgendaIcon('Saula'), isNull);
    });

    test('picks birthday cake for aniversario', () {
      expect(matchAgendaIcon('Aniversário dia domeiro')!.iconName, 'cake');
    });

    test('prefers the longer needle war room over war', () {
      expect(matchAgendaIcon('War Room')!.iconName, 'radio');
    });

    test('returns null when nothing matches', () {
      expect(matchAgendaIcon('xyzzy'), isNull);
    });

    test('maps common calendar keywords', () {
      expect(matchAgendaIcon('zoom com o time')!.iconName, 'video');
      expect(matchAgendaIcon('Dentista 15h')!.iconName, 'tooth');
      expect(matchAgendaIcon('1:1 Maria')!.iconName, 'briefcase');
      expect(matchAgendaIcon('Jantar em família')!.iconName, 'utensils');
      expect(matchAgendaIcon('sono pesado')!.iconName, 'moon');
    });
  });
}
