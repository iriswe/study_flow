import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/di/injection.dart';
import '../data/focus_repository.dart';

final focusProvider = StateNotifierProvider<FocusNotifier, FocusState>((ref) {
  return FocusNotifier(getIt<FocusRepository>());
});

class FocusState {
  final bool isRunning;
  final int remainingSeconds;
  final int totalSeconds;
  final int sessionsCompleted;
  final int todayTotalMinutes;
  final String? error;

  const FocusState({
    this.isRunning = false,
    this.remainingSeconds = 25 * 60,
    this.totalSeconds = 25 * 60,
    this.sessionsCompleted = 0,
    this.todayTotalMinutes = 0,
    this.error,
  });

  FocusState copyWith({
    bool? isRunning,
    int? remainingSeconds,
    int? totalSeconds,
    int? sessionsCompleted,
    int? todayTotalMinutes,
    String? error,
  }) {
    return FocusState(
      isRunning: isRunning ?? this.isRunning,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      totalSeconds: totalSeconds ?? this.totalSeconds,
      sessionsCompleted: sessionsCompleted ?? this.sessionsCompleted,
      todayTotalMinutes: todayTotalMinutes ?? this.todayTotalMinutes,
      error: error,
    );
  }

  double get progress => totalSeconds > 0 ? remainingSeconds / totalSeconds : 0;
  String get timeDisplay {
    final min = remainingSeconds ~/ 60;
    final sec = remainingSeconds % 60;
    return '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }
}

class FocusNotifier extends StateNotifier<FocusState> {
  final FocusRepository _repository;
  Timer? _timer;

  FocusNotifier(this._repository) : super(const FocusState()) {
    _loadTodayStats();
  }

  Future<void> _loadTodayStats() async {
    try {
      final sessions = await _repository.getTodaySessions();
      final now = DateTime.now();
      final todayMinutes = sessions.fold<int>(0, (sum, s) {
        final actual = s.actualDuration ?? 0;
        if (actual > 0) return sum + actual;
        // If no actualDuration yet, check status and createdAt
        if (s.status == 'COMPLETED' || s.status == 'INTERRUPTED') {
          final created = s.createdAt;
          if (created.year == now.year && created.month == now.month && created.day == now.day) {
            return sum + actual;
          }
        }
        return sum;
      });
      state = state.copyWith(todayTotalMinutes: todayMinutes);
    } catch (_) {}
  }

  void setDuration(int minutes) {
    if (state.isRunning) return;
    final seconds = minutes * 60;
    state = state.copyWith(
      remainingSeconds: seconds,
      totalSeconds: seconds,
    );
  }

  void start() {
    if (state.isRunning) return;
    state = state.copyWith(isRunning: true);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => tick());
  }

  void pause() {
    _timer?.cancel();
    _timer = null;
    state = state.copyWith(isRunning: false);
  }

  void tick() {
    if (!state.isRunning || state.remainingSeconds <= 0) return;
    state = state.copyWith(remainingSeconds: state.remainingSeconds - 1);
    if (state.remainingSeconds <= 0) {
      _completeSession(interrupted: false);
    }
  }

  Future<void> _completeSession({bool interrupted = false}) async {
    _timer?.cancel();
    _timer = null;
    final minutes = state.totalSeconds ~/ 60;
    final elapsedSeconds = state.totalSeconds - state.remainingSeconds;
    final elapsedMinutes = (elapsedSeconds / 60).ceil();
    // Only count if user spent at least 1 minute
    final countMinutes = interrupted && elapsedMinutes < 1 ? 0 : (interrupted ? elapsedMinutes : minutes);
    final newTodayMinutes = state.todayTotalMinutes + countMinutes;
    final currentSessionsCompleted = interrupted && elapsedMinutes < 1 ? state.sessionsCompleted : state.sessionsCompleted + (interrupted ? 0 : 1);

    state = state.copyWith(
      isRunning: false,
      sessionsCompleted: currentSessionsCompleted,
      todayTotalMinutes: newTodayMinutes,
    );
    // Save session to backend if at least 1 minute was spent
    if (countMinutes > 0) {
      try {
        await _repository.createSession(countMinutes);
      } catch (_) {}
    }
  }

  void reset() {
    _timer?.cancel();
    _timer = null;
    state = state.copyWith(
      isRunning: false,
      remainingSeconds: state.totalSeconds,
    );
  }

  void stopAndSave() {
    if (!state.isRunning) return;
    _completeSession(interrupted: true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
