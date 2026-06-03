import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../features/tasks/domain/models.dart';
import '../../features/goals/domain/models.dart';
import 'form_label.dart';
import 'date_picker_field.dart';
import 'toast.dart';

class TaskFormDialog {
  static Future<void> show({
    required BuildContext context,
    required List<Goal> goals,
    Task? task,
    int? goalId,
    required Future<void> Function({
      required int goalId,
      required String title,
      required String priority,
      TaskStatus? status,
      int? estimateMinutes,
      DateTime? dueDate,
      String? note,
      TaskType? taskType,
      String? recurringFrequency,
      String? recurringTime,
      List<String>? subTasks,
    }) onSaved,
  }) async {
    final isEdit = task != null;
    final titleCtrl = TextEditingController(text: task?.title ?? '');
    final descCtrl = TextEditingController(text: task?.note ?? '');
    final estimateCtrl = TextEditingController(text: task?.estimateMinutes?.toString() ?? '30');
    final dueDateCtrl = TextEditingController(
      text: task?.dueDate != null
          ? '${task!.dueDate!.year}-${task.dueDate!.month.toString().padLeft(2, '0')}-${task.dueDate!.day.toString().padLeft(2, '0')}'
          : '',
    );
    String priority = task?.priority ?? 'P2';
    String status = _statusToString(task?.status ?? TaskStatus.PENDING);
    int? selectedGoalId = goalId ?? task?.goalId;
    TaskType taskType = task?.taskType ?? TaskType.PROGRESSION;
    String? recurringFrequency = task?.recurringFrequency;
    TimeOfDay? recurringTime = task?.recurringTime;
    List<String> subTasks = task != null ? List.from(task.subTasks.map((s) => s.title)) : [];
    final subTaskCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Dialog(
          backgroundColor: AppTheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
          child: SizedBox(
            width: 560,
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
                      Text(isEdit ? '编辑任务' : '新建任务', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
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
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const FormLabel('任务标题', required: true),
                        TextField(controller: titleCtrl, decoration: InputDecoration(hintText: '例如：完成第三章练习题', filled: true, fillColor: AppTheme.bg2, border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd), borderSide: BorderSide(color: AppTheme.border)))),
                        if (goalId == null) ...[
                          const SizedBox(height: 16),
                          const FormLabel('关联目标', required: true),
                          DropdownButtonFormField<int>(
                            value: selectedGoalId,
                            decoration: InputDecoration(filled: true, fillColor: AppTheme.bg2, border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd), borderSide: BorderSide(color: AppTheme.border))),
                            hint: const Text('请选择目标'),
                            items: goals.map((g) => DropdownMenuItem(value: g.id, child: Text(g.title))).toList(),
                            onChanged: (v) => setState(() => selectedGoalId = v),
                          ),
                        ],
                        const SizedBox(height: 16),
                        const FormLabel('任务类型'),
                        Wrap(
                          spacing: 8,
                          children: [
                            ChoiceChip(
                              label: const Text('进度任务'),
                              selected: taskType == TaskType.PROGRESSION,
                              onSelected: (_) => setState(() {
                                taskType = TaskType.PROGRESSION;
                                recurringFrequency = null;
                                recurringTime = null;
                              }),
                              selectedColor: AppTheme.success.withValues(alpha: 0.2),
                              labelStyle: TextStyle(color: taskType == TaskType.PROGRESSION ? AppTheme.success : AppTheme.textSecondary, fontSize: 12),
                            ),
                            ChoiceChip(
                              label: const Text('习惯任务'),
                              selected: taskType == TaskType.HABIT,
                              onSelected: (_) => setState(() => taskType = TaskType.HABIT),
                              selectedColor: AppTheme.primary.withValues(alpha: 0.2),
                              labelStyle: TextStyle(color: taskType == TaskType.HABIT ? AppTheme.primary : AppTheme.textSecondary, fontSize: 12),
                            ),
                          ],
                        ),
                        if (taskType == TaskType.HABIT) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const FormLabel('重复频率'),
                                    DropdownButtonFormField<String>(
                                      value: recurringFrequency,
                                      decoration: InputDecoration(filled: true, fillColor: AppTheme.bg2, border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd), borderSide: BorderSide(color: AppTheme.border))),
                                      hint: const Text('选择频率'),
                                      items: const [
                                        DropdownMenuItem(value: 'DAILY', child: Text('每天')),
                                        DropdownMenuItem(value: 'WEEKLY', child: Text('每周')),
                                        DropdownMenuItem(value: 'WEEKDAYS', child: Text('工作日')),
                                      ],
                                      onChanged: (v) => setState(() => recurringFrequency = v),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const FormLabel('提醒时间'),
                                    InkWell(
                                      onTap: () async {
                                        final time = await showTimePicker(context: ctx, initialTime: recurringTime ?? TimeOfDay.now());
                                        if (time != null) setState(() => recurringTime = time);
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                        decoration: BoxDecoration(color: AppTheme.bg2, borderRadius: BorderRadius.circular(AppTheme.radiusMd), border: Border.all(color: AppTheme.border)),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(recurringTime != null ? '${recurringTime!.hour.toString().padLeft(2, '0')}:${recurringTime!.minute.toString().padLeft(2, '0')}' : '选择时间', style: TextStyle(fontSize: 14, color: recurringTime != null ? AppTheme.text : AppTheme.textMuted)),
                                            Icon(Icons.access_time, size: 16, color: AppTheme.textMuted),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const FormLabel('优先级'),
                                  Wrap(
                                    spacing: 8,
                                    children: ['P0', 'P1', 'P2'].map((p) => ChoiceChip(
                                      label: Text(p),
                                      selected: priority == p,
                                      onSelected: (_) => setState(() => priority = p),
                                      selectedColor: AppTheme.getPriorityBgColor(p),
                                      labelStyle: TextStyle(color: priority == p ? AppTheme.getPriorityColor(p) : AppTheme.textSecondary, fontSize: 12),
                                    )).toList(),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const FormLabel('预计时长（分钟）'),
                                  TextField(controller: estimateCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(hintText: '30', filled: true, fillColor: AppTheme.bg2, border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd), borderSide: BorderSide(color: AppTheme.border)))),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const FormLabel('截止日期'),
                                  SharedDatePickerField(controller: dueDateCtrl),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const FormLabel('状态'),
                                  DropdownButtonFormField<String>(
                                    value: status,
                                    decoration: InputDecoration(filled: true, fillColor: AppTheme.bg2, border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd), borderSide: BorderSide(color: AppTheme.border))),
                                    items: ['待办', '进行中', '已完成'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                                    onChanged: (v) => setState(() => status = v ?? status),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const FormLabel('任务描述'),
                        TextField(controller: descCtrl, maxLines: 2, decoration: InputDecoration(hintText: '详细描述任务内容...', filled: true, fillColor: AppTheme.bg2, border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd), borderSide: BorderSide(color: AppTheme.border)))),
                        if (taskType == TaskType.PROGRESSION) ...[
                          const SizedBox(height: 16),
                          const FormLabel('子任务'),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: AppTheme.bg2, borderRadius: BorderRadius.circular(AppTheme.radiusMd), border: Border.all(color: AppTheme.border)),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(child: TextField(controller: subTaskCtrl, decoration: const InputDecoration(hintText: '输入子任务标题', border: InputBorder.none), style: const TextStyle(fontSize: 14))),
                                    TextButton(
                                      onPressed: () {
                                        if (subTaskCtrl.text.trim().isNotEmpty) {
                                          setState(() {
                                            subTasks.add(subTaskCtrl.text.trim());
                                            subTaskCtrl.clear();
                                          });
                                        }
                                      },
                                      child: const Text('+ 添加'),
                                    ),
                                  ],
                                ),
                                if (subTasks.isNotEmpty) ...[
                                  const Divider(height: 16),
                                  ...subTasks.asMap().entries.map((entry) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Row(
                                      children: [
                                        Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.success)),
                                        const SizedBox(width: 8),
                                        Expanded(child: Text(entry.value, style: const TextStyle(fontSize: 13))),
                                        GestureDetector(
                                          onTap: () => setState(() => subTasks.removeAt(entry.key)),
                                          child: Icon(Icons.close, size: 16, color: AppTheme.textMuted),
                                        ),
                                      ],
                                    ),
                                  )),
                                ],
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    TextButton.icon(
                                      onPressed: () => _showBatchSubTaskDialog(ctx, subTasks, (items) => setState(() => subTasks = items)),
                                      icon: const Icon(Icons.playlist_add, size: 16),
                                      label: const Text('快捷添加'),
                                      style: TextButton.styleFrom(foregroundColor: AppTheme.textSecondary, padding: const EdgeInsets.symmetric(horizontal: 8)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
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
                            ToastWidget.show(ctx, '请输入任务标题', type: 'error');
                            return;
                          }
                          final effectiveGoalId = goalId ?? selectedGoalId;
                          if (effectiveGoalId == null) {
                            ToastWidget.show(ctx, '请选择关联目标', type: 'error');
                            return;
                          }
                          await onSaved(
                            goalId: effectiveGoalId,
                            title: titleCtrl.text,
                            priority: priority,
                            status: _statusFromString(status),
                            estimateMinutes: int.tryParse(estimateCtrl.text),
                            dueDate: dueDateCtrl.text.isNotEmpty ? DateTime.tryParse(dueDateCtrl.text) : null,
                            note: descCtrl.text.isNotEmpty ? descCtrl.text : null,
                            taskType: taskType,
                            recurringFrequency: recurringFrequency,
                            recurringTime: recurringTime != null ? '${recurringTime!.hour.toString().padLeft(2, '0')}:${recurringTime!.minute.toString().padLeft(2, '0')}:00' : null,
                            subTasks: subTasks.isNotEmpty ? subTasks : null,
                          );
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
                        ),
                        child: Text(isEdit ? '保存' : '创建任务'),
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

  static void _showBatchSubTaskDialog(BuildContext dialogContext, List<String> currentSubTasks, Function(List<String>) onUpdate) {
    final ctrl = TextEditingController();
    showDialog(
      context: dialogContext,
      builder: (ctx) => Dialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
        child: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppTheme.border)), borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLg))),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('批量添加子任务', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    IconButton(icon: Icon(Icons.close, color: AppTheme.textMuted), onPressed: () => Navigator.pop(ctx), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('粘贴导入', style: TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      TextField(controller: ctrl, maxLines: 8, decoration: InputDecoration(hintText: '每行一个子任务标题，示例：\n第1章 概述\n第2章 基础概念\n第3章 核心原理', filled: true, fillColor: AppTheme.bg2, border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd), borderSide: BorderSide(color: AppTheme.border)))),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(border: Border(top: BorderSide(color: AppTheme.border)), borderRadius: const BorderRadius.vertical(bottom: Radius.circular(AppTheme.radiusLg))),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd))),
                      child: const Text('取消'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        final lines = ctrl.text.split('\n').where((l) => l.trim().isNotEmpty).toList();
                        if (lines.isNotEmpty) {
                          final newList = [...currentSubTasks, ...lines.map((l) => l.trim())];
                          onUpdate(newList);
                        }
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd))),
                      child: const Text('导入'),
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

  static String _statusToString(TaskStatus status) {
    switch (status) {
      case TaskStatus.PENDING:
        return '待办';
      case TaskStatus.IN_PROGRESS:
        return '进行中';
      case TaskStatus.COMPLETED:
        return '已完成';
    }
  }

  static TaskStatus _statusFromString(String status) {
    switch (status) {
      case '进行中':
        return TaskStatus.IN_PROGRESS;
      case '已完成':
        return TaskStatus.COMPLETED;
      default:
        return TaskStatus.PENDING;
    }
  }
}
