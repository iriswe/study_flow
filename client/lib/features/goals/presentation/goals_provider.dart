import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/di/injection.dart';
import '../data/goals_repository.dart';
import '../domain/models.dart';

final goalsProvider = StateNotifierProvider<GoalsNotifier, GoalsState>((ref) {
  return GoalsNotifier(getIt<GoalsRepository>());
});

class GoalsState {
  final bool isLoading;
  final List<Goal> goals;
  final String? error;

  const GoalsState({
    this.isLoading = false,
    this.goals = const [],
    this.error,
  });

  GoalsState copyWith({
    bool? isLoading,
    List<Goal>? goals,
    String? error,
  }) {
    return GoalsState(
      isLoading: isLoading ?? this.isLoading,
      goals: goals ?? this.goals,
      error: error,
    );
  }
}

class GoalsNotifier extends StateNotifier<GoalsState> {
  final GoalsRepository _repository;

  GoalsNotifier(this._repository) : super(const GoalsState()) {
    loadGoals();
  }

  Future<void> loadGoals() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final goals = await _repository.getGoals();
      state = state.copyWith(isLoading: false, goals: goals);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> createGoal({
    required String title,
    String? description,
    required GoalType type,
    required Priority priority,
    DateTime? deadline,
  }) async {
    try {
      final goal = await _repository.createGoal(
        title: title,
        description: description,
        type: type,
        priority: priority,
        deadline: deadline,
      );
      state = state.copyWith(goals: [goal, ...state.goals]);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> updateGoal(int id, Map<String, dynamic> updates) async {
    try {
      final updatedGoal = await _repository.updateGoal(id, updates);
      final goals = state.goals.map((g) => g.id == id ? updatedGoal : g).toList();
      state = state.copyWith(goals: goals);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> deleteGoal(int id) async {
    try {
      await _repository.deleteGoal(id);
      final goals = state.goals.where((g) => g.id != id).toList();
      state = state.copyWith(goals: goals);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}