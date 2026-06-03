import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class FormLabel extends StatelessWidget {
  final String text;
  final bool required;

  const FormLabel(this.text, {super.key, this.required = false});

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
