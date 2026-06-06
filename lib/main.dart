import 'package:bookplayz/api/api_constants.dart';
import 'package:bookplayz/api/session_manager.dart';
import 'package:bookplayz/screens/auth/otp_screen.dart';
import 'package:bookplayz/screens/auth/signin_screen.dart';
import 'package:bookplayz/screens/auth/signup_screen.dart';
import 'package:bookplayz/screens/map/venue_map_screen.dart';
import 'package:bookplayz/screens/search/search_screen.dart';
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:bookplayz/screens/venues/VenueDetailScreen.dart';
import 'package:bookplayz/screens/wishlist/wishlist_screen.dart';
import 'package:bookplayz/widgets/location_permission_screen.dart';
import 'package:bookplayz/widgets/user_shell_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'theme/app_theme.dart';
import 'package:bookplayz/theme/app_constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Use Hybrid Composition so Flutter widgets (search bar, bottom cards)
  // render on top of the Google Map SurfaceView on Android.
  final mapsImpl = GoogleMapsFlutterPlatform.instance;
  if (mapsImpl is GoogleMapsFlutterAndroid) {
    mapsImpl.useAndroidViewSurface = true;
  }

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await SessionManager.instance.restoreLocation();
  await SessionManager.instance.restoreSession();
  if (SessionManager.instance.isLoggedIn) {
    try { await FavoritesApi.fetchIds(); } catch (_) {}
  }
  runApp(const BookPlayZApp());
}

class BookPlayZApp extends StatelessWidget {
  const BookPlayZApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BookPlayZ',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      initialRoute: AppRoutes.splash,

      // ── Named routes (normal navigation) ──
      routes: {
        AppRoutes.splash:            (_) => const SplashScreen(),
        AppRoutes.onboarding:        (_) => const OnboardingScreen(),
        AppRoutes.shell:             (_) => const UserShellScreen(),
        AppRoutes.signin:            (_) => const SignInScreen(),
        AppRoutes.signup:            (_) => const SignUpScreen(),
        AppRoutes.otp:               (_) => const OTPScreen(),
        AppRoutes.home:              (_) => const UserShellScreen(),
        AppRoutes.locationPermission:(_) => const LocationPermissionScreen(),
        AppRoutes.search:            (_) => const SearchScreen(),
        AppRoutes.wishlist:          (_) => const WishlistScreen(),
        AppRoutes.venueMap:          (_) => const VenueMapScreen(),
        AppRoutes.venueDetail: (context) {
          final slug = ModalRoute.of(context)!.settings.arguments as String;
          return VenueDetailScreen(slug: slug);
        },
      },

      // ── Deep link handler ──
      // Handles:
      //   https://bookplayz.com/venues/{slug}   ← shared link / web
      //   bookplayz://venues/{slug}              ← custom scheme
      onGenerateRoute: (settings) {
        final name = settings.name ?? '';
        final uri = Uri.tryParse(name);

        if (uri != null) {
          final segments = uri.pathSegments;

          // /venues/{slug}  OR  bookplayz://venues/{slug}
          if (segments.length >= 2 && segments[0] == 'venues') {
            final slug = segments[1];
            if (slug.isNotEmpty) {
              return MaterialPageRoute(
                builder: (_) => VenueDetailScreen(slug: slug),
                settings: settings,
              );
            }
          }

          // bookplayz://venues with host as slug
          // e.g. bookplayz://greenfield-sports-testt
          if (uri.scheme == 'bookplayz' && uri.host.isNotEmpty) {
            return MaterialPageRoute(
              builder: (_) => VenueDetailScreen(slug: uri.host),
              settings: settings,
            );
          }
        }

        // Fallback — let named routes handle it
        return null;
      },
    );
  }
}