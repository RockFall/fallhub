import 'work_enums.dart';

/// Icon + schedule tint resolved from an event title (ADR-049 home rail).
class AgendaIconHint {
  const AgendaIconHint({required this.iconName, required this.mode});

  final String iconName;
  final ScheduleBlockMode mode;
}

/// Lowercases and strips Latin diacritics (`REUNIÃO` → `reuniao`).
String foldAgendaText(String raw) {
  const fold = {
    'á': 'a',
    'à': 'a',
    'ã': 'a',
    'â': 'a',
    'ä': 'a',
    'é': 'e',
    'è': 'e',
    'ê': 'e',
    'ë': 'e',
    'í': 'i',
    'ì': 'i',
    'î': 'i',
    'ï': 'i',
    'ó': 'o',
    'ò': 'o',
    'ô': 'o',
    'õ': 'o',
    'ö': 'o',
    'ú': 'u',
    'ù': 'u',
    'û': 'u',
    'ü': 'u',
    'ç': 'c',
    'ñ': 'n',
    'ý': 'y',
  };
  final buf = StringBuffer();
  for (final unit in raw.toLowerCase().codeUnits) {
    final ch = String.fromCharCode(unit);
    buf.write(fold[ch] ?? ch);
  }
  return buf.toString();
}

/// First keyword hit in [title], longest needle first (stable on ties).
///
/// Matching is case-insensitive and accent-insensitive. Single tokens use
/// word boundaries so `aula` does not match `saula`.
final _sortedRules = () {
  final indexed = [for (var i = 0; i < _rules.length; i++) (i, _rules[i])];
  indexed.sort((a, b) {
    final byLen = b.$2.needle.length.compareTo(a.$2.needle.length);
    return byLen != 0 ? byLen : a.$1.compareTo(b.$1);
  });
  return List<_Rule>.unmodifiable(indexed.map((e) => e.$2));
}();

AgendaIconHint? matchAgendaIcon(String title) {
  final folded = foldAgendaText(title);
  if (folded.trim().isEmpty) return null;
  for (final rule in _sortedRules) {
    if (_containsNeedle(folded, rule.needle)) return rule.hint;
  }
  return null;
}

bool _containsNeedle(String folded, String needle) {
  if (needle.contains(' ')) {
    return folded.contains(needle);
  }
  return RegExp(
    '(^|[^a-z0-9])${RegExp.escape(needle)}([^a-z0-9]|\$)',
  ).hasMatch(folded);
}

class _Rule {
  const _Rule(this.needle, this.hint);
  final String needle;
  final AgendaIconHint hint;
}

const _meet = AgendaIconHint(
  iconName: 'briefcase',
  mode: ScheduleBlockMode.meeting,
);
const _class = AgendaIconHint(iconName: 'cap', mode: ScheduleBlockMode.meeting);
const _sleep = AgendaIconHint(iconName: 'moon', mode: ScheduleBlockMode.sleep);
const _focus = AgendaIconHint(
  iconName: 'crosshair',
  mode: ScheduleBlockMode.focus,
);
const _meal = AgendaIconHint(
  iconName: 'utensils',
  mode: ScheduleBlockMode.recreation,
);
const _coffee = AgendaIconHint(
  iconName: 'coffee',
  mode: ScheduleBlockMode.recreation,
);
const _social = AgendaIconHint(
  iconName: 'handshake',
  mode: ScheduleBlockMode.social,
);
const _party = AgendaIconHint(iconName: 'cake', mode: ScheduleBlockMode.social);
const _gift = AgendaIconHint(iconName: 'gift', mode: ScheduleBlockMode.social);
const _health = AgendaIconHint(
  iconName: 'pill',
  mode: ScheduleBlockMode.recovery,
);
const _doctor = AgendaIconHint(
  iconName: 'stethoscope',
  mode: ScheduleBlockMode.recovery,
);
const _dentist = AgendaIconHint(
  iconName: 'tooth',
  mode: ScheduleBlockMode.recovery,
);
const _gym = AgendaIconHint(
  iconName: 'dumbbell',
  mode: ScheduleBlockMode.exercise,
);
const _travel = AgendaIconHint(
  iconName: 'plane',
  mode: ScheduleBlockMode.commute,
);
const _commute = AgendaIconHint(
  iconName: 'commute',
  mode: ScheduleBlockMode.commute,
);
const _free = AgendaIconHint(iconName: 'star', mode: ScheduleBlockMode.free);
const _study = AgendaIconHint(iconName: 'cards', mode: ScheduleBlockMode.focus);
const _book = AgendaIconHint(iconName: 'book', mode: ScheduleBlockMode.focus);
const _code = AgendaIconHint(
  iconName: 'keyboard',
  mode: ScheduleBlockMode.focus,
);
const _war = AgendaIconHint(iconName: 'radio', mode: ScheduleBlockMode.meeting);
const _call = AgendaIconHint(
  iconName: 'phone',
  mode: ScheduleBlockMode.meeting,
);
const _video = AgendaIconHint(
  iconName: 'video',
  mode: ScheduleBlockMode.meeting,
);
const _mic = AgendaIconHint(iconName: 'mic', mode: ScheduleBlockMode.meeting);
const _money = AgendaIconHint(
  iconName: 'coin',
  mode: ScheduleBlockMode.routine,
);
const _music = AgendaIconHint(
  iconName: 'album',
  mode: ScheduleBlockMode.recreation,
);
const _ticket = AgendaIconHint(
  iconName: 'ticket',
  mode: ScheduleBlockMode.recreation,
);
const _pet = AgendaIconHint(iconName: 'paw', mode: ScheduleBlockMode.social);
const _church = AgendaIconHint(
  iconName: 'church',
  mode: ScheduleBlockMode.social,
);
const _wedding = AgendaIconHint(
  iconName: 'rings',
  mode: ScheduleBlockMode.social,
);
const _drinks = AgendaIconHint(
  iconName: 'beer',
  mode: ScheduleBlockMode.recreation,
);
const _games = AgendaIconHint(
  iconName: 'gamepad',
  mode: ScheduleBlockMode.recreation,
);
const _cut = AgendaIconHint(
  iconName: 'scissors',
  mode: ScheduleBlockMode.routine,
);
const _write = AgendaIconHint(
  iconName: 'scroll',
  mode: ScheduleBlockMode.focus,
);
const _pizza = AgendaIconHint(
  iconName: 'pizza',
  mode: ScheduleBlockMode.recreation,
);

/// Longest needles first so `war room` wins over `war`.
const _rules = <_Rule>[
  _Rule('cafe da manha', _coffee),
  _Rule('happy hour', _drinks),
  _Rule('war room', _war),
  _Rule('deep work', _focus),
  _Rule('one on one', _meet),
  _Rule('all hands', _meet),
  _Rule('pair programming', _code),
  _Rule('video chamada', _video),
  _Rule('video call', _video),
  _Rule('google meet', _video),
  _Rule('aniversario', _party),
  _Rule('birthday', _party),
  _Rule('reuniao', _meet),
  _Rule('meeting', _meet),
  _Rule('retrospectiva', _meet),
  _Rule('planning', _meet),
  _Rule('kickoff', _meet),
  _Rule('standup', _meet),
  _Rule('alinhamento', _meet),
  _Rule('entrevista', _mic),
  _Rule('interview', _mic),
  _Rule('palestra', _class),
  _Rule('seminario', _class),
  _Rule('workshop', _class),
  _Rule('lecture', _class),
  _Rule('cryptografia', _class),
  _Rule('criptografia', _class),
  _Rule('flashcard', _study),
  _Rule('flashcards', _study),
  _Rule('academia', _gym),
  _Rule('exercicio', _gym),
  _Rule('pilates', _gym),
  _Rule('consulta', _doctor),
  _Rule('dentista', _dentist),
  _Rule('psicologo', _doctor),
  _Rule('terapia', _doctor),
  _Rule('hospital', _doctor),
  _Rule('aeroporto', _travel),
  _Rule('deslocamento', _commute),
  _Rule('restaurante', _meal),
  _Rule('casamento', _wedding),
  _Rule('cabeleireiro', _cut),
  _Rule('barbeiro', _cut),
  _Rule('pagamento', _money),
  _Rule('imposto', _money),
  _Rule('boleto', _money),
  _Rule('igreja', _church),
  _Rule('missa', _church),
  _Rule('cinema', _ticket),
  _Rule('teatro', _ticket),
  _Rule('show', _ticket),
  _Rule('videogame', _games),
  _Rule('gameplay', _games),
  _Rule('veterinario', _pet),
  _Rule('faculdade', _class),
  _Rule('universidade', _class),
  _Rule('colegio', _class),
  _Rule('aula', _class),
  _Rule('class', _class),
  _Rule('curso', _class),
  _Rule('prova', _class),
  _Rule('exame', _class),
  _Rule('estudo', _study),
  _Rule('estudar', _study),
  _Rule('sono', _sleep),
  _Rule('dormir', _sleep),
  _Rule('sleep', _sleep),
  _Rule('sesta', _sleep),
  _Rule('cochilo', _sleep),
  _Rule('jantar', _meal),
  _Rule('almoco', _meal),
  _Rule('dinner', _meal),
  _Rule('lunch', _meal),
  _Rule('brunch', _meal),
  _Rule('lanche', _meal),
  _Rule('pizza', _pizza),
  _Rule('comer', _meal),
  _Rule('cafe', _coffee),
  _Rule('coffee', _coffee),
  _Rule('foco', _focus),
  _Rule('coding', _code),
  _Rule('codigo', _code),
  _Rule('programar', _code),
  _Rule('deploy', _code),
  _Rule('festa', _party),
  _Rule('party', _party),
  _Rule('niver', _party),
  _Rule('presente', _gift),
  _Rule('encontro', _social),
  _Rule('social', _social),
  _Rule('treino', _gym),
  _Rule('gym', _gym),
  _Rule('yoga', _gym),
  _Rule('corrida', _gym),
  _Rule('run', _gym),
  _Rule('medico', _doctor),
  _Rule('voo', _travel),
  _Rule('flight', _travel),
  _Rule('viagem', _travel),
  _Rule('uber', _commute),
  _Rule('onibus', _commute),
  _Rule('metro', _commute),
  _Rule('taxi', _commute),
  _Rule('livre', _free),
  _Rule('lazer', _free),
  _Rule('folga', _free),
  _Rule('feriado', _free),
  _Rule('call', _call),
  _Rule('ligacao', _call),
  _Rule('1:1', _meet),
  _Rule('1-1', _meet),
  _Rule('zoom', _video),
  _Rule('meet', _video),
  _Rule('teams', _video),
  _Rule('musica', _music),
  _Rule('ensaio', _write),
  _Rule('jogo', _games),
  _Rule('game', _games),
  _Rule('pet', _pet),
  _Rule('cachorro', _pet),
  _Rule('gato', _pet),
  _Rule('bar', _drinks),
  _Rule('cerveja', _drinks),
  _Rule('war', _war),
  _Rule('banco', _money),
  _Rule('tcc', _book),
  _Rule('tese', _book),
];
