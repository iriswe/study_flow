import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../domain/models.dart';
import '../presentation/goals_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/toast.dart';
import '../../../shared/widgets/date_picker_field.dart';

class GoalsScreen extends ConsumerStatefulWidget {
  const GoalsScreen({super.key});

  @override
  ConsumerState<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends ConsumerState<GoalsScreen> {
  String _filter = 'all';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(goalsProvider.notifier).loadGoals();
    });
  }

  @override
  Widget build(BuildContext context) {
    final goalsState = ref.watch(goalsProvider);

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
                const Text('学习目标', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
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
                                hintText: '搜索目标...',
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
                    ElevatedButton.icon(
                      onPressed: () => _showCreateGoalDialog(context),
                      icon: const Icon(Icons.add, size: 16),
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('新建目标'),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(3),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                            ),
                            child: const Text('Ctrl+Shift+G', style: TextStyle(fontSize: 9, fontFamily: 'SF Mono')),
                          ),
                        ],
                      ),
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
                _FilterTab('进行中', _filter == 'active', () => setState(() => _filter = 'active')),
                const SizedBox(width: 8),
                _FilterTab('已完成', _filter == 'done', () => setState(() => _filter = 'done')),
                const SizedBox(width: 8),
                _FilterTab('已过期', _filter == 'expired', () => setState(() => _filter = 'expired')),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Goals grid
          Expanded(
            child: goalsState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildGoalsList(goalsState),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsList(GoalsState state) {
    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppTheme.danger),
            const SizedBox(height: 12),
            Text(state.error!, style: TextStyle(color: AppTheme.textSecondary)),
            TextButton(
              onPressed: () => ref.read(goalsProvider.notifier).loadGoals(),
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    final filteredGoals = state.goals.where((goal) {
      // Apply search filter
      if (_searchQuery.isNotEmpty) {
        if (!goal.title.contains(_searchQuery)) return false;
      }
      // Apply status filter
      switch (_filter) {
        case 'active':
          return goal.progress < 100;
        case 'done':
          return goal.progress >= 100;
        case 'expired':
          return goal.deadline != null && goal.deadline!.isBefore(DateTime.now());
        default:
          return true;
      }
    }).toList();

    if (filteredGoals.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.flag_outlined, size: 64, color: AppTheme.border),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty ? '暂无目标' : '没有找到匹配的目标',
              style: TextStyle(fontSize: 16, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 12),
            Text(
              '创建你的第一个学习目标',
              style: TextStyle(fontSize: 14, color: AppTheme.textMuted),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Align(
        alignment: Alignment.topLeft,
        child: Wrap(
          spacing: 14,
          runSpacing: 14,
          children: filteredGoals.map((goal) => SizedBox(
            width: 280,
            child: _GoalCard(
              goal: goal,
              onTap: () => context.go('/goals/${goal.id}'),
              onDelete: () => _confirmDelete(context, goal),
            ),
          )).toList(),
        ),
      ),
    );
  }

  void _showCreateGoalDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final deadlineController = TextEditingController();
    GoalType selectedType = GoalType.PROGRAMMING;
    Priority selectedPriority = Priority.P2;

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
                      _FormLabel('目标名称', required: true),
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
                      _FormLabel('目标描述'),
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
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _FormLabel('类型'),
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
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _FormLabel('截止日期'),
                                SharedDatePickerField(controller: deadlineController),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _FormLabel('优先级'),
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
                          if (titleController.text.isEmpty) {
                            ToastWidget.show(ctx, '请输入目标名称', type: 'error');
                            return;
                          }
                          final success = await ref.read(goalsProvider.notifier).createGoal(
                            title: titleController.text,
                            description: descController.text.isNotEmpty ? descController.text : null,
                            type: selectedType,
                            priority: selectedPriority,
                            deadline: deadlineController.text.isNotEmpty ? DateTime.tryParse(deadlineController.text) : null,
                          );
                          final screenContext = context;
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (success && screenContext.mounted) {
                            ToastWidget.show(screenContext, '目标创建成功', type: 'success');
                          } else if (!success && screenContext.mounted) {
                            ToastWidget.show(screenContext, '创建失败，请重试', type: 'error');
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

  void _confirmDelete(BuildContext context, Goal goal) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除目标「${goal.title}」吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await ref.read(goalsProvider.notifier).deleteGoal(goal.id);
              final screenContext = context;
              if (success && screenContext.mounted) {
                ToastWidget.show(screenContext, '目标已删除', type: 'success');
              } else if (!success && screenContext.mounted) {
                ToastWidget.show(screenContext, '删除失败，请重试', type: 'error');
              }
            },
            style: FilledButton.styleFrom(backgroundColor: AppTheme.danger),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}

class _FormLabel extends StatelessWidget {
  final String text;
  final bool required;

  const _FormLabel(this.text, {this.required = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textSecondary)),
          if (required) Text(' *', style: TextStyle(color: AppTheme.danger, fontSize: 13)),
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

class _GoalCard extends StatelessWidget {
  final Goal goal;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _GoalCard({required this.goal, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(color: AppTheme.border),
            boxShadow: [AppTheme.shadowSm],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.getPriorityBgColor(goal.priority.name),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      AppTheme.getPriorityLabel(goal.priority.name),
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.getPriorityColor(goal.priority.name)),
                    ),
                  ),
                  const Spacer(),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, size: 18, color: AppTheme.textMuted),
                    padding: EdgeInsets.zero,
                    onSelected: (v) { if (v == 'delete') onDelete(); },
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'delete', child: Text('删除')),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                goal.title,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                goal.type.label,
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: goal.progress / 100,
                        backgroundColor: AppTheme.border,
                        valueColor: AlwaysStoppedAnimation(AppTheme.getPriorityColor(goal.priority.name)),
                        minHeight: 5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${goal.progress.toInt()}%',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.getPriorityColor(goal.priority.name)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.task_outlined, size: 12, color: AppTheme.textMuted),
                  const SizedBox(width: 4),
                  Text('${goal.completedTasks}/${goal.totalTasks} 任务', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}