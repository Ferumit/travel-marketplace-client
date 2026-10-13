import '../theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../l10n/app_localizations.dart';

class DocumentsScreen extends StatelessWidget {
  const DocumentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft),
          onPressed: () => context.pop(),
        ),
        title: Text(l10n.profileDocuments),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildDocCard(
                context,
                icon: LucideIcons.shieldCheck,
                color: Colors.green,
                title: l10n.docsInsurancePolicy,
                subtitle: l10n.docsInsurancePolicyDesc, // № 89320-YDX • Активен до 25.09
              ),
              const SizedBox(height: 16),
              _buildDocCard(
                context,
                icon: LucideIcons.userSquare2,
                color: Colors.blue,
                title: l10n.docsPassport,
                subtitle: l10n.docsPassportDesc, // **** 4512 • Иванов Д.А.
              ),
              const SizedBox(height: 16),
              _buildDocCard(
                context,
                icon: LucideIcons.ticket,
                color: AppColors.accent,
                title: l10n.docsTourVoucher,
                subtitle: l10n.docsTourVoucherDesc, // Алтай • 24 Сентября
              ),
            ],
          ),

          // Floating Action Button
          Positioned(
            bottom: 32,
            right: 24,
            child: FloatingActionButton(
              onPressed: () {},
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.black,
              elevation: 0, // No shadows
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
                side: BorderSide(
                  color: AppColors.accent.withValues(alpha: 0.5),
                ),
              ),
              child: const Icon(LucideIcons.plus, size: 28),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocCard(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          fontFamily: 'Manrope',
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(LucideIcons.eye, size: 20),
                color: AppColors.textSecondary,
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(LucideIcons.download, size: 20),
                color: AppColors.textSecondary,
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}

