import '../theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

enum ServiceRole {
  guide,
  cityGuide,
  busDriver,
  suvDriver,
  minibusDriver,
  minivanDriver,
}

extension ServiceRoleDetails on ServiceRole {
  String get title {
    switch (this) {
      case ServiceRole.guide:
        return 'Горный гид';
      case ServiceRole.cityGuide:
        return 'Городской обзорный гид';
      case ServiceRole.busDriver:
        return 'Водитель автобуса';
      case ServiceRole.suvDriver:
        return 'Водитель внедорожника';
      case ServiceRole.minibusDriver:
        return 'Водитель микроавтобуса';
      case ServiceRole.minivanDriver:
        return 'Водитель минивена';
    }
  }

  String get subtitle {
    switch (this) {
      case ServiceRole.guide:
        return 'Пешие эко-тропы';
      case ServiceRole.cityGuide:
        return 'Обзорные экскурсии';
      case ServiceRole.busDriver:
        return 'Крупные тур. группы';
      case ServiceRole.suvDriver:
        return 'Экспедиции & оффроад';
      case ServiceRole.minibusDriver:
        return 'Группы до 15 чел.';
      case ServiceRole.minivanDriver:
        return 'Комфорт до 7 чел.';
    }
  }

  IconData get icon {
    switch (this) {
      case ServiceRole.guide:
        return LucideIcons.user;
      case ServiceRole.cityGuide:
        return LucideIcons.building; // Or LucideIcons.building2
      case ServiceRole.busDriver:
        return LucideIcons.bus;
      case ServiceRole.suvDriver:
        return LucideIcons.car; // SUV icon
      case ServiceRole.minibusDriver:
        return LucideIcons.truck; // Using truck/bus type icon
      case ServiceRole.minivanDriver:
        return LucideIcons.car;
    }
  }
}

class ServiceSelectionBottomSheet extends StatelessWidget {
  final ServiceRole? initialSelection;
  final ValueChanged<ServiceRole> onSelected;

  const ServiceSelectionBottomSheet({
    super.key,
    this.initialSelection,
    required this.onSelected,
  });

  static void show(
    BuildContext context, {
    bool isGuide = false,
    ServiceRole? initialSelection,
    required ValueChanged<ServiceRole> onSelected,
  }) {
    final roles = isGuide
        ? ServiceRole.values
              .where(
                (r) => r == ServiceRole.guide || r == ServiceRole.cityGuide,
              )
              .toList()
        : ServiceRole.values
              .where(
                (r) => r != ServiceRole.guide && r != ServiceRole.cityGuide,
              )
              .toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          builder: (_, controller) {
            return Container(
              decoration: BoxDecoration(
                color: AppColors.surface, // Theme-aware surface
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  // Drag handle
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.textSecondary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isGuide ? 'Выберите тип гида' : 'Выберите тип транспорта',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.separated(
                      controller: controller,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: roles.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final role = roles[index];
                        final isSelected = role == initialSelection;

                        return _ServiceRoleCard(
                          role: role,
                          isSelected: isSelected,
                          onTap: () {
                            onSelected(role);
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink(); // Handled completely via show method
  }
}

class _ServiceRoleCard extends StatelessWidget {
  final ServiceRole role;
  final bool isSelected;
  final VoidCallback onTap;

  const _ServiceRoleCard({
    required this.role,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accent.withValues(alpha: 0.1)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.accent : AppColors.border,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.accent
                    : AppColors.border,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                role.icon,
                color: isSelected ? Colors.white : AppColors.textSecondary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    role.title,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    role.subtitle,
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

