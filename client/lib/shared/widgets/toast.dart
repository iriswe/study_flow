import 'package:flutter/material.dart';

class ToastWidget extends StatelessWidget {
  final String message;
  final String type; // success, error, info
  final VoidCallback? onDismiss;

  const ToastWidget({
    super.key,
    required this.message,
    this.type = 'info',
    this.onDismiss,
  });

  static void show(BuildContext context, String message, {String type = 'info', Duration duration = const Duration(seconds: 3)}) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => Positioned(
        bottom: 20,
        right: 20,
        child: _ToastOverlay(
          message: message,
          type: type,
          onDismiss: () => entry.remove(),
          duration: duration,
        ),
      ),
    );
    overlay.insert(entry);
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _ToastOverlay extends StatefulWidget {
  final String message;
  final String type;
  final VoidCallback onDismiss;
  final Duration duration;

  const _ToastOverlay({
    required this.message,
    required this.type,
    required this.onDismiss,
    required this.duration,
  });

  @override
  State<_ToastOverlay> createState() => _ToastOverlayState();
}

class _ToastOverlayState extends State<_ToastOverlay> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 220),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(_controller);
    _controller.forward();
    Future.delayed(widget.duration, _dismiss);
  }

  void _dismiss() {
    if (mounted) {
      _controller.reverse().then((_) => widget.onDismiss());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _borderColor {
    switch (widget.type) {
      case 'success':
        return const Color(0xFF6BA368);
      case 'error':
        return const Color(0xFFD95550);
      default:
        return const Color(0xFFE07A5F);
    }
  }

  IconData get _icon {
    switch (widget.type) {
      case 'success':
        return Icons.check_circle;
      case 'error':
        return Icons.error;
      default:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            constraints: const BoxConstraints(minWidth: 260),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border(
                left: BorderSide(color: _borderColor, width: 3),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 16,
                  offset: const Offset(4, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_icon, color: _borderColor, size: 18),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    widget.message,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF2D2A26)),
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