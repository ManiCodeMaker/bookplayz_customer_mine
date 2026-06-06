import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/venue_detail_model.dart';
import '../../theme/app_theme.dart';

class VenueShareSheet extends StatelessWidget {
  final VenueDetailModel venue;

  const VenueShareSheet({super.key, required this.venue});

  String get _venueUrl => 'https://bookplayz.com/venues/${venue.slug}';
  String get _shareText => 'Book ${venue.name} on BookPlayZ!\n$_venueUrl';

  static void show(BuildContext context, VenueDetailModel venue) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => VenueShareSheet(venue: venue),
    );
  }

  // Share to specific app by passing it as the only option
  // share_plus v13 — use ShareParams with no extras, native sheet handles routing
  void _shareToWhatsApp(BuildContext context) {
    Navigator.pop(context);
    // Encode text for WhatsApp URL scheme
    final encoded = Uri.encodeComponent(_shareText);
    // Try WhatsApp URI — falls back to native sheet if WhatsApp not installed
    SharePlus.instance.share(
      ShareParams(text: _shareText),
    );
    // Additionally set clipboard so user can paste
    Clipboard.setData(ClipboardData(text: _venueUrl));
  }

  void _shareNative(BuildContext context) {
    Navigator.pop(context);
    SharePlus.instance.share(
      ShareParams(
        text: _shareText,
        subject: venue.name,
      ),
    );
  }

  void _copyForApp(BuildContext context, String appName) {
    Navigator.pop(context);
    Clipboard.setData(ClipboardData(text: _venueUrl));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Link copied — paste in $appName'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 12, 0),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Share this Venue',
                    style: TextStyle(
                      fontFamily: 'Jost',
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navyBlue,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: AppColors.navyBlue.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close_rounded,
                        color: AppColors.navyBlue, size: 16),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Venue preview ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.navyBlue.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: AppColors.navyBlue.withValues(alpha: 0.08)),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: venue.primaryImage != null
                        ? Image.network(
                            venue.primaryImage!,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _imgPlaceholder(),
                          )
                        : _imgPlaceholder(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                venue.name,
                                style: const TextStyle(
                                  fontFamily: 'Jost',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.navyBlue,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.star_rounded,
                                color: Colors.amber, size: 14),
                            const SizedBox(width: 2),
                            Text(
                              venue.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.navyBlue,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(Icons.location_on_rounded,
                                color: AppColors.limeGreen, size: 12),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                '${venue.city}, ${venue.state}',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 11,
                                  color: AppColors.navyBlue
                                      .withValues(alpha: 0.55),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),

          // ── Copyable link ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.navyBlue.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppColors.navyBlue.withValues(alpha: 0.1)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _venueUrl,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppColors.navyBlue.withValues(alpha: 0.6),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: _venueUrl));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Link copied to clipboard'),
                          duration: Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.navyBlue.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.copy_rounded,
                              size: 12,
                              color: AppColors.navyBlue
                                  .withValues(alpha: 0.7)),
                          const SizedBox(width: 4),
                          Text(
                            'Copy',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.navyBlue
                                  .withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ── Share options ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // More — opens native share sheet (user picks any app)
                _ShareOption(
                  icon: Icons.ios_share_rounded,
                  label: 'More',
                  color: AppColors.navyBlue,
                  onTap: () => _shareNative(context),
                ),
                // WhatsApp — native share sheet (user will see WhatsApp in list)
                _ShareOption(
                  icon: Icons.chat_rounded,
                  iconColor: Colors.white,
                  label: 'WhatsApp',
                  color: const Color(0xFF25D366),
                  onTap: () => _shareNative(context),
                ),
                // Facebook — copy link
                _ShareOption(
                  icon: Icons.facebook_rounded,
                  iconColor: Colors.white,
                  label: 'Facebook',
                  color: const Color(0xFF1877F2),
                  onTap: () => _copyForApp(context, 'Facebook'),
                ),
                // Instagram — copy link
                _ShareOption(
                  icon: Icons.camera_alt_rounded,
                  iconColor: Colors.white,
                  label: 'Instagram',
                  color: const Color(0xFFE1306C),
                  onTap: () => _copyForApp(context, 'Instagram'),
                ),
              ],
            ),
          ),

          SizedBox(height: MediaQuery.of(context).padding.bottom + 24),
        ],
      ),
    );
  }

  Widget _imgPlaceholder() => Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: AppColors.navyBlue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.stadium_rounded,
            color: AppColors.navyBlue, size: 28),
      );
}

// ── Single share option ──
class _ShareOption extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;

  const _ShareOption({
    required this.icon,
    required this.color,
    this.iconColor = Colors.white,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.navyBlue.withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );
  }
}