import 'package:colony_design_system/colony_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/localization/app_strings.dart';

class CommandPalette extends ConsumerStatefulWidget {
  const CommandPalette({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (_) => const CommandPalette(),
    );
  }

  @override
  ConsumerState<CommandPalette> createState() => _CommandPaletteState();
}

class _CommandPaletteState extends ConsumerState<CommandPalette> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  final _commands = const [
    _PaletteCommand('Revisão semanal', '/pawn/review/weekly', Icons.date_range_outlined),
    _PaletteCommand('Ir para Colônia', '/colony', Icons.home_work_outlined),
    _PaletteCommand('Habitat', '/colony/habitat', Icons.cottage_outlined),
    _PaletteCommand(
      'Criar colonista',
      '/colony/pawn-create',
      Icons.face_retouching_natural,
    ),
    _PaletteCommand('Ir para Trabalho', '/work', Icons.grid_on_outlined),
    _PaletteCommand('Ir para Agenda', '/work/schedule', Icons.calendar_today_outlined),
    _PaletteCommand('Missões', '/quests', Icons.flag_outlined),
    _PaletteCommand('Nova missão', '/quests?create=1', Icons.add),
    _PaletteCommand('Projetos', '/projects', Icons.folder_outlined),
    _PaletteCommand('Novo projeto', '/projects?create=1', Icons.create_new_folder_outlined),
    _PaletteCommand('Decisões', '/decisions', Icons.gavel_outlined),
    _PaletteCommand('Pesquisa', '/research', Icons.science_outlined),
    _PaletteCommand('Flashcards', '/flashcards', Icons.style_outlined),
    _PaletteCommand('Estudar flashcards', '/flashcards/study', Icons.play_arrow_outlined),
    _PaletteCommand('Novo cartão', '/flashcards?capture=1', Icons.note_add_outlined),
    _PaletteCommand('Novo baralho', '/flashcards', Icons.add),
    _PaletteCommand('Novo nó de pesquisa', '/research?create=1', Icons.add),
    _PaletteCommand('Finanças', '/resources/finance', Icons.account_balance_wallet_outlined),
    _PaletteCommand('Nova conta financeira', '/resources/finance?create=account', Icons.add),
    _PaletteCommand('Saúde', '/resources/health', Icons.favorite_outline),
    _PaletteCommand('Nova condição de saúde', '/resources/health', Icons.add),
    _PaletteCommand('Inventário', '/resources/inventory', Icons.inventory_2_outlined),
    _PaletteCommand('Novo item de inventário', '/resources/inventory', Icons.add),
    _PaletteCommand('Viagens', '/resources/travel', Icons.luggage_outlined),
    _PaletteCommand('Nova viagem', '/resources/travel', Icons.add),
    _PaletteCommand('Casa', '/resources/home', Icons.home_repair_service_outlined),
    _PaletteCommand('Nova manutenção', '/resources/home', Icons.add),
    _PaletteCommand('Zonas', '/resources/zones', Icons.place_outlined),
    _PaletteCommand('Nova zona', '/resources/zones', Icons.add),
    _PaletteCommand('Pessoas', '/relations/people', Icons.people_outline),
    _PaletteCommand('Nova pessoa', '/relations/people', Icons.person_add_outlined),
    _PaletteCommand(
      'Organizações',
      '/relations/organizations',
      Icons.apartment_outlined,
    ),
    _PaletteCommand(
      'Nova organização',
      '/relations/organizations',
      Icons.add,
    ),
    _PaletteCommand(
      'Compromissos',
      '/relations/commitments',
      Icons.handshake_outlined,
    ),
    _PaletteCommand(
      'Novo compromisso',
      '/relations/commitments',
      Icons.add,
    ),
    _PaletteCommand('Ir para Caixa de entrada', '/inbox', Icons.inbox_outlined),
    _PaletteCommand('Ir para Crônica', '/chronicle', Icons.history),
    _PaletteCommand('Ir para Configurações', '/settings', Icons.settings_outlined),
    _PaletteCommand('Sincronização', '/settings/sync', Icons.sync_outlined),
    _PaletteCommand(
      'Integrações',
      '/settings/integrations',
      Icons.extension_outlined,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _focus.requestFocus();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _controller.text.toLowerCase();
    final filtered = _commands
        .where((c) => c.label.toLowerCase().contains(query))
        .toList();

    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
      },
      child: Actions(
        actions: {
          DismissIntent: CallbackAction<DismissIntent>(
            onInvoke: (_) {
              Navigator.of(context).pop();
              return null;
            },
          ),
        },
        child: Dialog(
          backgroundColor: ColonyColors.panel,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(ColonySpacing.lg),
                  child: TextField(
                    controller: _controller,
                    focusNode: _focus,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: AppStrings.commandHint,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final cmd = filtered[index];
                      return ListTile(
                        leading: Icon(cmd.icon),
                        title: Text(cmd.label),
                        onTap: () {
                          Navigator.of(context).pop();
                          context.go(cmd.route);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PaletteCommand {
  const _PaletteCommand(this.label, this.route, this.icon);

  final String label;
  final String route;
  final IconData icon;
}
