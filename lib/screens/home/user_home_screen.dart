import 'package:bookplayz/api/api_service.dart';
import 'package:bookplayz/api/session_manager.dart';
import 'package:bookplayz/api/api_constants.dart';
import 'package:bookplayz/models/promo_banner_model.dart';
import 'package:bookplayz/models/venue_model.dart';
import 'package:bookplayz/widgets/invite_friend_banner.dart';
import 'package:bookplayz/widgets/review_carousel.dart';
import 'package:bookplayz/widgets/venue_cards.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_constants.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../widgets/venue_filters.dart';

class UserHomeScreen extends StatefulWidget {
  final VoidCallback? onSeeAll;
  const UserHomeScreen({super.key, this.onSeeAll});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  int _activeSport = 0;
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, String>> _sports = [
    {'label': 'FOOTBALL', 'icon': AppImages.sportFootball},
    {'label': 'CRICKET', 'icon': AppImages.sportCricket},
    {'label': 'TENNIS', 'icon': AppImages.sportTennis},
    {'label': 'SHUTTLE', 'icon': AppImages.sportShuttle},
    {'label': 'SWIMMING', 'icon': AppImages.sportSwimming},
    {'label': 'VOLLEYBALL', 'icon': AppImages.sportVolleyball},
    {'label': 'BASKETBALL', 'icon': AppImages.sportBasketball},
    {'label': 'TABLE TENNIS', 'icon': AppImages.sportTableTennis},
  ];

  List<VenueModel> _venues = [];
  bool _venuesLoading = true;
  String? _venuesError;



  
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


  // ── Bulk booking / promo banners ──
  static const List<PromoBanner> _promoBanners = [
    PromoBanner(localImage: AppImages.offerBooking1),
    PromoBanner(localImage: AppImages.offerBooking2),
    PromoBanner(localImage: AppImages.offerBooking3),
  ];

  // ── Team games ──
  final List<Map<String, dynamic>> _teamGames = [
    {
      'distance': '4.6 Kms',
      'team1': 'Grand slam champ',
      'vs': 'vs',
      'team2': 'Voriors Basky',
      'image': AppImages.venueHero,
    },
    {
      'distance': '2.1 Kms',
      'team1': 'Tigers FC',
      'vs': 'vs',
      'team2': 'Blue Hawks',
      'image': AppImages.venueHero,
    },
  ];

  // ── Reviews ──
  final List<Map<String, dynamic>> _reviews = [
    {
      'image': AppImages.venueHero,
      'rating': '41.6k',
      'comment': 'We have enjoyed the play. Ground is WOW...',
      'reviewer': 'Dianne',
      'time': '5m',
    },
    {
      'image': AppImages.venueHero,
      'rating': '41.6k',
      'comment': 'Well maintained and good.',
      'reviewer': 'Dianne',
      'time': '5m',
    },
    {
      'image': AppImages.venueHero,
      'rating': '41.6k',
      'comment': 'We will come again. Nice place to play here.',
      'reviewer': 'Dianne',
      'time': '5m',
    },
  ];

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    _loadVenues();
  
  }
  Future<void> _loadVenues() async {
    final lat = SessionManager.instance.latitude;
    final lng = SessionManager.instance.longitude;

    if (lat == null || lng == null) {
      setState(() {
        _venuesLoading = false;
        _venuesError = 'Location unavailable';
      });
      return;
    }

    try {
      final result = await VenueApi.search(
        latitude: lat,
        longitude: lng,
        limit: 4, // only 4 on home screen
      );
      setState(() {
        _venues = result.venues;
        _venuesLoading = false;
      });
    } catch (e) {
      setState(() {
        _venuesLoading = false;
        _venuesError = e.toString();
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.navyBlue,
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // ── Stats grid (4 cards) ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: _StatsGrid(),
            ),
          ),

          // ── Popular Venues title ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
              child: Column(
                children: [
                  Text(
                    'Popular Venues',
                    style: TextStyle(
                      fontFamily: 'AtlanticBentley',
                      fontSize: 20,
                      color: AppColors.limeGreen,
                      height: 1.0,
                    ),
                  ),
                  Text(
                    'Around You',
                    style: TextStyle(
                      fontFamily: 'Anton',
                      fontSize: 24,
                      color: AppColors.white,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Sport filter icons ──
          SliverToBoxAdapter(
            child: SportFilterRow(
              sports: _sports,
              activeIndex: _activeSport,
              onChanged: (i) => setState(() => _activeSport = i),
            ),
          ),

          // ── Map banner ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 28, 16, 0),
              child: _MapBanner(),
            ),
          ),

          // // ── Filter chips ──
          // SliverToBoxAdapter(
          //   child: Padding(
          //     padding: const EdgeInsets.fromLTRB(0, 16, 0, 0),
          //     child: VenueFilterChipsRow(
          //       chips: const [
          //         VenueFilterChipData(
          //             label: 'Price', icon: Icons.swap_vert_rounded),
          //         VenueFilterChipData(label: 'Sport', hasDropdown: true),
          //         VenueFilterChipData(label: 'Distance', hasDropdown: true),
          //         VenueFilterChipData(
          //             label: 'Popular', icon: Icons.swap_vert_rounded),
          //       ],
          //     ),
          //   ),
          // ),

          // ── Venues header ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Venues',
                      style: TextStyle(
                        fontFamily: 'Jost', fontSize: 18,
                        fontWeight: FontWeight.w700, color: AppColors.white,
                      )),
                  GestureDetector(
                    onTap: widget.onSeeAll ?? () {},
                    child: Text('See All',
                        style: TextStyle(
                          fontFamily: 'Inter', fontSize: 13,
                          fontWeight: FontWeight.w600, color: AppColors.limeGreen,
                        )),
                  ),
                ],
              ),
            ),
          ),
                    // ── Venue cards list ──
          if (_venuesLoading)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator(color: AppColors.limeGreen)),
              ),
            )
          else if (_venuesError != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(_venuesError!,
                    style: TextStyle(color: AppColors.white.withValues(alpha: 0.5))),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: ValueListenableBuilder<Set<int>>(
                    valueListenable: SessionManager.instance.favoriteIds,
                    builder: (_, favIds, __) => VenueCard(
                      venue: _venues[i],
                      isFavorite: favIds.contains(_venues[i].id),
                      onBookmarkTap: () => _toggleFavorite(_venues[i].id),
                    ),
                  ),
                ),
                childCount: _venues.length,
              ),
            ),

          // ── Bulk booking promo banner ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              child: _PromoBannerCarousel(banners: _promoBanners),
            ),
          ),

          // ── Team Games section ──
          // SliverToBoxAdapter(
          //   child: _SectionHeader(
          //     title: 'Team Games',
          //     onSeeAll: () {},
          //   ),
          // ),
          // SliverToBoxAdapter(
          //   child: SizedBox(
          //     height: 160,
          //     child: ListView.separated(
          //       scrollDirection: Axis.horizontal,
          //       padding: const EdgeInsets.symmetric(horizontal: 16),
          //       itemCount: _teamGames.length,
          //       separatorBuilder: (_, __) => const SizedBox(width: 12),
          //       itemBuilder: (_, i) => _TeamGameCard(game: _teamGames[i]),
          //     ),
          //   ),
          // ),

          // ── Reviews section ──
          SliverToBoxAdapter(
            child: _SectionHeader(
              title: 'Reviews',
              onSeeAll: () {},
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 160,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _reviews.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) => ReviewCard(review: _reviews[i]),
              ),
            ),
          ),

          // ── Invite Friends banner ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
              child: InviteFriendsBanner(
                discount: '₹200',
                onInviteTap: () {
                  // TODO: launch share sheet
                },
              ),
            ),
          ),

          // ── Bottom padding ──
          const SliverToBoxAdapter(
            child: SizedBox(height: 24),
          ),
        ],
      ),
    );
  }
}

// ── Stats Grid (4 cards) ──────────────────────────────────
class _StatsGrid extends StatelessWidget {
  final List<Map<String, dynamic>> _stats = const [
    {
      'title': 'Leave your Stress Come and Joy with your Friends',
      'badge': '15 Course',
      'image': AppImages.homeStats1,
    },
    {
      'title': 'Great place to Book your Venue',
      'badge': '800+ Venues',
      'image': AppImages.homeStats2,
    },
    {
      'title': 'Train with the Best from Us',
      'badge': '258+ Trainers',
      'image': AppImages.homeStats3,
    },
    {
      'title': 'Find your play tribe partners',
      'badge': null,
      'image': AppImages.homeStats4,
    },
  ];

  const _StatsGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _stats.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemBuilder: (_, i) => _StatCard(data: _stats[i]),
    );
  }
}

class _StatCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _StatCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        color: AppColors.veryDarkBlue,
        child: Stack(
          children: [
            // Text — top-left
            Positioned(
              left: 14,
              top: 14,
              right: 50,
              bottom: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    data['title'],
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.softYellowGreen,
                      height: 1.4,
                    ),
                  ),
                  if (data['badge'] != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      data['badge'],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.white,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // 3D illustration — bottom-right, clipped by card
            Positioned(
              right: 0,
              bottom: 0,
              child: Image.asset(
                data['image'],
                width: 100,
                height: 100,
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section Header ────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;

  const _SectionHeader({required this.title, this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Jost',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.white,
            ),
          ),
          GestureDetector(
            onTap: onSeeAll,
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
    );
  }
}

// ── Promo Banner Carousel ─────────────────────────────────
class _PromoBannerCarousel extends StatefulWidget {
  final List<PromoBanner> banners;
  const _PromoBannerCarousel({required this.banners});

  @override
  State<_PromoBannerCarousel> createState() => _PromoBannerCarouselState();
}

class _PromoBannerCarouselState extends State<_PromoBannerCarousel> {
  static const int _multiplier = 1000;
  late final PageController _ctrl;
  late int _currentPage;

  @override
  void initState() {
    super.initState();
    final count = widget.banners.length;
    _currentPage = count * (_multiplier ~/ 2);
    _ctrl = PageController(
      viewportFraction: 0.82,
      initialPage: _currentPage,
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  int get _currentIndex => _currentPage % widget.banners.length;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 140,
          child: PageView.builder(
            controller: _ctrl,
            itemCount: widget.banners.length * _multiplier,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (_, i) {
              final b = widget.banners[i % widget.banners.length];
              final isCenter = i == _currentPage;
              return AnimatedScale(
                scale: isCenter ? 1.0 : 0.91,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isCenter ? 0.3 : 0.1),
                          blurRadius: isCenter ? 12 : 4,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.asset(b.localImage, fit: BoxFit.cover),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            widget.banners.length,
            (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: _currentIndex == i ? 18 : 7,
              height: 7,
              decoration: BoxDecoration(
                color: _currentIndex == i
                    ? AppColors.limeGreen
                    : AppColors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Team Game Card ────────────────────────────────────────
// class _TeamGameCard extends StatelessWidget {
//   final Map<String, dynamic> game;
//   const _TeamGameCard({required this.game});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: 260,
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(14),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withValues(alpha: 0.2),
//             blurRadius: 8,
//           ),
//         ],
//       ),
//       child: ClipRRect(
//         borderRadius: BorderRadius.circular(14),
//         child: Stack(
//           fit: StackFit.expand,
//           children: [
//             // Background image
//             Image.asset(game['image'], fit: BoxFit.cover),

//             // Dark overlay
//             Container(
//               color: Colors.black.withValues(alpha: 0.55),
//             ),

//             // Content
//             Padding(
//               padding: const EdgeInsets.all(14),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // Distance badge
//                   Container(
//                     padding: const EdgeInsets.symmetric(
//                         horizontal: 8, vertical: 4),
//                     decoration: BoxDecoration(
//                       color: AppColors.limeGreen.withValues(alpha: 0.2),
//                       borderRadius: BorderRadius.circular(20),
//                     ),
//                     child: Row(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         const Icon(Icons.location_on_rounded,
//                             color: AppColors.limeGreen, size: 11),
//                         const SizedBox(width: 3),
//                         Text(
//                           game['distance'],
//                           style: const TextStyle(
//                             fontFamily: 'Inter',
//                             fontSize: 10,
//                             fontWeight: FontWeight.w600,
//                             color: AppColors.limeGreen,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),

//                   const Spacer(),

//                   // Match info
//                   Text(
//                     game['team1'],
//                     style: const TextStyle(
//                       fontFamily: 'Jost',
//                       fontSize: 14,
//                       fontWeight: FontWeight.w700,
//                       color: AppColors.white,
//                     ),
//                   ),
//                   Text(
//                     game['vs'],
//                     style: TextStyle(
//                       fontFamily: 'Inter',
//                       fontSize: 11,
//                       color: AppColors.white.withValues(alpha: 0.6),
//                     ),
//                   ),
//                   Text(
//                     game['team2'],
//                     style: const TextStyle(
//                       fontFamily: 'Jost',
//                       fontSize: 14,
//                       fontWeight: FontWeight.w700,
//                       color: AppColors.white,
//                     ),
//                   ),

//                   const SizedBox(height: 10),

//                   // Register button
//                   Container(
//                     padding: const EdgeInsets.symmetric(
//                         horizontal: 14, vertical: 7),
//                     decoration: BoxDecoration(
//                       color: AppColors.limeGreen,
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                     child: Text(
//                       'Register Now',
//                       style: TextStyle(
//                         fontFamily: 'Inter',
//                         fontSize: 12,
//                         fontWeight: FontWeight.w700,
//                         color: AppColors.navyBlue,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// ── Map Banner ────────────────────────────────────────────
class _MapBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppRoutes.venueMap),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Green container — fills the Stack (sizes the Stack to 90px)
          Container(
            height: 90,
            decoration: BoxDecoration(
              color: AppColors.limeGreen,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                // Reserve space where the image overlaps the box
                const SizedBox(width: 150),

                // Text
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Find the Venue',
                        style: TextStyle(
                          fontFamily: 'AtlanticBentley',
                          fontSize: 20,
                          color: AppColors.navyBlue,
                          height: 1.0,
                        ),
                      ),
                      Text(
                        'NEAR YOUR',
                        style: TextStyle(
                          fontFamily: 'Anton',
                          fontSize: 22,
                          color: AppColors.navyBlue,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),

                // Arrow
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Container(
                    width: 30,
                    height: 40,
                    // decoration: BoxDecoration(
                    //   color: AppColors.navyBlue.withValues(alpha: 0.15),
                    //   shape: BoxShape.circle,
                    // ),
                    child: const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.white,
                      size: 40,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Map image — negative top makes it overflow above the green box
          Positioned(
            left: 0,
            top: -25,
            child: Image.asset(
              AppImages.mapImage,
              width: 150,
              height: 120,
              fit: BoxFit.fill,
            ),
          ),
        ],
      ),
    );
  }
}