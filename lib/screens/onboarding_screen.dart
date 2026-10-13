import '../theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../services/auth_service.dart';
import '../theme/theme.dart';
import '../l10n/app_localizations.dart';

class OnboardingSlideData {
  final IconData icon;
  final String title;
  final String desc;
  final Color iconColor;

  OnboardingSlideData({
    required this.icon,
    required this.title,
    required this.desc,
    required this.iconColor,
  });
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  List<OnboardingSlideData> _getSlides(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [
      OnboardingSlideData(
        icon: LucideIcons.compass,
        title: l10n.onboardingSlide1Title,
        desc: l10n.onboardingSlide1Desc,
        iconColor: Colors.white,
      ),
      OnboardingSlideData(
        icon: LucideIcons.mountain,
        title: l10n.onboardingSlide2Title,
        desc: l10n.onboardingSlide2Desc,
        iconColor: Colors.white,
      ),
      OnboardingSlideData(
        icon: LucideIcons.truck,
        title: l10n.onboardingSlide3Title,
        desc: l10n.onboardingSlide3Desc,
        iconColor: const Color(0xFF147EFB),
      ),
    ];
  }

  void _handleNext(int slidesLength) {
    if (_currentIndex < slidesLength - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      AuthService.instance.completeOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    final slides = _getSlides(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background, // Dark slate bg for onboarding
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  itemCount: slides.length,
                  itemBuilder: (context, index) {
                    final slide = slides[index];
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 192,
                          height: 192,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.surface, // Lighter slate
                            border: Border.all(
                              color: AppColors.textSecondary.withValues(alpha: 0.1),
                              width: 1,
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              slide.icon,
                              size: 80,
                              color: slide.iconColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          slide.title,
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          slide.desc,
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    );
                  },
                ),
              ),

              // Footer Controls
              Column(
                children: [
                  // Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      slides.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 8,
                        width: _currentIndex == index ? 32 : 8,
                        decoration: BoxDecoration(
                          color: _currentIndex == index
                              ? AppColors.accent
                              : AppColors.border,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () => _handleNext(slides.length),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: context.colorScheme.onPrimary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _currentIndex == slides.length - 1
                                ? l10n.onboardingStart
                                : l10n.onboardingNext,
                            style: const TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (_currentIndex < slides.length - 1) ...[
                            const SizedBox(width: 8),
                            const Icon(LucideIcons.arrowRight, size: 20),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

