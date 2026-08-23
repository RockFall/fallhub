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

final allPersonInteractionsProvider =
    StreamProvider<List<PersonInteraction>>((ref) async* {
  final profile = await ref.watch(profileProvider.future);
  if (profile == null) {
    yield [];
    return;
  }
  yield* ref.watch(repositoriesProvider).people.watchAllInteractions(profile.id);
});

final friendshipsProvider = StreamProvider<List<Friendship>>((ref) async* {
  final profile = await ref.watch(profileProvider.future);
  if (profile == null) {
    yield [];
    return;
  }
  yield* ref.watch(repositoriesProvider).friendships.watchAll(profile.id);
});

final friendshipCirclesProvider =
    StreamProvider<List<FriendshipCircle>>((ref) async* {
  final profile = await ref.watch(profileProvider.future);
  if (profile == null) {
    yield [];
    return;
  }
  yield* ref.watch(repositoriesProvider).friendships.watchCircles(profile.id);
});

final friendshipMembershipsProvider =
    StreamProvider<List<FriendshipCircleMembership>>((ref) async* {
  final profile = await ref.watch(profileProvider.future);
  if (profile == null) {
    yield [];
    return;
  }
  yield* ref
      .watch(repositoriesProvider)
      .friendships
      .watchMemberships(profile.id);
});

final friendshipOverviewsProvider = Provider<AsyncValue<List<FriendshipOverview>>>(
  (ref) {
    final people = ref.watch(peopleProvider);
    final friendships = ref.watch(friendshipsProvider);
    final circles = ref.watch(friendshipCirclesProvider);
    final memberships = ref.watch(friendshipMembershipsProvider);
    final interactions = ref.watch(allPersonInteractionsProvider);
    if (people.isLoading ||
        friendships.isLoading ||
        circles.isLoading ||
        memberships.isLoading ||
        interactions.isLoading) {
      return const AsyncLoading();
    }
    final error = people.error ??
        friendships.error ??
        circles.error ??
        memberships.error ??
        interactions.error;
    if (error != null) {
      return AsyncError(error, StackTrace.current);
    }
    return AsyncData(
      FriendshipOverview.assemble(
        people: people.value ?? const [],
        friendships: friendships.value ?? const [],
        circles: circles.value ?? const [],
        memberships: memberships.value ?? const [],
        interactions: interactions.value ?? const [],
        now: DateTime.now().toUtc(),
      ),
    );
  },
);

final friendshipForPersonProvider =
    Provider.family<Friendship?, EntityId>((ref, personId) {
  final friendships = ref.watch(friendshipsProvider).valueOrNull ?? const [];
  for (final friendship in friendships) {
    if (friendship.personId == personId && !friendship.isArchived) {
      return friendship;
    }
  }
  return null;
});

final commitmentsProvider = StreamProvider<List<Commitment>>((ref) async* {
  final profile = await ref.watch(profileProvider.future);
  if (profile == null) {
    yield [];
    return;
  }
  yield* ref.watch(repositoriesProvider).commitments.watchAll(profile.id);
});
