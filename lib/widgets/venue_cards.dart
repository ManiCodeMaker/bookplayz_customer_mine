import 'package:bookplayz/models/venue_model.dart';
import 'package:bookplayz/theme/app_constants.dart';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'package:flutter_svg/flutter_svg.dart';

class VenueCard extends StatelessWidget {
  final VenueModel venue;
  final bool isFavorite;
  final VoidCallback? onBookmarkTap;

  const VenueCard({
    super.key,
    required this.venue,
    this.isFavorite = false,
    this.onBookmarkTap,
  });

  String get _distanceLabel {
    final d = venue.distance;
    if (d == null) return '';
    return '${d.toStringAsFixed(1)} km';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          AppRoutes.venueDetail,
          arguments: venue.slug,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hero image ──
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: venue.primaryImage != null
                      ? Image.network(
                          venue.primaryImage!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.broken_image_rounded),
                          ),
                        )
                      : Container(color: Colors.grey.shade200),
                ),

                // Category icons bottom-left
                if (venue.categories.isNotEmpty)
                  Positioned(
                    left: 10,
                    bottom: 10,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: venue.categories.take(3).map((cat) {
                        return Container(
                          margin: const EdgeInsets.only(right: 6),
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(5),
                          child: cat.image != null
                              ? SvgPicture.network(
                                  cat.image!,
                                  colorFilter: const ColorFilter.mode(
                                    AppColors.limeGreen,
                                    BlendMode.srcIn,
                                  ),
                                  placeholderBuilder: (_) => const SizedBox(),
                                )
                              : const Icon(Icons.sports,
                                  color: AppColors.limeGreen, size: 14),
                        );
                      }).toList(),
                    ),
                  ),

                // Distance badge bottom-right
                if (_distanceLabel.isNotEmpty)
                  Positioned(
                    right: 10,
                    bottom: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.directions_bike_rounded,
                              color: AppColors.white, size: 12),
                          const SizedBox(width: 4),
                          Text(_distanceLabel,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.white,
                              )),
                        ],
                      ),
                    ),
                  ),

                // ── Bookmark icon top-right ──
                Positioned(
                  right: 10,
                  top: 10,
                  child: GestureDetector(
                    onTap: onBookmarkTap,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isFavorite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: isFavorite ? Colors.red : AppColors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // ── Info section ──
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
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
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.navyBlue,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.limeGreen,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded,
                                color: AppColors.white, size: 13),
                            const SizedBox(width: 4),
                            Text(
                              venue.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${venue.city}, ${venue.state}',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: AppColors.navyBlue.withValues(alpha: 0.55),
                        ),
                      ),
                      Text(
                        'Price ₹550–₹850',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.navyBlue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.limeGreen,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Over most people booked this venue',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          color: AppColors.navyBlue.withValues(alpha: 0.6),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppColors.limeGreen,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.trending_up_rounded,
                            color: AppColors.white, size: 16),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}