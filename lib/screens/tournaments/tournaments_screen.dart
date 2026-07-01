import 'package:bookplayz/api/api_constants.dart';
import 'package:bookplayz/models/tournament_model.dart';
import 'package:bookplayz/theme/app_theme.dart';
import 'package:bookplayz/widgets/app_loader.dart';
import 'package:bookplayz/widgets/tournament_card.dart';
import 'package:flutter/material.dart';

class TournamentsScreen extends StatefulWidget {
  const TournamentsScreen({super.key});

  @override
  State<TournamentsScreen> createState() => _TournamentsScreenState();
}

class _TournamentsScreenState extends State<TournamentsScreen> {
  List<TournamentModel> _tournaments = [];
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  int _currentPage = 1;
  bool _hasNext = false;

  final TextEditingController _searchCtrl = TextEditingController();
  String? _selectedCategory;
  String? _selectedGender;
  DateTime? _selectedDate;

  final ScrollController _scrollCtrl = ScrollController();

  static const _categories = [
    'Children & Adults',
    'Only Adults',
    'Only Children',
  ];
  static const _genders = ['Male', 'Female', 'Mixed / Open'];

  @override
  void initState() {
    super.initState();
    _load();
    _scrollCtrl.addListener(_onScroll);
    _searchCtrl.addListener(() {
      final q = _searchCtrl.text.trim();
      Future.delayed(const Duration(milliseconds: 350), () {
        if (_searchCtrl.text.trim() == q) _load();
      });
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
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

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await TournamentApi.fetchPublic(
        page: 1,
        search: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
        category: _selectedCategory,
        genderCategory: _selectedGender,
        date: _selectedDate == null
            ? null
            : '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}',
      );
      setState(() {
        _tournaments = result.tournaments;
        _currentPage = 1;
        _hasNext = result.pagination.hasNext;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore) return;
    setState(() => _loadingMore = true);
    try {
      final result = await TournamentApi.fetchPublic(
        page: _currentPage + 1,
        search: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
        category: _selectedCategory,
        genderCategory: _selectedGender,
        date: _selectedDate == null
            ? null
            : '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}',
      );
      setState(() {
        _tournaments.addAll(result.tournaments);
        _currentPage++;
        _hasNext = result.pagination.hasNext;
        _loadingMore = false;
      });
    } catch (_) {
      setState(() => _loadingMore = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked == null) return;
    setState(() => _selectedDate = picked);
    _load();
  }

  void _openFilterSheet({
    required String title,
    required List<String> options,
    required String? selected,
    required void Function(String?) onSelect,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.navyBlue,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                    fontFamily: 'Jost',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                  )),
              const SizedBox(height: 16),
              _SheetOption(
                label: 'All',
                isSelected: selected == null,
                onTap: () {
                  onSelect(null);
                  Navigator.pop(context);
                },
              ),
              ...options.map((opt) => _SheetOption(
                    label: opt,
                    isSelected: selected == opt,
                    onTap: () {
                      onSelect(opt);
                      Navigator.pop(context);
                    },
                  )),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navyBlue,
      appBar: AppBar(
        backgroundColor: AppColors.navyBlue,
        title: const Text(
          'Tournaments',
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
      body: Column(
        children: [
          // ── Search box ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
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
                  Icon(Icons.search_rounded, color: AppColors.white.withValues(alpha: 0.6), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      style: const TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppColors.white),
                      decoration: InputDecoration(
                        hintText: 'Search tournaments...',
                        hintStyle: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          color: AppColors.white.withValues(alpha: 0.4),
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Filter chips ──
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                _FilterChip(
                  label: _selectedDate == null
                      ? 'Date'
                      : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                  icon: Icons.calendar_today_rounded,
                  active: _selectedDate != null,
                  onTap: _pickDate,
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: _selectedCategory ?? 'Category',
                  icon: Icons.groups_rounded,
                  active: _selectedCategory != null,
                  hasDropdown: true,
                  onTap: () => _openFilterSheet(
                    title: 'Filter by Category',
                    options: _categories,
                    selected: _selectedCategory,
                    onSelect: (v) {
                      setState(() => _selectedCategory = v);
                      _load();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: _selectedGender ?? 'Gender',
                  icon: Icons.wc_rounded,
                  active: _selectedGender != null,
                  hasDropdown: true,
                  onTap: () => _openFilterSheet(
                    title: 'Filter by Gender',
                    options: _genders,
                    selected: _selectedGender,
                    onSelect: (v) {
                      setState(() => _selectedGender = v);
                      _load();
                    },
                  ),
                ),
              ],
            ),
          ),

          // ── List ──
          Expanded(
            child: _loading
                ? const Center(child: AppLoader())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_error!,
                                style: TextStyle(color: AppColors.white.withValues(alpha: 0.6))),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _load,
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.limeGreen),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _tournaments.isEmpty
                        ? Padding(
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
                                    Icons.emoji_events_outlined,
                                    color: AppColors.limeGreen,
                                    size: 40,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'No tournaments found',
                                  style: TextStyle(
                                    fontFamily: 'Jost',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.white,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollCtrl,
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                            itemCount: _tournaments.length + (_loadingMore ? 1 : 0),
                            itemBuilder: (_, i) {
                              if (i == _tournaments.length) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 20),
                                  child: Center(child: AppLoader()),
                                );
                              }
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: TournamentCard(tournament: _tournaments[i]),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  final bool hasDropdown;

  const _FilterChip({
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active
              ? AppColors.limeGreen.withValues(alpha: 0.15)
              : AppColors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? AppColors.limeGreen : AppColors.white.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: active ? AppColors.limeGreen : AppColors.white),
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
                  size: 14, color: active ? AppColors.limeGreen : AppColors.white),
            ],
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
            color: isSelected ? AppColors.limeGreen : AppColors.white.withValues(alpha: 0.1),
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
