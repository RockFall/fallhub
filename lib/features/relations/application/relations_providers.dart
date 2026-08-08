import 'package:colony_domain/colony_domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';

final peopleProvider = StreamProvider<List<Person>>((ref) async* {
  final profile = await ref.watch(profileProvider.future);
  if (profile == null) {
    yield [];
    return;
  }
  yield* ref.watch(repositoriesProvider).people.watchAll(profile.id);
});

final personInteractionsProvider =
    StreamProvider.family<List<PersonInteraction>, EntityId>((ref, personId) async* {
  yield* ref
      .watch(repositoriesProvider)
      .people
      .watchInteractionsForPerson(personId);
});

final organizationsProvider =
    StreamProvider<List<Organization>>((ref) async* {
  final profile = await ref.watch(profileProvider.future);
  if (profile == null) {
    yield [];
    return;
  }
  yield* ref.watch(repositoriesProvider).organizations.watchAll(profile.id);
});

final organizationMembersProvider =
    StreamProvider.family<List<Person>, String>((ref, organizationId) {
  return ref
      .watch(repositoriesProvider)
      .organizations
      .watchMembers(EntityId(organizationId));
});

final personMembershipsProvider =
    StreamProvider.family<List<Organization>, String>((ref, personId) {
  return ref
      .watch(repositoriesProvider)
      .organizations
      .watchMembershipsForPerson(EntityId(personId));
});

final commitmentsProvider = StreamProvider<List<Commitment>>((ref) async* {
  final profile = await ref.watch(profileProvider.future);
  if (profile == null) {
    yield [];
    return;
  }
  yield* ref.watch(repositoriesProvider).commitments.watchAll(profile.id);
});
