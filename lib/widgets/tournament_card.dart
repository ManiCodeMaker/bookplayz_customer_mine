import 'package:bookplayz/models/tournament_model.dart';
import 'package:bookplayz/theme/app_constants.dart';
import 'package:bookplayz/theme/app_theme.dart';
import 'package:flutter/material.dart';

class _TournamentNoImagePlaceholder extends StatelessWidget {
  const _TournamentNoImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: AppColors.navyBlue.withValues(alpha: 0.08),
      child: Icon(
        Icons.emoji_events_outlined,
        size: 32,
        color: AppColors.navyBlue.withValues(alpha: 0.35),
      ),
    );
  }
}

String _monthShort(int month) {
  const months = [
    'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
    'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
  ];
  if (month < 1 || month > 12) return '';
  return months[month - 1];
}

class TournamentCard extends StatelessWidget {
  final TournamentModel tournament;

  const TournamentCard({super.key, required this.tournament});

  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse(tournament.tournamentDate);

    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        AppRoutes.tournamentDetail,
        arguments: tournament.id,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Image + date badge ──
              SizedBox(
                width: 120,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    tournament.bannerImage != null &&
                            tournament.bannerImage!.isNotEmpty
                        ? Image.network(
                            tournament.bannerImage!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const _TournamentNoImagePlaceholder(),
                          )
                        : const _TournamentNoImagePlaceholder(),
                    if (date != null)
                      Positioned(
                        left: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              Text(
                                _monthShort(date.month),
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.limeGreen,
                                ),
                              ),
                              Text(
                                date.day.toString().padLeft(2, '0'),
                                style: const TextStyle(
                                  fontFamily: 'Jost',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    Positioned(
                      left: 8,
                      bottom: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: tournament.status == 'Active'
                              ? AppColors.limeGreen
                              : Colors.grey,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          tournament.status,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Info section ──
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (tournament.genderCategory.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.limeGreen.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                tournament.genderCategory,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.navyBlue,
                                ),
                              ),
                            ),
                          const SizedBox(height: 6),
                          Text(
                            tournament.name,
                            style: const TextStyle(
                              fontFamily: 'Jost',
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.navyBlue,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (tournament.location.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              tournament.location,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11,
                                color: AppColors.navyBlue.withValues(alpha: 0.55),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          const SizedBox(height: 6),
                          if (tournament.startTime.isNotEmpty)
                            Row(
                              children: [
                                Icon(Icons.check_circle_outline_rounded,
                                    size: 12,
                                    color: AppColors.navyBlue.withValues(alpha: 0.5)),
                                const SizedBox(width: 4),
                                Text(
                                  '${tournament.startTime} – ${tournament.endTime}',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 11,
                                    color: AppColors.navyBlue.withValues(alpha: 0.55),
                                  ),
                                ),
                              ],
                            ),
                          if (tournament.category.isNotEmpty)
                            Row(
                              children: [
                                Icon(Icons.check_circle_outline_rounded,
                                    size: 12,
                                    color: AppColors.navyBlue.withValues(alpha: 0.5)),
                                const SizedBox(width: 4),
                                Text(
                                  tournament.category,
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 11,
                                    color: AppColors.navyBlue.withValues(alpha: 0.55),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.limeGreen,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Register Now',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.white,
                            ),
                          ),
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
    );
  }
}
