import 'package:flutter/material.dart';

import '../theme.dart';

/// 管家式引导弹窗：谦卑、讲清逻辑，再请用户做选择。
Future<bool?> showButlerDialog(
  BuildContext context, {
  required String title,
  required String content,
  String confirm = '好的，去开启',
  String cancel = '先不了',
}) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(content, style: const TextStyle(height: 1.6)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(cancel, style: const TextStyle(color: AppColors.textGrey)),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirm),
        ),
      ],
    ),
  );
}

