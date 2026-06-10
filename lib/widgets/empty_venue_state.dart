import 'package:bookplayz/theme/app_theme.dart';
import 'package:flutter/material.dart';

class EmptyVenueState extends StatelessWidget {
  final String? city;
  final String? message;

  const EmptyVenueState({super.key, this.city, this.message});

  @override
  Widget build(BuildContext context) {
    final hasCity = city != null && city!.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.limeGreen.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.stadium_outlined,
              color: AppColors.limeGreen,
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            message ?? (hasCity ? 'No venues in $city' : 'No venues found'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Jost',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasCity
                ? 'There are no listed venues in $city yet.\nTry selecting a different city.'
                : 'Tap the location bar above\nto choose your city.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: AppColors.white.withValues(alpha: 0.45),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
