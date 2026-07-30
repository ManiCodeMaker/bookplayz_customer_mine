import 'dart:async';

import 'package:bookplayz/widgets/hero_banner_topbar.dart';
import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../api/api_constants.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_constants.dart';


/// ─────────────────────────────────────────────────────────────
/// HeroBanner — the full-width hero component for BookPlayZ User.
///
/// Variants:
///   • Home tab  → showCarousel: true, controller: _pageController
///                 optionally onSearchTap for the compact search icon
///                 Slides are fetched from the backend
///                 (pageType "user-app-home-screen") and auto-scroll in
///                 an infinite loop; falls back to a static asset if the
///                 fetch fails or returns nothing.
///   • All other → backgroundImage: AppImages.someAsset (each
///                 screen passes its own sport-themed image)
///
/// Sub-components (always composed inside this widget):
///   • HeroBannerTopBar — menu(avatar) / search / location / notification row
/// ─────────────────────────────────────────────────────────────
class HeroBanner extends StatefulWidget {
  // ── Background ──
  /// Show the auto-scrolling carousel (home tab only).
  final bool showCarousel;

  /// Required when [showCarousel] is true.
  final PageController? controller;

  /// Number of carousel slides shown while the backend images are still
  /// loading / as a fallback (defaults to 3).
  final int carouselCount;

  /// Static background image asset path used on all non-home screens, and
  /// as the home carousel's fallback while loading / on fetch failure.
  /// Ignored when [showCarousel] is true and backend images are loaded.
  final String? backgroundImage;

  // ── Top-bar passthrough ──
  final String city;
  final VoidCallback? onMenuTap;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onLocationTap;
  final VoidCallback? onResetTap;
  final bool showNotificationBadge;

  // ── Search ──
  /// If set, a compact search icon button is shown in the top-bar row
  /// (next to the menu/avatar) and calls this on tap.
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
    this.onMenuTap,
    this.onNotificationTap,
    this.onLocationTap,
    this.onResetTap,
    this.showNotificationBadge = false,
    // search
    this.onSearchTap,
    // promo
    this.promoOverlay,
    // scroll animation
    this.scrollProgress = 0.0,
  });

  @override
  State<HeroBanner> createState() => _HeroBannerState();
}

class _HeroBannerState extends State<HeroBanner> {
  // pageType slug (superadmin "User App Home Screen") that backs the home
  // carousel's images.
  static const String _homePageType = 'user-app-home-screen';
  static const Duration _autoScrollInterval = Duration(seconds: 4);
  // Large multiplier trick for an effectively-infinite loop: real slides
  // are addressed via `index % _images.length`.
  static const int _loopMultiplier = 1000;

  /// null = not loaded yet (or fetch failed) → fall back to the static
  /// asset carousel. Non-null → backend-driven slides.
  List<String>? _images;
  int _currentIndex = 0;
  Timer? _autoScrollTimer;

  @override
  void initState() {
    super.initState();
    if (widget.showCarousel) _loadImages();
  }

  @override
  void didUpdateWidget(covariant HeroBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showCarousel && !oldWidget.showCarousel) _loadImages();
    if (!widget.showCarousel) _autoScrollTimer?.cancel();
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadImages() async {
    try {
      final images = await PageImagesApi.byPageType(_homePageType);
      if (!mounted || images.isEmpty) return;
      setState(() => _images = images.map((e) => e.imageUrl).toList());
      _jumpToMiddle();
      _startAutoScroll();
    } catch (e) {
      debugPrint('Home hero banner images fetch failed, using local asset: $e');
    }
  }

  // Jumps the shared PageController to the middle of the looped range so
  // the user can swipe backwards immediately without hitting an edge.
  void _jumpToMiddle() {
    final controller = widget.controller;
    final images = _images;
    if (controller == null || images == null || images.length <= 1) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !controller.hasClients) return;
      final middle = images.length * (_loopMultiplier ~/ 2);
      controller.jumpToPage(middle);
      setState(() => _currentIndex = middle % images.length);
    });
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    final controller = widget.controller;
    final images = _images;
    if (controller == null || images == null || images.length <= 1) return;
    _autoScrollTimer = Timer.periodic(_autoScrollInterval, (_) {
      if (!controller.hasClients) return;
      controller.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  // ── Height calculation ──────────────────────────────────────
  // minH is dynamic: status-bar safe area + TopBar's own padding (20) + icon row (40).
  double _computeHeight(BuildContext context) {
    if (widget.showCarousel) {
      double maxH = 300;
      if (widget.promoOverlay != null) maxH += 80;
      final double minH = MediaQuery.of(context).padding.top + 90;
      return maxH + (minH - maxH) * widget.scrollProgress;
    }
    // Static header: compact — minimum 130 so the banner has visible presence.
    return 130;
  }

  // Elements that should fade as the banner collapses (dots).
  double get _fadeOpacity => (1.0 - widget.scrollProgress * 2.0).clamp(0.0, 1.0);

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

          // ── 3. Top-bar (menu/avatar, search, location, notification) ──
          HeroBannerTopBar(
            city: widget.city,
            onMenuTap: widget.onMenuTap,
            onNotificationTap: widget.onNotificationTap,
            onLocationTap: widget.onLocationTap,
            onResetTap: widget.onResetTap,
            onSearchTap: widget.onSearchTap,
            showNotificationBadge: widget.showNotificationBadge,
          ),

          // ── 4. Promo overlay (carousel only, bottom-centre) ───
          if (widget.showCarousel && widget.promoOverlay != null)
            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: Center(child: widget.promoOverlay!),
            ),

          // ── 5. Dot indicator (carousel only) ─────────────────
          if (widget.showCarousel && widget.controller != null)
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Opacity(
                opacity: _fadeOpacity,
                child: Center(child: _buildDots()),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: widget.showCarousel ? 60 : 40,
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

  Widget _buildDots() {
    final images = _images;
    // Still loading / fell back to the static asset — keep the original
    // fixed-count indicator bound directly to the controller.
    if (images == null) {
      return SmoothPageIndicator(
        controller: widget.controller!,
        count: widget.carouselCount,
        effect: ExpandingDotsEffect(
          activeDotColor: AppColors.limeGreen,
          dotColor: AppColors.white.withValues(alpha: 0.4),
          dotHeight: 8,
          dotWidth: 8,
          expansionFactor: 2.5,
          spacing: 5,
        ),
      );
    }
    // A single backend slide has nothing to loop through — no dots needed.
    if (images.length <= 1) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(images.length, (i) {
        final active = _currentIndex == i;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 2.5),
          width: active ? 20 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active
                ? AppColors.limeGreen
                : AppColors.white.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  Widget _buildBackground() {
    final String assetPath =
        widget.backgroundImage ?? AppImages.dashboardCarousel;
    final images = _images;

    if (widget.showCarousel && widget.controller != null) {
      if (images != null && images.isNotEmpty) {
        final looped = images.length > 1;
        return PageView.builder(
          controller: widget.controller,
          itemCount: looped ? images.length * _loopMultiplier : 1,
          onPageChanged: (i) =>
              setState(() => _currentIndex = i % images.length),
          itemBuilder: (_, i) => Image.network(
            images[i % images.length],
            fit: BoxFit.cover,
            width: double.infinity,
            errorBuilder: (_, _, _) => Image.asset(
              assetPath,
              fit: BoxFit.cover,
              width: double.infinity,
            ),
          ),
        );
      }
      // Loading / no backend data yet — same static placeholder as before.
      return PageView.builder(
        controller: widget.controller,
        itemCount: widget.carouselCount,
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
    if (widget.showCarousel) {
      // Deep navy gradient for the carousel (legible bottom text/dots),
      // plus a dedicated top scrim so the top-bar (avatar/search/location/
      // notification) stays readable over bright carousel images.
      return IgnorePointer(
        child: Stack(
          children: [
            Container(
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
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 120,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.55),
                      Colors.black.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ],
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
