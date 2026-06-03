import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/di/injection.dart';
import '../data/tasks_repository.dart';
import '../domain/models.dart';

final tasksProvider = StateNotifierProvider<TasksNotifier, TasksState>((ref) {
  return TasksNotifier(getIt<TasksRepository>());
});

class TasksState {
  final bool isLoading;
  final List<Task> tasks;
  final String? error;

  const TasksState({
    this.isLoading = false,
    this.tasks = const [],
    this.error,
  });

  TasksState copyWith({
    bool? isLoading,
    List<Task>? tasks,
    String? error,
  }) {
    return TasksState(
      isLoading: isLoading ?? this.isLoading,
      tasks: tasks ?? this.tasks,
      error: error,
    );
  }
}

class TasksNotifier extends StateNotifier<TasksState> {
  final TasksRepository _repository;

  TasksNotifier(this._repository) : super(const TasksState());

  Future<void> loadTasks() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final tasks = await _repository.getTasks();
      state = state.copyWith(isLoading: false, tasks: tasks);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadTodayTasks() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final tasks = await _repository.getTasks(todayOnly: true);
      state = state.copyWith(isLoading: false, tasks: tasks);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadTasksByGoalId(int goalId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final tasks = await _repository.getTasksByGoalId(goalId);
      state = state.copyWith(isLoading: false, tasks: tasks);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> createTask({
    required int goalId,
    required String title,
    required String priority,
    int? estimateMinutes,
    DateTime? dueDate,
    String? note,
    TaskType taskType = TaskType.PROGRESSION,
    String? recurringFrequency,
    String? recurringTime,
    List<String>? subTasks,
  }) async {
    try {
      final task = await _repository.createTask(
        goalId: goalId,
        title: title,
        priority: priority,
        estimateMinutes: estimateMinutes,
        dueDate: dueDate,
        note: note,
        taskType: taskType,
        recurringFrequency: recurringFrequency,
        recurringTime: recurringTime,
        subTasks: subTasks,
      );
      state = state.copyWith(tasks: [task, ...state.tasks]);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<Task?> completeTask(int id) async {
    try {
      final completedTask = await _repository.completeTask(id);
      final tasks = state.tasks.map((t) => t.id == id ? completedTask : t).toList();
      state = state.copyWith(tasks: tasks);
      return completedTask;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  Future<Task?> uncompleteTask(int id) async {
    try {
      final task = await _repository.uncompleteTask(id);
      final tasks = state.tasks.map((t) => t.id == id ? task : t).toList();
      state = state.copyWith(tasks: tasks);
      return task;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  Future<bool> deleteTask(int id) async {
    try {
      await _repository.deleteTask(id);
      final tasks = state.tasks.where((t) => t.id != id).toList();
      state = state.copyWith(tasks: tasks);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<Task?> batchCreateSubTasksPaste(int taskId, List<String> items) async {
    try {
      final updatedTask = await _repository.batchCreateSubTasksPaste(taskId, items);
      final tasks = state.tasks.map((t) => t.id == taskId ? updatedTask : t).toList();
      state = state.copyWith(tasks: tasks);
      return updatedTask;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  Future<Task?> batchCreateSubTasksSequence(
    int taskId, {
    required String prefix,
    String suffix = '',
    int count = 10,
    int startAt = 1,
    String placeholder = '{n}',
  }) async {
    try {
      final updatedTask = await _repository.batchCreateSubTasksSequence(
        taskId,
        prefix: prefix,
        suffix: suffix,
        count: count,
        startAt: startAt,
        placeholder: placeholder,
      );
      final tasks = state.tasks.map((t) => t.id == taskId ? updatedTask : t).toList();
      state = state.copyWith(tasks: tasks);
      return updatedTask;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  Future<Task?> toggleSubTask(int taskId, int subTaskId) async {
    try {
      final updatedTask = await _repository.toggleSubTask(taskId, subTaskId);
      final tasks = state.tasks.map((t) => t.id == taskId ? updatedTask : t).toList();
      state = state.copyWith(tasks: tasks);
      return updatedTask;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  Future<Task?> addSubTask(int taskId, String title) async {
    try {
      final updatedTask = await _repository.addSubTask(taskId, title);
      final tasks = state.tasks.map((t) => t.id == taskId ? updatedTask : t).toList();
      state = state.copyWith(tasks: tasks);
      return updatedTask;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  Future<Task?> batchAddSubTasks(int taskId, List<String> titles) async {
    try {
      final updatedTask = await _repository.batchAddSubTasks(taskId, titles);
      final tasks = state.tasks.map((t) => t.id == taskId ? updatedTask : t).toList();
      state = state.copyWith(tasks: tasks);
      return updatedTask;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  Future<bool> updateTask(
    int id, {
    required int goalId,
    required String title,
    required String priority,
    required TaskStatus status,
    int? estimateMinutes,
    DateTime? dueDate,
    String? note,
    TaskType? taskType,
    String? recurringFrequency,
    String? recurringTime,
    List<String>? subTasks,
  }) async {
    try {
      final updatedTask = await _repository.updateTask(
        id: id,
        goalId: goalId,
        title: title,
        priority: priority,
        status: status,
        estimateMinutes: estimateMinutes,
        dueDate: dueDate,
        note: note,
        taskType: taskType,
        recurringFrequency: recurringFrequency,
        recurringTime: recurringTime,
        subTasks: subTasks,
      );
      final tasks = state.tasks.map((t) => t.id == id ? updatedTask : t).toList();
      state = state.copyWith(tasks: tasks);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}