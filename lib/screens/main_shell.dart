import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_services.dart';
import '../theme.dart';
import 'checklist_screen.dart';
import 'places_screen.dart';
import 'settings_screen.dart';
import 'templates_screen.dart';

const _kTabItems = [
  (icon: Icons.checklist_rounded, active: Icons.checklist_rounded, label: '清单'),
  (icon: Icons.place_outlined, active: Icons.place_rounded, label: '地点'),
  (icon: Icons.style_outlined, active: Icons.style_rounded, label: '常用'),
  (icon: Icons.settings_outlined, active: Icons.settings_rounded, label: '设置'),
];

/// 主壳：PageView（可左右滑动，带弹性回弹）+ 自定义动画底部导航。
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final _controller = PageController();
  int _index = 0;

  @override
  void initState() {
    super.initState();
    AppEvents.tabIndex.addListener(_onExternalTab);
  }

  @override
  void dispose() {
    AppEvents.tabIndex.removeListener(_onExternalTab);
    _controller.dispose();
    super.dispose();
  }

  void _onExternalTab() {
    final target = AppEvents.tabIndex.value;
    if (target != _index && target >= 0 && target < _kTabItems.length) {
      _controller.animateToPage(
        target,
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _onTap(int i) {
    if (i == _index) return;
    _controller.animateToPage(
      i,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _controller,
        physics: const BouncingScrollPhysics(),
        onPageChanged: (i) {
          setState(() => _index = i);
          AppEvents.tabIndex.value = i;
        },
        children: const [
          ChecklistScreen(),
          PlacesScreen(),
          TemplatesScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: _AnimatedNavBar(index: _index, onTap: _onTap),
    );
  }
}

/// 弹性底部导航：选中项有滑动药丸 + 图标弹性缩放。
class _AnimatedNavBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  const _AnimatedNavBar({required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const count = 4;
    return Container(
      color: Colors.transparent,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                height: 62,
                decoration: AppDeco.island(radius: 28),
                child: LayoutBuilder(
            builder: (context, constraints) {
              final itemW = constraints.maxWidth / count;
              return Stack(
                children: [
                  // 滑动药丸
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 420),
                    curve: Curves.easeOutBack,
                    left: index * itemW + itemW * 0.12,
                    width: itemW * 0.76,
                    top: 6,
                    bottom: 6,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  Row(
                    children: List.generate(count, (i) {
                      return Expanded(
                        child: _NavItem(
                          icon: i == index ? _kTabItems[i].active : _kTabItems[i].icon,
                          label: _kTabItems[i].label,
                          selected: i == index,
                          onTap: () => onTap(i),
                        ),
                      );
                    }),
                  ),
                ],
              );
            },
              ),
            ),
          ),
        ),
      ),
    ),
  );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 图标弹性缩放（jelly 效果）
          TweenAnimationBuilder<double>(
            tween: Tween(end: selected ? 1.18 : 1.0),
            duration: const Duration(milliseconds: 420),
            curve: Curves.elasticOut,
            builder: (_, scale, child) =>
                Transform.scale(scale: scale, child: child),
            child: Icon(
              icon,
              size: 24,
              color: selected ? AppColors.primaryDark : AppColors.textGrey,
            ),
          ),
          const SizedBox(height: 2),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              fontSize: 11,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: selected ? AppColors.primaryDark : AppColors.textGrey,
            ),
            child: Text(label),
          ),
        ],
      ),
    );
  }
}





