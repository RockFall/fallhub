import 'package:colony_design_system/colony_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:living_habitat_assets/living_habitat_assets.dart';

import '../../../app/localization/app_strings.dart';
import '../application/colony_roster.dart';
import '../application/pawn_appearance_provider.dart';
import '../flame/habitat_pawn_draw.dart';
import '../flame/habitat_tint.dart';
import 'widgets/color_swatch_row.dart';
import 'widgets/pawn_preview.dart';

enum _CreateCategory { identity, body, hair, clothes }

/// RimWorld-style colonist creator — categories · live preview · options.
class CharacterCreateScreen extends ConsumerStatefulWidget {
  const CharacterCreateScreen({super.key, this.memberId});

  /// When set, edits that roster member (V9). Otherwise edits the player slot.
  final String? memberId;

  @override
  ConsumerState<CharacterCreateScreen> createState() =>
      _CharacterCreateScreenState();
}

class _CharacterCreateScreenState extends ConsumerState<CharacterCreateScreen> {
  late PawnAppearance _draft;
  late PawnAppearance _baseline;
  late final TextEditingController _nameCtrl;
  _CreateCategory _category = _CreateCategory.hair;
  var _seeded = false;
  var _userEdited = false;
  String? _memberId;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_seeded) return;
    final roster = ref.read(colonyRosterProvider);
    String? playerId;
    for (final m in roster) {
      if (m.isPlayer) {
        playerId = m.id;
        break;
      }
    }
    _memberId = widget.memberId ?? playerId ?? 'player';
    final member = ref.read(colonyRosterProvider.notifier).byId(_memberId!) ??
        (roster.isEmpty ? null : roster.first);
    _applySeed(member?.appearance ?? ref.read(pawnAppearanceProvider));
    _seeded = true;
  }

  void _applySeed(PawnAppearance current) {
    _draft = current.copy();
    _baseline = current.copy();
    _nameCtrl.text = _draft.name;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _touch(void Function() fn) {
    _userEdited = true;
    setState(fn);
  }

  void _randomAll() {
    _touch(() {
      _draft.randomize(includeSkin: true);
      if (_nameCtrl.text.trim().isEmpty) {
        _draft.name = 'Colonista';
        _nameCtrl.text = _draft.name;
      } else {
        _draft.name = _nameCtrl.text.trim();
      }
    });
  }

  void _randomHair() {
    _touch(() => _draft.randomizeHair());
  }

  void _randomClothes() {
    _touch(() => _draft.randomizeClothes());
  }

  void _reset() {
    _touch(() {
      _draft = _baseline.copy();
      _nameCtrl.text = _draft.name;
    });
  }

  Future<void> _saveDraft() async {
    _draft.name = _nameCtrl.text.trim().isEmpty
        ? 'Colonista'
        : _nameCtrl.text.trim();
    final id = _memberId ?? 'player';
    await ref.read(colonyRosterProvider.notifier).replaceAppearance(id, _draft);
    // Legacy single-slot provider — keep player in sync for older callers.
    final member = ref.read(colonyRosterProvider.notifier).byId(id);
    if (member?.isPlayer ?? id == 'player') {
      await ref.read(pawnAppearanceProvider.notifier).replace(_draft);
    }
  }

  Future<void> _accept() async {
    await _saveDraft();
    if (!mounted) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/colony/habitat');
    }
  }

  void _close() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/colony');
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(colonyRosterProvider, (prev, next) {
      if (_userEdited || !mounted || _memberId == null) return;
      for (final m in next) {
        if (m.id == _memberId) {
          setState(() => _applySeed(m.appearance));
          break;
        }
      }
    });

    final size = MediaQuery.sizeOf(context);
    final wide = size.width >= 900;

    return Padding(
      padding: const EdgeInsets.all(ColonySpacing.sm),
      child: ColonySurface(
        kind: ColonySurfaceKind.window,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Toolbar(
              title: AppStrings.habitatCreateTitle,
              onAccept: _accept,
              onClose: _close,
            ),
            const Divider(height: 1, color: ColonyColors.borderSeparator),
            Expanded(
              child: wide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(width: 148, child: _categoryRail()),
                        const VerticalDivider(
                          width: 1,
                          color: ColonyColors.borderSeparator,
                        ),
                        SizedBox(
                          width: 300,
                          child: _previewPane(
                            compact: true,
                            previewSize: HabitatPawnDraw.portraitPx * 1.5,
                          ),
                        ),
                        const VerticalDivider(
                          width: 1,
                          color: ColonyColors.borderSeparator,
                        ),
                        Expanded(child: _optionsPane()),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          height: 200,
                          child: _previewPane(
                            compact: true,
                            previewSize: HabitatPawnDraw.portraitPx,
                          ),
                        ),
                        const Divider(
                          height: 1,
                          color: ColonyColors.borderSeparator,
                        ),
                        _categoryChips(),
                        const Divider(
                          height: 1,
                          color: ColonyColors.borderSeparator,
                        ),
                        Expanded(child: _optionsPane()),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _categoryRail() {
    return ColonySurface(
      kind: ColonySurfaceKind.panel,
      padding: const EdgeInsets.symmetric(vertical: ColonySpacing.sm),
      child: ListView(
        children: [
          for (final c in _CreateCategory.values)
            _CategoryTile(
              label: _categoryLabel(c),
              icon: _categoryIcon(c),
              selected: _category == c,
              onTap: () => _touch(() => _category = c),
            ),
        ],
      ),
    );
  }

  Widget _categoryChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: ColonySpacing.sm,
        vertical: ColonySpacing.xs,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final c in _CreateCategory.values) ...[
              FilterChip(
                avatar: Icon(_categoryIcon(c), size: 16),
                label: Text(_categoryLabel(c)),
                selected: _category == c,
                onSelected: (_) => _touch(() => _category = c),
              ),
              const SizedBox(width: ColonySpacing.xs),
            ],
          ],
        ),
      ),
    );
  }

  Widget _previewPane({
    required bool compact,
    double previewSize = HabitatPawnDraw.portraitPx * 1.35,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ColonySpacing.sm,
        ColonySpacing.sm,
        ColonySpacing.sm,
        ColonySpacing.xs,
      ),
      child: Column(
        children: [
          Text(
            _draft.name.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: ColonyColors.textSeparator,
                  letterSpacing: 1.2,
                ),
          ),
          const SizedBox(height: ColonySpacing.xs),
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: PawnPreviewStage(
                    appearance: _draft,
                    size: previewSize,
                    compact: compact,
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: AppStrings.habitatResetLook,
                        visualDensity: VisualDensity.compact,
                        onPressed: _reset,
                        icon: const Icon(Icons.undo, size: 20),
                      ),
                      IconButton(
                        tooltip: AppStrings.habitatRandomAll,
                        visualDensity: VisualDensity.compact,
                        onPressed: _randomAll,
                        icon: const Icon(Icons.casino_outlined, size: 20),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _optionsPane() {
    return ColoredBox(
      color: ColonyColors.panel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              ColonySpacing.md,
              ColonySpacing.md,
              ColonySpacing.sm,
              ColonySpacing.sm,
            ),
            child: Row(
              children: [
                Icon(_categoryIcon(_category), size: 18),
                const SizedBox(width: ColonySpacing.sm),
                Expanded(
                  child: Text(
                    _categoryLabel(_category),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (_category == _CreateCategory.hair)
                  IconButton(
                    tooltip: AppStrings.habitatRandomHair,
                    onPressed: _randomHair,
                    icon: const Icon(Icons.shuffle, size: 20),
                  ),
                if (_category == _CreateCategory.clothes)
                  IconButton(
                    tooltip: AppStrings.habitatRandomClothes,
                    onPressed: _randomClothes,
                    icon: const Icon(Icons.shuffle, size: 20),
                  ),
              ],
            ),
          ),
          const Divider(height: 1, color: ColonyColors.borderSeparator),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(ColonySpacing.md),
              child: switch (_category) {
                _CreateCategory.identity => _identityOptions(),
                _CreateCategory.body => _bodyOptions(),
                _CreateCategory.hair => _hairOptions(),
                _CreateCategory.clothes => _clothesOptions(),
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _identityOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          AppStrings.habitatCreateName,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: ColonyColors.textSeparator,
              ),
        ),
        const SizedBox(height: ColonySpacing.sm),
        TextField(
          controller: _nameCtrl,
          style: const TextStyle(color: ColonyColors.textPrimary),
          decoration: const InputDecoration(
            hintText: AppStrings.pawnName,
          ),
          onChanged: (v) => _touch(() => _draft.name = v),
        ),
        const SizedBox(height: ColonySpacing.lg),
        Text(
          AppStrings.habitatCreateIdentityHint,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: ColonyColors.textMuted,
              ),
        ),
      ],
    );
  }

  Widget _bodyOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          AppStrings.habitatBodyType,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: ColonyColors.textSeparator,
              ),
        ),
        const SizedBox(height: ColonySpacing.sm),
        Wrap(
          spacing: ColonySpacing.sm,
          runSpacing: ColonySpacing.sm,
          children: [
            for (final type in HabitatAssets.bodyTypes)
              FilterChip(
                label: Text(PawnAppearance.bodyTypeLabel(type)),
                selected: _draft.bodyType == type,
                onSelected: (_) => _touch(() {
                  _draft.bodyType = type;
                  if (type == 'female') _draft.beardStyle = null;
                }),
              ),
          ],
        ),
        const SizedBox(height: ColonySpacing.lg),
        ColorSwatchRow(
          label: AppStrings.habitatSkinColor,
          colors: PawnPalettes.skinSwatches,
          selected: _draft.skin,
          onSelected: (c) => _touch(() => _draft.skin = c),
        ),
      ],
    );
  }

  Widget _hairOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          AppStrings.habitatHairStyle,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: ColonyColors.textSeparator,
              ),
        ),
        const SizedBox(height: ColonySpacing.sm),
        Wrap(
          spacing: ColonySpacing.sm,
          runSpacing: ColonySpacing.sm,
          children: [
            for (final style in HabitatAssets.hairStyles)
              _HairStyleChip(
                style: style,
                selected: _draft.hairStyle == style,
                appearance: _draft,
                onTap: () => _touch(() => _draft.hairStyle = style),
              ),
          ],
        ),
        const SizedBox(height: ColonySpacing.lg),
        ColorSwatchRow(
          label: AppStrings.habitatHairColor,
          colors: PawnPalettes.hairSwatches,
          selected: _draft.hair,
          onSelected: (c) => _touch(() => _draft.hair = c),
        ),
        const SizedBox(height: ColonySpacing.lg),
        Text(
          AppStrings.habitatBeard,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: ColonyColors.textSeparator,
              ),
        ),
        const SizedBox(height: ColonySpacing.sm),
        Wrap(
          spacing: ColonySpacing.sm,
          runSpacing: ColonySpacing.sm,
          children: [
            FilterChip(
              label: Text(PawnAppearance.beardLabel(null)),
              selected: _draft.beardStyle == null,
              onSelected: (_) => _touch(() => _draft.beardStyle = null),
            ),
            for (final style in HabitatAssets.beardStyles)
              FilterChip(
                label: Text(PawnAppearance.beardLabel(style)),
                selected: _draft.beardStyle == style,
                onSelected: _draft.bodyType == 'female'
                    ? null
                    : (_) => _touch(() => _draft.beardStyle = style),
              ),
          ],
        ),
      ],
    );
  }

  Widget _clothesOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          AppStrings.habitatLoadout,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: ColonyColors.textSeparator,
              ),
        ),
        const SizedBox(height: ColonySpacing.sm),
        Wrap(
          spacing: ColonySpacing.sm,
          runSpacing: ColonySpacing.sm,
          children: [
            for (final id in HabitatAssets.loadoutIds)
              FilterChip(
                label: Text(VisualLoadouts.label(id)),
                selected: _draft.loadoutId == id,
                onSelected: (_) => _touch(() => _draft.applyLoadout(id)),
              ),
          ],
        ),
        const SizedBox(height: ColonySpacing.lg),
        Text(
          AppStrings.habitatApparelTop,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: ColonyColors.textSeparator,
              ),
        ),
        const SizedBox(height: ColonySpacing.sm),
        Wrap(
          spacing: ColonySpacing.sm,
          runSpacing: ColonySpacing.sm,
          children: [
            for (final piece in HabitatAssets.apparelTops)
              FilterChip(
                label: Text(PawnAppearance.apparelLabel(piece)),
                selected: _draft.apparelTop == piece,
                onSelected: (_) => _touch(() => _draft.apparelTop = piece),
              ),
          ],
        ),
        const SizedBox(height: ColonySpacing.lg),
        Text(
          AppStrings.habitatHat,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: ColonyColors.textSeparator,
              ),
        ),
        const SizedBox(height: ColonySpacing.sm),
        Wrap(
          spacing: ColonySpacing.sm,
          runSpacing: ColonySpacing.sm,
          children: [
            FilterChip(
              label: Text(PawnAppearance.hatLabel(null)),
              selected: _draft.hat == null,
              onSelected: (_) => _touch(() => _draft.hat = null),
            ),
            for (final h in HabitatAssets.hats)
              FilterChip(
                label: Text(PawnAppearance.hatLabel(h)),
                selected: _draft.hat == h,
                onSelected: (_) => _touch(() => _draft.hat = h),
              ),
          ],
        ),
        const SizedBox(height: ColonySpacing.lg),
        ColorSwatchRow(
          label: AppStrings.habitatApparelColor,
          colors: StuffPalettes.furnitureSwatches,
          selected: _draft.apparelTint,
          onSelected: (c) => _touch(() => _draft.apparelTint = c),
        ),
      ],
    );
  }

  String _categoryLabel(_CreateCategory c) => switch (c) {
        _CreateCategory.identity => AppStrings.habitatCatIdentity,
        _CreateCategory.body => AppStrings.habitatCatBody,
        _CreateCategory.hair => AppStrings.habitatCatHair,
        _CreateCategory.clothes => AppStrings.habitatCatClothes,
      };

  IconData _categoryIcon(_CreateCategory c) => switch (c) {
        _CreateCategory.identity => Icons.badge_outlined,
        _CreateCategory.body => Icons.accessibility_new,
        _CreateCategory.hair => Icons.face_retouching_natural,
        _CreateCategory.clothes => Icons.checkroom_outlined,
      };
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.title,
    required this.onAccept,
    required this.onClose,
  });

  final String title;
  final VoidCallback onAccept;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: ColonySpacing.sm,
        vertical: ColonySpacing.xs,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title.toUpperCase(),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: ColonyColors.textSeparator,
                    letterSpacing: 0.8,
                  ),
            ),
          ),
          IconButton(
            tooltip: AppStrings.habitatAcceptPawn,
            onPressed: onAccept,
            icon: const Icon(Icons.check_circle, size: 26),
            color: ColonyColors.textOption,
          ),
          IconButton(
            tooltip: AppStrings.close,
            onPressed: onClose,
            icon: const Icon(Icons.close, size: 20),
          ),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? ColonyColors.optionSelected : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: ColonySpacing.md,
            vertical: ColonySpacing.md,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: selected
                    ? ColonyColors.textOption
                    : ColonyColors.textMuted,
              ),
              const SizedBox(width: ColonySpacing.sm),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: selected
                            ? ColonyColors.textOption
                            : ColonyColors.textPrimary,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HairStyleChip extends StatelessWidget {
  const _HairStyleChip({
    required this.style,
    required this.selected,
    required this.appearance,
    required this.onTap,
  });

  final String style;
  final bool selected;
  final PawnAppearance appearance;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final mini = appearance.copy()..hairStyle = style;
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 88,
        padding: const EdgeInsets.all(ColonySpacing.xs),
        decoration: BoxDecoration(
          color: selected ? ColonyColors.optionSelected : ColonyColors.window,
          border: Border.all(
            color: selected
                ? ColonyColors.textMouseover
                : ColonyColors.borderStandard,
          ),
        ),
        child: Column(
          children: [
            PawnPreview(appearance: mini, size: HabitatPawnDraw.chipPx),
            const SizedBox(height: 4),
            Text(
              PawnAppearance.hairStyleLabel(style),
              style: Theme.of(context).textTheme.labelSmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
