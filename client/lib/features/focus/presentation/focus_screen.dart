import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'focus_provider.dart';
import '../../tasks/presentation/tasks_provider.dart';
import '../../tasks/domain/models.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/toast.dart';

class FocusScreen extends ConsumerStatefulWidget {
  const FocusScreen({super.key});

  @override
  ConsumerState<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends ConsumerState<FocusScreen> {
  String _focusTaskName = '选择一个任务开始专注';
  int _totalSessions = 4;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(focusProvider.notifier).setDuration(25);
      ref.read(tasksProvider.notifier).loadTasks();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(focusProvider);
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
                const Text('专注模式', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.fullscreen, size: 16),
                  label: const Text('全屏'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textSecondary,
                    side: BorderSide(color: AppTheme.border),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
                  ),
                ),
              ],
            ),
          ),
          // Focus card
          Expanded(
            child: Center(
              child: Container(
                width: 460,
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                  border: Border.all(color: AppTheme.border),
                  boxShadow: [AppTheme.shadowLg],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('当前专注', style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
                    const SizedBox(height: 6),
                    Text(
                      _focusTaskName,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 28),
                    // Circular timer
                    SizedBox(
                      width: 200,
                      height: 200,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CustomPaint(
                            size: const Size(200, 200),
                            painter: _TimerRingPainter(
                              progress: state.progress,
                              bgColor: AppTheme.border,
                              fgColor: AppTheme.primary,
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                state.timeDisplay,
                                style: TextStyle(
                                  fontSize: 80,
                                  fontWeight: FontWeight.w700,
                                  color: state.isRunning ? AppTheme.primary : AppTheme.text,
                                  fontFamily: 'SF Mono',
                                  letterSpacing: -0.02,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      state.isRunning ? '专注中...' : '点击开始 · 按 Space 暂停',
                      style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 24),
                    // Controls
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Start button
                        _TimerBtn(
                          icon: Icons.play_arrow,
                          onTap: () => ref.read(focusProvider.notifier).start(),
                          primary: true,
                        ),
                        const SizedBox(width: 14),
                        // Pause/Resume button
                        _TimerBtn(
                          icon: state.isRunning ? Icons.pause : Icons.play_arrow,
                          onTap: () {
                            if (state.isRunning) {
                              ref.read(focusProvider.notifier).pause();
                            } else {
                              ref.read(focusProvider.notifier).start();
                            }
                          },
                        ),
                        const SizedBox(width: 14),
                        // Skip button
                        _TimerBtn(
                          icon: Icons.skip_next,
                          onTap: () => _showSelectTaskDialog(context, tasksState.tasks),
                        ),
                        const SizedBox(width: 14),
                        // Stop/Interrupt button
                        _TimerBtn(
                          icon: Icons.stop,
                          onTap: state.isRunning
                              ? () => _stopAndSave(context)
                              : () => ref.read(focusProvider.notifier).reset(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '第 ${state.sessionsCompleted + 1} 轮 · 共 $_totalSessions 轮',
                      style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 20),
                    OutlinedButton(
                      onPressed: () => _showSelectTaskDialog(context, tasksState.tasks),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primary,
                        side: BorderSide(color: AppTheme.primary),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
                      ),
                      child: const Text('切换任务'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSelectTaskDialog(BuildContext context, List<Task> tasks) {
    showDialog(
      context: context,
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
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppTheme.border)),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLg)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('选择专注任务', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    IconButton(
                      icon: Icon(Icons.close, color: AppTheme.textMuted),
                      onPressed: () => Navigator.pop(ctx),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              Container(
                constraints: const BoxConstraints(maxHeight: 320),
                child: tasks.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.task_outlined, size: 40, color: AppTheme.border),
                            const SizedBox(height: 12),
                            Text('还没有任务，先去添加一个吧', style: TextStyle(color: AppTheme.textSecondary)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        padding: const EdgeInsets.all(8),
                        itemCount: tasks.length,
                        itemBuilder: (context, index) {
                          final task = tasks[index];
                          return _SelectTaskItem(
                            task: task,
                            onTap: () {
                              final screenContext = context;
                              setState(() {
                                _focusTaskName = task.title;
                                _totalSessions = task.estimateMinutes != null ? (task.estimateMinutes! / 25).ceil().clamp(1, 8) : 4;
                              });
                              Navigator.pop(ctx);
                              ToastWidget.show(screenContext, '已切换到：${task.title}', type: 'success');
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _stopAndSave(BuildContext context) {
    ref.read(focusProvider.notifier).stopAndSave();
    ToastWidget.show(context, '专注已结束', type: 'info');
  }
}

class _TimerBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool primary;

  const _TimerBtn({required this.icon, required this.onTap, this.primary = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: primary ? AppTheme.primary : AppTheme.border,
            width: 2,
          ),
          color: primary ? AppTheme.primary : Colors.transparent,
        ),
        child: Icon(
          icon,
          color: primary ? Colors.white : AppTheme.textSecondary,
          size: 22,
        ),
      ),
    );
  }
}

class _SelectTaskItem extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;

  const _SelectTaskItem({required this.task, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isCompleted = task.isDone;
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: Material(
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
                  child: isCompleted
                      ? const Icon(Icons.check, size: 10, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: TextStyle(
                          fontSize: 14,
                          color: isCompleted ? AppTheme.textMuted : AppTheme.text,
                          decoration: isCompleted ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(task.goalTitle, style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                          if (task.estimateMinutes != null) ...[
                            const SizedBox(width: 8),
                            Icon(Icons.timer_outlined, size: 12, color: AppTheme.textMuted),
                            const SizedBox(width: 2),
                            Text('${task.estimateMinutes}分钟', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
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
          ),
        ),
      ),
    );
  }
}

class _TimerRingPainter extends CustomPainter {
  final double progress;
  final Color bgColor;
  final Color fgColor;

  _TimerRingPainter({required this.progress, required this.bgColor, required this.fgColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 6.0;

    // Background circle
    final bgPaint = Paint()
      ..color = bgColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius - strokeWidth / 2, bgPaint);

    // Foreground arc
    final fgPaint = Paint()
      ..color = fgColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      -pi / 2,
      sweepAngle,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _TimerRingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
