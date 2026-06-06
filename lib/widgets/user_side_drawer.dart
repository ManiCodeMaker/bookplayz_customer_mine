import 'package:bookplayz/api/session_manager.dart';
import 'package:bookplayz/theme/app_constants.dart';
import 'package:bookplayz/theme/app_theme.dart';
import 'package:flutter/material.dart';

class UserSideDrawer extends StatelessWidget {
  final VoidCallback onClose;
  final VoidCallback onHomeTap;
  final VoidCallback onBookingTap;
  final VoidCallback onProfileTap;
  final VoidCallback onLogout;
  final VoidCallback onWishListTap;

  const UserSideDrawer({
    super.key,
    required this.onClose,
    required this.onHomeTap,
    required this.onBookingTap,
    required this.onProfileTap,
    required this.onLogout,
    required this.onWishListTap,
  });

  @override
  Widget build(BuildContext context) {
    final session = SessionManager.instance;
    final user = session.currentUser;

    return Material(
      color: Colors.transparent,
      child: SizedBox(
        height: double.infinity,
        child: Row(
          children: [
            // ── Drawer panel ──────────────────────────────────────────────
            Container(
              width: MediaQuery.of(context).size.width * 0.82,
              height: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFEFF3FB),
              ),
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Profile header ─────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                      child: Row(
                        children: [
                          Container(
                            width: 62,
                            height: 62,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey.shade300,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: ClipOval(
                              child: Icon(
                                Icons.person_rounded,
                                color: AppColors.navyBlue,
                                size: 30,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Replace the name + location display block with:
                                Text(
                                  user?.fullName?.isNotEmpty == true
                                      ? user!.fullName
                                      : 'Hey there 👋',
                                  style: const TextStyle(
                                    fontFamily: 'Jost',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.navyBlue,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  user?.mobile ?? '',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 12,
                                    color: AppColors.navyBlue.withValues(alpha: 0.7),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                                                ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    Divider(
                      color: AppColors.navyBlue.withValues(alpha: 0.1),
                      thickness: 1,
                      indent: 20,
                      endIndent: 20,
                    ),
                    const SizedBox(height: 8),

                    // ── Menu items ──────────────────────────────────────────
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        children: [
                          _DrawerItem(
                            icon: Icons.home_outlined,
                            label: 'Home',
                            onTap: () { onClose(); onHomeTap(); },
                          ),
                          _DrawerItem(
                            icon: Icons.receipt_long_outlined,
                            label: 'My Bookings',
                            onTap: () { onClose(); onBookingTap(); },
                          ),
                          _DrawerItem(
                            icon: Icons.favorite_border_rounded,
                            label: 'Wish List',
                            onTap: () { onClose(); onWishListTap(); },
                          ),
                          _DrawerItem(
                            icon: Icons.emoji_events_outlined,
                            label: 'Upcoming Tournaments',
                            onTap: onClose,
                          ),
                          _DrawerItem(
                            icon: Icons.sports_cricket_outlined,
                            label: 'Upcoming Games',
                            onTap: onClose,
                          ),
                          _DrawerItem(
                            icon: Icons.notifications_outlined,
                            label: 'Notification',
                            onTap: onClose,
                          ),
                     
                          _DrawerItem(
                            icon: Icons.person_outline_rounded,
                            label: 'Profile',
                            onTap: () { onClose(); onProfileTap(); },
                          ),
                          _DrawerItem(
                            icon: Icons.logout_rounded,
                            label: 'Log Out',
                            isDestructive: true,
                            onTap: () { onClose(); onLogout(); },
                          ),
                        ],
                      ),
                    ),

                    // ── Footer ──────────────────────────────────────────────
                    Container(
                      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.navyBlue.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Toll Free Number',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              color: AppColors.navyBlue.withValues(alpha: 0.6),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.headset_mic_outlined,
                                  color: AppColors.limeGreen, size: 18),
                              const SizedBox(width: 6),
                              const Text(
                                '+91 98765 98765',
                                style: TextStyle(
                                  fontFamily: 'Jost',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.navyBlue,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Ask the Experts',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              color: AppColors.navyBlue.withValues(alpha: 0.5),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Connect With US',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              color: AppColors.navyBlue.withValues(alpha: 0.6),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              _SocialBtn(icon: Icons.facebook_rounded, color: const Color(0xFF1877F2)),
                              const SizedBox(width: 12),
                              _SocialBtn(icon: Icons.camera_alt_outlined, color: const Color(0xFFE1306C)),
                              const SizedBox(width: 12),
                              _SocialBtn(icon: Icons.close_rounded, color: Colors.black),
                              const SizedBox(width: 12),
                              _SocialBtn(icon: Icons.play_arrow_rounded, color: const Color(0xFFFF0000)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Tap outside to close ───────────────────────────────────────
            Expanded(
              child: GestureDetector(
                onTap: onClose,
                child: Container(color: Colors.transparent),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? const Color(0xFFE53935) : AppColors.navyBlue;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SocialBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _SocialBtn({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }
}