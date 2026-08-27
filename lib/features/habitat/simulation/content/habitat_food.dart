import '../embodied/need_engine.dart';
import '../embodied/pawn_embodied_state.dart';

/// Simulated food / cooking (MD 08 M37) — not nutritional science.
class HabitatRecipe {
  const HabitatRecipe({
    required this.id,
    required this.title,
    required this.ingredientTags,
    required this.durationSim,
    this.stationTags = const {'stove', 'counter'},
    this.interestTags = const {},
    this.servings = 2,
  });

  final String id;
  final String title;
  final Set<String> ingredientTags;
  final Set<String> stationTags;
  final Set<String> interestTags;
  final double durationSim;
  final int servings;
}

enum CookingPhase {
  collect,
  prep,
  cook,
  dishReady,
  serve,
  done,
}

class CookingSession {
  CookingSession({
    required this.id,
    required this.recipeId,
    required this.cookPawnId,
    this.helperPawnIds = const [],
  });

  final String id;
  final String recipeId;
  final String cookPawnId;
  final List<String> helperPawnIds;
  CookingPhase phase = CookingPhase.collect;
  double progress = 0;
}

class MealInstance {
  MealInstance({
    required this.id,
    required this.recipeId,
    required this.participantIds,
    required this.servings,
  });

  final String id;
  final String recipeId;
  final List<String> participantIds;
  final int servings;
  bool underway = false;
  bool finished = false;
}

/// Kitchen pipeline + shared meals (M37).
class HabitatKitchenDirector {
  final List<HabitatRecipe> recipes = const [
    HabitatRecipe(
      id: 'pasta_simple',
      title: 'Massa simples',
      ingredientTags: {'pasta', 'sauce'},
      durationSim: 40,
      interestTags: {'food.italian'},
      servings: 2,
    ),
    HabitatRecipe(
      id: 'omelette',
      title: 'Omelete',
      ingredientTags: {'eggs'},
      durationSim: 25,
      interestTags: {'food.breakfast'},
      servings: 1,
    ),
    HabitatRecipe(
      id: 'coffee',
      title: 'Café',
      ingredientTags: {'coffee'},
      durationSim: 15,
      stationTags: {'counter'},
      interestTags: {'coffee'},
      servings: 1,
    ),
  ];

  final Map<String, CookingSession> sessions = {};
  final Map<String, MealInstance> meals = {};
  final List<String> aftermath = [];
  final List<String> debugLog = [];

  HabitatRecipe? recipe(String id) {
    for (final r in recipes) {
      if (r.id == id) return r;
    }
    return null;
  }

  CookingSession startCook({
    required String recipeId,
    required String cookPawnId,
    List<String> helpers = const [],
    double nowSim = 0,
  }) {
    final id = 'cook.$recipeId.$nowSim';
    final s = CookingSession(
      id: id,
      recipeId: recipeId,
      cookPawnId: cookPawnId,
      helperPawnIds: helpers,
    );
    sessions[id] = s;
    debugLog.add('cook start $recipeId');
    return s;
  }

  void advanceCooking(String sessionId, {double step = 0.35}) {
    final s = sessions[sessionId];
    if (s == null || s.phase == CookingPhase.done) return;
    s.progress = (s.progress + step).clamp(0.0, 1.0);
    if (s.progress < 1) return;
    s.progress = 0;
    s.phase = switch (s.phase) {
      CookingPhase.collect => CookingPhase.prep,
      CookingPhase.prep => CookingPhase.cook,
      CookingPhase.cook => CookingPhase.dishReady,
      CookingPhase.dishReady => CookingPhase.serve,
      CookingPhase.serve => CookingPhase.done,
      CookingPhase.done => CookingPhase.done,
    };
    debugLog.add('cook ${s.recipeId} → ${s.phase.name}');
  }

  MealInstance startMeal({
    required String recipeId,
    required List<String> participantIds,
    double nowSim = 0,
  }) {
    final r = recipe(recipeId);
    final meal = MealInstance(
      id: 'meal.$recipeId.$nowSim',
      recipeId: recipeId,
      participantIds: participantIds,
      servings: r?.servings ?? participantIds.length,
    )..underway = true;
    meals[meal.id] = meal;
    debugLog.add('meal ${meal.id} ×${participantIds.length}');
    return meal;
  }

  /// Satisfy food need for participants; leave physical aftermath.
  List<PawnEmbodiedState> finishMeal(
    String mealId, {
    required Map<String, PawnEmbodiedState> states,
    required DateTime observedAt,
  }) {
    final meal = meals[mealId];
    if (meal == null || meal.finished) return states.values.toList();
    meal.finished = true;
    meal.underway = false;
    aftermath.add('pratos sujos');
    aftermath.add('xícaras na mesa');
    debugLog.add('meal done $mealId');

    final out = <PawnEmbodiedState>[];
    for (final id in meal.participantIds) {
      final st = states[id];
      if (st == null) continue;
      final food = st.need(NeedKind.food);
      if (food == null) {
        out.add(st);
        continue;
      }
      out.add(
        st.copyWith(
          needs: {
            ...st.needs,
            NeedKind.food: food.copyWith(
              pressure: (food.pressure - 0.55).clamp(0.0, 1.0),
              observedAt: observedAt,
            ),
          },
        ),
      );
    }
    return out;
  }

  /// Quick demo: cook two dishes end-to-end for [cookId].
  void demoTwoDishes(String cookId, {double nowSim = 0}) {
    for (final rid in ['pasta_simple', 'omelette']) {
      final s = startCook(recipeId: rid, cookPawnId: cookId, nowSim: nowSim);
      for (var i = 0; i < 20; i++) {
        advanceCooking(s.id, step: 1);
        if (s.phase == CookingPhase.done) break;
      }
    }
  }
}
