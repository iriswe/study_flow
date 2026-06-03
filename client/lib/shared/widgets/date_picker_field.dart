import 'package:flutter/material.dart';
import 'package:studyflow_app/core/theme/app_theme.dart';

class SharedDatePickerField extends StatefulWidget {
  final TextEditingController controller;

  const SharedDatePickerField({super.key, required this.controller});

  @override
  State<SharedDatePickerField> createState() => _SharedDatePickerFieldState();
}

class _SharedDatePickerFieldState extends State<SharedDatePickerField> {
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