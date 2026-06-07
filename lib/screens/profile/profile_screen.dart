import 'package:bookplayz/api/session_manager.dart';
import 'package:bookplayz/screens/profile/edit_profile_screen.dart';
import 'package:bookplayz/theme/app_theme.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final GlobalKey<NavigatorState>? navigatorKey;

  const ProfileScreen({
    super.key,
    this.onBack,
    this.navigatorKey,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final GlobalKey<NavigatorState> _navigatorKey =
      widget.navigatorKey ?? GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_navigatorKey.currentState?.canPop() ?? false) {
          _navigatorKey.currentState?.pop();
        } else {
          widget.onBack?.call();
        }
      },
      child: Navigator(
        key: _navigatorKey,
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/edit-profile':
              return MaterialPageRoute(
                builder: (_) => EditProfileScreen(
                  onBack: () => _navigatorKey.currentState?.pop(),
                ),
              );

            default:
              return MaterialPageRoute(
                builder: (_) => _ProfileHome(
                  onEditProfileTap: () =>
                      _navigatorKey.currentState?.pushNamed('/edit-profile'),
                ),
              );
          }
        },
      ),
    );
  }
}

// ── Profile home ──────────────────────────────────────────────────────────────
class _ProfileHome extends StatelessWidget {
  final VoidCallback? onEditProfileTap;

  const _ProfileHome({this.onEditProfileTap});

  @override
  Widget build(BuildContext context) {
    final user = SessionManager.instance.currentUser;

    return Container(
      color: AppColors.navyBlue,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // ── Title ──────────────────────────────────────────────────
            const Padding(
              padding: EdgeInsets.fromLTRB(0, 20, 0, 20),
              child: Column(
                children: [
                  Text(
                    'My',
                    style: TextStyle(
                      fontFamily: 'AtlanticBentley',
                      fontSize: 22,
                      color: AppColors.brightLimeGreen,
                      height: 1.0,
                    ),
                  ),
                  Text(
                    'Profile',
                    style: TextStyle(
                      fontFamily: 'Anton',
                      fontSize: 26,
                      color: AppColors.white,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(30, 0, 30, 32),
              child: Column(
                children: [
                  // ── User summary card ────────────────────────────────
                  _UserCard(user: user),
                  const SizedBox(height: 20),

                  // ── Account menu ─────────────────────────────────────
                  _MenuCard(
                    title: 'Account',
                    items: [
                      _MenuItem(
                        icon: Icons.person_outline_rounded,
                        label: 'Edit Profile',
                        subtitle: 'Name, email, profile photo',
                        onTap: onEditProfileTap ?? () {},
                        showDivider: false,
                      ),
                    ],
                  ),

                  // Future menu sections can be added here, e.g.:
                  // const SizedBox(height: 16),
                  // _MenuCard(title: 'Saved', items: [ ... ])
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── User summary card ─────────────────────────────────────────────────────────
class _UserCard extends StatelessWidget {
  final SessionUser? user;
  const _UserCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.limeGreen.withValues(alpha: 0.15),
              border: Border.all(color: AppColors.limeGreen, width: 1.5),
            ),
            child: ClipOval(
              child: user?.profileImage != null && user!.profileImage!.isNotEmpty
                  ? Image.network(
                      user!.profileImage!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, err) => _avatarIcon,
                    )
                  : _avatarIcon,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.fullName.isNotEmpty == true
                      ? user!.fullName
                      : 'Hey there!',
                  style: const TextStyle(
                    fontFamily: 'Jost',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  user?.mobile ?? '',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppColors.white.withValues(alpha: 0.5),
                  ),
                ),
                if (user?.email != null && user!.email!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        user!.email!,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: AppColors.white.withValues(alpha: 0.45),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(width: 6),
                      if (user!.emailVerified)
                        const Icon(Icons.verified_rounded,
                            size: 13, color: AppColors.limeGreen)
                      else
                        Icon(Icons.error_outline_rounded,
                            size: 13,
                            color: Colors.orange.withValues(alpha: 0.8)),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget get _avatarIcon => const Icon(
    Icons.person_rounded,
    color: AppColors.limeGreen,
    size: 30,
  );
}

// ── Menu card ─────────────────────────────────────────────────────────────────
class _MenuCard extends StatelessWidget {
  final String? title;
  final List<_MenuItem> items;

  const _MenuCard({this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4E8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text(
                title!,
                style: TextStyle(
                  fontFamily: 'Jost',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navyBlue,
                ),
              ),
            ),
          ...items,
        ],
      ),
    );
  }
}

// ── Menu item ─────────────────────────────────────────────────────────────────
class _MenuItem extends StatelessWidget {
  final IconData? icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
  final bool showDivider;

  const _MenuItem({
    this.icon,
    required this.label,
    this.subtitle,
    required this.onTap,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, color: AppColors.navyBlue, size: 20),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.navyBlue,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            color: AppColors.navyBlue.withValues(alpha: 0.45),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.navyBlue.withValues(alpha: 0.5),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            color: AppColors.navyBlue.withValues(alpha: 0.08),
            indent: 16,
            endIndent: 16,
          ),
      ],
    );
  }
}
