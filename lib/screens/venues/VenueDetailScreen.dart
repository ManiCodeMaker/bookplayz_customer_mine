import 'package:bookplayz/api/api_constants.dart';
import 'package:bookplayz/models/venue_detail_model.dart';
import 'package:bookplayz/models/venue_model.dart';
import 'package:bookplayz/screens/venues/booking_screen.dart';
import 'package:bookplayz/theme/app_theme.dart';
import 'package:bookplayz/widgets/venue_filters.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

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

  @override
  void initState() {
    super.initState();
    // Match home screen — transparent status bar, light icons
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    _fetch();
  }

  @override
  void dispose() {
    _imageController.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    try {
      final v = await VenueDetailApi.bySlug(widget.slug);
      if (mounted) setState(() { _venue = v; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, // body goes behind status bar
      backgroundColor: AppColors.navyBlue,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.limeGreen))
          : _error != null
              ? _ErrorView(error: _error!, onRetry: () {
                  setState(() { _loading = true; _error = null; });
                  _fetch();
                })
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
        CustomScrollView(
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
                        ? Container(
                            color: AppColors.navyBlue,
                            child: const Center(
                              child: Icon(Icons.stadium_rounded,
                                  color: Colors.white54, size: 64),
                            ),
                          )
                        : PageView.builder(
                            controller: _imageController,
                            onPageChanged: (i) =>
                                setState(() => _currentImage = i),
                            itemCount: imgList.length,
                            itemBuilder: (_, i) => Image.network(
                              imgList[i].imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  Container(color: AppColors.navyBlue),
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
                            final active = i == _currentImage;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 3),
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
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    _buildHeader(v),
                    const SizedBox(height: 16),
                    _buildCategories(v.categories),
                    const SizedBox(height: 20),
                    _buildAmenities(v.amenities),
                    const SizedBox(height: 20),
                    _buildAbout(v),
                    const SizedBox(height: 20),
                    _buildTimings(v),
                    const SizedBox(height: 20),
                    _buildLocation(v),
                    const SizedBox(height: 20),
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
              child: const Icon(Icons.arrow_back_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
        ),

        // ── Share button — always fixed ──
        Positioned(
          top: topPad + 8,
          right: 16,
          child: GestureDetector(
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
              child: const Icon(Icons.share_rounded,
                  color: Colors.white, size: 18),
            ),
          ),
        ),

        // ── Fixed Book Now button ──
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _buildBookNow(v),
        ),
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
                    const Icon(Icons.location_on_rounded,
                        color: AppColors.limeGreen, size: 14),
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
          height: 72,
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
    if (v.description == null || v.description!.isEmpty) return const SizedBox.shrink();
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
          const Text('About Venue',
              style: TextStyle(
                fontFamily: 'Jost',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              )),
          const SizedBox(height: 8),
          Text(displayText,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                height: 1.6,
                color: Colors.white.withValues(alpha: 0.65),
              )),
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
              child: const Icon(Icons.access_time_rounded,
                  color: AppColors.limeGreen, size: 20),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Timings',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.5),
                    )),
                const SizedBox(height: 2),
                Text(v.timingLabel,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    )),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Location',
                  style: TextStyle(
                    fontFamily: 'Jost',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  )),
              GestureDetector(
                onTap: () {},
                child: const Text('Open Map',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.limeGreen,
                    )),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              height: 160,
              color: Colors.white.withValues(alpha: 0.06),
              child: v.latitude != null && v.longitude != null
                  ? Image.network(
                      'https://maps.googleapis.com/maps/api/staticmap'
                      '?center=${v.latitude},${v.longitude}'
                      '&zoom=15&size=600x300&markers=color:green%7C${v.latitude},${v.longitude}'
                      '&key=YOUR_KEY',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _MapFallback(venue: v),
                    )
                  : _MapFallback(venue: v),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.location_on_rounded,
                  color: AppColors.limeGreen, size: 16),
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
                  if (v.latitude != null && v.longitude != null) {
                    Clipboard.setData(ClipboardData(
                        text: '${v.latitude}, ${v.longitude}'));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Coordinates copied')),
                    );
                  }
                },
                child: const Text('Copy',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.limeGreen,
                    )),
              ),
            ],
          ),
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
          const Text('Venue Rules',
              style: TextStyle(
                fontFamily: 'Jost',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              )),
          const SizedBox(height: 10),
          ...rules.map((rule) => Padding(
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
                      child: Text(rule,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            height: 1.5,
                            color: Colors.white.withValues(alpha: 0.7),
                          )),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  // ── Book Now ──
  Widget _buildBookNow(VenueDetailModel v) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: Colors.white,
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
                  // Pop all booking screens back to shell
                  Navigator.of(context).popUntil((route) => route.isFirst);
                  // Shell will handle tab switch via deep link or callback
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
              Text('Book Now',
                  style: TextStyle(
                    fontFamily: 'Jost',
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  )),
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
      case 'parking':           return Icons.local_parking_rounded;
      case 'changing-room':     return Icons.checkroom_rounded;
      case 'drinking-water':    return Icons.water_drop_rounded;
      case 'flood-lights':      return Icons.light_mode_rounded;
      case 'first-aid':         return Icons.medical_services_rounded;
      case 'shower':            return Icons.shower_rounded;
      case 'restrooms':         return Icons.wc_rounded;
      case 'seating-area':      return Icons.chair_rounded;
      case 'cctv-surveillance': return Icons.videocam_rounded;
      case 'artificial-turf':   return Icons.grass_rounded;
      case 'outdoor-ground':    return Icons.stadium_rounded;
      default:                  return Icons.check_circle_outline_rounded;
    }
  }
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
            Icon(Icons.map_rounded,
                color: AppColors.navyBlue.withValues(alpha: 0.3), size: 40),
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
          const Icon(Icons.error_outline_rounded, color: Colors.white54, size: 48),
          const SizedBox(height: 12),
          const Text('Failed to load venue',
              style: TextStyle(
                  fontFamily: 'Jost',
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.limeGreen,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('Retry',
                  style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}