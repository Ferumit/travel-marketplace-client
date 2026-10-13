import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../models/tour_models.dart' as app_models;
import '../repository/firestore_data_repository.dart';
import '../theme/app_colors.dart';
import '../widgets/safe_network_image.dart';
import '../navigation/main_tab_scaffold.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  List<app_models.Route> _allRoutes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRoutes();
    
    // Check if there is an initial search request
    if (MainTabScaffold.searchRequest.value.isNotEmpty) {
      _query = MainTabScaffold.searchRequest.value;
      _searchCtrl.text = _query;
      MainTabScaffold.searchRequest.value = ''; // Consume it
    }
    
    MainTabScaffold.searchRequest.addListener(_onSearchRequestChanged);
  }

  void _onSearchRequestChanged() {
    final req = MainTabScaffold.searchRequest.value;
    if (req.isNotEmpty && mounted) {
      setState(() {
        _query = req;
        _searchCtrl.text = req;
      });
      MainTabScaffold.searchRequest.value = ''; // Consume it
    }
  }

  @override
  void dispose() {
    MainTabScaffold.searchRequest.removeListener(_onSearchRequestChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadRoutes() async {
    try {
      final routesStream = FirestoreDataRepository.instance.getSharedRoutes();
      final routes = await routesStream;
      if (mounted) {
        setState(() {
          _allRoutes = routes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<app_models.Route> get _filteredRoutes {
    if (_query.isEmpty) return _allRoutes;
    final lower = _query.toLowerCase();
    return _allRoutes.where((r) => r.title.toLowerCase().contains(lower)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Поиск',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppColors.radiusMd),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  const Icon(LucideIcons.search, color: AppColors.textTertiary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (v) => setState(() => _query = v.trim()),
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
                      decoration: const InputDecoration(
                        hintText: 'Искать маршруты...',
                        hintStyle: TextStyle(color: AppColors.textTertiary, fontSize: 15),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  if (_query.isNotEmpty)
                    IconButton(
                      icon: const Icon(LucideIcons.x, color: AppColors.textSecondary, size: 18),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _query = '');
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 120), // Фикс перекрытия тачбара
              itemCount: _filteredRoutes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, i) {
                final route = _filteredRoutes[i];
                return GestureDetector(
                  onTap: () => context.push('/route-details', extra: route),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppColors.radiusLg),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(AppColors.radiusMd),
                            color: AppColors.surfaceHigh,
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: route.imageUrl.isNotEmpty
                              ? SafeNetworkImage(url: route.imageUrl, fit: BoxFit.cover)
                              : const Center(child: Icon(LucideIcons.image, color: AppColors.textTertiary)),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                route.title,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(LucideIcons.star, color: AppColors.warning, size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    route.rating.toStringAsFixed(1),
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '${route.price} ₸',
                                    style: const TextStyle(
                                      color: AppColors.accent,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
