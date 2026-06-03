import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/toast.dart';
import '../../../shared/widgets/task_form_dialog.dart';
import '../../../shared/widgets/form_label.dart';
import '../../tasks/presentation/tasks_provider.dart';
import '../../tasks/domain/models.dart';
import '../../goals/presentation/goals_provider.dart';
import '../../goals/domain/models.dart';
import '../../review/presentation/review_provider.dart';
import '../../stats/presentation/stats_provider.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  String _taskFilter = 'all'; // 'all' or 'mine'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 每次页面可见时刷新今日任务数据（避免被任务页面的 loadTasks() 污染）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
  }

  void _refreshData() {
    ref.read(tasksProvider.notifier).loadTodayTasks();
    ref.read(goalsProvider.notifier).loadGoals();
    ref.read(reviewProvider.notifier).loadReviews();
  }

  @override
  Widget build(BuildContext context) {
    final tasksState = ref.watch(tasksProvider);
    final reviewState = ref.watch(reviewProvider);
    final statsState = ref.watch(statsProvider);
    ref.watch(goalsProvider);

    final todayStudyMinutes = (statsState.overview?.todayStudyDuration ?? 0);
    final consecutiveDays = (statsState.overview?.consecutiveDays ?? 0);

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: KeyboardListener(
        focusNode: FocusNode()..requestFocus(),
        onKeyEvent: (event) {
          if (event is KeyDownEvent) {
            if (HardwareKeyboard.instance.isControlPressed && event.logicalKey == LogicalKeyboardKey.keyN) {
              _showCreateDialog(context);
            }
          }
        },
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              color: AppTheme.bg,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('工作台', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(color: AppTheme.success, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 6),
                            Text('已同步', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () => _showCreateDialog(context),
                        icon: const Icon(Icons.add, size: 16),
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('新建任务'),
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(3),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                              ),
                              child: const Text('Ctrl+N', style: TextStyle(fontSize: 9, fontFamily: 'SF Mono')),
                            ),
                          ],
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () => _showCreateGoalDialog(context),
                        icon: const Icon(Icons.flag_outlined, size: 16),
                        label: const Text('新建目标'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primary,
                          side: BorderSide(color: AppTheme.primary.withValues(alpha: 0.5)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () => context.go('/study-log/new'),
                        icon: const Icon(Icons.note_add_outlined, size: 16),
                        label: const Text('新建笔记'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.accent,
                          side: BorderSide(color: AppTheme.accent.withValues(alpha: 0.5)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatCards(tasksState, reviewState.reviews.length, todayStudyMinutes, consecutiveDays),
                    const SizedBox(height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildTasksCard(tasksState)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildReviewCard()),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      )
    );
  }

  Widget _buildStatCards(TasksState state, int reviewCount, int studyMinutes, int consecutiveDays) {
    final incomplete = state.tasks.where((t) => !t.isDone).length;
    final completed = state.tasks.where((t) => t.isDone).length;
    final total = state.tasks.length;
    final studyHours = (studyMinutes / 60).toStringAsFixed(1);

    return Row(
      children: [
        Expanded(child: _StatCard(value: '$incomplete', label: '今日任务', color: AppTheme.primary, hint: '')),
        const SizedBox(width: 12),
        Expanded(child: _StatCard(value: '$reviewCount', label: '待复习', color: AppTheme.accent, hint: '')),
        const SizedBox(width: 12),
        Expanded(child: _StatCard(value: '$completed/$total', label: '已完成', color: AppTheme.success, hint: '完成率 ${total > 0 ? (completed * 100 / total).toInt() : 0}%')),
        const SizedBox(width: 12),
        Expanded(child: _StatCard(value: '${studyHours}h', label: '学习时长', color: Colors.blue, hint: '')),
        const SizedBox(width: 12),
        Expanded(child: _StatCard(value: '$consecutiveDays', label: '连续学习', color: AppTheme.warning, hint: '')),
      ],
    );
  }

  Widget _buildTasksCard(TasksState state) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.border),
        boxShadow: [AppTheme.shadowSm],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppTheme.border))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('今日任务', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                Row(
                  children: [
                    _FilterTab('全部', _taskFilter == 'all', () => setState(() => _taskFilter = 'all')),
                    const SizedBox(width: 8),
                    _FilterTab('我的', _taskFilter == 'mine', () => setState(() => _taskFilter = 'mine')),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildFilteredTasks(state.tasks),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard() {
    final reviewState = ref.watch(reviewProvider);
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.border),
        boxShadow: [AppTheme.shadowSm],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppTheme.border))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('复习队列', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                Text('${reviewState.reviews.length} 个待复习', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: reviewState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : reviewState.reviews.isEmpty
                    ? Center(
                        child: Column(
                          children: [
                            Icon(Icons.check_circle_outline, size: 36, color: AppTheme.success),
                            const SizedBox(height: 8),
                            Text('今日复习已完成', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                          ],
                        ),
                      )
                    : Column(
                        children: reviewState.reviews.take(5).map((review) => _ReviewItem(
                          question: review.goalTitle,
                          interval: '${review.interval} 天后',
                          stability: (review.stability / 21 * 100).toInt().clamp(0, 100),
                        )).toList(),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyTasks() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.task_outlined, size: 40, color: AppTheme.border),
            const SizedBox(height: 12),
            Text('暂无任务', style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
            const SizedBox(height: 12),
            TextButton(onPressed: () => _showCreateDialog(context), child: const Text('创建第一个任务')),
          ],
        ),
      ),
    );
  }

  Widget _buildFilteredTasks(List<Task> tasks) {
    if (tasks.isEmpty) {
      return _buildEmptyTasks();
    }
    return Column(
      children: tasks.take(5).map((task) => _TaskItem(
        task: task,
        onToggle: (completed) => _toggleTask(task, completed),
        onEdit: () => _showEditDialog(context, task),
        onDelete: () => _confirmDelete(context, task),
        onToggleSubTask: (subTask, completed) => _toggleSubTask(task.id, subTask.id),
      )).toList(),
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
          dueDate: dueDate, note: note, taskType: taskType ?? TaskType.PROGRESSION,
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


  void _showCreateGoalDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final deadlineCtrl = TextEditingController();
    GoalType type = GoalType.PROGRAMMING;
    Priority priority = Priority.P2;

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
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppTheme.border)),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLg)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('新建目标', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                      IconButton(
                        icon: Icon(Icons.close, color: AppTheme.textMuted),
                        onPressed: () => Navigator.pop(ctx),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                // Body
                SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FormLabel('目标名称', required: true),
                      TextField(
                        controller: titleCtrl,
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
                        controller: descCtrl,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: '详细描述你的学习目标...',
                          filled: true,
                          fillColor: AppTheme.bg2,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd), borderSide: BorderSide(color: AppTheme.border)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                FormLabel('类型'),
                                DropdownButtonFormField<GoalType>(
                                  value: type,
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: AppTheme.bg2,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd), borderSide: BorderSide(color: AppTheme.border)),
                                  ),
                                  items: GoalType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.label))).toList(),
                                  onChanged: (v) => setState(() => type = v ?? type),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                FormLabel('截止日期'),
                                TextField(
                                  controller: deadlineCtrl,
                                  decoration: InputDecoration(
                                    hintText: '选择日期',
                                    filled: true,
                                    fillColor: AppTheme.bg2,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd), borderSide: BorderSide(color: AppTheme.border)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      FormLabel('优先级'),
                      Wrap(
                        spacing: 8,
                        children: Priority.values.map((p) => ChoiceChip(
                          label: Text(p.label),
                          selected: priority == p,
                          onSelected: (_) => setState(() => priority = p),
                          selectedColor: AppTheme.getPriorityBgColor(p.name),
                          labelStyle: TextStyle(
                            color: priority == p ? AppTheme.getPriorityColor(p.name) : AppTheme.textSecondary,
                            fontSize: 13,
                          ),
                        )).toList(),
                      ),
                    ],
                  ),
                ),
                // Footer
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
                          if (titleCtrl.text.isEmpty) {
                            ToastWidget.show(ctx, '请输入目标名称', type: 'error');
                            return;
                          }
                          final success = await ref.read(goalsProvider.notifier).createGoal(
                            title: titleCtrl.text,
                            description: descCtrl.text.isNotEmpty ? descCtrl.text : null,
                            type: type,
                            priority: priority,
                            deadline: deadlineCtrl.text.isNotEmpty ? DateTime.tryParse(deadlineCtrl.text) : null,
                          );
                          final screenContext = context;
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (success && screenContext.mounted) {
                            ToastWidget.show(screenContext, '目标创建成功', type: 'success');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
                        ),
                        child: const Text('创建目标'),
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
      if (mounted) ToastWidget.show(context, '已取消打卡', type: 'success');
    } else if (completed) {
      if (task.subTasks.isEmpty) {
        await ref.read(tasksProvider.notifier).completeTask(task.id);
        if (mounted) ToastWidget.show(context, '任务已完成', type: 'success');
      } else {
        await ref.read(tasksProvider.notifier).completeTask(task.id);
      }
    } else {
      await ref.read(tasksProvider.notifier).uncompleteTask(task.id);
      if (mounted) ToastWidget.show(context, '已取消完成', type: 'success');
    }
  }

  Future<void> _toggleSubTask(int taskId, int subTaskId) async {
    final updated = await ref.read(tasksProvider.notifier).toggleSubTask(taskId, subTaskId);
    if (mounted && updated != null && updated.taskType == TaskType.HABIT) {
      if (updated.checkedInToday) {
        ToastWidget.show(context, '打卡成功！连续 ${updated.currentStreak} 天', type: 'success');
      } else {
        ToastWidget.show(context, '已取消打卡', type: 'info');
      }
    }
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
                        final screenContext = context;
                        if (success && screenContext.mounted) {
                          ToastWidget.show(screenContext, '任务已删除', type: 'success');
                        } else if (!success && screenContext.mounted) {
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


class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final String hint;

  const _StatCard({required this.value, required this.label, required this.color, required this.hint});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(AppTheme.radiusLg), border: Border.all(color: AppTheme.border), boxShadow: [AppTheme.shadowSm]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          const SizedBox(height: 5),
          Row(
            children: [
              if (hint.contains('比') || hint.contains('高于')) Icon(Icons.arrow_upward, size: 10, color: AppTheme.success),
              Text(hint, style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
            ],
          ),
        ],
      ),
    );
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(color: active ? AppTheme.primary : Colors.transparent, borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
        child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: active ? Colors.white : AppTheme.textSecondary)),
      ),
    );
  }
}

class _TaskItem extends StatelessWidget {
  final Task task;
  final Function(bool) onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Function(SubTask, bool)? onToggleSubTask;

  const _TaskItem({required this.task, required this.onToggle, required this.onEdit, required this.onDelete, this.onToggleSubTask});

  @override
  Widget build(BuildContext context) {
    final isCompleted = task.isDone;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(AppTheme.radiusMd), border: Border.all(color: isCompleted ? AppTheme.borderLight : AppTheme.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => onToggle(!isCompleted),
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: isCompleted ? AppTheme.success : Colors.transparent, border: Border.all(color: isCompleted ? AppTheme.success : AppTheme.borderLight, width: 2)),
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
                          decoration: BoxDecoration(color: task.taskType == TaskType.HABIT ? AppTheme.primary.withValues(alpha: 0.1) : AppTheme.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                          child: Text(task.taskType == TaskType.HABIT ? '习惯' : '进度', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: task.taskType == TaskType.HABIT ? AppTheme.primary : AppTheme.success)),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: AppTheme.getPriorityBgColor(task.priority), borderRadius: BorderRadius.circular(10)),
                          child: Text(task.priority, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.getPriorityColor(task.priority))),
                        ),
                        if (task.estimateMinutes != null) ...[
                          const SizedBox(width: 6),
                          Icon(Icons.timer_outlined, size: 12, color: AppTheme.textMuted),
                          const SizedBox(width: 2),
                          Text('${task.estimateMinutes}分钟', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(task.title, style: TextStyle(fontSize: 14, decoration: isCompleted ? TextDecoration.lineThrough : null, color: isCompleted ? AppTheme.textMuted : AppTheme.text)),
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
          // Progress bar for PROGRESSION tasks
          if (task.taskType == TaskType.PROGRESSION && task.subTasks.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildProgressBar(),
          ],
          // Streak info for HABIT tasks
          if (task.taskType == TaskType.HABIT) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.local_fire_department, size: 14, color: AppTheme.primary),
                const SizedBox(width: 4),
                Text('连续 ${task.currentStreak} 天', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                const SizedBox(width: 8),
                Text('累计 ${task.totalCompleted} 次', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
              ],
            ),
          ],
        ],
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
            child: LinearProgressIndicator(value: percent / 100, backgroundColor: AppTheme.border, valueColor: AlwaysStoppedAnimation<Color>(AppTheme.success), minHeight: 4),
          ),
        ),
        const SizedBox(width: 8),
        Text('$percent%', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
        const SizedBox(width: 4),
        Text('($completedCount/$totalCount)', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
      ],
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
}

class _ReviewItem extends StatelessWidget {
  final String question;
  final String interval;
  final int stability;

  const _ReviewItem({required this.question, required this.interval, required this.stability});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppTheme.bg2, borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: stability >= 80 ? AppTheme.success : (stability >= 60 ? AppTheme.warning : AppTheme.danger))),
          const SizedBox(width: 10),
          Expanded(child: Text(question, style: TextStyle(fontSize: 13, color: AppTheme.text), maxLines: 1, overflow: TextOverflow.ellipsis)),
          const SizedBox(width: 8),
          Text(interval, style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
        ],
      ),
    );
  }
}

class SharedDatePickerField extends StatefulWidget {
  final TextEditingController controller;

  const SharedDatePickerField({required this.controller});

  @override
  State<SharedDatePickerField> createState() => SharedDatePickerFieldState();
}

class SharedDatePickerFieldState extends State<SharedDatePickerField> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (date != null && mounted) {
          widget.controller.text = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
          setState(() {});
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          hintText: '选择日期',
          filled: true,
          fillColor: AppTheme.bg2,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd), borderSide: BorderSide(color: AppTheme.border)),
          suffixIcon: Icon(Icons.calendar_today, size: 16, color: AppTheme.textMuted),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        ),
        child: Text(
          widget.controller.text.isEmpty ? '' : widget.controller.text,
          style: TextStyle(fontSize: 14, color: widget.controller.text.isEmpty ? AppTheme.textMuted : AppTheme.text),
        ),
      ),
    );
  }
}