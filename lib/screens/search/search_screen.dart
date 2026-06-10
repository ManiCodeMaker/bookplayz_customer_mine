import 'package:bookplayz/api/session_manager.dart';
import 'package:bookplayz/api/api_constants.dart';
import 'package:bookplayz/models/venue_model.dart';
import 'package:bookplayz/theme/app_theme.dart';
import 'package:bookplayz/widgets/app_loader.dart';
import 'package:bookplayz/widgets/venue_cards.dart';
import 'package:flutter/material.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollCtrl = ScrollController();

  _SearchState _state = _SearchState.idle;
  List<String> _suggestions = [];
  List<String> _recentSearches = [];
  String? _selectedCity;
  int _currentPage = 1;
  bool _hasNext = false;
  bool _loadingMore = false;

  // ── Filters ──
  String? _selectedCategoryId;
  _SortType _sortType = _SortType.none;
  List<VenueModel> _allVenues = [];
  List<VenueModel> _filtered = [];
  List<_SportOption> _sportOptions = [];

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
    _scrollCtrl.addListener(_onScroll);
    _searchCtrl.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _focusNode.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
            _scrollCtrl.position.maxScrollExtent - 200 &&
        _hasNext &&
        !_loadingMore) {
      _loadMore();
    }
  }

  void _onTextChanged() {
    final q = _searchCtrl.text.trim();
    if (q.isEmpty) {
      setState(() {
        _state = _SearchState.idle;
        _suggestions = [];
        _selectedCity = null;
      });
      return;
    }
    setState(() => _state = _SearchState.suggesting);
    Future.delayed(const Duration(milliseconds: 350), () {
      if (_searchCtrl.text.trim() == q && q.isNotEmpty) {
        _fetchSuggestions(q);
      }
    });
  }

  Future<void> _fetchSuggestions(String q) async {
    try {
      final res = await VenueApi.fetchCities(q);
      if (mounted) {
        setState(() {
          _suggestions = res;
          _state = _SearchState.suggesting;
        });
      }
    } catch (_) {}
  }

  Future<void> _onCitySelected(String city) async {
    _searchCtrl.removeListener(_onTextChanged);
    _focusNode.unfocus();
    SessionManager.instance.saveCity(city);

    setState(() {
      _recentSearches.remove(city);
      _recentSearches.insert(0, city);
      if (_recentSearches.length > 5) {
        _recentSearches = _recentSearches.take(5).toList();
      }
      _selectedCity = city;
      _searchCtrl.text = city;
      _suggestions = [];
      _state = _SearchState.loading;
      _currentPage = 1;
      _allVenues = [];
    });

    _searchCtrl.addListener(_onTextChanged);

    await _fetchVenues(city: city, page: 1);
  }

  Future<void> _fetchVenues({required String city, int page = 1}) async {
    final lat = SessionManager.instance.latitude;
    final lng = SessionManager.instance.longitude;

    if (lat == null || lng == null) {
      setState(() => _state = _SearchState.error);
      return;
    }
  print('DEBUG search lat: $lat, lng: $lng, city: $city');
    try {
      final result = await VenueApi.search(
        latitude: lat,
        longitude: lng,
        page: page,
        limit: 12,
        city: city,
      );
      print('DEBUG distance: ${result.venues.first.distance}');
      setState(() {
        if (page == 1) {
          _allVenues = result.venues;
        } else {
          _allVenues.addAll(result.venues);
        }
        _currentPage = page;
        _hasNext = result.pagination.hasNext;
        _state = _SearchState.results;
        _buildSportOptions();
        _applyFilters();
        print('DEBUG search raw distance: ${result.venues.first.distance}');

      });
    } catch (_) {
      setState(() => _state = _SearchState.error);
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasNext || _selectedCity == null) return;
    setState(() => _loadingMore = true);
    await _fetchVenues(city: _selectedCity!, page: _currentPage + 1);
    setState(() => _loadingMore = false);
  }

  void _buildSportOptions() {
    final seen = <int>{};
    final options = <_SportOption>[];
    for (final v in _allVenues) {
      for (final cat in v.categories) {
        if (seen.add(cat.categoryId)) {
          options.add(_SportOption(
              categoryId: cat.categoryId, name: cat.name, image: cat.image));
        }
      }
    }
    _sportOptions = options;
  }

  void _applyFilters() {
    List<VenueModel> list = List.from(_allVenues);
    if (_selectedCategoryId != null) {
      final id = int.tryParse(_selectedCategoryId!);
      if (id != null) {
        list =
            list.where((v) => v.categories.any((c) => c.categoryId == id)).toList();
      }
    }
    switch (_sortType) {
      case _SortType.distanceAsc:
        list.sort((a, b) => (a.distance ?? 999).compareTo(b.distance ?? 999));
        break;
      case _SortType.distanceDesc:
        list.sort((a, b) => (b.distance ?? 0).compareTo(a.distance ?? 0));
        break;
      case _SortType.popular:
        list.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      default:
        break;
    }
    _filtered = list; // no setState here
  }

  void _onSportFilter() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.navyBlue,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _SportFilterSheet(
        options: _sportOptions,
        selected: _selectedCategoryId,
        onSelect: (id) {
          setState(() {
            _selectedCategoryId = id;
            _applyFilters();
          });
          Navigator.pop(context);
        },
      ),
    );
  }

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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navyBlue,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Search bar row ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.07),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: AppColors.white.withValues(alpha: 0.15)),
                      ),
                      child: const Icon(Icons.arrow_back_rounded,
                          color: AppColors.limeGreen, size: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.white.withValues(alpha: 0.15)),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 14),
                          Icon(Icons.search_rounded,
                              color: AppColors.white.withValues(alpha: 0.5),
                              size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _searchCtrl,
                              focusNode: _focusNode,
                              style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 14,
                                  color: AppColors.white),
                              decoration: InputDecoration(
                                hintText: 'Search city...',
                                hintStyle: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 14,
                                    color: AppColors.white.withValues(alpha: 0.4)),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                            ),
                          ),
                          if (_searchCtrl.text.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                _searchCtrl.clear();
                                setState(() {
                                  _state = _SearchState.idle;
                                  _selectedCity = null;
                                });
                                _focusNode.requestFocus();
                              },
                              child: Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: Icon(Icons.close_rounded,
                                    color: AppColors.white.withValues(alpha: 0.5),
                                    size: 18),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Filter chips (only when results) ──
            if (_state == _SearchState.results)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'Sport',
                      active: _selectedCategoryId != null,
                      onTap: _onSportFilter,
                      hasDropdown: true,
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Distance',
                      active: _sortType == _SortType.distanceAsc ||
                          _sortType == _SortType.distanceDesc,
                      onTap: () {
                        setState(() {
                          _sortType = _sortType == _SortType.distanceAsc
                              ? _SortType.distanceDesc
                              : _SortType.distanceAsc;
                          _applyFilters();
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Popular',
                      active: _sortType == _SortType.popular,
                      onTap: () {
                        setState(() {
                          _sortType = _sortType == _SortType.popular
                              ? _SortType.none
                              : _SortType.popular;
                          _applyFilters();
                        });
                      },
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 12),

            Expanded(
              child: _buildBody(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_state) {
      case _SearchState.idle:
        return _buildIdle();
      case _SearchState.suggesting:
        return _buildSuggestions();
      case _SearchState.loading:
        return const Center(child: AppLoader());
      case _SearchState.results:
        return _buildResults();
      case _SearchState.error:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded,
                  color: AppColors.white.withValues(alpha: 0.4), size: 48),
              const SizedBox(height: 12),
              Text('Something went wrong',
                  style: TextStyle(
                      fontFamily: 'Inter',
                      color: AppColors.white.withValues(alpha: 0.6))),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () {
                  if (_selectedCity != null) {
                    setState(() => _state = _SearchState.loading);
                    _fetchVenues(city: _selectedCity!);
                  }
                },
                child: Text('Retry',
                    style: TextStyle(
                        fontFamily: 'Inter',
                        color: AppColors.limeGreen,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildIdle() {
    if (_recentSearches.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_rounded,
                size: 64, color: AppColors.white.withValues(alpha: 0.15)),
            const SizedBox(height: 16),
            Text(
              'Search for a city',
              style: TextStyle(
                fontFamily: 'Jost',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.white.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Find venues near you',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: AppColors.white.withValues(alpha: 0.3),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Searches',
            style: TextStyle(
              fontFamily: 'Jost',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.white.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 12),
          ..._recentSearches.map((city) => GestureDetector(
                onTap: () {
                  _searchCtrl.text = city;
                  _onCitySelected(city);
                },
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Icon(Icons.history_rounded,
                          color: AppColors.white.withValues(alpha: 0.4),
                          size: 18),
                      const SizedBox(width: 12),
                      Text(
                        city,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          color: AppColors.white.withValues(alpha: 0.8),
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.north_west_rounded,
                          color: AppColors.white.withValues(alpha: 0.3),
                          size: 16),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildSuggestions() {
    if (_suggestions.isEmpty) {
      return Center(
        child: Text(
          'No cities found',
          style: TextStyle(
              fontFamily: 'Inter',
              color: AppColors.white.withValues(alpha: 0.4)),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _suggestions.length,
      separatorBuilder: (_, __) => Divider(
        color: AppColors.white.withValues(alpha: 0.07),
        height: 1,
      ),
      itemBuilder: (_, i) {
        final city = _suggestions[i];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.limeGreen.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.location_on_rounded,
                color: AppColors.limeGreen, size: 18),
          ),
          title: Text(
            city,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              color: AppColors.white,
            ),
          ),
          subtitle: Text(
            'Tamil Nadu',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.white.withValues(alpha: 0.4),
            ),
          ),
          trailing: Icon(Icons.north_west_rounded,
              color: AppColors.white.withValues(alpha: 0.3), size: 16),
          onTap: () => _onCitySelected(city),
        );
      },
    );
  }

  Widget _buildResults() {
    if (_filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_off_rounded,
                size: 56, color: AppColors.white.withValues(alpha: 0.2)),
            const SizedBox(height: 16),
            Text(
              'No venues found in $_selectedCity',
              style: TextStyle(
                fontFamily: 'Jost',
                fontSize: 16,
                color: AppColors.white.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Text(
            '${_filtered.length} venues in $_selectedCity',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: AppColors.white.withValues(alpha: 0.5),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: _scrollCtrl,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            itemCount: _filtered.length + (_loadingMore ? 1 : 0),
            itemBuilder: (_, i) {
              if (i == _filtered.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: AppLoader()),
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
    );
  }
}

// ── States ────────────────────────────────────────────────
enum _SearchState { idle, suggesting, loading, results, error }

enum _SortType { none, distanceAsc, distanceDesc, popular }

class _SportOption {
  final int categoryId;
  final String name;
  final String? image;
  const _SportOption(
      {required this.categoryId, required this.name, this.image});
}

// ── Filter Chip ───────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  final bool hasDropdown;

  const _FilterChip({
    required this.label,
    required this.active,
    required this.onTap,
    this.hasDropdown = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                  color: active ? AppColors.limeGreen : AppColors.white),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Sport Filter Sheet ────────────────────────────────────
class _SportFilterSheet extends StatelessWidget {
  final List<_SportOption> options;
  final String? selected;
  final void Function(String?) onSelect;

  const _SportFilterSheet({
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filter by Sport',
              style: TextStyle(
                fontFamily: 'Jost',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.white,
              ),
            ),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5,
              ),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _SheetOption(
                      label: 'All Sports',
                      isSelected: selected == null,
                      onTap: () => onSelect(null),
                    ),
                    ...options.map((opt) => _SheetOption(
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

class _SheetOption extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SheetOption({
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