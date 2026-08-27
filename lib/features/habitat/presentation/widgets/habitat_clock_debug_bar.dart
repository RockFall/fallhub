import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../flame/habitat_game.dart';

/// Compact debug strip for scene/sim clocks + habitat demos (MD 08).
///
/// Collapsed by default — expand via the top-left control; `?` opens a
/// glossary of every chip.
class HabitatClockDebugBar extends StatefulWidget {
  const HabitatClockDebugBar({
    super.key,
    required this.game,
    this.onChanged,
  });

  final HabitatGame game;
  final VoidCallback? onChanged;

  @override
  State<HabitatClockDebugBar> createState() => _HabitatClockDebugBarState();
}

class _HabitatClockDebugBarState extends State<HabitatClockDebugBar> {
  bool _expanded = false;

  void _act(VoidCallback fn) {
    fn();
    widget.onChanged?.call();
    setState(() {});
  }

  Future<void> _showHelp() async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A222A),
        title: const Text(
          'Debug Habitat',
          style: TextStyle(color: Color(0xFFE8E6E3), fontSize: 16),
        ),
        content: SizedBox(
          width: 360,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final e in _helpEntries) ...[
                  Text(
                    e.label,
                    style: const TextStyle(
                      color: Color(0xFFE8E6E3),
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    e.detail,
                    style: const TextStyle(
                      color: Color(0xFFB0B4B8),
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();

    if (!_expanded) {
      return Align(
        alignment: Alignment.topLeft,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Material(
            color: const Color(0xCC1A222A),
            borderRadius: BorderRadius.circular(6),
            child: InkWell(
              onTap: () => setState(() => _expanded = true),
              borderRadius: BorderRadius.circular(6),
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(
                  Icons.bug_report_outlined,
                  size: 20,
                  color: Color(0xFFE8E6E3),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Material(
      color: const Color(0xCC1A222A),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, 4, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: 'Recolher debug',
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  onPressed: () => setState(() => _expanded = false),
                  icon: const Icon(
                    Icons.keyboard_arrow_up,
                    size: 20,
                    color: Color(0xFFE8E6E3),
                  ),
                ),
                Expanded(
                  child: Text(
                    widget.game.clockDebugLine,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: const TextStyle(
                      color: Color(0xFFE8E6E3),
                      fontSize: 11,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'O que cada botão faz',
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  onPressed: _showHelp,
                  icon: const Icon(
                    Icons.help_outline,
                    size: 18,
                    color: Color(0xFFE8E6E3),
                  ),
                ),
              ],
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final chip in _chips)
                    _SpeedChip(
                      label: chip.label,
                      onTap: () => _act(chip.run),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<_DebugChipSpec> get _chips => [
        _DebugChipSpec('1×', () => widget.game.setDebugSimSpeed(1)),
        _DebugChipSpec('5×', () => widget.game.setDebugSimSpeed(5)),
        _DebugChipSpec('30×', () => widget.game.setDebugSimSpeed(30)),
        _DebugChipSpec('+1h', widget.game.debugSkipOneHour),
        _DebugChipSpec('22h', () => widget.game.debugSetSceneHour(22)),
        _DebugChipSpec(
          '28°',
          () => widget.game.setIndoorTemperatureOverride(
            28,
            reason: 'debug heater',
          ),
        ),
        _DebugChipSpec('clr°', widget.game.clearIndoorTemperatureOverride),
        _DebugChipSpec('jantar', widget.game.debugScheduleDinnerAppointment),
        _DebugChipSpec('visita', widget.game.debugScheduleVisitor),
        _DebugChipSpec('call', widget.game.debugStartVoiceCall),
        _DebugChipSpec('hang', widget.game.debugEndVoiceCall),
        _DebugChipSpec('café', widget.game.debugBeginTransitToCafe),
        _DebugChipSpec('prefab', widget.game.debugStampPrefab),
        _DebugChipSpec('furnish', widget.game.debugAutoFurnish),
        _DebugChipSpec('cena', widget.game.debugCycleScenePreset),
        _DebugChipSpec('pijama', widget.game.debugApplySleepLoadout),
        _DebugChipSpec('inv', widget.game.debugInventoryPath),
        _DebugChipSpec('ler', widget.game.debugStartReading),
        _DebugChipSpec('retomar', widget.game.debugResumeActivity),
        _DebugChipSpec('rotina', widget.game.debugStartRoutine),
        _DebugChipSpec('manhã', widget.game.debugMorningBedtime),
        _DebugChipSpec('sair', widget.game.debugLeaveAndArrive),
        _DebugChipSpec('janta', widget.game.debugSharedMeal),
        _DebugChipSpec('tela', widget.game.debugWorkpiece),
        _DebugChipSpec('prep', widget.game.debugPrepWork),
        _DebugChipSpec('jet', widget.game.debugJetLagHop),
        _DebugChipSpec('mapa', widget.game.debugWorldMapGo),
        _DebugChipSpec('custom', widget.game.debugCustomContent),
        _DebugChipSpec('gate', widget.game.debugPersistAndGate),
      ];
}

class _DebugChipSpec {
  const _DebugChipSpec(this.label, this.run);
  final String label;
  final VoidCallback run;
}

class _HelpEntry {
  const _HelpEntry(this.label, this.detail);
  final String label;
  final String detail;
}

const _helpEntries = <_HelpEntry>[
  _HelpEntry('1× / 5× / 30×', 'Velocidade da simulação (SceneClock / needs). 1× = tempo normal.'),
  _HelpEntry('+1h', 'Avança a hora de cena em 1 hora (ciclo dia/noite, sono, etc.).'),
  _HelpEntry('22h', 'Fixa a hora de cena em 22:00 (útil para testar noite/sono).'),
  _HelpEntry('28°', 'Override manual da temperatura indoor para 28°C (fonte manual/debug).'),
  _HelpEntry('clr°', 'Remove o override de temperatura; volta ao sinal derivado/simulado.'),
  _HelpEntry(
    'jantar',
    'Agenda um HabitatAppointment demo (jantar): preparação → início → pawns vão à mesa.',
  ),
  _HelpEntry(
    'visita',
    'Agenda um visitante (personProxy): chega na entrada, episódio de presença, depois sai.',
  ),
  _HelpEntry(
    'call',
    'Inicia chamada de voz remota com “Amigo” sem spawn físico do convidado (M20).',
  ),
  _HelpEntry('hang', 'Encerra a chamada ativa (interrupção manual).'),
  _HelpEntry(
    'café',
    'Coloca o pawn em trânsito Home → Café. Destino sem mapa vira estado away (casa vazia).',
  ),
  _HelpEntry(
    'prefab',
    'Entra no editor (se preciso) e carimba o prefab “cantinho de leitura” perto do spawn.',
  ),
  _HelpEntry(
    'furnish',
    'Detecta o papel do cômodo e auto-mobilia com o prefab correspondente (M29).',
  ),
  _HelpEntry(
    'cena',
    'Cicla ScenePreset. Olhe a sala: movieNight escurece + TV acende (brilho azul); sleepMode apaga lâmpadas. HUD embaixo mostra cena:…',
  ),
  _HelpEntry(
    'pijama',
    'Tira a camisa (pijama), aplica sleepMode (luz off) e deita. Mudança bem visível no pawn + escuridão.',
  ),
  _HelpEntry(
    'inv',
    '1º toque: pega o livro (ícone marrom na mão + HUD mão:Duna). 2º toque: guarda na bolsa.',
  ),
  _HelpEntry(
    'ler',
    'Inicia atividade sustentada de leitura (bookmark). Use call para interromper (M33).',
  ),
  _HelpEntry(
    'retomar',
    'Retoma a melhor atividade interrompida ainda na janela de resume (M33).',
  ),
  _HelpEntry(
    'rotina',
    'Roda BehaviorRoutine prepareSleep (preset + loadout + bubble). wakeUp tem branch chuveiro/rosto (M34).',
  ),
  _HelpEntry(
    'manhã',
    'Executa rotina morning ponta a ponta e em seguida bedtime → sleep (M35).',
  ),
  _HelpEntry(
    'sair',
    'Prep de saída (itens + loadout travel) → trânsito → arriveHome com drop-zone (M36).',
  ),
  _HelpEntry(
    'janta',
    'Cozinha + refeição compartilhada (2 pawns), reduz Need.food e deixa vestígios (M37).',
  ),
  _HelpEntry(
    'tela',
    'Avança workpiece de pintura em duas sessões; stage/visualProgress muda (M38).',
  ),
  _HelpEntry(
    'prep',
    'Checa PreparationRequirement do contexto work e coleta itens pro bag (M39).',
  ),
  _HelpEntry(
    'jet',
    'Viagem SP→hotel Tóquio: SceneClock muda fuso; body clock adapta aos poucos (M40).',
  ),
  _HelpEntry(
    'mapa',
    'World map → materializa café abstrato e inicia trânsito (M41).',
  ),
  _HelpEntry(
    'custom',
    'Registry (sax) + cria prop/activity custom sem scripting (M42/M43). Ports M44 null/sim.',
  ),
  _HelpEntry(
    'gate',
    'Salva snapshot Mirror-Ready (M47) e checa gate M50 (invariantes/content/presets).',
  ),
];

class _SpeedChip extends StatelessWidget {
  const _SpeedChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF4A525C)),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFFE8E6E3),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
