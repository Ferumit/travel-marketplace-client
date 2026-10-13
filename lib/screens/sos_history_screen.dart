import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../services/sos_history_service.dart';
import '../theme/app_colors.dart';

/// Экран истории всех полученных SOS-сигналов.
/// Доступен из меню профиля → «SOS История».
class SosHistoryScreen extends StatelessWidget {
  const SosHistoryScreen({super.key});

  Future<void> _openMaps(BuildContext context, SosHistoryEntry entry) async {
    if (entry.lat == null || entry.lng == null) return;
    final coords =
        '${entry.lat!.toStringAsFixed(6)}, ${entry.lng!.toStringAsFixed(6)}';
    await Clipboard.setData(ClipboardData(text: coords));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('📍 Скопировано: $coords'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft),
          onPressed: () => context.pop(),
        ),
        title: const Text('История SOS'),
        actions: [
          StreamBuilder<List<SosHistoryEntry>>(
            stream: SosHistoryService.instance.stream,
            builder: (context, snap) {
              final entries = snap.data ?? SosHistoryService.instance.entries;
              if (entries.isEmpty) return const SizedBox.shrink();
              return TextButton(
                onPressed: () => _confirmClear(context),
                child: const Text('Очистить',
                    style: TextStyle(color: Colors.redAccent)),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<SosHistoryEntry>>(
        stream: SosHistoryService.instance.stream,
        initialData: SosHistoryService.instance.entries,
        builder: (context, snap) {
          final entries = snap.data ?? [];
          if (entries.isEmpty) return _buildEmpty(context);
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: entries.length,
            separatorBuilder: (context, i) => const SizedBox(height: 12),
            itemBuilder: (context, i) => _SosCard(
              entry:    entries[i],
              onMapTap: () => _openMaps(context, entries[i]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
            ),
            child: Icon(
              LucideIcons.shieldCheck,
              size: 48,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Сигналов SOS не получено',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Здесь появятся сигналы бедствия,\nполученные через MESH-сеть',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmClear(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Очистить историю?'),
        content: const Text(
          'Все записи о полученных SOS-сигналах будут удалены.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              SosHistoryService.instance.clear();
              Navigator.pop(context);
            },
            child: const Text('Удалить',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}

// ─── Карточка одного SOS-сигнала ─────────────────────────────────────────────

class _SosCard extends StatelessWidget {
  final SosHistoryEntry entry;
  final VoidCallback onMapTap;
  const _SosCard({required this.entry, required this.onMapTap});

  @override
  Widget build(BuildContext context) {
    final hasGps = entry.lat != null && entry.lng != null;
    final time   = DateFormat('dd.MM.yyyy  HH:mm:ss').format(entry.receivedAt);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFB71C1C).withValues(alpha: 0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Шапка
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFB71C1C).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('🆘', style: TextStyle(fontSize: 18)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.userName,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        entry.userId,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: entry.isFromMyTrip
                        ? const Color(0xFFB71C1C).withValues(alpha: 0.15)
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: entry.isFromMyTrip
                          ? const Color(0xFFB71C1C).withValues(alpha: 0.4)
                          : AppColors.border,
                    ),
                  ),
                  child: Text(
                    entry.isFromMyTrip ? 'Мой маршрут' : 'Чужой MESH',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: entry.isFromMyTrip
                          ? const Color(0xFFEF5350)
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Координаты
            Row(
              children: [
                Icon(Icons.location_on_outlined,
                    size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(
                  hasGps
                      ? '${entry.lat!.toStringAsFixed(5)}°N, '
                        '${entry.lng!.toStringAsFixed(5)}°E'
                      : 'Координаты недоступны',
                  style: TextStyle(
                    color: hasGps ? AppColors.textPrimary : AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Время
            Row(
              children: [
                Icon(Icons.access_time_outlined,
                    size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(
                  time,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),

            if (hasGps) ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onMapTap,
                  icon: const Icon(Icons.map_outlined, size: 16),
                  label: const Text('Открыть на карте'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFEF5350),
                    side: const BorderSide(
                        color: Color(0xFFB71C1C), width: 0.8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
