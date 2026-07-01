import 'package:bookplayz/api/api_constants.dart';
import 'package:bookplayz/models/tournament_model.dart';
import 'package:bookplayz/theme/app_constants.dart';
import 'package:bookplayz/theme/app_theme.dart';
import 'package:bookplayz/widgets/app_loader.dart';
import 'package:flutter/material.dart';

class TournamentDetailScreen extends StatefulWidget {
  final int tournamentId;
  const TournamentDetailScreen({super.key, required this.tournamentId});

  @override
  State<TournamentDetailScreen> createState() => _TournamentDetailScreenState();
}

class _TournamentDetailScreenState extends State<TournamentDetailScreen> {
  TournamentModel? _tournament;
  List<TournamentModel> _moreEvents = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final tournament = await TournamentApi.fetchDetail(widget.tournamentId);
      final more = await TournamentApi.fetchMoreEvents(widget.tournamentId);
      setState(() {
        _tournament = tournament;
        _moreEvents = more;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Tournament not found.';
      });
    }
  }

  String _formattedDate(String dateStr) {
    final d = DateTime.tryParse(dateStr);
    if (d == null) return dateStr;
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${d.day.toString().padLeft(2, '0')} ${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navyBlue,
      appBar: AppBar(
        backgroundColor: AppColors.navyBlue,
        title: const Text(
          'Tournament Details',
          style: TextStyle(
            fontFamily: 'Jost',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(child: AppLoader())
          : _error != null || _tournament == null
              ? Center(
                  child: Text(_error ?? 'Tournament not found.',
                      style: TextStyle(color: AppColors.white.withValues(alpha: 0.6))),
                )
              : _buildContent(_tournament!),
    );
  }

  Widget _buildContent(TournamentModel t) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Banner ──
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: t.bannerImage != null && t.bannerImage!.isNotEmpty
                  ? Image.network(
                      t.bannerImage!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppColors.white.withValues(alpha: 0.08),
                        child: const Icon(Icons.emoji_events_outlined,
                            color: AppColors.limeGreen, size: 48),
                      ),
                    )
                  : Container(
                      color: AppColors.white.withValues(alpha: 0.08),
                      child: const Icon(Icons.emoji_events_outlined,
                          color: AppColors.limeGreen, size: 48),
                    ),
            ),
          ),
          const SizedBox(height: 16),

          Text(
            t.name,
            style: const TextStyle(
              fontFamily: 'Jost',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 12),

          _MetaRow(icon: Icons.calendar_today_rounded, text: _formattedDate(t.tournamentDate)),
          if (t.venueName != null || t.location.isNotEmpty)
            _MetaRow(
              icon: Icons.location_on_rounded,
              text: t.venueName != null && t.venueName!.isNotEmpty
                  ? '${t.venueName} — ${t.location}'
                  : t.location,
            ),
          if (t.startTime.isNotEmpty)
            _MetaRow(icon: Icons.access_time_rounded, text: '${t.startTime} – ${t.endTime}'),
          if (t.category.isNotEmpty)
            _MetaRow(icon: Icons.groups_rounded, text: t.category),
          if (t.genderCategory.isNotEmpty)
            _MetaRow(icon: Icons.wc_rounded, text: t.genderCategory),

          if (t.description != null && t.description!.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text(
              'About this event',
              style: TextStyle(
                fontFamily: 'Jost',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              t.description!,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                height: 1.5,
                color: AppColors.white.withValues(alpha: 0.7),
              ),
            ),
          ],

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Registration will open soon. Stay tuned!'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.limeGreen,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'Register Now',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white,
                ),
              ),
            ),
          ),

          if (_moreEvents.isNotEmpty) ...[
            const SizedBox(height: 28),
            const Text(
              'More Events',
              style: TextStyle(
                fontFamily: 'Jost',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.white,
              ),
            ),
            const SizedBox(height: 12),
            ..._moreEvents.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _MoreEventTile(tournament: e),
                )),
          ],
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _MetaRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.limeGreen),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: AppColors.white.withValues(alpha: 0.75),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MoreEventTile extends StatelessWidget {
  final TournamentModel tournament;
  const _MoreEventTile({required this.tournament});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushReplacementNamed(
        context,
        AppRoutes.tournamentDetail,
        arguments: tournament.id,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            SizedBox(
              width: 72,
              height: 72,
              child: tournament.bannerImage != null && tournament.bannerImage!.isNotEmpty
                  ? Image.network(
                      tournament.bannerImage!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppColors.navyBlue.withValues(alpha: 0.08),
                        child: const Icon(Icons.emoji_events_outlined,
                            color: AppColors.navyBlue, size: 24),
                      ),
                    )
                  : Container(
                      color: AppColors.navyBlue.withValues(alpha: 0.08),
                      child: const Icon(Icons.emoji_events_outlined,
                          color: AppColors.navyBlue, size: 24),
                    ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      tournament.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Jost',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navyBlue,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tournament.location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: AppColors.navyBlue.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
