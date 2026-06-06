import 'package:bookplayz/api/session_manager.dart';
import 'package:bookplayz/theme/app_constants.dart';
import 'package:bookplayz/theme/app_theme.dart';
import 'package:flutter/material.dart';

class LocationPermissionScreen extends StatefulWidget {
  const LocationPermissionScreen({super.key});

  @override
  State<LocationPermissionScreen> createState() =>
      _LocationPermissionScreenState();
}

class _LocationPermissionScreenState extends State<LocationPermissionScreen> {
  bool _loading = false;

  Future<void> _useLocation() async {
    setState(() => _loading = true);
    await SessionManager.instance.fetchAndStoreLocation();
    setState(() => _loading = false);
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final user = SessionManager.instance.currentUser;
    final name = user?.fullName.isNotEmpty == true
        ? user!.fullName
        : 'User';

    return Scaffold(
      backgroundColor: AppColors.navyBlue,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // ── Title ──
              Text(
                'Pick',
                style: TextStyle(
                  fontFamily: 'AtlanticBentley',
                  fontSize: 22,
                  color: AppColors.limeGreen,
                  height: 1.0,
                ),
              ),
              Text(
                'Your Favourites',
                style: TextStyle(
                  fontFamily: 'Anton',
                  fontSize: 30,
                  color: AppColors.white,
                  height: 1.1,
                ),
              ),

              const Spacer(flex: 2),

              // ── Pin icon ──
              // Icon(
              //   Icons.location_pin,
              //   size: 140,
              //   color: AppColors.limeGreen,
              // ),
              Image.asset(
                AppImages.locationPinIcon,
                width: 140,
                height: 160,
                fit: BoxFit.contain,
              ),

              const Spacer(flex: 2),

              // ── Greeting ──
              Text(
                'Hii $name',
                style: TextStyle(
                  fontFamily: 'AtlanticBentley',
                  fontSize: 18,
                  color: AppColors.limeGreen,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your Location Allow With Us',
                style: TextStyle(
                  fontFamily: 'Jost',
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: AppColors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Set Your Location To Start Find Trainer\naround you',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: AppColors.white.withValues(alpha: 1),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              const Spacer(flex: 2),

              // ── Button ──
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _loading ? null : _useLocation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.limeGreen,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _loading ? 'Getting location...' : 'Use Your Location',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 10),
                      _loading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.navyBlue,
                              ),
                            )
                          : const Icon(Icons.near_me_rounded, size: 20),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),
              Text(
                'We Only access Your Location while you are\nusing this location app',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  color: AppColors.white.withValues(alpha: 0.45),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}