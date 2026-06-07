import 'package:bookplayz/api/session_manager.dart';
import 'package:bookplayz/api/api_constants.dart';
import 'package:bookplayz/models/venue_model.dart';
import 'package:bookplayz/theme/app_theme.dart';
import 'package:bookplayz/theme/app_constants.dart';
import 'package:bookplayz/widgets/venue_cards.dart';
import 'package:flutter/material.dart';

class VenuesScreen extends StatefulWidget {
  final VoidCallback? onBack;
  const VenuesScreen({super.key, this.onBack});

  @override
  State<VenuesScreen> createState() => VenuesScreenState();
}

class VenuesScreenState extends State<VenuesScreen> {
  // ── Data ──
  List<VenueModel> _allVenues = [];
  List<VenueModel> _filtered = [];
  bool _loading = true;
  String? _error;
  int _currentPage = 1;
  bool _hasNext = false;
  bool _loadingMore = false;
  

  // ── Search ──
  final TextEditingController _searchCtrl = TextEditingController();
  List<String> _citySuggestions = [];
  bool _showSuggestions = false;
  String? _selectedCity;
  final _debounce = ValueNotifier<String>('');

  // ── Filters ──
  String? _selectedCategoryId; // for Sport filter
  VenueSortType _sortType = VenueSortType.none;

  // ── Sport filter options built from fetched data ──
  List<VenueSportOption> _sportOptions = [];

  final ScrollController _scrollCtrl = ScrollController();

  Future<void> _toggleFavorite(int venueId) async {
  final current = Set<int>.from(SessionManager.instance.favoriteIds.value);
  if (current.contains(venueId)) {
    current.remove(venueId);
  } else {
    current.add(venueId);
  }
  SessionManager.instance.favoriteIds.value = current;
  try {
    await FavoritesApi.toggle(venueId);
  } catch (_) {
    final revert = Set<int>.from(SessionManager.instance.favoriteIds.value);
    if (revert.contains(venueId)) {
      revert.remove(venueId);
    } else {
      revert.add(venueId);
    }
    SessionManager.instance.favoriteIds.value = revert;
  }
}

  @override
  void initState() {
    super.initState();
    _loadVenues();
    _scrollCtrl.addListener(_onScroll);
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    _debounce.dispose();
    super.dispose();
  }

  void refresh() => _loadVenues();



  // ── Scroll to load more ──
  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
            _scrollCtrl.position.maxScrollExtent - 200 &&
        _hasNext &&
        !_loadingMore) {
      _loadMoreVenues();
    }
  }

  // ── Search with debounce ──
  void _onSearchChanged() {
      final q = _searchCtrl.text.trim();
      if (q.isEmpty) {
        setState(() {
          _citySuggestions = [];
          _showSuggestions = false;
          _selectedCity = null;
        });
        _loadVenues(); // reload with no city filter
        return;
      }
      Future.delayed(const Duration(milliseconds: 350), () {
        if (_searchCtrl.text.trim() == q) {
          _fetchCitySuggestions(q);
        }
      });
  }

  Future<void> _fetchCitySuggestions(String q) async {
    try {
      final res = await VenueApi.fetchCities(q);
      setState(() {
        _citySuggestions = res;
        _showSuggestions = res.isNotEmpty;
      });
    } catch (_) {}
  }

  void _onCitySelected(String city) {
    SessionManager.instance.saveCity(city); 
    setState(() {
      _selectedCity = city;
      _searchCtrl.text = city;
      _showSuggestions = false;
      _citySuggestions = [];
      _currentPage = 1;
      _allVenues = [];
    });
    _loadVenues(city: city);
  }

  // ── Load venues ──
  Future<void> _loadVenues({String? city}) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final lat = SessionManager.instance.latitude;
    final lng = SessionManager.instance.longitude;

    print('DEBUG lat: $lat, lng: $lng'); // add this
    print('DEBUG city: ${city ?? _selectedCity ?? SessionManager.instance.city}');

    if (lat == null || lng == null) {
      setState(() {
        _loading = false;
        _error = 'Location unavailable';
      });
      return;
    }

    try {
      final result = await VenueApi.search(
        latitude: lat,
        longitude: lng,
        page: 1,
        limit: 12,
        city: city ?? _selectedCity,
      );
      print('DEBUG first venue distance: ${result.venues.first.distance}');
      setState(() {
        _allVenues = result.venues;
        _currentPage = 1;
        _hasNext = result.pagination.hasNext;
        _loading = false;
        _buildSportOptions();
        _applyFilters();
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _loadMoreVenues() async {
    if (_loadingMore) return;
    setState(() => _loadingMore = true);

    final lat = SessionManager.instance.latitude!;
    final lng = SessionManager.instance.longitude!;

    try {
      final result = await VenueApi.search(
        latitude: lat,
        longitude: lng,
        page: _currentPage + 1,
        limit: 12,
        city: _selectedCity,
      );
      setState(() {
        _allVenues.addAll(result.venues);
        _currentPage++;
        _hasNext = result.pagination.hasNext;
        _loadingMore = false;
        _buildSportOptions();
        _applyFilters();
      });
    } catch (_) {
      setState(() => _loadingMore = false);
    }
  }

  // ── Build sport filter options from fetched venues ──
  void _buildSportOptions() {
    final seen = <int>{};
    final options = <VenueSportOption>[];
    for (final v in _allVenues) {
      for (final cat in v.categories) {
        if (seen.add(cat.categoryId)) {
          options.add(VenueSportOption(
            categoryId: cat.categoryId,
            name: cat.name,
            image: cat.image,
          ));
        }
      }
    }
    _sportOptions = options;
  }

  // ── Client-side filter + sort ──
  void _applyFilters() {
    List<VenueModel> list = List.from(_allVenues);

    // Sport filter
    if (_selectedCategoryId != null) {
      final id = int.tryParse(_selectedCategoryId!);
      if (id != null) {
        list = list
            .where((v) => v.categories.any((c) => c.categoryId == id))
            .toList();
      }
    }

    // Sort
    switch (_sortType) {
      case VenueSortType.priceAsc:
      case VenueSortType.priceDesc:
        break;
      case VenueSortType.distanceAsc:
        list.sort((a, b) => (a.distance ?? 999).compareTo(b.distance ?? 999));
        break;
      case VenueSortType.distanceDesc:
        list.sort((a, b) => (b.distance ?? 0).compareTo(a.distance ?? 0));
        break;
      case VenueSortType.popular:
        list.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case VenueSortType.none:
        break;
    }

    setState(() => _filtered = list);
  }



  void _onSportFilter() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.navyBlue,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => VenueSportFilterSheet(
        options: _sportOptions,
        selected: _selectedCategoryId,
        onSelect: (id) {
          setState(() => _selectedCategoryId = id);
          _applyFilters();
          Navigator.pop(context);
        },
      ),
    );
  }


void _onPriceFilter() {
  setState(() {
    _sortType = _sortType == VenueSortType.priceAsc
        ? VenueSortType.priceDesc
        : VenueSortType.priceAsc;
  });
  _applyFilters();
}

void _onDistanceFilter() {
  setState(() {
    _sortType = _sortType == VenueSortType.distanceAsc
        ? VenueSortType.distanceDesc
        : VenueSortType.distanceAsc;
  });
  _applyFilters();
}

void _onPopularFilter() {
  setState(() {
    _sortType = _sortType == VenueSortType.popular
        ? VenueSortType.none
        : VenueSortType.popular;
  });
  _applyFilters();
}
@override
Widget build(BuildContext context) {
  return Container(
    color: AppColors.navyBlue,
    child: Column(
      children: [
     
        // Replace the search Padding + filter SingleChildScrollView with:
Stack(
  clipBehavior: Clip.none,
  children: [
    Column(
      children: [
        // search box
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: GestureDetector(
            onTap: () => Navigator.pushNamed(context, AppRoutes.search),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.white.withValues(alpha: 0.15)),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 14),
                  Image.asset(
                    AppImages.searchIcon,
                    width: 20,
                    height: 20,
                    color: AppColors.white,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Search city or venue...',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        color: AppColors.white.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              VenueFilterChip(
                label: 'Price',
                icon: Icons.swap_vert_rounded,
                active: _sortType == VenueSortType.priceAsc || _sortType == VenueSortType.priceDesc,
                onTap: _onPriceFilter,
              ),
              const SizedBox(width: 8),
              VenueFilterChip(
                label: 'Sport',
                icon: Icons.sports_rounded,
                active: _selectedCategoryId != null,
                onTap: _onSportFilter,
                hasDropdown: true,
              ),
              const SizedBox(width: 8),
              VenueFilterChip(
                label: 'Distance',
                icon: Icons.swap_vert_rounded,
                active: _sortType == VenueSortType.distanceAsc || _sortType == VenueSortType.distanceDesc,
                onTap: _onDistanceFilter,
                hasDropdown: true,
              ),
              const SizedBox(width: 8),
              VenueFilterChip(
                label: 'Popular',
                icon: Icons.swap_vert_rounded,
                active: _sortType == VenueSortType.popular,
                onTap: _onPopularFilter,
              ),
            ],
          ),
        ),
      ],
    ),

    // Floating suggestions ON TOP of everything
    if (_showSuggestions)
      Positioned(
        top: 64,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          elevation: 16,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1A2A4A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.white.withValues(alpha: 0.1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: _citySuggestions
                  .map((city) => InkWell(
                        onTap: () => _onCitySelected(city),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              Icon(Icons.location_on_rounded,
                                  color: AppColors.limeGreen, size: 16),
                              const SizedBox(width: 10),
                              Text(city,
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 14,
                                    color: AppColors.white,
                                  )),
                            ],
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),
        ),
      ),
  ],
),
        // ── Venue list ──
        Expanded(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(
                      color: AppColors.limeGreen))
              : _error != null
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_error!,
                              style: TextStyle(
                                  color:
                                      AppColors.white.withValues(alpha: 0.6))),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadVenues,
                            style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.limeGreen),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : _filtered.isEmpty
                      ? Center(
                          child: Text(
                            'No venues found',
                            style: TextStyle(
                                color:
                                    AppColors.white.withValues(alpha: 0.5)),
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollCtrl,
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          itemCount:
                              _filtered.length + (_loadingMore ? 1 : 0),
                          itemBuilder: (_, i) {
                            if (i == _filtered.length) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 20),
                                child: Center(
                                  child: CircularProgressIndicator(
                                      color: AppColors.limeGreen),
                                ),
                              );
                            }
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: ValueListenableBuilder<Set<int>>(
                                valueListenable: SessionManager.instance.favoriteIds,
                                builder: (_, favIds, __) => VenueCard(
                                  venue: _filtered[i],
                                  isFavorite: favIds.contains(_filtered[i].id),
                                  onBookmarkTap: () => _toggleFavorite(_filtered[i].id),
                                ),
                              ),
                            );
                          },
                        ),
        ),
      ],
    ),
  );
}
}
// ── Sort type ─────────────────────────────────────────────
enum VenueSortType { none, priceAsc, priceDesc, distanceAsc, distanceDesc, popular }


// ── Sport option model ────────────────────────────────────
class VenueSportOption {
  final int categoryId;
  final String name;
  final String? image;
  const VenueSportOption(
      {required this.categoryId, required this.name, this.image});
}

// ── Filter chip widget ────────────────────────────────────
class VenueFilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  final bool hasDropdown;

  const VenueFilterChip({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
    this.hasDropdown = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active
              ? AppColors.limeGreen.withValues(alpha: 0.15)
              : AppColors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active
                ? AppColors.limeGreen
                : AppColors.white.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 14,
                color:
                    active ? AppColors.limeGreen : AppColors.white),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: active ? AppColors.limeGreen : AppColors.white,
              ),
            ),
            if (hasDropdown) ...[
              const SizedBox(width: 4),
              Icon(Icons.keyboard_arrow_down_rounded,
                  size: 14,
                  color: active
                      ? AppColors.limeGreen
                      : AppColors.white),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Sport filter bottom sheet ─────────────────────────────
class VenueSportFilterSheet extends StatelessWidget {
  final List<VenueSportOption> options;
  final String? selected;
  final void Function(String?) onSelect;

  const VenueSportFilterSheet({
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    // In _SportFilterSheet, replace Column with:
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Filter by Sport',
                style: TextStyle(
                  fontFamily: 'Jost', fontSize: 16,
                  fontWeight: FontWeight.w700, color: AppColors.white,
                )),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5,
              ),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    VenueSheetOption(
                      label: 'All Sports',
                      isSelected: selected == null,
                      onTap: () => onSelect(null),
                    ),
                    ...options.map((opt) => VenueSheetOption(
                          label: opt.name,
                          isSelected: selected == opt.categoryId.toString(),
                          onTap: () => onSelect(opt.categoryId.toString()),
                        )),
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

class VenueSheetOption extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const VenueSheetOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.limeGreen.withValues(alpha: 0.15)
              : AppColors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? AppColors.limeGreen
                : AppColors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isSelected ? AppColors.limeGreen : AppColors.white,
          ),
        ),
      ),
    );
  }
}