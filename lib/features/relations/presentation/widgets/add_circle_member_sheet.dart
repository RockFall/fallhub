import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../application/relations_controllers.dart';
import '../../application/relations_providers.dart';
import '../relations_visuals.dart';

class AddCircleMemberSheet extends ConsumerWidget {
  const AddCircleMemberSheet({super.key, required this.circle});

  final FriendshipCircle circle;

  static Future<void> show(BuildContext context, FriendshipCircle circle) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => AddCircleMemberSheet(circle: circle),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final people = (ref.watch(peopleProvider).value ?? const [])
        .where((p) => !p.isArchived)
        .toList();
    final memberships =
        ref.watch(friendshipMembershipsProvider).value ?? const [];
    final linked = {
      for (final link in memberships)
        if (link.circleId == circle.id) link.personId,
    };
    final candidates = people.where((p) => !linked.contains(p.id)).toList();

    return Padding(
      padding: EdgeInsets.only(
        left: ColonySpacing.lg,
        right: ColonySpacing.lg,
        top: ColonySpacing.lg,
        bottom: MediaQuery.viewInsetsOf(context).bottom + ColonySpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppStrings.circleAddMember,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: ColonySpacing.md),
          if (candidates.isEmpty)
            Text(AppStrings.circleAddMemberEmpty)
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 360),
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final person in candidates)
                    ListTile(
                      leading: PersonGlyph(person: person),
                      title: Text(person.displayName),
                      onTap: () async {
                        await ref
                            .read(relationsControllerProvider.notifier)
                            .ensureFriendship(person: person);
                        await ref
                            .read(relationsControllerProvider.notifier)
                            .linkPersonToCircle(
                              personId: person.id,
                              circleId: circle.id,
                            );
                        if (!context.mounted) return;
                        Navigator.pop(context);
                      },
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
