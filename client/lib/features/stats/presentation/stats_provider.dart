import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/di/injection.dart';
import '../../dashboard/domain/models.dart';
import '../data/stats_repository.dart';

final statsProvider = StateNotifierProvider<StatsNotifier, StatsState>((ref) {
  return StatsNotifier(getIt<StatsRepository>());
});

class StatsState {
  final bool isLoading;
  final DashboardStats? overview;
  final Map<String, dynamic>? learningStats;
  final Map<String, dynamic>? reviewStats;
  final String? error;

  const StatsState({
    this.isLoading = false,
    this.overview,
    this.learningStats,
    this.reviewStats,
    this.error,
  });

  StatsState copyWith({
    bool? isLoading,
    DashboardStats? overview,
    Map<String, dynamic>? learningStats,
    Map<String, dynamic>? reviewStats,
    String? error,
  }) {
    return StatsState(
      isLoading: isLoading ?? this.isLoading,
      overview: overview ?? this.overview,
      learningStats: learningStats ?? this.learningStats,
      reviewStats: reviewStats ?? this.reviewStats,
      error: error,
    );
  }
}

class StatsNotifier extends StateNotifier<StatsState> {
  final StatsRepository _repository;

  StatsNotifier(this._repository) : super(const StatsState()) {
    loadAll();
  }

  Future<void> loadAll() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final results = await Future.wait([
        _repository.getOverview(),
        _repository.getLearningStats(),
        _repository.getReviewStats(),
      ]);
      state = state.copyWith(
        isLoading: false,
        overview: results[0] as DashboardStats,
        learningStats: results[1] as Map<String, dynamic>,
        reviewStats: results[2] as Map<String, dynamic>,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}