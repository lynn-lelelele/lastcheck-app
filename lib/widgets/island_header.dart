import 'package:flutter/material.dart';

import '../theme.dart';

/// 悬浮岛式标题栏：脱离顶部、圆角、半透明、柔和阴影。
class IslandHeader extends StatelessWidget {
  final String title;
  final List<Widget> actions;
  const IslandHeader({super.key, required this.title, this.actions = const []});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: AppDeco.island(),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              ...actions,
            ],
          ),
        ),
      ),
    );
  }
}
