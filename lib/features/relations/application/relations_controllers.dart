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
          );
    });
    if (state.hasError) return null;
    ref.invalidate(peopleProvider);
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
    return created;
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
