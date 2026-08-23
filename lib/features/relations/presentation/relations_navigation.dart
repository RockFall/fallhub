import 'package:colony_domain/colony_domain.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'circle_detail_screen.dart';
import 'friendship_detail_screen.dart';
import 'person_detail_screen.dart';

void goRelations(BuildContext context, String path) {
  final router = GoRouter.maybeOf(context);
  if (router != null) {
    context.go(path);
  }
}

void openPersonDetail(BuildContext context, EntityId personId) {
  final router = GoRouter.maybeOf(context);
  if (router != null) {
    context.go('/relations/people/${personId.value}');
    return;
  }
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => PersonDetailScreen(personId: personId),
    ),
  );
}

void openFriendshipDetail(BuildContext context, EntityId friendshipId) {
  final router = GoRouter.maybeOf(context);
  if (router != null) {
    context.go('/relations/friendships/${friendshipId.value}');
    return;
  }
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => FriendshipDetailScreen(friendshipId: friendshipId),
    ),
  );
}

void openCircleDetail(BuildContext context, EntityId circleId) {
  final router = GoRouter.maybeOf(context);
  if (router != null) {
    context.go('/relations/circles/${circleId.value}');
    return;
  }
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => CircleDetailScreen(circleId: circleId),
    ),
  );
}
