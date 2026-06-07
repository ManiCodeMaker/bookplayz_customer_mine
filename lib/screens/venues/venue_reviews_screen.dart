import 'package:bookplayz/api/api_constants.dart';
import 'package:bookplayz/models/venue_detail_model.dart';
import 'package:bookplayz/models/venue_review_model.dart';
import 'package:bookplayz/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class VenueReviewsScreen extends StatefulWidget {
  final VenueDetailModel venue;
  const VenueReviewsScreen({super.key, required this.venue});

  @override
  State<VenueReviewsScreen> createState() => _VenueReviewsScreenState();
}

class _VenueReviewsScreenState extends State<VenueReviewsScreen> {
  final List<VenueReview> _reviews = [];
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  int _page = 1;
  bool _hasMore = false;
  int _displayTotal = 0;

  final ScrollController _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    _scrollCtrl.addListener(_onScroll);
    _fetchPage(1);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      if (!_loadingMore && _hasMore) _fetchMore();
    }
  }

  Future<void> _fetchPage(int page) async {
    try {
      final result = await ReviewApi.fetchVenuePublic(
        widget.venue.id,
        page: page,
        limit: 10,
      );
      if (!mounted) return;
      setState(() {
        if (page == 1) _reviews.clear();
        _reviews.addAll(result.reviews);
        _hasMore = result.meta.hasNext;
        _displayTotal = result.meta.total > 0
            ? result.meta.total
            : _reviews.length;
        _page = page;
        _loading = false;
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
        _loadingMore = false;
      });
    }
  }

  Future<void> _fetchMore() async {
    if (_loadingMore) return;
    setState(() => _loadingMore = true);
    await _fetchPage(_page + 1);
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final v = widget.venue;

    return Scaffold(
      backgroundColor: AppColors.navyBlue,
      body: Stack(
        children: [
          // Hero image
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: topPad + 180,
            child: v.images.isNotEmpty
                ? Image.network(
                    v.primaryImage ?? v.images.first.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, err, st) =>
                        Container(color: AppColors.navyBlue),
                  )
                : Container(color: AppColors.navyBlue),
          ),
          // Gradient over hero
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: topPad + 180,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.35),
                    Colors.black.withValues(alpha: 0.6),
                  ],
                ),
              ),
            ),
          ),

          // White content panel
          Column(
            children: [
              SizedBox(height: topPad + 120),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: _loading
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.navyBlue),
                        )
                      : _error != null
                          ? _buildError()
                          : _buildContent(),
                ),
              ),
            ],
          ),

          // Back button
          Positioned(
            top: topPad + 8,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: AppColors.limeGreen,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_rounded,
                    color: Colors.white, size: 20),
              ),
            ),
          ),

          // Title
          Positioned(
            top: topPad + 14,
            left: 0,
            right: 0,
            child: const Center(
              child: Text(
                'Reviews',
                style: TextStyle(
                  fontFamily: 'Jost',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final v = widget.venue;
    final total = _displayTotal > 0 ? _displayTotal : v.totalRatings;

    return ListView(
      controller: _scrollCtrl,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      children: [
        _buildRatingSummary(v, total),
        const SizedBox(height: 24),
        Text(
          'Reviews ($total)',
          style: const TextStyle(
            fontFamily: 'Jost',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.navyBlue,
          ),
        ),
        const SizedBox(height: 16),
        if (_reviews.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'No reviews yet',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ),
          )
        else ...[
          ..._reviews.map((r) => _buildReviewItem(r)),
          if (_loadingMore)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.navyBlue),
              ),
            )
          else if (!_hasMore)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Center(
                child: Text(
                  'All reviews loaded',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildRatingSummary(VenueDetailModel v, int total) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Overall rating
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              v.rating.toStringAsFixed(1),
              style: const TextStyle(
                fontFamily: 'Jost',
                fontSize: 52,
                fontWeight: FontWeight.w700,
                color: AppColors.navyBlue,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: List.generate(5, (i) {
                final filled = i < v.rating.floor();
                final half = !filled && (v.rating - v.rating.floor()) >= 0.5 && i == v.rating.floor();
                return Icon(
                  half
                      ? Icons.star_half_rounded
                      : filled
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                  color: Colors.amber,
                  size: 18,
                );
              }),
            ),
            const SizedBox(height: 6),
            Text(
              'Based on $total review${total != 1 ? 's' : ''}',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
        const SizedBox(width: 28),
        // Star breakdown bars (visual estimate)
        Expanded(
          child: Column(
            children: List.generate(5, (i) {
              final star = 5 - i;
              final fraction = _barFraction(star, v.rating);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Text(
                      '$star',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: Colors.grey.shade400,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: Stack(
                          children: [
                            Container(
                              height: 6,
                              color: Colors.grey.withValues(alpha: 0.15),
                            ),
                            FractionallySizedBox(
                              widthFactor: fraction,
                              child: Container(
                                height: 6,
                                decoration: BoxDecoration(
                                  color: AppColors.navyBlue,
                                  borderRadius: BorderRadius.circular(3),
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
            }),
          ),
        ),
      ],
    );
  }

  double _barFraction(int star, double avg) {
    final diff = (star - avg).abs();
    return (1.0 - diff * 0.28).clamp(0.05, 1.0);
  }

  Widget _buildReviewItem(VenueReview review) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.navyBlue.withValues(alpha: 0.1),
                child: Text(
                  review.userName.isNotEmpty
                      ? review.userName[0].toUpperCase()
                      : 'U',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navyBlue,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  review.userName,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.navyBlue,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded,
                        color: Colors.amber, size: 13),
                    const SizedBox(width: 3),
                    Text(
                      review.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.navyBlue,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 52),
            child: Text(
              review.content,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                height: 1.5,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          if (review.imageUrls.isNotEmpty) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 52),
              child: SizedBox(
                height: 64,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: review.imageUrls.length,
                  itemBuilder: (_, i) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        review.imageUrls[i],
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                        errorBuilder: (_, err, st) => Container(
                          width: 64,
                          height: 64,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.broken_image_rounded,
                              color: Colors.grey, size: 24),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: Colors.grey, size: 48),
            const SizedBox(height: 12),
            Text(
              _error ?? 'Failed to load reviews',
              style:
                  const TextStyle(fontFamily: 'Inter', color: Colors.grey, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () {
                setState(() {
                  _loading = true;
                  _error = null;
                });
                _fetchPage(1);
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.navyBlue,
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
      ),
    );
  }
}
