import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../domain/models.dart';
import '../data/goals_repository.dart';
import 'goals_provider.dart';
import '../../tasks/presentation/tasks_provider.dart';
import '../../tasks/domain/models.dart';
import '../../../core/di/injection.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/toast.dart';
import '../../../shared/widgets/task_form_dialog.dart';
import '../../../shared/widgets/form_label.dart';

final goalDetailProvider = FutureProvider.family<GoalDetailData, int>((ref, goalId) async {
  final repository = getIt<GoalsRepository>();
  return repository.getGoalDetail(goalId);
});

final goalTasksProvider = FutureProvider.family<List<Task>, int>((ref, goalId) async {
  final repository = getIt<GoalsRepository>();
  return repository.getTasksByGoalId(goalId);
});

final goalNotesProvider = FutureProvider.family<List<Map<String, dynamic>>, int>((ref, goalId) async {
  final repository = getIt<GoalsRepository>();
  return repository.getNotesByGoalId(goalId);
});

class GoalDetailScreen extends ConsumerStatefulWidget {
  final String goalId;

  const GoalDetailScreen({super.key, required this.goalId});

  @override
  ConsumerState<GoalDetailScreen> createState() => _GoalDetailScreenState();
}

class _GoalDetailScreenState extends ConsumerState<GoalDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final goalId = int.tryParse(widget.goalId) ?? 0;
    final detailAsync = ref.watch(goalDetailProvider(goalId));

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: AppTheme.danger),
              const SizedBox(height: 12),
              Text('加载失败: $e'),
              TextButton(
                onPressed: () => ref.invalidate(goalDetailProvider(goalId)),
                child: const Text('重试'),
              ),
            ],
          ),
        ),
        data: (data) => _buildContent(data, goalId),
      ),
    );
  }

  Widget _buildContent(GoalDetailData data, int goalId) {
    final goal = data.goal;

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
          color: AppTheme.bg,
          child: Row(
            children: [
              OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, size: 16),
                label: const Text('返回'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.textSecondary,
                  side: BorderSide(color: AppTheme.border),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
                ),
              ),
              const SizedBox(width: 16),
              Text('目标详情', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const Spacer(),
              OutlinedButton(
                onPressed: () => _showEditGoalDialog(context, goal),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.textSecondary,
                  side: BorderSide(color: AppTheme.border),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
                ),
                child: const Text('编辑'),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () => _confirmDeleteGoal(context, goal),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.danger,
                  side: BorderSide(color: AppTheme.danger.withValues(alpha: 0.5)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
                ),
                child: const Text('删除'),
              ),
            ],
          ),
        ),
        // Content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Goal info card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.getPriorityBgColor(goal.priority.name),
                                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                  ),
                                  child: Text(
                                    goal.type.label,
                                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  goal.title,
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                                ),
                                if (goal.description != null && goal.description!.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    goal.description!,
                                    style: TextStyle(fontSize: 14, color: AppTheme.textSecondary, height: 1.5),
                                  ),
                                ],
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    if (goal.deadline != null) ...[
                                      Icon(Icons.calendar_today, size: 12, color: AppTheme.textMuted),
                                      const SizedBox(width: 4),
                                      Text('截止日期：${_formatDate(goal.deadline!)}', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                                      const SizedBox(width: 16),
                                    ],
                                    Icon(Icons.task_outlined, size: 12, color: AppTheme.textMuted),
                                    const SizedBox(width: 4),
                                    Text('共 ${goal.totalTasks} 个任务', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.getPriorityBgColor(goal.priority.name),
                              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                            ),
                            child: Text(
                              AppTheme.getPriorityLabel(goal.priority.name),
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.getPriorityColor(goal.priority.name)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Stats cards
                Row(
                  children: [
                    Expanded(child: _StatCard(value: '${goal.progress.toInt()}%', label: '总体进度', color: AppTheme.primary)),
                    const SizedBox(width: 12),
                    Expanded(child: _StatCard(value: '${goal.completedTasks}/${goal.totalTasks}', label: '已完成任务', color: AppTheme.success)),
                  ],
                ),
                const SizedBox(height: 20),
                // Progress bar
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppTheme.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: goal.progress / 100,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.primary, AppTheme.primaryLight],
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Tabs: Tasks + Notes
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Column(
                    children: [
                      // Tab bar
                      Container(
                        decoration: BoxDecoration(
                          border: Border(bottom: BorderSide(color: AppTheme.border)),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLg)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _tabController.animateTo(0),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    border: Border(bottom: BorderSide(color: _tabController.index == 0 ? AppTheme.primary : Colors.transparent, width: 2)),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '关联任务',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: _tabController.index == 0 ? AppTheme.primary : AppTheme.textSecondary,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _tabController.animateTo(1),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    border: Border(bottom: BorderSide(color: _tabController.index == 1 ? AppTheme.primary : Colors.transparent, width: 2)),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '关联笔记',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: _tabController.index == 1 ? AppTheme.primary : AppTheme.textSecondary,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Tab content
                      SizedBox(
                        height: 300,
                        child: TabBarView(
                          controller: _tabController,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            _TasksTabContent(goalId: goalId),
                            _NotesTabContent(goalId: goalId),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}年${date.month}月${date.day}日';
  }

  void _showEditGoalDialog(BuildContext context, Goal goal) {
    final titleController = TextEditingController(text: goal.title);
    final descController = TextEditingController(text: goal.description ?? '');
    GoalType selectedType = goal.type;
    Priority selectedPriority = goal.priority;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Dialog(
          backgroundColor: AppTheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
          child: SizedBox(
            width: 480,
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
                      const Text('编辑目标', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                      IconButton(
                        icon: Icon(Icons.close, color: AppTheme.textMuted),
                        onPressed: () => Navigator.pop(ctx),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FormLabel('目标名称', required: true),
                      TextField(
                        controller: titleController,
                        decoration: InputDecoration(
                          hintText: '例如：三个月学会 Python',
                          filled: true,
                          fillColor: AppTheme.bg2,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd), borderSide: BorderSide(color: AppTheme.border)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      FormLabel('目标描述'),
                      TextField(
                        controller: descController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: '详细描述你的学习目标...',
                          filled: true,
                          fillColor: AppTheme.bg2,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd), borderSide: BorderSide(color: AppTheme.border)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      FormLabel('类型'),
                      DropdownButtonFormField<GoalType>(
                        value: selectedType,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppTheme.bg2,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd), borderSide: BorderSide(color: AppTheme.border)),
                        ),
                        items: GoalType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.label))).toList(),
                        onChanged: (v) => setState(() => selectedType = v ?? selectedType),
                      ),
                      const SizedBox(height: 16),
                      FormLabel('优先级'),
                      Wrap(
                        spacing: 8,
                        children: Priority.values.map((p) => ChoiceChip(
                          label: Text(p.label),
                          selected: selectedPriority == p,
                          onSelected: (_) => setState(() => selectedPriority = p),
                          selectedColor: AppTheme.getPriorityBgColor(p.name),
                          labelStyle: TextStyle(
                            color: selectedPriority == p ? AppTheme.getPriorityColor(p.name) : AppTheme.textSecondary,
                            fontSize: 13,
                          ),
                        )).toList(),
                      ),
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
                          if (titleController.text.isEmpty) {
                            ToastWidget.show(ctx, '请输入目标名称', type: 'error');
                            return;
                          }
                          final success = await ref.read(goalsProvider.notifier).updateGoal(goal.id, {
                            'title': titleController.text,
                            'description': descController.text,
                            'type': selectedType.name,
                            'priority': selectedPriority.name,
                          });
                          final screenContext = context;
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (success && screenContext.mounted) {
                            ToastWidget.show(screenContext, '目标已更新', type: 'success');
                            final id = int.tryParse(widget.goalId) ?? 0;
                            ref.invalidate(goalDetailProvider(id));
                          } else if (!success && screenContext.mounted) {
                            ToastWidget.show(screenContext, '更新失败，请重试', type: 'error');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
                        ),
                        child: const Text('保存'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDeleteGoal(BuildContext context, Goal goal) {
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
                child: Text('确定要删除目标「${goal.title}」吗？', style: TextStyle(color: AppTheme.textSecondary, height: 1.6)),
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
                        final success = await ref.read(goalsProvider.notifier).deleteGoal(goal.id);
                        final screenContext = context;
                        if (success && mounted) {
                          Navigator.pop(screenContext);
                          ToastWidget.show(screenContext, '目标已删除', type: 'success');
                        } else if (!success && mounted) {
                          ToastWidget.show(screenContext, '删除失败，请重试', type: 'error');
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
}

class _TasksTabContent extends ConsumerStatefulWidget {
  final int goalId;

  const _TasksTabContent({required this.goalId});

  @override
  ConsumerState<_TasksTabContent> createState() => _TasksTabContentState();
}

class _TasksTabContentState extends ConsumerState<_TasksTabContent> {
  void _showAddTaskDialog() {
    final goals = ref.read(goalsProvider).goals;
    TaskFormDialog.show(
      context: context,
      goals: goals,
      goalId: widget.goalId,
      onSaved: ({required goalId, required title, required priority, status, estimateMinutes, dueDate, note, taskType = TaskType.PROGRESSION, recurringFrequency, recurringTime, subTasks}) async {
        final success = await ref.read(tasksProvider.notifier).createTask(
          goalId: goalId, title: title, priority: priority,
          estimateMinutes: estimateMinutes, dueDate: dueDate,
          note: note, taskType: taskType ?? TaskType.PROGRESSION,
          recurringFrequency: recurringFrequency,
          recurringTime: recurringTime, subTasks: subTasks,
        );
        if (success && context.mounted) {
          ToastWidget.show(context, '任务创建成功', type: 'success');
          ref.invalidate(goalTasksProvider(widget.goalId));
        } else if (!success && context.mounted) {
          ToastWidget.show(context, '创建失败，请重试', type: 'error');
        }
      },
    );
  }

  void _showEditDialog(Task task) {
    final goals = ref.read(goalsProvider).goals;
    TaskFormDialog.show(
      context: context,
      goals: goals,
      task: task,
      goalId: widget.goalId,
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
          ToastWidget.show(context, '任务已更新', type: 'success');
          ref.invalidate(goalTasksProvider(widget.goalId));
          ref.invalidate(goalDetailProvider(widget.goalId));
        } else if (!success && context.mounted) {
          ToastWidget.show(context, '更新失败，请重试', type: 'error');
        }
      },
    );
  }



  void _confirmDeleteTask(Task task) {
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
                child: Text('确定要删除任务「${task.title}」吗？', style: TextStyle(color: AppTheme.textSecondary, height: 1.6)),
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
                        if (success && mounted) {
                          ToastWidget.show(context, '任务已删除', type: 'success');
                          ref.invalidate(goalTasksProvider(widget.goalId));
                          ref.invalidate(goalDetailProvider(widget.goalId));
                        } else if (!success && mounted) {
                          ToastWidget.show(context, '删除失败，请重试', type: 'error');
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
    if (task.taskType == TaskType.HABIT) {
      if (task.subTasks.isNotEmpty) {
        // Has subtasks - use toggleSubTask path
        final firstIncomplete = task.subTasks.firstWhere((s) => !s.completed, orElse: () => task.subTasks.first);
        final updated = await ref.read(tasksProvider.notifier).toggleSubTask(task.id, firstIncomplete.id);
        if (mounted && updated != null) {
          if (updated.checkedInToday) {
            ToastWidget.show(context, '打卡成功！连续 ${updated.currentStreak} 天', type: 'success');
          } else {
            ToastWidget.show(context, '已取消打卡', type: 'info');
          }
        }
      } else if (completed) {
        final updated = await ref.read(tasksProvider.notifier).completeTask(task.id);
        if (mounted && updated != null) {
          ToastWidget.show(context, '打卡成功！连续 ${updated.currentStreak} 天', type: 'success');
        }
      } else {
        await ref.read(tasksProvider.notifier).uncompleteTask(task.id);
        if (mounted) ToastWidget.show(context, '已取消打卡', type: 'success');
      }
    } else if (completed) {
      await ref.read(tasksProvider.notifier).completeTask(task.id);
      if (mounted) ToastWidget.show(context, '任务已完成', type: 'success');
    } else {
      await ref.read(tasksProvider.notifier).uncompleteTask(task.id);
      if (mounted) ToastWidget.show(context, '已取消完成', type: 'success');
    }
    ref.invalidate(goalTasksProvider(widget.goalId));
    ref.invalidate(goalDetailProvider(widget.goalId));
  }

  Future<void> _toggleSubTask(Task task, SubTask subTask) async {
    final updated = await ref.read(tasksProvider.notifier).toggleSubTask(task.id, subTask.id);
    if (mounted && updated != null) {
      if (task.taskType == TaskType.HABIT) {
        if (updated.checkedInToday) {
          ToastWidget.show(context, '打卡成功！连续 ${updated.currentStreak} 天', type: 'success');
        } else {
          ToastWidget.show(context, '已取消打卡', type: 'info');
        }
      }
    }
    ref.invalidate(goalTasksProvider(widget.goalId));
    ref.invalidate(goalDetailProvider(widget.goalId));
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(goalTasksProvider(widget.goalId));

    return tasksAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 32, color: AppTheme.danger),
            const SizedBox(height: 8),
            Text('加载失败: $e', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
          ],
        ),
      ),
      data: (tasks) => Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: AppTheme.border)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${tasks.length} 个任务', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                ElevatedButton.icon(
                  onPressed: _showAddTaskDialog,
                  icon: const Icon(Icons.add, size: 14),
                  label: const Text('添加任务'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: tasks.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.task_outlined, size: 40, color: AppTheme.border),
                        const SizedBox(height: 12),
                        Text('暂无关联任务', style: TextStyle(color: AppTheme.textSecondary)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return _GoalTaskCard(
                        task: task,
                        onToggle: (completed) => _toggleTask(task, completed),
                        onEdit: () => _showEditDialog(task),
                        onDelete: () => _confirmDeleteTask(task),
                        onToggleSubTask: (subTask, completed) => _toggleSubTask(task, subTask),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _NotesTabContent extends ConsumerWidget {
  final int goalId;

  const _NotesTabContent({required this.goalId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(goalNotesProvider(goalId));

    return notesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 32, color: AppTheme.danger),
            const SizedBox(height: 8),
            Text('加载失败: $e', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
          ],
        ),
      ),
      data: (notes) => Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: AppTheme.border)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${notes.length} 条笔记', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                ElevatedButton.icon(
                  onPressed: () => context.go('/study-log/new'),
                  icon: const Icon(Icons.add, size: 14),
                  label: const Text('新建笔记'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: notes.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.note_alt_outlined, size: 40, color: AppTheme.border),
                        const SizedBox(height: 12),
                        Text('暂无关联笔记', style: TextStyle(color: AppTheme.textSecondary)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: notes.length,
                    itemBuilder: (context, index) {
                      final note = notes[index];
                      return _GoalNoteCard(
                        note: note,
                        onTap: () => context.go('/study-log/edit/${note['id']}'),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _GoalTaskCard extends ConsumerWidget {
  final Task task;
  final Function(bool) onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Function(SubTask, bool)? onToggleSubTask;

  const _GoalTaskCard({
    required this.task,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
    this.onToggleSubTask,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCompleted = task.isDone;
    final notDueToday = task.taskType == TaskType.HABIT && !task.isDueToday;

    return Opacity(
      opacity: notDueToday ? 0.5 : 1.0,
      child: Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: InkWell(
        onTap: () => _showTaskDetailDialog(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: notDueToday ? BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: AppTheme.borderLight.withValues(alpha: 0.5)),
          ) : null,
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
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            task.title,
                            style: TextStyle(
                              fontSize: 14,
                              decoration: isCompleted ? TextDecoration.lineThrough : null,
                              color: isCompleted ? AppTheme.textMuted : AppTheme.text,
                            ),
                          ),
                        ),
                        if (notDueToday) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.textMuted.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('今日不出现', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                          ),
                        ],
                      ],
                    ),
                    // 进度任务显示进度条
                    if (task.taskType == TaskType.PROGRESSION && task.subTasks.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      _buildProgressBar(),
                    ],
                    // 习惯任务显示连续天数
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
                      onPressed: () => _showSubTaskListDialog(context, ref),
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
    );
  }

  void _showTaskDetailDialog(BuildContext context) {
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
                    _DetailRow('类型', task.taskType == TaskType.HABIT ? '习惯' : '进度'),
                    _DetailRow('状态', isCompleted ? '已完成' : (task.status == TaskStatus.IN_PROGRESS ? '进行中' : '待办')),
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

  Widget _buildProgressBar() {
    final completedCount = task.subTasks.where((s) => s.completed).length;
    final totalCount = task.subTasks.length;
    final percent = totalCount > 0 ? (completedCount / totalCount * 100).round() : 0;

    return Row(
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
        const SizedBox(width: 4),
        Text('($completedCount/$totalCount)', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
      ],
    );
  }

  Widget _buildStreakInfo() {
    return Row(
      children: [
        Icon(Icons.local_fire_department, size: 14, color: AppTheme.primary),
        const SizedBox(width: 4),
        Text('连续 ${task.currentStreak} 天', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        const SizedBox(width: 8),
        Text('累计 ${task.totalCompleted} 次', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
      ],
    );
  }

  void _showSubTaskListDialog(BuildContext context, WidgetRef ref) {
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
}

class _GoalNoteCard extends StatelessWidget {
  final Map<String, dynamic> note;
  final VoidCallback onTap;

  const _GoalNoteCard({required this.note, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final noteText = note['note'] as String? ?? '';
    final duration = note['duration'] as int? ?? 0;
    final createdAt = note['createdAt'] as String? ?? '';
    final taskTitle = note['taskTitle'] as String? ?? '';

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.timer_outlined, size: 12, color: AppTheme.accent),
                    const SizedBox(width: 4),
                    Text('$duration 分钟', style: TextStyle(fontSize: 12, color: AppTheme.accent)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      noteText.isNotEmpty ? noteText : '无内容',
                      style: TextStyle(
                        fontSize: 13,
                        color: noteText.isNotEmpty ? AppTheme.text : AppTheme.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (taskTitle.isNotEmpty)
                      Text(
                        taskTitle,
                        style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                      ),
                  ],
                ),
              ),
              if (createdAt.isNotEmpty)
                Text(
                  _formatTime(DateTime.tryParse(createdAt) ?? DateTime.now()),
                  style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes} 分钟前';
    if (diff.inHours < 24) return '${diff.inHours} 小时前';
    if (diff.inDays < 7) return '${diff.inDays} 天前';
    return '${dt.month}/${dt.day}';
  }
}


class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _StatCard({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        ],
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
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: TextStyle(fontSize: 13, color: AppTheme.textMuted)),
          ),
          Expanded(child: Text(value, style: TextStyle(fontSize: 13, color: AppTheme.text))),
        ],
      ),
    );
  }
}