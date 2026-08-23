import 'package:colony_domain/colony_domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import 'relations_providers.dart';

class RelationsController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<Person?> create({
    required String displayName,
    String? preferredName,
    List<String> relationshipTypes = const [],
    String? notes,
    DateTime? birthday,
    bool alsoFriendship = false,
    FriendshipKind friendshipKind = FriendshipKind.unspecified,
    FriendshipCadence? friendshipCadence,
  }) async {
    state = const AsyncLoading();
    Person? created;
    state = await AsyncValue.guard(() async {
      final profile = await ref.read(repositoriesProvider).profiles.getActive();
      if (profile == null) throw StateError('Perfil não configurado');
      created = await ref.read(repositoriesProvider).people.create(
            profileId: profile.id,
            displayName: displayName,
            preferredName: preferredName,
            relationshipTypes: relationshipTypes,
            notes: notes,
            birthday: birthday,
          );
      if (alsoFriendship && created != null) {
        await ref.read(repositoriesProvider).friendships.ensureForPerson(
              profileId: profile.id,
              personId: created!.id,
              kind: friendshipKind,
              cadence: friendshipCadence,
            );
      }
    });
    if (state.hasError) return null;
    ref.invalidate(peopleProvider);
    ref.invalidate(friendshipsProvider);
    return created;
  }

  Future<Person?> savePerson(Person person) async {
    state = const AsyncLoading();
    Person? updated;
    state = await AsyncValue.guard(() async {
      updated = await ref.read(repositoriesProvider).people.save(person);
    });
    if (state.hasError) return null;
    ref.invalidate(peopleProvider);
    return updated;
  }

  Future<Person?> archive(Person person) async {
    state = const AsyncLoading();
    Person? archived;
    state = await AsyncValue.guard(() async {
      archived = await ref.read(repositoriesProvider).people.archive(person);
    });
    if (state.hasError) return null;
    ref.invalidate(peopleProvider);
    return archived;
  }

  Future<PersonInteraction?> logInteraction({
    required Person person,
    required InteractionKind kind,
    required DateTime occurredAt,
    String? note,
  }) async {
    state = const AsyncLoading();
    PersonInteraction? created;
    state = await AsyncValue.guard(() async {
      final profile = await ref.read(repositoriesProvider).profiles.getActive();
      if (profile == null) throw StateError('Perfil não configurado');
      created = await ref.read(repositoriesProvider).people.logInteraction(
            profileId: profile.id,
            person: person,
            kind: kind,
            occurredAt: occurredAt,
            note: note,
          );
    });
    if (state.hasError) return null;
    ref.invalidate(peopleProvider);
    ref.invalidate(personInteractionsProvider(person.id));
    ref.invalidate(allPersonInteractionsProvider);
    return created;
  }

  Future<List<PersonInteraction>> logEncounter({
    required List<Person> people,
    required InteractionKind kind,
    required DateTime occurredAt,
    String? note,
  }) async {
    final created = <PersonInteraction>[];
    for (final person in people) {
      final ix = await logInteraction(
        person: person,
        kind: kind,
        occurredAt: occurredAt,
        note: note,
      );
      if (ix != null) created.add(ix);
    }
    return created;
  }

  Future<Friendship?> ensureFriendship({
    required Person person,
    FriendshipKind kind = FriendshipKind.unspecified,
    FriendshipCadence? cadence,
    String? howWeMet,
    String? notes,
    Iterable<EntityId> circleIds = const [],
  }) async {
    state = const AsyncLoading();
    Friendship? created;
    state = await AsyncValue.guard(() async {
      final profile = await ref.read(repositoriesProvider).profiles.getActive();
      if (profile == null) throw StateError('Perfil não configurado');
      created = await ref.read(repositoriesProvider).friendships.ensureForPerson(
            profileId: profile.id,
            personId: person.id,
            kind: kind,
            cadence: cadence,
            howWeMet: howWeMet,
            notes: notes,
          );
      await ref.read(repositoriesProvider).friendships.replacePersonCircles(
            personId: person.id,
            circleIds: circleIds,
          );
    });
    if (state.hasError) return null;
    _invalidateFriendships();
    return created;
  }

  Future<Friendship?> saveFriendship(
    Friendship friendship, {
    Iterable<EntityId>? circleIds,
  }) async {
    state = const AsyncLoading();
    Friendship? updated;
    state = await AsyncValue.guard(() async {
      updated =
          await ref.read(repositoriesProvider).friendships.save(friendship);
      if (circleIds != null) {
        await ref.read(repositoriesProvider).friendships.replacePersonCircles(
              personId: friendship.personId,
              circleIds: circleIds,
            );
      }
    });
    if (state.hasError) return null;
    _invalidateFriendships();
    return updated;
  }

  Future<Friendship?> archiveFriendship(Friendship friendship) async {
    state = const AsyncLoading();
    Friendship? archived;
    state = await AsyncValue.guard(() async {
      archived =
          await ref.read(repositoriesProvider).friendships.archive(friendship);
    });
    if (state.hasError) return null;
    _invalidateFriendships();
    return archived;
  }

  Future<FriendshipCircle?> createCircle({
    required String name,
    String? notes,
    FriendshipCadence? defaultCadence,
  }) async {
    state = const AsyncLoading();
    FriendshipCircle? created;
    state = await AsyncValue.guard(() async {
      final profile = await ref.read(repositoriesProvider).profiles.getActive();
      if (profile == null) throw StateError('Perfil não configurado');
      created = await ref.read(repositoriesProvider).friendships.createCircle(
            profileId: profile.id,
            name: name,
            notes: notes,
            defaultCadence: defaultCadence,
          );
    });
    if (state.hasError) return null;
    ref.invalidate(friendshipCirclesProvider);
    return created;
  }

  Future<bool> linkPersonToCircle({
    required EntityId personId,
    required EntityId circleId,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(repositoriesProvider).friendships.linkPersonToCircle(
            personId: personId,
            circleId: circleId,
          );
    });
    if (state.hasError) return false;
    _invalidateFriendships();
    return true;
  }

  Future<bool> unlinkPersonFromCircle({
    required EntityId personId,
    required EntityId circleId,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(repositoriesProvider).friendships.unlinkPersonFromCircle(
            personId: personId,
            circleId: circleId,
          );
    });
    if (state.hasError) return false;
    _invalidateFriendships();
    return true;
  }

  Future<FriendshipCircle?> archiveCircle(FriendshipCircle circle) async {
    state = const AsyncLoading();
    FriendshipCircle? archived;
    state = await AsyncValue.guard(() async {
      archived =
          await ref.read(repositoriesProvider).friendships.archiveCircle(circle);
    });
    if (state.hasError) return null;
    ref.invalidate(friendshipCirclesProvider);
    ref.invalidate(friendshipMembershipsProvider);
    return archived;
  }

  void _invalidateFriendships() {
    ref.invalidate(friendshipsProvider);
    ref.invalidate(friendshipCirclesProvider);
    ref.invalidate(friendshipMembershipsProvider);
    ref.invalidate(allPersonInteractionsProvider);
  }

  Future<Organization?> createOrganization({
    required String name,
    required OrganizationKind kind,
    String? notes,
  }) async {
    state = const AsyncLoading();
    Organization? created;
    state = await AsyncValue.guard(() async {
      final profile = await ref.read(repositoriesProvider).profiles.getActive();
      if (profile == null) throw StateError('Perfil não configurado');
      created = await ref.read(repositoriesProvider).organizations.create(
            profileId: profile.id,
            name: name,
            kind: kind,
            notes: notes,
          );
    });
    if (state.hasError) return null;
    ref.invalidate(organizationsProvider);
    return created;
  }

  Future<Organization?> saveOrganization(Organization organization) async {
    state = const AsyncLoading();
    Organization? updated;
    state = await AsyncValue.guard(() async {
      updated = await ref
          .read(repositoriesProvider)
          .organizations
          .save(organization);
    });
    if (state.hasError) return null;
    ref.invalidate(organizationsProvider);
    return updated;
  }

  Future<Organization?> archiveOrganization(Organization organization) async {
    state = const AsyncLoading();
    Organization? archived;
    state = await AsyncValue.guard(() async {
      archived = await ref
          .read(repositoriesProvider)
          .organizations
          .archive(organization);
    });
    if (state.hasError) return null;
    ref.invalidate(organizationsProvider);
    return archived;
  }

  Future<bool> linkPersonToOrganization({
    required EntityId personId,
    required EntityId organizationId,
    String? role,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(repositoriesProvider).organizations.linkPerson(
            personId: personId,
            organizationId: organizationId,
            role: role,
          );
    });
    if (state.hasError) return false;
    ref.invalidate(organizationMembersProvider(organizationId.value));
    ref.invalidate(personMembershipsProvider(personId.value));
    return true;
  }

  Future<bool> unlinkPersonFromOrganization({
    required EntityId personId,
    required EntityId organizationId,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(repositoriesProvider).organizations.unlinkPerson(
            personId: personId,
            organizationId: organizationId,
          );
    });
    if (state.hasError) return false;
    ref.invalidate(organizationMembersProvider(organizationId.value));
    ref.invalidate(personMembershipsProvider(personId.value));
    return true;
  }

  Future<Commitment?> createCommitment({
    required String description,
    String madeByLabel = 'eu',
    EntityId? madeToPersonId,
    EntityId? madeToOrganizationId,
    String? madeToLabel,
    DateTime? dueAt,
    String? notes,
    EntityId? linkedQuestId,
  }) async {
    state = const AsyncLoading();
    Commitment? created;
    state = await AsyncValue.guard(() async {
      final profile = await ref.read(repositoriesProvider).profiles.getActive();
      if (profile == null) throw StateError('Perfil não configurado');
      created = await ref.read(repositoriesProvider).commitments.create(
            profileId: profile.id,
            description: description,
            madeByLabel: madeByLabel,
            madeToPersonId: madeToPersonId,
            madeToOrganizationId: madeToOrganizationId,
            madeToLabel: madeToLabel,
            dueAt: dueAt,
            notes: notes,
            linkedQuestId: linkedQuestId,
          );
    });
    if (state.hasError) return null;
    ref.invalidate(commitmentsProvider);
    return created;
  }

  Future<Commitment?> saveCommitment(Commitment commitment) async {
    state = const AsyncLoading();
    Commitment? updated;
    state = await AsyncValue.guard(() async {
      updated =
          await ref.read(repositoriesProvider).commitments.save(commitment);
    });
    if (state.hasError) return null;
    ref.invalidate(commitmentsProvider);
    return updated;
  }

  Future<Commitment?> setCommitmentStatus(
    Commitment commitment,
    CommitmentStatus status,
  ) async {
    state = const AsyncLoading();
    Commitment? updated;
    state = await AsyncValue.guard(() async {
      updated = await ref
          .read(repositoriesProvider)
          .commitments
          .setStatus(commitment, status);
    });
    if (state.hasError) return null;
    ref.invalidate(commitmentsProvider);
    return updated;
  }
}

final relationsControllerProvider =
    AsyncNotifierProvider<RelationsController, void>(RelationsController.new);
