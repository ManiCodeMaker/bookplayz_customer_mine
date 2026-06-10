import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// The persistent top row inside every HeroBanner variant.
/// Renders: menu icon · location block · notification bell.
class HeroBannerTopBar extends StatelessWidget {
  /// City / area name shown in bold lime-green.
  final String city;

  /// Subtitle address line (truncated to one line).
  final String address;

  final VoidCallback? onMenuTap;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onLocationTap;
  final bool showNotificationBadge;

  const HeroBannerTopBar({
    super.key,
    this.city = 'Coimbatore, TN',
    this.address = 'Ramakrishna Nagar, Palanigoundan pudur...',
    this.onMenuTap,
    this.onNotificationTap,
    this.onLocationTap,
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
            // ── Menu button ──
            _CircleIconBtn(
              icon: Icons.menu_rounded,
              onTap: onMenuTap,
            ),
            const SizedBox(width: 10),

            // ── Location block ──
            Expanded(
              child: GestureDetector(
                onTap: onLocationTap,
                behavior: HitTestBehavior.opaque,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          color: AppColors.limeGreen,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            city,
                            style: const TextStyle(
                              fontFamily: 'Jost',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.limeGreen,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: AppColors.limeGreen,
                          size: 16,
                        ),
                      ],
                    ),
                    Text(
                      address,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: AppColors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),

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

/// Shared circular icon button (menu / notification).
class _CircleIconBtn extends StatelessWidget {
  final IconData icon;
  final bool hasBadge;
  final VoidCallback? onTap;

  const _CircleIconBtn({
    required this.icon,
    this.hasBadge = false,
    this.onTap,
  });

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
            child: Icon(icon, color: AppColors.white, size: 18),
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