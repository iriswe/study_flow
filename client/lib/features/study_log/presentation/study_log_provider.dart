import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/di/injection.dart';
import '../data/study_log_repository.dart';

final studyLogProvider = StateNotifierProvider<StudyLogNotifier, StudyLogState>((ref) {
  return StudyLogNotifier(getIt<StudyLogRepository>());
});

class StudyLogState {
  final bool isLoading;
  final List<StudyLog> logs;
  final String? error;
  final int page;
  final bool hasMore;

  const StudyLogState({
    this.isLoading = false,
    this.logs = const [],
    this.error,
    this.page = 0,
    this.hasMore = true,
  });

  StudyLogState copyWith({
    bool? isLoading,
    List<StudyLog>? logs,
    String? error,
    int? page,
    bool? hasMore,
  }) {
    return StudyLogState(
      isLoading: isLoading ?? this.isLoading,
      logs: logs ?? this.logs,
      error: error,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class StudyLog {
  final int id;
  final int? goalId;
  final String? goalTitle;
  final int duration;
  final DateTime createdAt;
  final String? note;

  const StudyLog({
    required this.id,
    this.goalId,
    this.goalTitle,
    required this.duration,
    required this.createdAt,
    this.note,
  });

  factory StudyLog.fromJson(Map<String, dynamic> json) {
    return StudyLog(
      id: json['id'] as int,
      goalId: json['goalId'] as int?,
      goalTitle: json['goalTitle'] as String?,
      duration: json['duration'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      note: json['note'] as String?,
    );
  }
}

class StudyLogNotifier extends StateNotifier<StudyLogState> {
  final StudyLogRepository _repository;
  static const int _pageSize = 20;

  StudyLogNotifier(this._repository) : super(const StudyLogState()) {
    loadLogs();
  }

  Future<void> loadLogs() async {
    state = state.copyWith(isLoading: true, error: null, page: 0);
    try {
      final data = await _repository.getStudyLogs(page: 0, size: _pageSize);
      final logs = data.map((e) => StudyLog.fromJson(e as Map<String, dynamic>)).toList();
      state = state.copyWith(
        isLoading: false,
        logs: logs,
        hasMore: logs.length >= _pageSize,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoading: true);
    try {
      final nextPage = state.page + 1;
      final data = await _repository.getStudyLogs(page: nextPage, size: _pageSize);
      final logs = data.map((e) => StudyLog.fromJson(e as Map<String, dynamic>)).toList();
      state = state.copyWith(
        isLoading: false,
        logs: [...state.logs, ...logs],
        page: nextPage,
        hasMore: logs.length >= _pageSize,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> createLog({
    int? goalId,
    int? taskId,
    required int duration,
    String? note,
    String? score,
    String? problem,
  }) async {
    try {
      await _repository.createStudyLog({
        'goalId': goalId,
        'taskId': taskId,
        'duration': duration,
        'note': note,
        'score': score,
        'problem': problem,
      });
      await loadLogs();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> deleteLog(int id) async {
    try {
      await _repository.deleteStudyLog(id);
      state = state.copyWith(logs: state.logs.where((l) => l.id != id).toList());
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> updateLog(
    int id, {
    int? taskId,
    required int duration,
    String? note,
    String? score,
    String? problem,
  }) async {
    try {
      await _repository.updateStudyLog(id, {
        'taskId': taskId,
        'duration': duration,
        'note': note,
        'score': score,
        'problem': problem,
      });
      await loadLogs();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}