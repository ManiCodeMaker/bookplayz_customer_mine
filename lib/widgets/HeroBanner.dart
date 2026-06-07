import 'package:bookplayz/widgets/hero_banner_searchbar.dart';
import 'package:bookplayz/widgets/hero_banner_topbar.dart';
import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_constants.dart';


/// ─────────────────────────────────────────────────────────────
/// HeroBanner — the full-width hero component for BookPlayZ User.
///
/// Variants:
///   • Home tab  → showCarousel: true, controller: _pageController
///                 optionally showSearch: true for the search bar
///   • All other → backgroundImage: AppImages.someAsset (each
///                 screen passes its own sport-themed image)
///
/// Sub-components (always composed inside this widget):
///   • HeroBannerTopBar  — menu / location / notification row
///   • HeroBannerSearchBar (optional) — shown when showSearch: true
/// ─────────────────────────────────────────────────────────────
class HeroBanner extends StatelessWidget {
  // ── Background ──
  /// Show the auto-scrolling carousel (home tab only).
  final bool showCarousel;

  /// Required when [showCarousel] is true.
  final PageController? controller;

  /// Number of carousel slides (defaults to 3).
  final int carouselCount;

  /// Static background image asset path used on all non-home screens.
  /// Ignored when [showCarousel] is true.
  final String? backgroundImage;

  // ── Top-bar passthrough ──
  final String city;
  final String address;
  final VoidCallback? onMenuTap;
  final VoidCallback? onNotificationTap;
  final bool showNotificationBadge;

  // ── Search bar ──
  /// Show the search bar below the top-bar row.
  final bool showSearch;
  final String searchHint;
  final TextEditingController? searchController;
  final ValueChanged<String>? onSearchChanged;

  /// If set, the search bar becomes a read-only tap target that calls
  /// this callback instead of showing an inline keyboard.
  final VoidCallback? onSearchTap;

  // ── Promo overlay (home carousel only) ──
  /// Optional widget rendered in the bottom-centre of the carousel,
  /// e.g. the "Up To 70% OFF" promo card in Image 1.
  final Widget? promoOverlay;

  /// Scroll-driven collapse progress: 0.0 = fully expanded, 1.0 = collapsed.
  /// Only meaningful on the home tab where showCarousel is true.
  final double scrollProgress;

  const HeroBanner({
    super.key,
    // background
    this.showCarousel = false,
    this.controller,
    this.carouselCount = 3,
    this.backgroundImage,
    // top-bar
    this.city = 'Coimbatore, TN',
    this.address = 'Ramakrishna Nagar, Palanigoundan pudur...',
    this.onMenuTap,
    this.onNotificationTap,
    this.showNotificationBadge = false,
    // search
    this.showSearch = false,
    this.searchHint = 'Search...',
    this.searchController,
    this.onSearchChanged,
    this.onSearchTap,
    // promo
    this.promoOverlay,
    // scroll animation
    this.scrollProgress = 0.0,
  });

  // ── Height calculation ──────────────────────────────────────
  // minH is dynamic: status-bar safe area + TopBar's own padding (20) + icon row (40).
  double _computeHeight(BuildContext context) {
    if (showCarousel) {
      double maxH = 220;
      if (showSearch) maxH += 54;
      if (promoOverlay != null) maxH += 80;
      final double minH = MediaQuery.of(context).padding.top + 90;
      return maxH + (minH - maxH) * scrollProgress;
    }
    // Static header: compact — minimum 130 so the banner has visible presence.
    return showSearch ? 160 : 130;
  }

  // Elements that should fade as the banner collapses (search bar + dots).
  double get _fadeOpacity => (1.0 - scrollProgress * 2.0).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _computeHeight(context),
      child: Stack(
        children: [
          // ── 1. Background ────────────────────────────────────
          _buildBackground(),

          // ── 2. Gradient / brush-stroke overlay ───────────────
          _buildOverlay(),

          // ── 3. Top-bar + optional search ─────────────────────
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              HeroBannerTopBar(
                city: city,
                address: address,
                onMenuTap: onMenuTap,
                onNotificationTap: onNotificationTap,
                showNotificationBadge: showNotificationBadge,
              ),
              if (showSearch)
                SizedBox(
                  // Shrink allocated height as it fades so the Column never overflows.
                  height: (62.0 * _fadeOpacity).clamp(0.0, 62.0),
                  child: ClipRect(
                    child: Opacity(
                      opacity: _fadeOpacity,
                      child: HeroBannerSearchBar(
                        hint: searchHint,
                        controller: searchController,
                        onChanged: onSearchChanged,
                        onTap: onSearchTap,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          // ── 4. Promo overlay (carousel only, bottom-centre) ───
          if (showCarousel && promoOverlay != null)
            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: Center(child: promoOverlay!),
            ),

          // ── 5. Dot indicator (carousel only) ─────────────────
          if (showCarousel && controller != null)
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Opacity(
                opacity: _fadeOpacity,
                child: Center(
                  child: SmoothPageIndicator(
                    controller: controller!,
                    count: carouselCount,
                    effect: ExpandingDotsEffect(
                      activeDotColor: AppColors.limeGreen,
                      dotColor: AppColors.white.withValues(alpha: 0.4),
                      dotHeight: 8,
                      dotWidth: 8,
                      expansionFactor: 2.5,
                      spacing: 5,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: showCarousel ? 60 : 40,
              child: Image.asset(
                AppImages.brushStrokePanel,
                fit: BoxFit.fill,
                alignment: Alignment.topCenter,
              ),
            ),
        ],
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────

  Widget _buildBackground() {
    final String assetPath =
        backgroundImage ?? AppImages.dashboardCarousel;

    if (showCarousel && controller != null) {
      return PageView.builder(
        controller: controller!,
        itemCount: carouselCount,
        itemBuilder: (_, i) => Image.asset(
          assetPath,
          fit: BoxFit.cover,
          width: double.infinity,
        ),
      );
    }

    return Image.asset(
      assetPath,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      alignment: Alignment.topCenter,
    );
  }

  Widget _buildOverlay() {
    if (showCarousel) {
      // Deep navy gradient for the carousel (legible top-bar + space for promo).
      return IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.15),
                AppColors.navyBlue.withValues(alpha: 0.85),
              ],
              stops: const [0.3, 1.0],
            ),
          ),
        ),
      );
    }

    // Compact pages: dark gradient at top for readability, brush stroke at bottom.
    return Stack(
      children: [
        // Top dark scrim so the top-bar text is always legible.
        IgnorePointer(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.45),
                  Colors.black.withValues(alpha: 0.0),
                ],
                stops: const [0.0, 0.6],
              ),
            ),
          ),
        ),
        // Brush-stroke panel at the bottom edge.
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 40,
          child: Image.asset(
            AppImages.brushStrokePanel,
            fit: BoxFit.fill,
            alignment: Alignment.topCenter,
          ),
        ),
      ],
    );
  }
}