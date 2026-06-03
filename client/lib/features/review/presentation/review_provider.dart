import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/di/injection.dart';
import '../data/review_repository.dart';

final reviewProvider = StateNotifierProvider<ReviewNotifier, ReviewState>((ref) {
  return ReviewNotifier(getIt<ReviewRepository>());
});

class ReviewState {
  final bool isLoading;
  final List<ReviewCard> reviews;
  final int currentIndex;
  final String? error;
  final bool allReviewed;
  final int todayDue;
  final int weekDue;
  final int avgStabilityPercent;

  const ReviewState({
    this.isLoading = false,
    this.reviews = const [],
    this.currentIndex = 0,
    this.error,
    this.allReviewed = false,
    this.todayDue = 0,
    this.weekDue = 0,
    this.avgStabilityPercent = 0,
  });

  ReviewState copyWith({
    bool? isLoading,
    List<ReviewCard>? reviews,
    int? currentIndex,
    String? error,
    bool? allReviewed,
    int? todayDue,
    int? weekDue,
    int? avgStabilityPercent,
  }) {
    return ReviewState(
      isLoading: isLoading ?? this.isLoading,
      reviews: reviews ?? this.reviews,
      currentIndex: currentIndex ?? this.currentIndex,
      error: error,
      allReviewed: allReviewed ?? this.allReviewed,
      todayDue: todayDue ?? this.todayDue,
      weekDue: weekDue ?? this.weekDue,
      avgStabilityPercent: avgStabilityPercent ?? this.avgStabilityPercent,
    );
  }
}

class ReviewCard {
  final int id;
  final String goalTitle;
  final String? note;
  final DateTime dueDate;
  final int interval;
  final double stability;
  final double difficulty;

  const ReviewCard({
    required this.id,
    required this.goalTitle,
    this.note,
    required this.dueDate,
    required this.interval,
    required this.stability,
    required this.difficulty,
  });

  factory ReviewCard.fromJson(Map<String, dynamic> json) {
    return ReviewCard(
      id: (json['id'] as num).toInt(),
      goalTitle: json['goalTitle'] as String? ?? json['taskTitle'] as String? ?? '未知目标',
      note: json['note'] as String?,
      dueDate: DateTime.parse((json['nextReviewDate'] as String).split('T')[0]),
      interval: json['interval'] as int? ?? 1,
      stability: (json['stability'] as num?)?.toDouble() ?? 0.0,
      difficulty: (json['difficulty'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class ReviewNotifier extends StateNotifier<ReviewState> {
  final ReviewRepository _repository;

  ReviewNotifier(this._repository) : super(const ReviewState()) {
    loadReviews();
  }

  Future<void> loadReviews() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final results = await Future.wait([
        _repository.getTodayReviews(),
        _repository.getReviewStats(),
      ]);
      final reviews = (results[0] as List).map((e) => ReviewCard.fromJson(e as Map<String, dynamic>)).toList();
      final stats = results[1] as Map<String, dynamic>;
      state = state.copyWith(
        isLoading: false,
        reviews: reviews,
        currentIndex: 0,
        allReviewed: reviews.isEmpty,
        todayDue: stats['todayDue'] as int? ?? 0,
        weekDue: stats['weekDue'] as int? ?? 0,
        avgStabilityPercent: stats['avgStabilityPercent'] as int? ?? 0,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> submitReview(int reviewId, String response) async {
    try {
      await _repository.review(reviewId, response);
      _moveToNext();
      return true;
    } catch (e) {
      state = state.copyWith(error: '提交失败: $e');
      return false;
    }
  }

  void nextReview() {
    _moveToNext();
  }

  Future<void> skip() async {
    if (state.reviews.isEmpty) return;
    final current = state.reviews[state.currentIndex];
    try {
      await _repository.skip(current.id);
      _moveToNext();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> delay(int days) async {
    if (state.reviews.isEmpty) return;
    final current = state.reviews[state.currentIndex];
    try {
      await _repository.delay(current.id, days);
      _moveToNext();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void _moveToNext() {
    final nextIndex = state.currentIndex + 1;
    if (nextIndex >= state.reviews.length) {
      state = state.copyWith(allReviewed: true);
    } else {
      state = state.copyWith(currentIndex: nextIndex);
    }
  }
}