import 'package:bookplayz/api/api_constants.dart';
import 'package:bookplayz/api/session_manager.dart';
import 'package:bookplayz/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Opens the state → district/city picker bottom sheet.
/// Saves the chosen city to [SessionManager] and returns it,
/// or returns null if the user dismisses without selecting.
Future<String?> showCityPickerSheet(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _CityPickerSheet(),
  );
}

class _CityPickerSheet extends StatefulWidget {
  const _CityPickerSheet();

  @override
  State<_CityPickerSheet> createState() => _CityPickerSheetState();
}

class _CityPickerSheetState extends State<_CityPickerSheet> {
  // ── State list ──
  List<StateModel> _states = [];
  bool _loadingStates = true;
  String? _statesError;

  // ── Selected state ──
  StateModel? _selectedState;

  // ── District list ──
  List<DistrictModel> _allDistricts = [];
  List<DistrictModel> _filteredDistricts = [];
  bool _loadingDistricts = false;
  String? _districtsError;

  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchStates();
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchStates() async {
    try {
      final res = await LocationsApi.fetchStates();
      if (mounted) {
        setState(() {
          _states = res;
          _loadingStates = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statesError = 'Failed to load states';
          _loadingStates = false;
        });
      }
    }
  }

  Future<void> _onStateTap(StateModel state) async {
    setState(() {
      _selectedState = state;
      _loadingDistricts = true;
      _districtsError = null;
      _allDistricts = [];
      _filteredDistricts = [];
      _searchCtrl.clear();
    });
    try {
      final res = await LocationsApi.fetchDistricts(state.id);
      if (mounted) {
        setState(() {
          _allDistricts = res;
          _filteredDistricts = res;
          _loadingDistricts = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _districtsError = 'Failed to load cities';
          _loadingDistricts = false;
        });
      }
    }
  }

  void _onSearchChanged() {
    final q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      _filteredDistricts = q.isEmpty
          ? _allDistricts
          : _allDistricts
              .where((d) => d.name.toLowerCase().contains(q))
              .toList();
    });
  }

  void _onDistrictTap(DistrictModel district) {
    SessionManager.instance.saveCity(district.name);
    Navigator.pop(context, district.name);
  }

  void _backToStates() {
    setState(() {
      _selectedState = null;
      _allDistricts = [];
      _filteredDistricts = [];
      _districtsError = null;
      _searchCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: AppColors.navyBlue,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // ── Drag handle ──
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
              child: Row(
                children: [
                  if (_selectedState != null)
                    GestureDetector(
                      onTap: _backToStates,
                      child: const Padding(
                        padding: EdgeInsets.only(right: 12),
                        child: Icon(Icons.arrow_back_rounded,
                            color: Colors.white, size: 22),
                      ),
                    ),
                  Expanded(
                    child: Text(
                      _selectedState?.name ?? 'Select State',
                      style: const TextStyle(
                        fontFamily: 'Jost',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close_rounded,
                        color: Colors.white54, size: 22),
                  ),
                ],
              ),
            ),

            const Divider(color: Colors.white12, height: 1),

            // ── Content ──
            Expanded(
              child: _selectedState == null
                  ? _StateList(
                      scrollCtrl: scrollCtrl,
                      states: _states,
                      loading: _loadingStates,
                      error: _statesError,
                      onRetry: _fetchStates,
                      onStateTap: _onStateTap,
                    )
                  : _DistrictList(
                      scrollCtrl: scrollCtrl,
                      districts: _filteredDistricts,
                      loading: _loadingDistricts,
                      error: _districtsError,
                      searchCtrl: _searchCtrl,
                      stateName: _selectedState!.name,
                      onDistrictTap: _onDistrictTap,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── State list panel ──────────────────────────────────────────────────────────

class _StateList extends StatelessWidget {
  final ScrollController scrollCtrl;
  final List<StateModel> states;
  final bool loading;
  final String? error;
  final VoidCallback onRetry;
  final ValueChanged<StateModel> onStateTap;

  const _StateList({
    required this.scrollCtrl,
    required this.states,
    required this.loading,
    required this.error,
    required this.onRetry,
    required this.onStateTap,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
        child: CircularProgressIndicator(
            color: AppColors.limeGreen, strokeWidth: 2),
      );
    }
    if (error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(error!,
                style: const TextStyle(fontFamily: 'Jost', color: Colors.white54)),
            const SizedBox(height: 12),
            TextButton(
              onPressed: onRetry,
              child: const Text('Retry',
                  style: TextStyle(color: AppColors.limeGreen)),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      controller: scrollCtrl,
      itemCount: states.length,
      separatorBuilder: (_, _) =>
          const Divider(color: Colors.white12, height: 1, indent: 56),
      itemBuilder: (_, i) {
        final state = states[i];
        return ListTile(
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.limeGreen.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.location_city_outlined,
                color: AppColors.limeGreen, size: 18),
          ),
          title: Text(
            state.name,
            style: const TextStyle(
              fontFamily: 'Jost',
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          trailing: const Icon(Icons.chevron_right_rounded,
              color: Colors.white38, size: 20),
          onTap: () => onStateTap(state),
        );
      },
    );
  }
}

// ── District list panel ───────────────────────────────────────────────────────

class _DistrictList extends StatelessWidget {
  final ScrollController scrollCtrl;
  final List<DistrictModel> districts;
  final bool loading;
  final String? error;
  final TextEditingController searchCtrl;
  final String stateName;
  final ValueChanged<DistrictModel> onDistrictTap;

  const _DistrictList({
    required this.scrollCtrl,
    required this.districts,
    required this.loading,
    required this.error,
    required this.searchCtrl,
    required this.stateName,
    required this.onDistrictTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Search field ──
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Container(
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            child: TextField(
              controller: searchCtrl,
              autofocus: true,
              style: const TextStyle(
                  fontFamily: 'Jost', fontSize: 14, color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search city in $stateName...',
                hintStyle: const TextStyle(
                    fontFamily: 'Jost', fontSize: 14, color: Colors.white38),
                prefixIcon: const Icon(Icons.search_rounded,
                    color: Colors.white38, size: 20),
                suffixIcon: searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded,
                            color: Colors.white38, size: 18),
                        onPressed: searchCtrl.clear,
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ),

        // ── Results ──
        Expanded(
          child: loading
              ? const Center(
                  child: CircularProgressIndicator(
                      color: AppColors.limeGreen, strokeWidth: 2),
                )
              : error != null
                  ? Center(
                      child: Text(error!,
                          style: const TextStyle(
                              fontFamily: 'Jost', color: Colors.white54)),
                    )
                  : districts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.search_off_rounded,
                                  color: Colors.white12, size: 48),
                              const SizedBox(height: 12),
                              Text(
                                searchCtrl.text.isEmpty
                                    ? 'No cities available'
                                    : 'No cities found for "${searchCtrl.text}"',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontFamily: 'Jost',
                                    fontSize: 14,
                                    color: Colors.white38),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          controller: scrollCtrl,
                          itemCount: districts.length,
                          separatorBuilder: (_, _) => const Divider(
                              color: Colors.white12, height: 1, indent: 56),
                          itemBuilder: (_, i) {
                            final district = districts[i];
                            return ListTile(
                              leading: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.limeGreen.withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.location_on_outlined,
                                    color: AppColors.limeGreen, size: 18),
                              ),
                              title: Text(
                                district.name,
                                style: const TextStyle(
                                  fontFamily: 'Jost',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                              subtitle: Text(
                                stateName,
                                style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 12,
                                    color: Colors.white38),
                              ),
                              onTap: () => onDistrictTap(district),
                            );
                          },
                        ),
        ),
      ],
    );
  }
}
