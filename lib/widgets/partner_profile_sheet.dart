import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/partner_models.dart';
import '../theme/app_colors.dart';
import '../l10n/app_localizations.dart';

class PartnerProfileSheet extends StatelessWidget {
  final PartnerProfile profile;

  const PartnerProfileSheet({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 12), // Leave handle space
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Default bottom sheet drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header: Avatar, Name, Role, Rating
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.background,
                    backgroundImage: (profile.photoUrl?.isNotEmpty ?? false)
                        ? NetworkImage(profile.photoUrl!)
                        : null,
                    child: (profile.photoUrl?.isEmpty ?? true)
                        ? Icon(
                            LucideIcons.user,
                            size: 40,
                            color: AppColors.textSecondary,
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.fullName.isNotEmpty
                              ? profile.fullName
                              : profile.shortName,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Manrope',
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                profile.role.getLocalizedName(l10n),
                                style: TextStyle(
                                  color: AppColors.accent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (profile.isVerified) ...[
                              const SizedBox(width: 8),
                              Icon(
                                LucideIcons.checkCircle2,
                                color: AppColors.accent,
                                size: 16,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              LucideIcons.star,
                              color: AppColors.accent,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              profile.rating.toStringAsFixed(1),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              l10n.partnerProfileReviews(profile.reviewCount),
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // About Section
              if (profile.bio.isNotEmpty || profile.description.isNotEmpty) ...[
                Text(
                  l10n.partnerProfileAboutMe,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Manrope',
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  profile.bio.isNotEmpty ? profile.bio : profile.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Role Specific Details
              if (profile.role.isDriver) ...[
                _buildSectionHeader(context, l10n.partnerProfileCarDetails, LucideIcons.car),
                const SizedBox(height: 16),
                _buildInfoRow(
                  context,
                  l10n.partnerProfileVehicleModel,
                  profile.vehicleModel.isNotEmpty
                      ? profile.vehicleModel
                      : 'Стандартный',
                ),
                _buildInfoRow(context, l10n.partnerProfileVehicleClass, profile.vehicleType.toUpperCase()),
                _buildInfoRow(
                  context,
                  l10n.partnerProfileVehicleCapacity,
                  l10n.partnerProfileVehicleCapacityValue(profile.vehicleCapacity),
                ),
                _buildInfoRow(context, l10n.partnerProfileRate, l10n.partnerProfileRatePerKm(profile.pricePerKm.toInt())),
              ] else if (profile.role.isGuide) ...[
                _buildSectionHeader(context, l10n.partnerProfileSpecialization, LucideIcons.map),
                const SizedBox(height: 16),
                _buildInfoRow(context, l10n.partnerProfileExperience, l10n.partnerProfileExperienceYears(profile.experience)),
                _buildInfoRow(context, l10n.partnerProfileLanguages, profile.languages.join(', ')),
                if (profile.specializations.isNotEmpty)
                  _buildInfoRow(
                    context,
                    l10n.partnerProfileDestinations,
                    profile.specializations.join(', '),
                  ),
                _buildInfoRow(
                  context,
                  l10n.partnerProfileRate,
                  l10n.partnerProfileRatePerDay(profile.pricePerDay.toInt()),
                ),
              ],

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.accent, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Manrope',
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

