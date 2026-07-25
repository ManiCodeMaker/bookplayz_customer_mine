import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/app_constants.dart';
import '../api/session_manager.dart';

/// The persistent top row inside every HeroBanner variant.
/// Renders: menu avatar · greeting/location block · search · notification bell.
class HeroBannerTopBar extends StatelessWidget {
  /// City / area name shown under the greeting (tappable to change).
  final String city;

  final VoidCallback? onMenuTap;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onLocationTap;
  final VoidCallback? onResetTap;
  final VoidCallback? onSearchTap;
  final bool showNotificationBadge;

  const HeroBannerTopBar({
    super.key,
    this.city = 'Coimbatore, TN',
    this.onMenuTap,
    this.onNotificationTap,
    this.onLocationTap,
    this.onResetTap,
    this.onSearchTap,
    this.showNotificationBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Menu button — shows user's profile picture (falls back to a
            // person icon). Reads SessionManager directly, same as the side
            // drawer, since it's a small presentational exception rather
            // than plumbing user state through every HeroBanner caller. ──
            _CircleIconBtn(
              onTap: onMenuTap,
              child: ClipOval(
                child: ValueListenableBuilder<SessionUser?>(
                  valueListenable: SessionManager.instance.userNotifier,
                  builder: (_, user, _) {
                    final img = user?.profileImage ?? '';
                    if (img.isEmpty) {
                      return const Icon(Icons.person_rounded,
                          color: AppColors.white, size: 18);
                    }
                    return Image.network(
                      img,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const Icon(
                          Icons.person_rounded,
                          color: AppColors.white,
                          size: 18),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 10),

            // ── Greeting + location block ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Greeting — not tappable, just a name display.
                  ValueListenableBuilder<SessionUser?>(
                    valueListenable: SessionManager.instance.userNotifier,
                    builder: (_, user, _) {
                      final name = user?.fullName.trim() ?? '';
                      return Text(
                        'Hey ${name.isNotEmpty ? name : 'there'}!',
                        style: const TextStyle(
                          fontFamily: 'Jost',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.limeGreen,
                        ),
                        overflow: TextOverflow.ellipsis,
                      );
                    },
                  ),
                  const SizedBox(height: 2),
                  // Location — tappable to change.
                  GestureDetector(
                    onTap: onLocationTap,
                    behavior: HitTestBehavior.opaque,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          color: AppColors.white.withValues(alpha: 0.7),
                          size: 13,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            city,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              color: AppColors.white.withValues(alpha: 0.85),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: AppColors.white.withValues(alpha: 0.7),
                          size: 15,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // ── Reset-to-GPS button (only shown when a city is selected) ──
            if (onResetTap != null)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: GestureDetector(
                  onTap: onResetTap,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.25),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.limeGreen.withValues(alpha: 0.6),
                      ),
                    ),
                    child: const Icon(
                      Icons.gps_fixed_rounded,
                      color: AppColors.limeGreen,
                      size: 16,
                    ),
                  ),
                ),
              ),

            // ── Compact search button — sits left of notification, navigates
            // to search instead of an inline bar that covers the carousel. ──
            if (onSearchTap != null) ...[
              _CircleIconBtn(
                onTap: onSearchTap,
                child: Image.asset(
                  AppImages.searchIcon,
                  width: 18,
                  height: 18,
                  fit: BoxFit.scaleDown,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(width: 10),
            ],

            // ── Notification button ──
            _CircleIconBtn(
              icon: Icons.notifications_outlined,
              onTap: onNotificationTap,
              hasBadge: showNotificationBadge,
            ),
          ],
        ),
      ),
    );
  }
}

/// Shared circular icon button (menu / notification / search).
/// Pass either [icon] for a plain icon, or [child] for custom content
/// (e.g. the profile-picture avatar).
class _CircleIconBtn extends StatelessWidget {
  final IconData? icon;
  final Widget? child;
  final bool hasBadge;
  final VoidCallback? onTap;

  const _CircleIconBtn({
    this.icon,
    this.child,
    this.hasBadge = false,
    this.onTap,
  }) : assert(icon != null || child != null);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.white.withValues(alpha: 0.25),
              ),
            ),
            child: Center(
              child: child ?? Icon(icon, color: AppColors.white, size: 18),
            ),
          ),
          if (hasBadge)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}