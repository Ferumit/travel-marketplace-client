import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../screens/home_screen.dart';
import '../screens/search_screen.dart';
import '../screens/my_orders_screen.dart';
import '../screens/profile_screen.dart';
import '../services/location_permission_service.dart';
import '../theme/app_colors.dart';

/// Главный каркас с нижней навигацией Explora.
///
/// Вкладки: Главная · Поиск · SOS (центральная кнопка) · Маршруты · Профиль.
/// SOS — это действие (переход на SOS-экран), расположено по центру.
class MainTabScaffold extends StatefulWidget {
  const MainTabScaffold({super.key, this.initialTab = 0});

  final int initialTab;

  /// Запрос на переключение вкладки из любого экрана.
  /// Индексы: 0 — Главная, 1 — Поиск, 2 — Маршруты, 3 — Профиль.
  static final ValueNotifier<int> tabRequest = ValueNotifier<int>(0);

  /// Глобальный запрос на поиск (для передачи строки фильтра).
  static final ValueNotifier<String> searchRequest = ValueNotifier<String>('');

  /// Переключить активную вкладку программно.
  static void goToTab(int index) => tabRequest.value = index;

  @override
  State<MainTabScaffold> createState() => _MainTabScaffoldState();
}

class _MainTabScaffoldState extends State<MainTabScaffold> {
  late int _currentIndex;

  static const _screens = <Widget>[
    HomeScreen(),
    SearchScreen(),
    MyOrdersScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab;
    MainTabScaffold.tabRequest.addListener(_onTabRequest);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        LocationPermissionService.requestAll(context);
      }
    });
  }

  @override
  void dispose() {
    MainTabScaffold.tabRequest.removeListener(_onTabRequest);
    super.dispose();
  }

  void _onTabRequest() {
    final index = MainTabScaffold.tabRequest.value;
    if (mounted && index >= 0 && index < _screens.length) {
      setState(() => _currentIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _ExploraNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          MainTabScaffold.tabRequest.value = index;
          setState(() => _currentIndex = index);
        },
        onSos: () => context.push('/sos'),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ExploraNavBar — нижняя навигационная панель
// ─────────────────────────────────────────────────────────────────────────────

class _ExploraNavBar extends StatelessWidget {
  const _ExploraNavBar({
    required this.currentIndex,
    required this.onTap,
    required this.onSos,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onSos;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.backgroundElevated,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      padding: EdgeInsets.only(bottom: bottomInset, top: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _NavItem(
            icon: LucideIcons.home,
            label: 'Главная',
            selected: currentIndex == 0,
            onTap: () => onTap(0),
          ),
          _NavItem(
            icon: LucideIcons.search,
            label: 'Поиск',
            selected: currentIndex == 1,
            onTap: () => onTap(1),
          ),
          _SosNavButton(onTap: onSos),
          _NavItem(
            icon: LucideIcons.clipboardList,
            label: 'Маршруты',
            selected: currentIndex == 2,
            onTap: () => onTap(2),
          ),
          _NavItem(
            icon: LucideIcons.user,
            label: 'Профиль',
            selected: currentIndex == 3,
            onTap: () => onTap(3),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _NavItem — элемент нижней навигации
// ─────────────────────────────────────────────────────────────────────────────

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.accent : AppColors.textTertiary;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: AppColors.accentMuted,
        highlightColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  icon,
                  key: ValueKey(selected),
                  size: 22,
                  color: color,
                ),
              ),
              const SizedBox(height: 5),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight:
                      selected ? FontWeight.w700 : FontWeight.w500,
                  color: color,
                  fontFamily: 'Manrope',
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SosNavButton — центральная SOS-кнопка
// ─────────────────────────────────────────────────────────────────────────────

class _SosNavButton extends StatelessWidget {
  const _SosNavButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.danger,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.danger.withValues(alpha: 0.4),
                    blurRadius: 16,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  'SOS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                    fontFamily: 'Manrope',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'SOS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.danger,
                fontFamily: 'Manrope',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
