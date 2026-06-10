import 'package:bookplayz/api/api_constants.dart';
import 'package:bookplayz/api/session_manager.dart';
import 'package:bookplayz/models/venue_model.dart';
import 'package:bookplayz/theme/app_theme.dart';
import 'package:bookplayz/widgets/app_loader.dart';
import 'package:bookplayz/widgets/venue_cards.dart';
import 'package:flutter/material.dart';

class FavScreen extends StatefulWidget {
  final VoidCallback? onBack;
  const FavScreen({super.key, this.onBack});

  @override
  State<FavScreen> createState() => _FavScreenState();
}

class _FavScreenState extends State<FavScreen> {
  List<VenueModel> _venues  = [];
  bool    _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final ids = SessionManager.instance.favoriteIds.value;
      if (ids.isEmpty) {
        if (mounted) setState(() { _venues = []; _loading = false; });
        return;
      }

      final lat = SessionManager.instance.latitude;
      final lng = SessionManager.instance.longitude;

      if (lat == null || lng == null) {
        if (mounted) setState(() { _venues = []; _loading = false; });
        return;
      }

      final result = await VenueApi.search(
        latitude:  lat,
        longitude: lng,
        limit:     100,
      );

      final favVenues = result.venues
          .where((v) => ids.contains(v.id))
          .toList();

      if (mounted) setState(() { _venues = favVenues; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _toggleFavorite(int venueId) async {
    final current = Set<int>.from(SessionManager.instance.favoriteIds.value);
    current.remove(venueId);
    SessionManager.instance.favoriteIds.value = current;
    setState(() => _venues.removeWhere((v) => v.id == venueId));
    try {
      await FavoritesApi.toggle(venueId);
    } catch (_) {
      _load();
    }
  }

  void _goBack() {
    if (widget.onBack != null) {
      widget.onBack!();
    } else {
      Navigator.maybePop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navyBlue,
      body: Column(
        children: [
          // ── Title with back button ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _goBack,
                  child: Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      color: AppColors.limeGreen,
                      size: 20,
                    ),
                  ),
                ),
                const Expanded(
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
                        'Favorites',
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
                const SizedBox(width: 38),
              ],
            ),
          ),

          // ── Body ──────────────────────────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(child: AppLoader())
                : _error != null
                    ? _ErrorView(error: _error!, onRetry: _load)
                    : _venues.isEmpty
                        ? _EmptyView()
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                            itemCount: _venues.length,
                            separatorBuilder: (_, idx) => const SizedBox(height: 16),
                            itemBuilder: (_, i) => ValueListenableBuilder<Set<int>>(
                              valueListenable: SessionManager.instance.favoriteIds,
                              builder: (_, favIds, child) => VenueCard(
                                venue:        _venues[i],
                                isFavorite:   favIds.contains(_venues[i].id),
                                onBookmarkTap: () => _toggleFavorite(_venues[i].id),
                              ),
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────
class _EmptyView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.favorite_border_rounded,
              size: 64, color: AppColors.white.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text(
            'No saved venues yet',
            style: TextStyle(
              fontFamily: 'Jost',
              fontSize: 16,
              color: AppColors.white.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the heart icon on any venue to save it here',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: AppColors.white.withValues(alpha: 0.35),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Error view ────────────────────────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded,
                size: 48, color: AppColors.white.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: AppColors.white.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.limeGreen,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Retry',
                  style: TextStyle(fontFamily: 'Inter', color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
