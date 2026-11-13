import 'package:bookplayz/api/api_constants.dart';
import 'package:bookplayz/api/session_manager.dart';
import 'package:bookplayz/models/venue_model.dart';
import 'package:bookplayz/theme/app_theme.dart';
import 'package:bookplayz/widgets/app_loader.dart';
import 'package:bookplayz/widgets/venue_cards.dart';
import 'package:flutter/material.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  List<VenueModel> _venues = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

 Future<void> _load() async {
  try {
    // From the server, wherever the venue is — not limited to nearby ones.
    final wishlistVenues = await FavoritesApi.fetchVenues();

    debugPrint('── Wishlist venues: ${wishlistVenues.length} ──');

    if (mounted) setState(() {
      _venues = wishlistVenues;
      _loading = false;
    });
  } catch (e) {
    debugPrint('── Wishlist error: $e ──');
    if (mounted) setState(() => _loading = false);
  }
}

  Future<void> _toggleFavorite(int venueId) async {
    // Remove from shared notifier
    final current = Set<int>.from(SessionManager.instance.favoriteIds.value);
    current.remove(venueId);
    SessionManager.instance.favoriteIds.value = current;
    // Remove from local list
    setState(() => _venues.removeWhere((v) => v.id == venueId));
    try {
      await FavoritesApi.toggle(venueId);
    } catch (_) {
      _load(); // revert by reloading
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navyBlue,
      appBar: AppBar(
        backgroundColor: AppColors.navyBlue,
        title: const Text(
          'Wish List',
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
          : _venues.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.favorite_border_rounded,
                          size: 64,
                          color: AppColors.white.withValues(alpha: 0.5)),
                      const SizedBox(height: 16),
                      Text(
                        'No saved venues yet',
                        style: TextStyle(
                          fontFamily: 'Jost',
                          fontSize: 16,
                          color: AppColors.white.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _venues.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (_, i) => ValueListenableBuilder<Set<int>>(
                    valueListenable: SessionManager.instance.favoriteIds,
                    builder: (_, favIds, __) => VenueCard(
                      venue: _venues[i],
                      isFavorite: favIds.contains(_venues[i].id),
                      onBookmarkTap: () => _toggleFavorite(_venues[i].id),
                    ),
                  ),
                ),
    );
  }
}