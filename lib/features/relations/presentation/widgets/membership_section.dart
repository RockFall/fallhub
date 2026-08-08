import 'package:colony_design_system/colony_design_system.dart';
import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/app_strings.dart';
import '../../application/relations_controllers.dart';
import '../../application/relations_providers.dart';

class PersonMembershipsSection extends ConsumerWidget {
  const PersonMembershipsSection({super.key, required this.person});

  final Person person;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberships = ref.watch(personMembershipsProvider(person.id.value));
    final allOrgs = ref.watch(organizationsProvider);

    return Padding(
      padding: const EdgeInsets.only(top: ColonySpacing.md),
      child: ColonyPanel(
        title: AppStrings.personMemberships,
        icon: Icons.apartment_outlined,
        actions: [
          IconButton(
            tooltip: AppStrings.personLinkOrganization,
            icon: const Icon(Icons.link, size: 20),
            onPressed: () async {
              final current = memberships.maybeWhen(
                data: (orgs) => orgs,
                orElse: () => const <Organization>[],
              );
              final available = allOrgs.maybeWhen(
                data: (orgs) => orgs
                    .where(
                      (o) =>
                          !o.isArchived &&
                          !current.any((c) => c.id == o.id),
                    )
                    .toList(),
                orElse: () => const <Organization>[],
              );
              if (available.isEmpty) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text(AppStrings.membershipPickerEmpty)),
                );
                return;
              }
              final selected = await showDialog<Organization>(
                context: context,
                builder: (ctx) => SimpleDialog(
                  title: const Text(AppStrings.personLinkOrganization),
                  children: available
                      .map(
                        (org) => SimpleDialogOption(
                          onPressed: () => Navigator.pop(ctx, org),
                          child: Text(org.name),
                        ),
                      )
                      .toList(),
                ),
              );
              if (selected == null) return;
              await ref
                  .read(relationsControllerProvider.notifier)
                  .linkPersonToOrganization(
                    personId: person.id,
                    organizationId: selected.id,
                  );
            },
          ),
        ],
        child: memberships.when(
          loading: () => const Text(AppStrings.loading),
          error: (_, __) => const Text(AppStrings.errorGeneric),
          data: (orgs) {
            if (orgs.isEmpty) {
              return Text(
                AppStrings.personNoMemberships,
                style: Theme.of(context).textTheme.bodyMedium,
              );
            }
            return Column(
              children: orgs
                  .map(
                    (org) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(org.name),
                      subtitle: Text(AppStrings.organizationKindLabel(org.kind)),
                      trailing: IconButton(
                        tooltip: AppStrings.personUnlinkOrganization,
                        icon: const Icon(Icons.link_off, size: 20),
                        onPressed: () => ref
                            .read(relationsControllerProvider.notifier)
                            .unlinkPersonFromOrganization(
                              personId: person.id,
                              organizationId: org.id,
                            ),
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ),
    );
  }
}

class OrganizationMembersSection extends ConsumerWidget {
  const OrganizationMembersSection({super.key, required this.organization});

  final Organization organization;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members =
        ref.watch(organizationMembersProvider(organization.id.value));
    final allPeople = ref.watch(peopleProvider);

    return Padding(
      padding: const EdgeInsets.only(top: ColonySpacing.md),
      child: ColonyPanel(
        title: AppStrings.organizationMembers,
        icon: Icons.people_outline,
        actions: [
          IconButton(
            tooltip: AppStrings.organizationLinkPerson,
            icon: const Icon(Icons.link, size: 20),
            onPressed: () async {
              final current = members.maybeWhen(
                data: (people) => people,
                orElse: () => const <Person>[],
              );
              final available = allPeople.maybeWhen(
                data: (people) => people
                    .where(
                      (p) =>
                          !p.isArchived &&
                          !current.any((c) => c.id == p.id),
                    )
                    .toList(),
                orElse: () => const <Person>[],
              );
              if (available.isEmpty) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text(AppStrings.membershipPickerEmpty)),
                );
                return;
              }
              final selected = await showDialog<Person>(
                context: context,
                builder: (ctx) => SimpleDialog(
                  title: const Text(AppStrings.organizationLinkPerson),
                  children: available
                      .map(
                        (person) => SimpleDialogOption(
                          onPressed: () => Navigator.pop(ctx, person),
                          child: Text(person.displayName),
                        ),
                      )
                      .toList(),
                ),
              );
              if (selected == null) return;
              await ref
                  .read(relationsControllerProvider.notifier)
                  .linkPersonToOrganization(
                    personId: selected.id,
                    organizationId: organization.id,
                  );
            },
          ),
        ],
        child: members.when(
          loading: () => const Text(AppStrings.loading),
          error: (_, __) => const Text(AppStrings.errorGeneric),
          data: (people) {
            if (people.isEmpty) {
              return Text(
                AppStrings.organizationNoMembers,
                style: Theme.of(context).textTheme.bodyMedium,
              );
            }
            return Column(
              children: people
                  .map(
                    (person) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(person.displayName),
                      trailing: IconButton(
                        tooltip: AppStrings.organizationUnlinkPerson,
                        icon: const Icon(Icons.link_off, size: 20),
                        onPressed: () => ref
                            .read(relationsControllerProvider.notifier)
                            .unlinkPersonFromOrganization(
                              personId: person.id,
                              organizationId: organization.id,
                            ),
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ),
    );
  }
}
