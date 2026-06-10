import 'package:bookplayz/api/api_constants.dart';
import 'package:bookplayz/models/booking_model.dart';
import 'package:bookplayz/models/venue_detail_model.dart';
import 'package:bookplayz/models/venue_model.dart';
import 'package:bookplayz/screens/venues/booking_summary_screen.dart';
import 'package:bookplayz/theme/app_theme.dart';
import 'package:bookplayz/widgets/app_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

class BookingScreen extends StatefulWidget {
  final VenueDetailModel venue;
  final VoidCallback? onMyBookings;

  const BookingScreen({
    super.key,
    required this.venue,
    this.onMyBookings,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  // ── State ──
  int _selectedCategoryIndex = 0;

  List<BookingSubcategoryModel> _subcategories = [];
  bool _subcatLoading = false;

  BookingSubcategoryModel? _selectedSubcat;
  BookingGroundModel? _selectedGround;
  int? _expandedGroundId;

  // Date strip — 14 days from today
  late List<DateTime> _dates;
  int _selectedDateIndex = 0;

  // Time slots
  GroundAvailabilityModel? _availability;
  bool _availabilityLoading = false;
  List<String> _selectedSlots = []; // ["08:00", "09:00"]

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    _dates = List.generate(14, (i) {
      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day + i);
    });
    // Auto-load first category
    if (widget.venue.categories.isNotEmpty) {
      _loadSubcategories(widget.venue.categories[0]);
    }
  }

  VenueCategoryModel get _activeCategory =>
      widget.venue.categories[_selectedCategoryIndex];

  // ── Load subcategories for selected category ──
  Future<void> _loadSubcategories(VenueCategoryModel cat) async {
    setState(() {
      _subcatLoading = true;
      _subcategories = [];
      _selectedSubcat = null;
      _selectedGround = null;
      _expandedGroundId = null;
      _selectedSlots = [];
    });
    try {
      final list = await BookingApi.subcategoriesWithGrounds(
        venueCategoryId: cat.id,
        venueId: widget.venue.id,
      );
      debugPrint('Subcategories loaded: ${list.length} for categoryId=${cat.id}');
      if (mounted) setState(() { _subcategories = list; _subcatLoading = false; });
    } catch (e) {
      debugPrint('Subcategories error: $e');
      if (mounted) setState(() => _subcatLoading = false);
    }
  }

  // ── Load availability for selected ground + date ──
  Future<void> _loadAvailability() async {
    if (_selectedGround == null) return;
    setState(() { _availabilityLoading = true; _selectedSlots = []; });
    try {
      final date = _dates[_selectedDateIndex];
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final avail = await BookingApi.availability(
        venueId: widget.venue.id,
        groundId: _selectedGround!.id,
        date: dateStr,
      );
      if (mounted) setState(() { _availability = avail; _availabilityLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _availabilityLoading = false);
    }
  }

  // ── Generate time slots from open/close time ──
  // For today, filter out slots that have already passed
  List<String> _generateSlots() {
    final open = _parseTime(widget.venue.openTime);
    final close = _parseTime(widget.venue.closeTime);
    final slots = <String>[];
    var current = open;
    while (current < close) {
      final h = current ~/ 60;
      final m = current % 60;
      slots.add('${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}');
      current += widget.venue.slotDuration;
    }

    // For today (index 0), filter out past slots
    if (_selectedDateIndex == 0) {
      final now = DateTime.now();
      final nowMinutes = now.hour * 60 + now.minute;
      return slots.where((slot) {
        final parts = slot.split(':');
        final slotMinutes = int.parse(parts[0]) * 60 + int.parse(parts[1]);
        return slotMinutes > nowMinutes; // only future slots
      }).toList();
    }

    return slots;
  }

  int _parseTime(String t) {
    final parts = t.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  String _formatSlot(String slot) {
    final parts = slot.split(':');
    final h = int.parse(parts[0]);
    final m = parts[1];
    final period = h >= 12 ? 'PM' : 'AM';
    final h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$h12:$m $period';
  }

  // ── Slot tap — consecutive selection only ──
  void _onSlotTap(String slot) {
    final unavailable = _availability?.unavailableSlots ?? [];
    if (unavailable.contains(slot)) return;

    setState(() {
      if (_selectedSlots.isEmpty) {
        _selectedSlots = [slot];
      } else if (_selectedSlots.contains(slot)) {
        // Deselect — keep slots before this one
        final idx = _selectedSlots.indexOf(slot);
        if (idx == 0) {
          _selectedSlots = [];
        } else {
          _selectedSlots = _selectedSlots.sublist(0, idx);
        }
      } else {
        // Only allow consecutive slots
        final allSlots = _generateSlots();
        final lastSelected = _selectedSlots.last;
        final lastIdx = allSlots.indexOf(lastSelected);
        final tapIdx = allSlots.indexOf(slot);
        if (tapIdx == lastIdx + 1) {
          // Check not unavailable
          if (!unavailable.contains(slot)) {
            _selectedSlots = [..._selectedSlots, slot];
          }
        } else {
          // Start fresh
          _selectedSlots = [slot];
        }
      }
    });
  }

  // ── Build timing string ──
  String get _timingString {
    if (_selectedSlots.isEmpty) return '';
    final allSlots = _generateSlots();
    final lastIdx = allSlots.indexOf(_selectedSlots.last);
    final endSlot = lastIdx + 1 < allSlots.length
        ? allSlots[lastIdx + 1]
        : '${widget.venue.closeTime.substring(0, 5)}';
    return '${_selectedSlots.first}_$endSlot'; // "08:00_10:00"
  }

  String get _timingLabel {
    if (_selectedSlots.isEmpty) return '';
    final allSlots = _generateSlots();
    final lastIdx = allSlots.indexOf(_selectedSlots.last);
    final endSlot = lastIdx + 1 < allSlots.length
        ? allSlots[lastIdx + 1]
        : widget.venue.closeTime.substring(0, 5);
    final duration = _selectedSlots.length;
    return '${_formatSlot(_selectedSlots.first)} – ${_formatSlot(endSlot)} (${duration}h)';
  }

  // ── Navigate to booking summary ──
  Future<void> _goToSummary() async {
    if (_selectedSubcat == null || _selectedSlots.isEmpty) return;

    final request = BookingDescriptionRequest(
      venueSlug: widget.venue.slug,
      timing: _timingString,
      categoryId: _activeCategory.id,          // venueCategoryId e.g. 70 ✅
      subCategoryId: _selectedSubcat!.id,       // base subcategoryId e.g. 4 ✅
    );

    debugPrint('=== BookingDescriptionRequest ===');
    debugPrint('payload: ${request.toJson()}');
    debugPrint('timingString: $_timingString');
    debugPrint('selectedSlots: $_selectedSlots');
    debugPrint('venueSlug: ${widget.venue.slug}');
    debugPrint('activeCategory.id (venueCategoryId): ${_activeCategory.id}');
    debugPrint('activeCategory.categoryId: ${_activeCategory.categoryId}');
    debugPrint('subcat.venueSubcategoryId: ${_selectedSubcat!.venueSubcategoryId}');
    debugPrint('subcat.categoryId (base): ${_selectedSubcat!.categoryId}');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookingSummaryScreen(
          venue: widget.venue,
          request: request,
          selectedDate: _dates[_selectedDateIndex],
          selectedGround: _selectedGround,
          timingLabel: _timingLabel,
          categoryName: _activeCategory.name,
          subcategoryName: _selectedSubcat!.name,
          onMyBookings: widget.onMyBookings,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: AppColors.navyBlue,
      body: Stack(
        children: [
          // ── Scrollable body ──
          CustomScrollView(
            slivers: [
              // ── Hero image — pinned, doesn't scroll ──
              SliverAppBar(
                automaticallyImplyLeading: false,
                expandedHeight: topPad + 180,
                pinned: false,
                floating: false,
                backgroundColor: AppColors.navyBlue,
                flexibleSpace: FlexibleSpaceBar(
                  background: widget.venue.primaryImage != null
                      ? Image.network(
                          widget.venue.primaryImage!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              Container(color: AppColors.navyBlue),
                        )
                      : Container(color: AppColors.navyBlue),
                ),
              ),

              // ── White content card ──
              SliverToBoxAdapter(
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.navyBlue,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      _buildVenueHeader(),
                      const SizedBox(height: 20),
                      _buildCategoryTabs(),
                      const SizedBox(height: 16),
                      if (_subcatLoading)
                        const Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 20, vertical: 16),
                          child: Center(child: AppLoader()),
                        )
                      else if (_subcategories.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            'No subcategories available.',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.5),
                            ),
                          ),
                        )
                      else
                        _buildSubcategoryChips(),
                      const SizedBox(height: 20),
                      if (_selectedSubcat != null) _buildGroundsSection(),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // ── Back button — always on top ──
          Positioned(
            top: topPad + 8,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_rounded,
                    color: Colors.white, size: 20),
              ),
            ),
          ),

          // ── Book Now bottom bar ──
          if (_selectedSlots.isNotEmpty)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildBookNowBar(),
            ),
        ],
      ),
    );
  }

  // ── Venue header ──
  Widget _buildVenueHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.venue.name,
                  style: const TextStyle(
                    fontFamily: 'Jost',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded,
                        color: AppColors.limeGreen, size: 13),
                    const SizedBox(width: 3),
                    Text(
                      '${widget.venue.city}, ${widget.venue.state}',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.limeGreen.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              widget.venue.timingLabel,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.limeGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Category tabs ──
  Widget _buildCategoryTabs() {
    final cats = widget.venue.categories;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 96,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: cats.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              final cat = cats[i];
              final isActive = i == _selectedCategoryIndex;
              return GestureDetector(
                onTap: () {
                  if (_selectedCategoryIndex == i) return;
                  setState(() => _selectedCategoryIndex = i);
                  _loadSubcategories(cat);
                },
                child: Column(
                  children: [
                    Stack(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppColors.limeGreen
                                : AppColors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          // 4 px padding acts as the white ring — no border
                          // needed, so the inner shadow isn't hidden by it.
                          padding: isActive
                              ? const EdgeInsets.all(14)
                              : const EdgeInsets.all(4),
                          child: isActive
                              ? (cat.image != null
                                  ? _buildCatIcon(cat.image!, isActive)
                                  : Icon(Icons.sports,
                                      color: Colors.white, size: 28))
                              : Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.white,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.all(10),
                                  child: cat.image != null
                                      ? _buildCatIcon(cat.image!, isActive)
                                      : Icon(Icons.sports,
                                          color: Colors.white
                                              .withValues(alpha: 0.7),
                                          size: 28),
                                ),
                        ),
                        if (!isActive)
                          Positioned.fill(
                            child: IgnorePointer(
                              child: CustomPaint(
                                painter: const _CategoryTabInnerShadow(),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      cat.name.toUpperCase(),
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: isActive
                            ? AppColors.limeGreen
                            : Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCatIcon(String url, bool isActive) {
    final isSvg =
        url.toLowerCase().endsWith('.svg') || url.contains('.svg');
    final color = isActive ? Colors.white : AppColors.navyBlue;
    if (isSvg) {
      return SvgPicture.network(
        url,
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        placeholderBuilder: (_) => const SizedBox(),
      );
    }
    return Image.network(
      url,
      fit: BoxFit.contain,
      color: color,
      colorBlendMode: BlendMode.srcIn,
      errorBuilder: (_, __, ___) =>
          Icon(Icons.sports, color: color, size: 28),
    );
  }

  // ── Subcategory chips ──
  Widget _buildSubcategoryChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: _subcategories.map((subcat) {
          final isSelected = _selectedSubcat?.id == subcat.id;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedSubcat = subcat;
                _selectedGround = null;
                _expandedGroundId = null;
                _selectedSlots = [];
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.limeGreen
                    : AppColors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? AppColors.limeGreen
                      : AppColors.white.withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                subcat.name,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? AppColors.navyBlue
                      : Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Grounds section ──
  Widget _buildGroundsSection() {
    final grounds = _selectedSubcat!.grounds
        .where((g) => g.status == 'Active' && g.vgsStatus == 'Active')
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  color: AppColors.limeGreen,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Available Grounds',
                style: TextStyle(
                  fontFamily: 'Jost',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        if (grounds.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'No grounds available for this subcategory.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),
          )
        else
          ...grounds.map((g) => _buildGroundCard(g)),
      ],
    );
  }

  // ── Ground card ──
  Widget _buildGroundCard(BookingGroundModel ground) {
    final isExpanded = _expandedGroundId == ground.id;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isExpanded
                ? AppColors.limeGreen
                : AppColors.white.withValues(alpha: 0.12),
            width: isExpanded ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            // ── Ground header row ──
            GestureDetector(
              onTap: () {
                setState(() {
                  if (_expandedGroundId == ground.id) {
                    _expandedGroundId = null;
                    _selectedGround = null;
                    _selectedSlots = [];
                  } else {
                    _expandedGroundId = ground.id;
                    _selectedGround = ground;
                    _selectedSlots = [];
                  }
                });
                if (_expandedGroundId == ground.id) {
                  _loadAvailability();
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ground.name,
                            style: const TextStyle(
                              fontFamily: 'Jost',
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          if (ground.description != null &&
                              ground.description!.isNotEmpty)
                            Text(
                              ground.description!,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.55),
                              ),
                            ),
                        ],
                      ),
                    ),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '₹',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              color: AppColors.limeGreen,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          TextSpan(
                            text: ground.pricePerHour
                                .toStringAsFixed(0),
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.limeGreen,
                            ),
                          ),
                          TextSpan(
                            text: '/hr',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Expanded: pricing chips + date + slots ──
            if (isExpanded) ...[
              Divider(
                  height: 1,
                  color: AppColors.white.withValues(alpha: 0.1)),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Pricing chips
                    Row(
                      children: [
                        _PriceChip(
                            label: 'PER HOUR',
                            value: '₹${ground.pricePerHour.toStringAsFixed(0)}'),
                        const SizedBox(width: 10),
                        if (ground.pricePerPerson > 0)
                          _PriceChip(
                              label: 'PER PERSON',
                              value:
                                  '₹${ground.pricePerPerson.toStringAsFixed(0)}'),
                        const SizedBox(width: 10),
                        _PriceChip(
                            label: 'MIN SLOTS',
                            value:
                                '${ground.minBookingSlots}'),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Date strip
                    _buildDateStrip(),
                    const SizedBox(height: 16),

                    // Time slots
                    _availabilityLoading
                        ? const Center(child: AppLoader())
                        : _buildTimeSlots(),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Date strip — calendar style (matches venue app) ──
  static const _weekdayShort = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];

  Widget _buildDateStrip() {

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SELECT A DATE',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.45),
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 72,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _dates.length,
            itemBuilder: (_, i) {
              final date = _dates[i];
              final isSelected = i == _selectedDateIndex;
              final isToday = i == 0;
              final wdLabel = _weekdayShort[date.weekday - 1];
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDateIndex = i;
                    _selectedSlots = [];
                  });
                  _loadAvailability();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 60,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.limeGreen
                        : isToday
                            ? AppColors.limeGreen.withValues(alpha: 0.12)
                            : AppColors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: isToday && !isSelected
                        ? Border.all(
                            color: AppColors.limeGreen.withValues(alpha: 0.5))
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        wdLabel,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isSelected
                              ? AppColors.navyBlue
                              : Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${date.day}',
                        style: TextStyle(
                          fontFamily: 'Jost',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? AppColors.navyBlue : Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _monthShort[date.month - 1],
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10,
                          color: isSelected
                              ? AppColors.navyBlue.withValues(alpha: 0.7)
                              : Colors.white.withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  static const _monthShort = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  // ── Time slots — dark theme ──
  Widget _buildTimeSlots() {
    final allSlots = _generateSlots();
    final unavailable = _availability?.unavailableSlots ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'SELECT A TIME',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.45),
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: allSlots.map((slot) {
            final isSelected = _selectedSlots.contains(slot);
            final isUnavailable = unavailable.contains(slot);

            Color bgColor;
            Color borderColor;
            Color textColor;

            if (isUnavailable) {
              bgColor = Colors.red.withValues(alpha: 0.08);
              borderColor = Colors.red.withValues(alpha: 0.3);
              textColor = Colors.red.withValues(alpha: 0.5);
            } else if (isSelected) {
              bgColor = AppColors.limeGreen;
              borderColor = AppColors.limeGreen;
              textColor = Colors.white;
            } else {
              bgColor = AppColors.white.withValues(alpha: 0.07);
              borderColor = AppColors.white.withValues(alpha: 0.15);
              textColor = Colors.white.withValues(alpha: 0.85);
            }

            return GestureDetector(
              onTap: () => _onSlotTap(slot),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderColor),
                ),
                child: Text(
                  _formatSlot(slot),
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _Legend(color: Colors.red.withValues(alpha: 0.7), label: 'Booked'),
            const SizedBox(width: 16),
            _Legend(
                color: Colors.white.withValues(alpha: 0.3),
                label: 'Blocked'),
            const SizedBox(width: 16),
            _Legend(
                color: Colors.white.withValues(alpha: 0.15),
                label: 'Available'),
          ],
        ),
      ],
    );
  }

  // ── Book Now bottom bar ──
  Widget _buildBookNowBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: AppColors.navyBlue,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: GestureDetector(
        onTap: _goToSummary,
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            color: AppColors.limeGreen,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.limeGreen.withValues(alpha: 0.4),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Book Now',
                style: TextStyle(
                  fontFamily: 'Jost',
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '• $_timingLabel',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Price chip ──
class _PriceChip extends StatelessWidget {
  final String label;
  final String value;
  const _PriceChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 9,
              color: Colors.white.withValues(alpha: 0.5),
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Legend item ──
class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 10,
            color: Colors.white.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}

class _CategoryTabInnerShadow extends CustomPainter {
  const _CategoryTabInnerShadow();

  static const double _r = 8;
  static const double _b = 7;
  static const Color _c = Color.fromARGB(205, 0, 0, 0);

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(_r),
    );

    // Clip to the rounded rect — each shadow rect sits just outside the
    // boundary so only the inward-bleeding blur is visible, keeping the
    // centre white.
    canvas.save();
    canvas.clipRRect(rrect);

    final paint = Paint()
      ..color = _c
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, _b);

    final w = size.width;
    final h = size.height;
    const b = _b;

    canvas.drawRect(Rect.fromLTWH(-b, -b * 2, w + b * 2, b * 2), paint);
    canvas.drawRect(Rect.fromLTWH(-b, h, w + b * 2, b * 2), paint);
    canvas.drawRect(Rect.fromLTWH(-b * 2, -b, b * 2, h + b * 2), paint);
    canvas.drawRect(Rect.fromLTWH(w, -b, b * 2, h + b * 2), paint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(_CategoryTabInnerShadow old) => false;
}