import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models.dart';
import '../presentation/tasks_provider.dart';
import '../../goals/presentation/goals_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/task_form_dialog.dart';
import '../../../shared/widgets/toast.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  String _searchQuery = '';
  String _filter = 'all'; // all, todo, active, done
  String _viewMode = 'list'; // list or board

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(tasksProvider.notifier).loadTasks();
      ref.read(goalsProvider.notifier).loadGoals();
    });
  }

  @override
  Widget build(BuildContext context) {
    final tasksState = ref.watch(tasksProvider);

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
            color: AppTheme.bg,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('任务清单', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                Row(
                  children: [
                    // Search box
                    Container(
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.search, size: 14, color: AppTheme.textMuted),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 160,
                            child: TextField(
                              onChanged: (v) => setState(() => _searchQuery = v),
                              decoration: InputDecoration(
                                hintText: '搜索任务...',
                                hintStyle: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Filter tabs
                    _FilterTab('列表', _viewMode == 'list', () => setState(() => _viewMode = 'list')),
                    const SizedBox(width: 4),
                    _FilterTab('看板', _viewMode == 'board', () => setState(() => _viewMode = 'board')),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () => _showCreateDialog(context),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('新建任务'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Filter tabs
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            color: AppTheme.bg,
            child: Row(
              children: [
                _FilterTab('全部', _filter == 'all', () => setState(() => _filter = 'all')),
                const SizedBox(width: 8),
                _FilterTab('待办', _filter == 'todo', () => setState(() => _filter = 'todo')),
                const SizedBox(width: 8),
                _FilterTab('进行中', _filter == 'active', () => setState(() => _filter = 'active')),
                const SizedBox(width: 8),
                _FilterTab('已完成', _filter == 'done', () => setState(() => _filter = 'done')),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Tasks list
          Expanded(
            child: tasksState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildTasksList(tasksState),
          ),
        ],
      ),
    );
  }

  Widget _buildTasksList(TasksState state) {
    if (state.error != null && state.tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppTheme.danger),
            const SizedBox(height: 12),
            Text(state.error!, style: TextStyle(color: AppTheme.textSecondary)),
            TextButton(
              onPressed: () => ref.read(tasksProvider.notifier).loadTasks(),
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    final filteredTasks = state.tasks.where((task) {
      if (_searchQuery.isNotEmpty) {
        if (!task.title.contains(_searchQuery) && !task.goalTitle.contains(_searchQuery)) return false;
      }
      switch (_filter) {
        case 'todo':
          return task.status == TaskStatus.PENDING;
        case 'active':
          return task.status == TaskStatus.IN_PROGRESS;
        case 'done':
          return task.isDone;
        default:
          return true;
      }
    }).toList();

    if (filteredTasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.task_outlined, size: 64, color: AppTheme.border),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty ? '暂无任务' : '没有找到匹配的任务',
              style: TextStyle(fontSize: 16, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => _showCreateDialog(context),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('创建任务'),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.border),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.all(8),
        itemCount: filteredTasks.length,
        separatorBuilder: (_, __) => const SizedBox(height: 4),
        itemBuilder: (context, index) {
          final task = filteredTasks[index];
          return _TaskCard(
            task: task,
            onToggle: (completed) => _toggleTask(task, completed),
            onDelete: () => _confirmDelete(context, task),
            onEdit: () => _showEditDialog(context, task),
            onToggleSubTask: (subTask, completed) => _toggleSubTask(task.id, subTask.id, completed),
          );
        },
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    final goals = ref.read(goalsProvider).goals;
    TaskFormDialog.show(
      context: context,
      goals: goals,
      onSaved: ({required goalId, required title, required priority, status, estimateMinutes, dueDate, note, taskType = TaskType.PROGRESSION, recurringFrequency, recurringTime, subTasks}) async {
        final success = await ref.read(tasksProvider.notifier).createTask(
          goalId: goalId, title: title, priority: priority,
          estimateMinutes: estimateMinutes, dueDate: dueDate, note: note,
          taskType: taskType ?? TaskType.PROGRESSION, recurringFrequency: recurringFrequency,
          recurringTime: recurringTime, subTasks: subTasks,
        );
        if (success && context.mounted) {
          ToastWidget.show(context, '任务创建成功', type: 'success');
        } else if (!success && context.mounted) {
          ToastWidget.show(context, '创建失败，请重试', type: 'error');
        }
      },
    );
  }

  void _showEditDialog(BuildContext context, Task task) {
    final goals = ref.read(goalsProvider).goals;
    TaskFormDialog.show(
      context: context,
      goals: goals,
      task: task,
      onSaved: ({required goalId, required title, required priority, status, estimateMinutes, dueDate, note, taskType, recurringFrequency, recurringTime, subTasks}) async {
        final success = await ref.read(tasksProvider.notifier).updateTask(
          task.id,
          goalId: goalId, title: title, priority: priority,
          status: status ?? TaskStatus.PENDING, estimateMinutes: estimateMinutes,
          note: note, taskType: taskType ?? TaskType.PROGRESSION,
          recurringFrequency: recurringFrequency,
          recurringTime: recurringTime, subTasks: subTasks,
        );
        if (success && context.mounted) {
          ToastWidget.show(context, '任务更新成功', type: 'success');
        } else if (!success && context.mounted) {
          ToastWidget.show(context, '更新失败，请重试', type: 'error');
        }
      },
    );
  }

  void _confirmDelete(BuildContext context, Task task) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
        child: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppTheme.border)),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLg)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('确认删除', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    IconButton(
                      icon: Icon(Icons.close, color: AppTheme.textMuted),
                      onPressed: () => Navigator.pop(ctx),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text('确定要删除任务「${task.title}」吗？', style: TextStyle(color: AppTheme.textSecondary)),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: AppTheme.border)),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(AppTheme.radiusLg)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
                      ),
                      child: const Text('取消'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        final success = await ref.read(tasksProvider.notifier).deleteTask(task.id);
                        if (success && ctx.mounted) {
                          ToastWidget.show(ctx, '任务已删除', type: 'success');
                        } else if (!success && ctx.mounted) {
                          ToastWidget.show(ctx, '删除失败，请重试', type: 'error');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.danger,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
                      ),
                      child: const Text('删除'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _toggleTask(Task task, bool completed) async {
    if (task.taskType == TaskType.HABIT && completed) {
      if (task.subTasks.isEmpty) {
        final updated = await ref.read(tasksProvider.notifier).completeTask(task.id);
        if (mounted && updated != null) {
          ToastWidget.show(context, '打卡成功！连续 ${updated.currentStreak} 天', type: 'success');
        }
      } else {
        await ref.read(tasksProvider.notifier).completeTask(task.id);
      }
    } else if (task.taskType == TaskType.HABIT && !completed) {
      await ref.read(tasksProvider.notifier).uncompleteTask(task.id);
      if (mounted) {
        ToastWidget.show(context, '已取消打卡', type: 'success');
      }
    } else if (completed) {
      if (task.subTasks.isEmpty) {
        await ref.read(tasksProvider.notifier).completeTask(task.id);
        if (mounted) {
          ToastWidget.show(context, '任务已完成', type: 'success');
        }
      } else {
        await ref.read(tasksProvider.notifier).completeTask(task.id);
      }
    } else {
      await ref.read(tasksProvider.notifier).uncompleteTask(task.id);
      if (mounted) {
        ToastWidget.show(context, '已取消完成', type: 'success');
      }
    }
  }

  Future<void> _toggleSubTask(int taskId, int subTaskId, bool completed) async {
    final updated = await ref.read(tasksProvider.notifier).toggleSubTask(taskId, subTaskId);
    setState(() {});
    if (mounted && updated != null && updated.taskType == TaskType.HABIT) {
      if (updated.checkedInToday) {
        ToastWidget.show(context, '打卡成功！连续 ${updated.currentStreak} 天', type: 'success');
      } else {
        ToastWidget.show(context, '已取消打卡', type: 'info');
      }
    }
  }
}

class _FilterTab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _FilterTab(this.label, this.active, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: active ? Colors.white : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final Task task;
  final Function(bool) onToggle;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final Function(SubTask, bool)? onToggleSubTask;

  const _TaskCard({required this.task, required this.onToggle, required this.onDelete, required this.onEdit, this.onToggleSubTask});

  @override
  Widget build(BuildContext context) {
    final isCompleted = task.isDone;
    final notDueToday = task.taskType == TaskType.HABIT && !task.isDueToday;

    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      child: Opacity(
        opacity: notDueToday ? 0.5 : 1.0,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          child: InkWell(
            onTap: () => _showTaskDetailDialog(context, onEdit),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            child: Container(
              padding: const EdgeInsets.all(13),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: notDueToday ? null : () => onToggle(!isCompleted),
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCompleted ? AppTheme.success : Colors.transparent,
                        border: Border.all(
                          color: isCompleted ? AppTheme.success : AppTheme.borderLight,
                          width: 2,
                        ),
                      ),
                      child: isCompleted ? const Icon(Icons.check, size: 10, color: Colors.white) : null,
                    ),
                  ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: task.taskType == TaskType.HABIT ? AppTheme.primary.withValues(alpha: 0.1) : AppTheme.success.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              task.taskType == TaskType.HABIT ? '习惯' : '进度',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: task.taskType == TaskType.HABIT ? AppTheme.primary : AppTheme.success,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.getPriorityBgColor(task.priority),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              AppTheme.getPriorityLabel(task.priority),
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.getPriorityColor(task.priority)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(task.goalTitle, style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        task.title,
                        style: TextStyle(
                          fontSize: 14,
                          decoration: isCompleted ? TextDecoration.lineThrough : null,
                          color: isCompleted ? AppTheme.textMuted : AppTheme.text,
                        ),
                      ),
                      if (notDueToday) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.border.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text('今日不出现', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                        ),
                      ],
                      if (task.taskType == TaskType.PROGRESSION && task.subTasks.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        _buildProgressBar(),
                      ],
                      if (task.taskType == TaskType.HABIT) ...[
                        const SizedBox(height: 6),
                        _buildStreakInfo(),
                      ],
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (task.taskType == TaskType.PROGRESSION && task.subTasks.isNotEmpty)
                      IconButton(
                        icon: Icon(Icons.playlist_add_check, size: 16, color: AppTheme.success),
                        onPressed: () => _showSubTaskListDialog(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      ),
                    IconButton(
                      icon: Icon(Icons.edit_outlined, size: 16, color: AppTheme.textMuted),
                      onPressed: onEdit,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline, size: 16, color: AppTheme.textMuted),
                      onPressed: onDelete,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                    ),
                  ],
                ),
              ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showSubTaskListDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          backgroundColor: AppTheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
          child: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppTheme.border)), borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLg))),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('子任务 (${task.subTasks.where((s) => s.completed).length}/${task.subTasks.length})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      IconButton(icon: Icon(Icons.close, color: AppTheme.textMuted), onPressed: () => Navigator.pop(ctx), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                    ],
                  ),
                ),
                Flexible(
                  child: Consumer(
                    builder: (context, ref, _) {
                      final currentTask = ref.watch(tasksProvider).tasks.firstWhere((t) => t.id == task.id, orElse: () => task);
                      return ListView.builder(
                        shrinkWrap: true,
                        padding: const EdgeInsets.all(12),
                        itemCount: currentTask.subTasks.length,
                        itemBuilder: (ctx, index) {
                          final subTask = currentTask.subTasks[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                GestureDetector(
                                  onTap: () async {
                                    if (onToggleSubTask != null) {
                                      await onToggleSubTask!(subTask, !subTask.completed);
                                      setDialogState(() {});
                                    }
                                  },
                                  child: Container(
                                    width: 18,
                                    height: 18,
                                    decoration: BoxDecoration(shape: BoxShape.circle, color: subTask.completed ? AppTheme.success : Colors.transparent, border: Border.all(color: subTask.completed ? AppTheme.success : AppTheme.border, width: 2)),
                                    child: subTask.completed ? const Icon(Icons.check, size: 10, color: Colors.white) : null,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(child: Text(subTask.title, style: TextStyle(fontSize: 13, decoration: subTask.completed ? TextDecoration.lineThrough : null, color: subTask.completed ? AppTheme.textMuted : AppTheme.text))),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    final completedCount = task.subTasks.where((s) => s.completed).length;
    final totalCount = task.subTasks.length;
    final percent = totalCount > 0 ? (completedCount / totalCount * 100).round() : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: percent / 100,
                  backgroundColor: AppTheme.border,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.success),
                  minHeight: 4,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text('$percent%', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
          ],
        ),
        const SizedBox(height: 2),
        Text('$completedCount / $totalCount 项', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
      ],
    );
  }

  Widget _buildStreakInfo() {
    return Row(
      children: [
        Icon(Icons.local_fire_department, size: 14, color: Colors.orange[600]),
        const SizedBox(width: 4),
        Text(
          '连续 ${task.currentStreak} 天',
          style: TextStyle(fontSize: 12, color: Colors.orange[600], fontWeight: FontWeight.w600),
        ),
        const SizedBox(width: 8),
        Text('共 ${task.totalCompleted} 次', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
      ],
    );
  }

  void _showTaskDetailDialog(BuildContext context, VoidCallback onEdit) {
    final isCompleted = task.isDone;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
        child: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppTheme.border)),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLg)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('任务详情', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    IconButton(
                      icon: Icon(Icons.close, color: AppTheme.textMuted),
                      onPressed: () => Navigator.pop(ctx),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(task.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 16),
                    _DetailRow('状态', isCompleted ? '已完成' : (task.status == TaskStatus.IN_PROGRESS ? '进行中' : '待办')),
                    _DetailRow('关联目标', task.goalTitle),
                    _DetailRow('优先级', AppTheme.getPriorityLabel(task.priority)),
                    if (task.estimateMinutes != null) _DetailRow('预计时长', '${task.estimateMinutes}分钟'),
                    if (task.note != null && task.note!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text('任务描述', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.textSecondary)),
                      const SizedBox(height: 6),
                      Text(task.note!, style: TextStyle(fontSize: 14, color: AppTheme.text)),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: AppTheme.border)),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(AppTheme.radiusLg)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        onToggle(!isCompleted);
                      },
                      child: Text(isCompleted ? '取消完成' : '标记完成'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        onEdit();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
                      ),
                      child: const Text('编辑'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
          ),
          Expanded(child: Text(value, style: TextStyle(fontSize: 13, color: AppTheme.text))),
        ],
      ),
    );
  }
}