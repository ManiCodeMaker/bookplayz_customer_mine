import 'dart:async';
import 'package:bookplayz/api/api_constants.dart';
import 'package:bookplayz/api/session_manager.dart';
import 'package:bookplayz/models/public_event_model.dart';
import 'package:bookplayz/models/venue_detail_model.dart';
import 'package:bookplayz/models/venue_model.dart';
import 'package:bookplayz/models/venue_review_model.dart';
import 'package:bookplayz/screens/venues/booking_screen.dart';
import 'package:bookplayz/screens/venues/venue_reviews_screen.dart';
import 'package:bookplayz/theme/app_constants.dart';
import 'package:bookplayz/theme/app_theme.dart';
import 'package:bookplayz/widgets/app_loader.dart';
import 'package:bookplayz/widgets/bulk_corporate_sheet.dart';
import 'package:bookplayz/widgets/user_shell_screen.dart';
import 'package:bookplayz/widgets/venue_filters.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class VenueDetailScreen extends StatefulWidget {
  final String slug;
  const VenueDetailScreen({super.key, required this.slug});

  @override
  State<VenueDetailScreen> createState() => _VenueDetailScreenState();
}

class _VenueDetailScreenState extends State<VenueDetailScreen> {
  VenueDetailModel? _venue;
  bool _loading = true;
  String? _error;

  final PageController _imageController = PageController();
  int _currentImage = 0;
  int _activeCategory = -1;
  bool _aboutExpanded = false;
  Timer? _imageAutoSlideTimer;

  List<VenueReview> _reviews = [];
  bool _reviewsLoading = false;
  String? _reviewsError;

  List<PublicEventModel> _events = [];

  // Fades in the fixed top-bar backdrop as the hero image scrolls away, so
  // the back/share/bulk buttons get a solid, shadowed bar behind them once
  // the content card is what's actually behind them (0 = over the image,
  // fully transparent; 1 = fully opaque with a shadow).
  double _topBarProgress = 0.0;

  @override
  void initState() {
    super.initState();
    // Match home screen — transparent status bar, light icons
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
    _fetch();
    _imageAutoSlideTimer = Timer.periodic(
      const Duration(seconds: 4),
      (_) => _advanceImage(),
    );
  }

  @override
  void dispose() {
    _imageAutoSlideTimer?.cancel();
    _imageController.dispose();
    super.dispose();
  }

  void _advanceImage() {
    final images = _venue?.images ?? const [];
    if (images.length <= 1) return;
    if (!_imageController.hasClients) return;
    // Always move forward (never back to page 0) — the PageView is
    // unbounded and indexes into `images` via `%`, so this loops
    // seamlessly instead of sweeping backward on wraparound.
    _imageController.animateToPage(
      _currentImage + 1,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _fetch() async {
    try {
      final v = await VenueDetailApi.bySlug(widget.slug);
      if (mounted)
        setState(() {
          _venue = v;
          _loading = false;
        });
      _fetchReviews(v.id);
      _fetchEvents(v.id);
    } catch (e) {
      if (mounted)
        setState(() {
          _error = e.toString();
          _loading = false;
        });
    }
  }

  Future<void> _fetchReviews(int venueId) async {
    if (!mounted) return;
    setState(() {
      _reviewsLoading = true;
      _reviewsError = null;
    });
    try {
      final result = await ReviewApi.fetchVenuePublic(venueId, limit: 2);
      if (mounted) {
        setState(() {
          _reviews = result.reviews;
          _reviewsLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _reviewsError = e.toString();
          _reviewsLoading = false;
        });
      }
    }
  }

  Future<void> _fetchEvents(int venueId) async {
    try {
      final events = await EventsApi.byVenue(venueId, limit: 50);
      if (mounted) setState(() => _events = events);
    } catch (_) {
      // Silent — the section simply doesn't render when there's nothing to show.
    }
  }

  Future<void> _toggleFavorite(int venueId) async {
    final current = Set<int>.from(SessionManager.instance.favoriteIds.value);
    if (current.contains(venueId)) {
      current.remove(venueId);
    } else {
      current.add(venueId);
    }
    SessionManager.instance.favoriteIds.value = current;
    try {
      await FavoritesApi.toggle(venueId);
    } catch (_) {
      final revert = Set<int>.from(SessionManager.instance.favoriteIds.value);
      if (revert.contains(venueId)) {
        revert.remove(venueId);
      } else {
        revert.add(venueId);
      }
      SessionManager.instance.favoriteIds.value = revert;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, // body goes behind status bar
      backgroundColor: AppColors.navyBlue,
      body: _loading
          ? const Center(child: AppLoader())
          : _error != null
          ? _ErrorView(
              error: _error!,
              onRetry: () {
                setState(() {
                  _loading = true;
                  _error = null;
                });
                _fetch();
              },
            )
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    final v = _venue!;
    final images = v.images;
    final topPad = MediaQuery.of(context).padding.top;
    final imgList = images.isNotEmpty ? images : <VenueImageModel>[];

    return Stack(
      children: [
        // ── Scrollable ──
        NotificationListener<ScrollNotification>(
          onNotification: (n) {
            if (n.metrics.axis != Axis.vertical) return false;
            // Fully faded in by ~150px of scroll — well before the hero
            // image (topPad + 232 tall) has scrolled out of view.
            final progress = (n.metrics.pixels / 150).clamp(0.0, 1.0);
            if (progress != _topBarProgress) {
              setState(() => _topBarProgress = progress);
            }
            return false;
          },
          child: CustomScrollView(
            slivers: [
            // ── Hero — collapses on scroll ──
            SliverAppBar(
              automaticallyImplyLeading: false,
              expandedHeight: topPad + 232.0,
              pinned: false,
              floating: false,
              backgroundColor: AppColors.navyBlue,
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Image / PageView
                    imgList.isEmpty
                        ? Image.asset(
                            AppImages.dashboardCarousel,
                            fit: BoxFit.cover,
                          )
                        : PageView.builder(
                            controller: _imageController,
                            onPageChanged: (i) =>
                                setState(() => _currentImage = i),
                            // Unbounded (itemCount: null) — auto-slide just keeps
                            // incrementing forever, indexing into imgList via `%`,
                            // so looping never has to jump back to page 0
                            // (which would sweep backward through every image).
                            itemBuilder: (_, i) => Image.network(
                              imgList[i % imgList.length].imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, err, st) => Image.asset(
                                AppImages.dashboardCarousel,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                    // Bottom gradient
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      height: 80,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.5),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Dot indicators
                    if (imgList.length > 1)
                      Positioned(
                        bottom: 20,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(imgList.length, (i) {
                            final active = i == _currentImage % imgList.length;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              width: active ? 20 : 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: active
                                    ? AppColors.limeGreen
                                    : Colors.white.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            );
                          }),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // ── Content card ──
            SliverToBoxAdapter(
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.navyBlue,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    _buildHeader(v),
                    const SizedBox(height: 16),
                    _buildTimings(v),
                    const SizedBox(height: 20),
                    _buildLocation(v),
                    const SizedBox(height: 20),
                    _buildCategories(v.categories),
                    const SizedBox(height: 20),
                    _buildAmenities(v.amenities),
                    const SizedBox(height: 20),
                    _buildAbout(v),
                    const SizedBox(height: 20),
                    _buildReviews(v),
                    const SizedBox(height: 20),
                    if (_events.isNotEmpty) ...[
                      _buildEvents(v),
                      const SizedBox(height: 20),
                    ],
                    if (v.rules.isNotEmpty) ...[
                      _buildRules(v.rules),
                      const SizedBox(height: 20),
                    ],
                    const SizedBox(height: 90),
                  ],
                ),
              ),
            ),
            ],
          ),
        ),

        // ── Fixed top-bar backdrop — keeps back/share/bulk buttons legible
        // once the hero image scrolls away and the content card is right
        // behind them; these buttons live outside the CustomScrollView so
        // they'd otherwise sit with nothing behind them once scrolled.
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: topPad + 60,
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.navyBlue.withValues(alpha: _topBarProgress),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25 * _topBarProgress),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
            ),
          ),
        ),

        // ── Back button — always fixed ──
        Positioned(
          top: topPad + 8,
          left: 16,
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),

        // ── Bulk/Corporate + Share buttons — always fixed ──
        Positioned(
          top: topPad + 8,
          right: 16,
          child: Row(
            children: [
              GestureDetector(
                onTap: () => showBulkCorporateSheet(
                  context,
                  venueId: v.id,
                  venueName: v.name,
                  skipEvents: true,
                ),
                child: Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.limeGreen,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.groups_rounded, color: Colors.white, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Bulk / Corporate',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ValueListenableBuilder<Set<int>>(
                valueListenable: SessionManager.instance.favoriteIds,
                builder: (_, favIds, _) {
                  final isFavorite = favIds.contains(v.id);
                  return GestureDetector(
                    onTap: () => _toggleFavorite(v.id),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isFavorite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: isFavorite ? Colors.red : Colors.white,
                        size: 18,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  SharePlus.instance.share(
                    ShareParams(
                      text:
                          'Book ${v.name} on BookPlayZ!\nhttps://bookplayz.com/venues/${v.slug}',
                      subject: v.name,
                    ),
                  );
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.share_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Fixed Book Now button ──
        Positioned(left: 0, right: 0, bottom: 0, child: _buildBookNow(v)),
      ],
    );
  }

  // ── Header ──
  Widget _buildHeader(VenueDetailModel v) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  v.name,
                  style: const TextStyle(
                    fontFamily: 'Jost',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      color: AppColors.limeGreen,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${v.city}, ${v.state}',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.limeGreen,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star_rounded, color: Colors.white, size: 14),
                const SizedBox(width: 4),
                Text(
                  v.rating.toStringAsFixed(1),
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Sport categories ──
  Widget _buildCategories(List<VenueCategoryModel> categories) {
    if (categories.isEmpty) return const SizedBox.shrink();

    final sports = categories
        .map((c) => {'label': c.name, 'icon': c.image ?? ''})
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Sports',
            style: TextStyle(
              fontFamily: 'Jost',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SportFilterRow(
          sports: sports,
          activeIndex: _activeCategory,
          onChanged: (i) => setState(() => _activeCategory = i),
          // Dark bg — use default dark-bg colors (no overrides needed)
        ),
      ],
    );
  }

  // ── Amenities ──
  Widget _buildAmenities(List<VenueDetailAmenityModel> amenities) {
    if (amenities.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Facilities',
            style: TextStyle(
              fontFamily: 'Jost',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: amenities.length,
            itemBuilder: (_, i) {
              final a = amenities[i];
              return Container(
                margin: const EdgeInsets.only(right: 12),
                width: 64,
                child: Column(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.limeGreen.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _amenityIcon(a.slug),
                        color: AppColors.limeGreen,
                        size: 20,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      a.name,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.65),
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── About Venue ──
  Widget _buildAbout(VenueDetailModel v) {
    if (v.description == null || v.description!.isEmpty)
      return const SizedBox.shrink();
    final desc = v.description!;
    const maxLen = 120;
    final isLong = desc.length > maxLen;
    final displayText = isLong && !_aboutExpanded
        ? '${desc.substring(0, maxLen)}...'
        : desc;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'About Venue',
            style: TextStyle(
              fontFamily: 'Jost',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            displayText,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              height: 1.6,
              color: Colors.white.withValues(alpha: 0.65),
            ),
          ),
          if (isLong)
            GestureDetector(
              onTap: () => setState(() => _aboutExpanded = !_aboutExpanded),
              child: Text(
                _aboutExpanded ? 'Read Less' : 'Read More',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.limeGreen,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Timings ──
  Widget _buildTimings(VenueDetailModel v) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.limeGreen.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.access_time_rounded,
                color: AppColors.limeGreen,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Timings',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  v.timingLabel,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.limeGreen,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${v.slotDuration} min slots',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Location ──
  Widget _buildLocation(VenueDetailModel v) {
    final hasCoords = v.latitude != null && v.longitude != null;
    final venueLatLng = hasCoords ? LatLng(v.latitude!, v.longitude!) : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Location',
                style: TextStyle(
                  fontFamily: 'Jost',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              if (hasCoords)
                GestureDetector(
                  onTap: () async {
                    final url = Uri.parse(
                      'https://www.google.com/maps/search/?api=1'
                      '&query=${v.latitude},${v.longitude}',
                    );
                    if (await canLaunchUrl(url)) launchUrl(url);
                  },
                  child: const Text(
                    'Open Map',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.limeGreen,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              height: 160,
              child: hasCoords
                  ? GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: venueLatLng!,
                        zoom: 15,
                      ),
                      markers: {
                        Marker(
                          markerId: const MarkerId('venue'),
                          position: venueLatLng,
                        ),
                      },
                      liteModeEnabled: true,
                      scrollGesturesEnabled: false,
                      zoomGesturesEnabled: false,
                      tiltGesturesEnabled: false,
                      rotateGesturesEnabled: false,
                      zoomControlsEnabled: false,
                      myLocationEnabled: false,
                      myLocationButtonEnabled: false,
                      mapToolbarEnabled: false,
                    )
                  : _MapFallback(venue: v),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.location_on_rounded,
                color: AppColors.limeGreen,
                size: 16,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${v.address}, ${v.city}, ${v.state}',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.65),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  if (hasCoords) {
                    Clipboard.setData(
                      ClipboardData(text: '${v.latitude}, ${v.longitude}'),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Coordinates copied')),
                    );
                  }
                },
                child: const Text(
                  'Copy',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.limeGreen,
                  ),
                ),
              ),
            ],
          ),
          if (hasCoords) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () async {
                final url = Uri.parse(
                  'https://www.google.com/maps/dir/?api=1'
                  '&destination=${v.latitude},${v.longitude}',
                );
                if (await canLaunchUrl(url)) launchUrl(url);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.limeGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.limeGreen.withValues(alpha: 0.4),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.directions_rounded,
                        color: AppColors.limeGreen, size: 18),
                    SizedBox(width: 6),
                    Text(
                      'Get Directions',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.limeGreen,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Rules ──
  Widget _buildRules(List<String> rules) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Venue Rules',
            style: TextStyle(
              fontFamily: 'Jost',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          ...rules.map(
            (rule) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 5),
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.limeGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      rule,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        height: 1.5,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Reviews preview ──
  Widget _buildReviews(VenueDetailModel v) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Reviews',
                style: TextStyle(
                  fontFamily: 'Jost',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              if (_reviews.length >= 2)
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => VenueReviewsScreen(venue: v),
                    ),
                  ),
                  child: const Text(
                    'See All',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.limeGreen,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (_reviewsLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: AppLoader(),
              ),
            )
          else if (_reviewsError != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Could not load reviews',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.45),
                ),
              ),
            )
          else if (_reviews.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No reviews yet',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.45),
                ),
              ),
            )
          else
            ...List.generate(_reviews.length, (i) {
              final r = _reviews[i];
              return Padding(
                padding: EdgeInsets.only(
                  bottom: i < _reviews.length - 1 ? 14 : 0,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.limeGreen.withValues(
                        alpha: 0.15,
                      ),
                      child: Text(
                        r.userName.isNotEmpty
                            ? r.userName[0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.limeGreen,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  r.userName,
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.star_rounded,
                                      color: Colors.amber,
                                      size: 12,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      r.rating.toStringAsFixed(1),
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            r.content,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              height: 1.5,
                              color: Colors.white.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  // ── Upcoming Events ──
  Widget _buildEvents(VenueDetailModel v) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Upcoming',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              color: AppColors.limeGreen,
            ),
          ),
          const Text(
            'Events',
            style: TextStyle(
              fontFamily: 'Jost',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(_events.length, (i) {
            final evt = _events[i];
            return Padding(
              padding: EdgeInsets.only(bottom: i < _events.length - 1 ? 12 : 0),
              child: _EventCard(
                event: evt,
                onTap: () => showBulkCorporateSheet(
                  context,
                  venueId: v.id,
                  venueName: v.name,
                  initialEvent: evt,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Book Now ──
  Widget _buildBookNow(VenueDetailModel v) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: AppColors.navyBlue,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BookingScreen(
                venue: v,
                onMyBookings: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    UserShellScreen.onNavigateToMyBookings?.call();
                  });
                },
              ),
            ),
          );
        },
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            color: AppColors.limeGreen,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.limeGreen.withValues(alpha: 0.4),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Book Now',
                style: TextStyle(
                  fontFamily: 'Jost',
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 8),
              Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  IconData _amenityIcon(String slug) {
    switch (slug) {
      case 'parking':
        return Icons.local_parking_rounded;
      case 'changing-room':
        return Icons.checkroom_rounded;
      case 'drinking-water':
        return Icons.water_drop_rounded;
      case 'flood-lights':
        return Icons.light_mode_rounded;
      case 'first-aid':
        return Icons.medical_services_rounded;
      case 'shower':
        return Icons.shower_rounded;
      case 'restrooms':
        return Icons.wc_rounded;
      case 'seating-area':
        return Icons.chair_rounded;
      case 'cctv-surveillance':
        return Icons.videocam_rounded;
      case 'artificial-turf':
        return Icons.grass_rounded;
      case 'outdoor-ground':
        return Icons.stadium_rounded;
      default:
        return Icons.check_circle_outline_rounded;
    }
  }
}

// ── Event / package card ──
class _EventCard extends StatelessWidget {
  final PublicEventModel event;
  final VoidCallback onTap;
  const _EventCard({required this.event, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image + category badge ──
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: event.resolvedImage != null
                      ? Image.network(
                          event.resolvedImage!,
                          width: double.infinity,
                          height: 140,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _imgPlaceholder(),
                        )
                      : _imgPlaceholder(),
                ),
                if (event.categoryName != null &&
                    event.categoryName!.isNotEmpty)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.limeGreen,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        event.categoryName!,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // ── Body ──
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.eventTitle,
                    style: const TextStyle(
                      fontFamily: 'Jost',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  if (event.dateRangeLabel.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 13,
                          color: AppColors.limeGreen,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          event.dateRangeLabel,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.65),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (event.eventDescription.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      event.eventDescription,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        height: 1.4,
                        color: Colors.white.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Text(
                        'Enquire Now',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.limeGreen,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 15,
                        color: AppColors.limeGreen,
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
  }

  Widget _imgPlaceholder() => Container(
    width: double.infinity,
    height: 140,
    color: AppColors.navyBlue.withValues(alpha: 0.5),
    child: const Center(
      child: Icon(Icons.event_outlined, color: Colors.white54, size: 36),
    ),
  );
}

// ── Map fallback ──
class _MapFallback extends StatelessWidget {
  final VenueDetailModel venue;
  const _MapFallback({required this.venue});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.navyBlue.withValues(alpha: 0.06),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.map_rounded,
              color: AppColors.navyBlue.withValues(alpha: 0.3),
              size: 40,
            ),
            const SizedBox(height: 8),
            Text(
              venue.latitude != null
                  ? '${venue.latitude?.toStringAsFixed(4)}, ${venue.longitude?.toStringAsFixed(4)}'
                  : venue.address,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppColors.navyBlue.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Error view ──
class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Colors.white54,
            size: 48,
          ),
          const SizedBox(height: 12),
          const Text(
            'Failed to load venue',
            style: TextStyle(
              fontFamily: 'Jost',
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.limeGreen,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Retry',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
