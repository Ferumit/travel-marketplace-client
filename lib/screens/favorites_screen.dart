import '../theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../models/app_models.dart' as app_models;
import '../repository/firestore_data_repository.dart';
import '../services/auth_service.dart';
import '../theme/theme.dart';
import '../l10n/app_localizations.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  String _activeTab = 'routes';

  List<Map<String, String>> _getTabs(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [
      {'id': 'routes', 'label': l10n.favoritesTabRoutes},
      {'id': 'guides', 'label': l10n.favoritesTabGuides},
      {'id': 'cars', 'label': l10n.favoritesTabCars},
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tabs = _getTabs(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft),
          onPressed: () => context.pop(),
        ),
        title: Text(l10n.profileFavorites),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60.0),
          child: SizedBox(
            height: 44,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: tabs.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final tab = tabs[index];
                final isActive = _activeTab == tab['id'];

                return GestureDetector(
                  onTap: () => setState(() => _activeTab = tab['id']!),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.surface : AppColors.background,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isActive
                            ? AppColors.border
                            : AppColors.border.withValues(alpha: 0.5),
                        width: isActive ? 1.5 : 1,
                      ),
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                                color: context.secondaryContainer,
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : [],
                    ),
                    child: Center(
                      child: Text(
                        tab['label']!,
                        style: TextStyle(
                          color: isActive
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                          fontWeight: isActive
                              ? FontWeight.bold
                              : FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    final l10n = AppLocalizations.of(context)!;
    final uid = AuthService.instance.currentFirebaseUser?.uid;
    if (uid == null) {
      return Center(child: Text(l10n.authRequired));
    }

    return FutureBuilder<app_models.User?>(
      future: FirestoreDataRepository.instance.getUser(uid),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: AppColors.accent),
          );
        }

        final user = userSnapshot.data;
        if (user == null) {
          return Center(child: Text(l10n.userLoadError));
        }

        if (_activeTab == 'routes') {
          return _buildRoutesTab(user, l10n);
        } else if (_activeTab == 'guides') {
          return _buildGuidesTab(user, l10n);
        } else {
          return _buildCarsTab(user, l10n);
        }
      },
    );
  }

  Widget _buildRoutesTab(app_models.User user, AppLocalizations l10n) {
    return FutureBuilder<List<app_models.Route>>(
      future: FirestoreDataRepository.instance.getRoutes(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: AppColors.accent),
          );
        }
        final allRoutes = snapshot.data ?? [];
        final routes = allRoutes
            .where((r) => user.favoriteRouteIds.contains(r.id))
            .toList();

        if (routes.isEmpty) {
          return Center(
            child: Text(
              l10n.favoritesNoRoutes,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          );
        }
        return GridView.builder(
          padding: const EdgeInsets.all(16.0),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 3 / 4,
          ),
          itemCount: routes.length,
          itemBuilder: (context, i) {
            final route = routes[i];
            return _buildRouteCard(
              id: route.id,
              title: route.title,
              rating: route.rating.toStringAsFixed(1),
              img: route.imageUrl,
              difficulty: route.difficulty,
              isFavorite: true,
              onToggleFavorite: () async {
                await FirestoreDataRepository.instance.toggleFavoriteRoute(
                  user.id,
                  route.id,
                );
                setState(() {}); // Refresh future builders
              },
              l10n: l10n,
            );
          },
        );
      },
    );
  }

  Widget _buildGuidesTab(app_models.User user, AppLocalizations l10n) {
    return FutureBuilder<List<app_models.PartnerProfile>>(
      future: FirestoreDataRepository.instance.getGuides(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: AppColors.accent),
          );
        }
        final allGuides = snapshot.data ?? [];
        final guides = allGuides
            .where((g) => user.favoriteGuideIds.contains(g.id))
            .toList();

        if (guides.isEmpty) {
          return Center(
            child: Text(
              l10n.favoritesNoGuides,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16.0),
          itemCount: guides.length,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final g = guides[index];
            return _buildGuideCard(
              id: g.id,
              name: g.shortName,
              role: g.specializations.isNotEmpty
                  ? g.specializations.first
                  : g.role.getLocalizedName(l10n),
              rating: g.rating.toStringAsFixed(1),
              img: g.photoUrl ?? '',
              isFavorite: true,
              onToggleFavorite: () async {
                await FirestoreDataRepository.instance.toggleFavoriteGuide(
                  user.id,
                  g.id,
                );
                setState(() {});
              },
            );
          },
        );
      },
    );
  }

  Widget _buildCarsTab(app_models.User user, AppLocalizations l10n) {
    return FutureBuilder<List<app_models.PartnerProfile>>(
      future: FirestoreDataRepository.instance.getDrivers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: AppColors.accent),
          );
        }
        final allDrivers = snapshot.data ?? [];
        final drivers = allDrivers
            .where((d) => user.favoriteDriverIds.contains(d.id))
            .toList();

        if (drivers.isEmpty) {
          return Center(
            child: Text(
              l10n.favoritesNoCars,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16.0),
          itemCount: drivers.length,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final d = drivers[index];
            return _buildGuideCard(
              id: d.id,
              name: d.vehicleModel.isNotEmpty ? d.vehicleModel : d.shortName,
              role: d.vehicleType,
              rating: d.rating.toStringAsFixed(1),
              img: d.photoUrl ?? '',
              isFavorite: true,
              isCar: true,
              onToggleFavorite: () async {
                await FirestoreDataRepository.instance.toggleFavoriteDriver(
                  user.id,
                  d.id,
                );
                setState(() {});
              },
            );
          },
        );
      },
    );
  }

  Widget _buildRouteCard({
    required String id,
    required String title,
    required String rating,
    required String img,
    required app_models.Difficulty difficulty,
    required bool isFavorite,
    required VoidCallback onToggleFavorite,
    required AppLocalizations l10n,
  }) {
    final diffLabel = switch (difficulty) {
      app_models.Difficulty.easy => l10n.difficultyEasy,
      app_models.Difficulty.moderate => l10n.difficultyModerate,
      app_models.Difficulty.hard => l10n.difficultyHard,
      app_models.Difficulty.expert => l10n.difficultyExpert,
    };

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            color: AppColors.accent.withValues(alpha: 0.1),
            child: Center(
              child: Icon(
                LucideIcons.image,
                color: AppColors.accent,
                size: 32,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.8),
                  Colors.transparent,
                  Colors.transparent,
                ],
              ),
            ),
          ),
          // Difficulty badge
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                diffLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          // Heart
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: onToggleFavorite,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
                child: Icon(
                  isFavorite
                      ? LucideIcons.heart
                      : LucideIcons
                            .heart, // Note: filled heart doesn't exist in regular set easily, usually people do solid color
                  color: isFavorite ? context.errorColor : Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 12,
            left: 12,
            right: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      LucideIcons.star,
                      color: AppColors.accent,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      rating,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideCard({
    required String id,
    required String name,
    required String role,
    required String rating,
    required String img,
    required bool isFavorite,
    required VoidCallback onToggleFavorite,
    bool isCar = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: isCar ? 80 : 56,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(isCar ? 12 : 28),
              image: DecorationImage(
                image: NetworkImage(img),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  role,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  LucideIcons.star,
                  color: AppColors.accent,
                  size: 12,
                ),
                const SizedBox(width: 4),
                Text(
                  rating,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

