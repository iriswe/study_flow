import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'review_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/toast.dart';

class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key});

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(reviewProvider.notifier).loadReviews();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reviewProvider);

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
                const Text('复习计划', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                Text(
                  '${state.reviews.length} 个待复习',
                  style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          // Stats bar
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(value: '${state.todayDue}', label: '今日到期', color: AppTheme.danger),
                _StatItem(value: '${state.weekDue}', label: '本周到期', color: AppTheme.warning),
                _StatItem(value: '${state.avgStabilityPercent}%', label: '记忆稳定度', color: AppTheme.success),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Review cards
          Expanded(
            child: _buildContent(state),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ReviewState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppTheme.danger),
            const SizedBox(height: 12),
            Text(state.error!, style: TextStyle(color: AppTheme.textSecondary)),
            TextButton(
              onPressed: () => ref.read(reviewProvider.notifier).loadReviews(),
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (state.allReviewed || state.reviews.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, size: 80, color: AppTheme.success),
            const SizedBox(height: 24),
            const Text(
              '今日复习已完成！',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              '太棒了，继续保持',
              style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
            ),
          ],
        ),
      );
    }

    final current = state.reviews[state.currentIndex];
    return _ReviewCard(
      key: ValueKey(current.id),
      review: current,
      onRate: (rating) => _submitReview(rating, state.currentIndex),
      onNext: state.reviews.length > state.currentIndex + 1
          ? () => ref.read(reviewProvider.notifier).nextReview()
          : null,
    );
  }

  void _submitReview(String rating, int currentIndex) async {
    final state = ref.read(reviewProvider);
    if (state.reviews.isEmpty || currentIndex >= state.reviews.length) return;

    final current = state.reviews[currentIndex];
    final success = await ref.read(reviewProvider.notifier).submitReview(current.id, rating);
    if (success && mounted) {
      ToastWidget.show(context, '已记录', type: 'success');
    } else if (!success && mounted) {
      ToastWidget.show(context, '提交失败，请重试', type: 'error');
    }
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _StatItem({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: color),
        ),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
      ],
    );
  }
}

class _ReviewCard extends StatefulWidget {
  final ReviewCard review;
  final void Function(String) onRate;
  final VoidCallback? onNext;

  const _ReviewCard({super.key, required this.review, required this.onRate, this.onNext});

  @override
  State<_ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends State<_ReviewCard> {
  bool _showAnswer = false;
  bool _isSubmitting = false;

  @override
  void didUpdateWidget(_ReviewCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.review.id != widget.review.id) {
      setState(() {
        _showAnswer = false;
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.border),
        boxShadow: [AppTheme.shadowSm],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: InkWell(
          onTap: () => setState(() => _showAnswer = !_showAnswer),
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.review.stability > 80
                            ? AppTheme.success
                            : (widget.review.stability > 60 ? AppTheme.warning : AppTheme.danger),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.review.goalTitle,
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                    const Spacer(),
                    Text(
                      '${widget.review.interval}天',
                      style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  widget.review.note ?? '无笔记',
                  style: TextStyle(
                    fontSize: 16,
                    color: widget.review.note != null ? AppTheme.text : AppTheme.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (_showAnswer) ...[
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _RatingChip(
                        label: '忘记',
                        color: AppTheme.danger,
                        isLoading: _isSubmitting,
                        onTap: () => _handleRate('忘记'),
                      ),
                      _RatingChip(
                        label: '困难',
                        color: AppTheme.warning,
                        isLoading: _isSubmitting,
                        onTap: () => _handleRate('困难'),
                      ),
                      _RatingChip(
                        label: '一般',
                        color: Colors.blue,
                        isLoading: _isSubmitting,
                        onTap: () => _handleRate('一般'),
                      ),
                      _RatingChip(
                        label: '简单',
                        color: AppTheme.success,
                        isLoading: _isSubmitting,
                        onTap: () => _handleRate('简单'),
                      ),
                    ],
                  ),
                ] else ...[
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      '点击查看详情并评分',
                      style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleRate(String rating) async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    widget.onRate(rating);
    // Wait for parent to update, then hide loading
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) setState(() => _isSubmitting = false);
  }
}

class _RatingChip extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool isLoading;

  const _RatingChip({required this.label, required this.color, required this.onTap, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isLoading ? color.withValues(alpha: 0.05) : color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: isLoading
              ? SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: color))
              : Text(
                  label,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color),
                ),
        ),
      ),
    );
  }
}