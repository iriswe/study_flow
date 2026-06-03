import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'settings_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/toast.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(settingsProvider);

    if (state.isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.bg,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
            color: AppTheme.bg,
            child: const Row(
              children: [
                Text('设置', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
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
                  // Appearance section
                  _SectionTitle('外观'),
                  _SettingsCard([
                    _SettingsRow(
                      label: '主题',
                      child: _Dropdown(
                        value: _themeLabel(state.themeMode),
                        items: const ['浅色', '深色', '跟随系统'],
                        onChanged: (v) => _applyTheme(v, state.themeMode),
                      ),
                    ),
                    _SettingsRow(
                      label: '侧边栏',
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('展开', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                          const SizedBox(width: 8),
                          _Toggle(
                            active: state.sidebarExpandedValue,
                            onTap: () => ref.read(settingsProvider.notifier).setSidebarExpanded(!state.sidebarExpandedValue),
                          ),
                        ],
                      ),
                      child: const SizedBox.shrink(),
                    ),
                  ]),
                  const SizedBox(height: 20),

                  // Notifications section
                  _SectionTitle('通知提醒'),
                  _SettingsCard([
                    _SettingsRow(
                      label: '复习提醒',
                      subtitle: '有内容到期时发送通知',
                      trailing: _Toggle(
                        active: state.reviewNotificationEnabled,
                        onTap: () => ref.read(settingsProvider.notifier).setReviewNotification(!state.reviewNotificationEnabled),
                      ),
                      child: const SizedBox.shrink(),
                    ),
                    _SettingsRow(
                      label: '每日提醒时间',
                      child: GestureDetector(
                        onTap: () => _showTimePicker(context, state.reviewNotificationTime),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.bg2,
                            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(state.reviewNotificationTime, style: TextStyle(fontSize: 13, color: AppTheme.text)),
                              const SizedBox(width: 8),
                              Icon(Icons.access_time, size: 14, color: AppTheme.textMuted),
                            ],
                          ),
                        ),
                      ),
                    ),
                    _SettingsRow(
                      label: '专注提醒',
                      subtitle: '番茄钟完成时通知',
                      trailing: _Toggle(
                        active: state.focusNotificationEnabled,
                        onTap: () => ref.read(settingsProvider.notifier).setFocusNotification(!state.focusNotificationEnabled),
                      ),
                      child: const SizedBox.shrink(),
                    ),
                  ]),
                  const SizedBox(height: 20),

                  // Focus mode section
                  _SectionTitle('专注模式设置'),
                  _SettingsCard([
                    _SettingsRow(
                      label: '专注时长',
                      subtitle: '每个番茄钟的时长',
                      child: _Dropdown(
                        value: '${state.focusDuration} 分钟',
                        items: const ['15 分钟', '25 分钟', '30 分钟', '45 分钟', '60 分钟'],
                        onChanged: (v) => _applyFocusDuration(v),
                      ),
                    ),
                    _SettingsRow(
                      label: '短休息',
                      subtitle: '每个番茄钟后的休息',
                      child: _Dropdown(
                        value: '${state.breakDuration} 分钟',
                        items: const ['5 分钟', '10 分钟'],
                        onChanged: (v) => _applyBreakDuration(v),
                      ),
                    ),
                    _SettingsRow(
                      label: '长休息',
                      subtitle: '完成所有轮次后的休息',
                      child: _Dropdown(
                        value: '${state.longBreakDuration} 分钟',
                        items: const ['15 分钟', '20 分钟', '30 分钟'],
                        onChanged: (v) => _applyLongBreakDuration(v),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 20),

                  // Data sync section
                  _SectionTitle('数据同步'),
                  _SettingsCard([
                    _SettingsRow(
                      label: '同步状态',
                      subtitle: '上次同步：2 分钟前',
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.success,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text('已同步', style: TextStyle(fontSize: 13, color: AppTheme.success)),
                        ],
                      ),
                      child: const SizedBox.shrink(),
                    ),
                    _SettingsRow(
                      label: '离线模式',
                      subtitle: '无网络时可用',
                      trailing: Text('可用', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                      child: const SizedBox.shrink(),
                    ),
                    _SettingsRow(
                      label: '手动同步',
                      child: OutlinedButton(
                        onPressed: () => _doSync(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        child: const Text('立即同步'),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 20),

                  // About section
                  _SectionTitle('关于'),
                  _SettingsCard([
                    _SettingsRow(
                      label: '学流 StudyFlow',
                      subtitle: '版本 1.0.0 · 2026',
                      child: const SizedBox.shrink(),
                    ),
                  ]),
                  const SizedBox(height: 24),

                  // Footer links
                  Center(
                    child: Wrap(
                      spacing: 16,
                      children: [
                        _FooterLink('快捷键', onTap: () {}),
                        _FooterLink('帮助文档', onTap: () {}),
                        _FooterLink('用户协议', onTap: () {}),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _themeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return '浅色';
      case ThemeMode.dark:
        return '深色';
      default:
        return '跟随系统';
    }
  }

  void _applyTheme(String? label, ThemeMode current) {
    if (label == null) return;
    ThemeMode mode;
    switch (label) {
      case '浅色':
        mode = ThemeMode.light;
        break;
      case '深色':
        mode = ThemeMode.dark;
        break;
      default:
        mode = ThemeMode.system;
    }
    ref.read(settingsProvider.notifier).setThemeMode(mode);
  }

  void _applyFocusDuration(String? v) {
    if (v == null) return;
    final minutes = int.tryParse(v.replaceAll(' 分钟', ''));
    if (minutes != null) {
      ref.read(settingsProvider.notifier).setFocusDuration(minutes);
    }
  }

  void _applyBreakDuration(String? v) {
    if (v == null) return;
    final minutes = int.tryParse(v.replaceAll(' 分钟', ''));
    if (minutes != null) {
      ref.read(settingsProvider.notifier).setBreakDuration(minutes);
    }
  }

  void _applyLongBreakDuration(String? v) {
    if (v == null) return;
    final minutes = int.tryParse(v.replaceAll(' 分钟', ''));
    if (minutes != null) {
      ref.read(settingsProvider.notifier).setLongBreakDuration(minutes);
    }
  }

  void _showTimePicker(BuildContext context, String currentTime) async {
    final parts = currentTime.split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(parts.isNotEmpty ? parts[0] : '9') ?? 9,
      minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
    );
    final time = await showTimePicker(context: context, initialTime: initial);
    if (time != null && mounted) {
      final formatted = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      ref.read(settingsProvider.notifier).setReviewNotificationTime(formatted);
      ToastWidget.show(context, '提醒时间已设置', type: 'success');
    }
  }

  Future<void> _doSync(BuildContext context) async {
    ToastWidget.show(context, '同步中...', type: 'info');
    await ref.read(settingsProvider.notifier).syncNow();
    if (mounted) {
      ToastWidget.show(context, '同步完成', type: 'success');
    }
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.primary),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard(this.children);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: children.asMap().entries.map((entry) {
          final isLast = entry.key == children.length - 1;
          return Column(
            children: [
              entry.value,
              if (!isLast) Divider(height: 1, indent: 16, endIndent: 16, color: AppTheme.border),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final String label;
  final String? subtitle;
  final Widget? trailing;
  final Widget child;

  const _SettingsRow({required this.label, this.subtitle, this.trailing, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                if (subtitle != null) Text(subtitle!, style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
              ],
            ),
          ),
          if (trailing != null) trailing!,
          if (child is SizedBox && child.key == null) const SizedBox.shrink() else child,
        ],
      ),
    );
  }
}

class _Dropdown extends StatelessWidget {
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _Dropdown({required this.value, required this.items, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.bg2,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.border),
      ),
      child: DropdownButton<String>(
        value: value,
        underline: const SizedBox(),
        isDense: true,
        items: items.map((item) => DropdownMenuItem(value: item, child: Text(item, style: const TextStyle(fontSize: 13)))).toList(),
        onChanged: onChanged,
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  final bool active;
  final VoidCallback onTap;

  const _Toggle({required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 24,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: active ? AppTheme.primary : AppTheme.border,
          borderRadius: BorderRadius.circular(12),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 150),
          alignment: active ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _FooterLink(this.label, {required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(label, style: TextStyle(fontSize: 12, color: AppTheme.primary)),
    );
  }
}
