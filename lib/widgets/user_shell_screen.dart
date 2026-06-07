import 'package:bookplayz/api/session_manager.dart';
import 'package:bookplayz/screens/home/user_home_screen.dart';
import 'package:bookplayz/screens/my-booking/my_booking_screen.dart';
import 'package:bookplayz/screens/profile/profile_screen.dart';
import 'package:bookplayz/screens/venues/venues.dart';
import 'package:bookplayz/theme/app_constants.dart';
import 'package:bookplayz/theme/app_theme.dart';
import 'package:bookplayz/widgets/HeroBanner.dart';
import 'package:bookplayz/widgets/bottom_nav_screen.dart';
import 'package:bookplayz/widgets/user_side_drawer.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class UserShellScreen extends StatefulWidget {
  const UserShellScreen({super.key});

  // Registered by the shell state so any screen can navigate to My Bookings.
  static VoidCallback? onNavigateToMyBookings;

  @override
  State<UserShellScreen> createState() => _UserShellScreenState();
}

class _UserShellScreenState extends State<UserShellScreen>
    with SingleTickerProviderStateMixin {
  int _navIndex = 0;
  final List<int> _history = [0];
  final PageController _heroController = PageController();
  final GlobalKey<NavigatorState> _profileNavigatorKey = GlobalKey<NavigatorState>();
  final GlobalKey<NavigatorState> _bookingNavigatorKey = GlobalKey<NavigatorState>();
  final GlobalKey<MyBookingScreenState> _bookingKey = GlobalKey<MyBookingScreenState>();
  final GlobalKey<VenuesScreenState> _venuesKey = GlobalKey<VenuesScreenState>();

  final ValueNotifier<double> _scrollProgress = ValueNotifier(0.0);
  static const double _collapseThreshold = 100.0;

  bool _drawerOpen = false;
  bool _profileInSubRoute = false;
  late AnimationController _drawerAnim;
  late Animation<Offset> _drawerSlide;
  late Animation<double> _drawerFade;

  void _openDrawer() {
    setState(() => _drawerOpen = true);
    _drawerAnim.forward();
  }

  void _closeDrawer() {
    _drawerAnim.reverse().then((_) {
      if (mounted) setState(() => _drawerOpen = false);
    });
  }

  Future<void> _onLogout() async {
    _closeDrawer();
    await Future.delayed(const Duration(milliseconds: 300));
    await SessionManager.instance.clearSession();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.signin, (r) => false);
    }
  }

  void _openFavoritesInProfile() {
    _closeDrawer();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      // Pop any open profile sub-route back to home first
      _profileNavigatorKey.currentState?.popUntil((r) => r.isFirst);
      // Switch to the profile tab if not already there
      if (_navIndex != 3) {
        setState(() {
          _history.add(3);
          _navIndex = 3;
        });
      }
      // Push the favorites screen and mark nav as in sub-route
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _profileNavigatorKey.currentState?.pushNamed('/favorites');
        setState(() => _profileInSubRoute = true);
      });
    });
  }

  late final List<Widget> _screens;

  void _goBack() {
    if (_history.length > 1) {
      setState(() {
        _history.removeLast();
        _navIndex = _history.last;
      });
    }
  }

  void _onNavTap(int i) {
    if (i == _navIndex) return;
    if (i != 0) _scrollProgress.value = 0.0;
    if (_navIndex == 3 && i != 3) {
      _profileNavigatorKey.currentState?.popUntil((route) => route.isFirst);
      _profileInSubRoute = false;
    }
    if (_navIndex == 2 && i != 2) {
      _bookingNavigatorKey.currentState?.popUntil((route) => route.isFirst);
    }
    if (i == 1) {
      _venuesKey.currentState?.refresh();
    }
    if (i == 2) {
      _bookingKey.currentState?.onTabActivated();
    }
    setState(() {
      _history.add(i);
      _navIndex = i;
    });
  }

  @override
  void initState() {
    super.initState();
    _drawerAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _drawerSlide = Tween<Offset>(
      begin: const Offset(-1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _drawerAnim, curve: Curves.easeOutCubic));
    _drawerFade = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(parent: _drawerAnim, curve: Curves.easeOut),
    );

    UserShellScreen.onNavigateToMyBookings = () => _onNavTap(2);

    _screens = [
      UserHomeScreen(
        onSeeAll: () => _onNavTap(1),
      ),
      VenuesScreen(key: _venuesKey, onBack: _goBack),
      MyBookingScreen(
        key:          _bookingKey,
        navigatorKey: _bookingNavigatorKey,
        onBack:       _goBack,
      ),
      ProfileScreen(
        navigatorKey: _profileNavigatorKey,
        onBack: _goBack,
        onSubRouteChanged: (inSub) => setState(() => _profileInSubRoute = inSub),
      ),
    ];
  }

  @override
  void dispose() {
    _scrollProgress.dispose();
    _heroController.dispose();
    _drawerAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppColors.navyBlue,
          body: Column(
            children: [
              ValueListenableBuilder<double>(
                valueListenable: _scrollProgress,
                builder: (_, progress, _) => HeroBanner(
                  scrollProgress: _navIndex == 0 ? progress : 0.0,
                  showCarousel: _navIndex == 0,
                  controller: _navIndex == 0 ? _heroController : null,
                  showSearch: _navIndex == 0,
                  onSearchTap: () => Navigator.pushNamed(context, AppRoutes.search),
                  showNotificationBadge: false,
                  onMenuTap: _openDrawer,
                ),
              ),
              Expanded(
                child: NotificationListener<ScrollNotification>(
                  onNotification: (n) {
                    if (_navIndex == 0) {
                      _scrollProgress.value =
                          (n.metrics.pixels / _collapseThreshold).clamp(0.0, 1.0);
                    }
                    return false;
                  },
                  child: IndexedStack(
                    index: _navIndex,
                    children: _screens,
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: (_navIndex == 3 && _profileInSubRoute)
              ? null
              : Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 10),
                  child: UserBottomNav(
                    currentIndex: _navIndex,
                    onTap: _onNavTap,
                  ),
                ),
        ),

        // ── Backdrop ────────────────────────────────────────────────────────
        if (_drawerOpen)
          Positioned.fill(
            child: FadeTransition(
              opacity: _drawerFade,
              child: GestureDetector(
                onTap: _closeDrawer,
                child: Container(color: Colors.black),
              ),
            ),
          ),

        // ── Drawer ──────────────────────────────────────────────────────────
        if (_drawerOpen)
          Positioned.fill(
            child: SlideTransition(
              position: _drawerSlide,
              child: UserSideDrawer(
                onClose: _closeDrawer,
                onHomeTap: () => _onNavTap(0),
                onBookingTap: () => _onNavTap(2),
                onProfileTap: () => _onNavTap(3),
                onWishListTap: _openFavoritesInProfile,
                onLogout: _onLogout,
              ),
            ),
          ),
      ],
    );
  }
}