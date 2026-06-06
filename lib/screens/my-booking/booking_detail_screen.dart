import 'package:bookplayz/api/api_constants.dart';
import 'package:bookplayz/api/api_service.dart';
import 'package:bookplayz/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Booking Detail Screen
// ─────────────────────────────────────────────────────────────────────────────
class BookingDetailScreen extends StatefulWidget {
  final int bookingId;
  final String bookingCode;

  const BookingDetailScreen({
    super.key,
    required this.bookingId,
    required this.bookingCode,
  });

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;

  // ── Data accessors ──────────────────────────────────────────────────────────

  String _s(String key, [String fallback = '']) =>
      _data?[key]?.toString() ?? fallback;

  int _i(String key, [int fallback = 0]) {
    final v = _data?[key];
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? fallback;
  }

  double? _d(String key) {
    final v = _data?[key];
    if (v == null) return null;
    if (v is double) return v;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  Map<String, dynamic>? get _payment =>
      _data?['payment'] as Map<String, dynamic>?;

  String _ps(String key, [String fallback = '']) =>
      _payment?[key]?.toString() ?? fallback;

  // ── Location ────────────────────────────────────────────────────────────────

  double? get _lat => _d('venueLatitude');
  double? get _lng => _d('venueLongitude');

  // ── Time formatting ─────────────────────────────────────────────────────────

  String _fmtTime(String t) {
    try {
      final parts = t.split(':');
      final h = int.parse(parts[0]);
      final m = parts[1];
      final period = h >= 12 ? 'PM' : 'AM';
      final hour = h > 12 ? h - 12 : (h == 0 ? 12 : h);
      return '$hour:$m $period';
    } catch (_) {
      return t;
    }
  }

  String get _timeSlot {
    final start = _s('startTime');
    final end = _s('endTime');
    if (start.isEmpty && end.isEmpty) return '';
    return '${_fmtTime(start)} – ${_fmtTime(end)}';
  }

  String get _formattedDate {
    try {
      final raw = _s('bookingDate');
      if (raw.isEmpty) return '';
      final dt = DateTime.parse(raw);
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${dt.day.toString().padLeft(2, '0')} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return _s('bookingDate');
    }
  }

  // ── Status helpers ──────────────────────────────────────────────────────────

  Color get _statusColor {
    switch (_s('status')) {
      case 'confirmed':
        return const Color(0xFF2196F3);
      case 'completed':
        return const Color(0xFF4CAF50);
      case 'cancelled':
        return const Color(0xFFEF4444);
      case 'pending':
        return const Color(0xFFF59E0B);
      default:
        return Colors.grey;
    }
  }

  String get _statusLabel {
    final s = _s('status');
    if (s.isEmpty) return '';
    return s[0].toUpperCase() + s.substring(1);
  }

  // ── Lifecycle ───────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    if (mounted) setState(() { _loading = true; _error = null; });
    try {
      final res = await ApiService.instance.get(
        BookingDetailApi.byId(widget.bookingId),
      );
      final data = res['data'];
      if (mounted) {
        setState(() {
          _data = data as Map<String, dynamic>?;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = e.toString(); });
    }
  }

  Future<void> _openMaps() async {
    final lat = _lat;
    final lng = _lng;
    if (lat == null || lng == null) return;
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navyBlue,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF7F8FA),
                borderRadius: BorderRadius.circular(20),
              ),
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.limeGreen,
                      ),
                    )
                  : _error != null
                      ? _buildError()
                      : _buildBody(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final code = _data != null ? _s('bookingCode') : widget.bookingCode;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Booking Details',
              style: const TextStyle(
                fontFamily: 'Jost',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          // Status badge
          if (code.isNotEmpty && _data != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _statusColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _statusLabel,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 56,
              color: Colors.red.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'Could not load booking details',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0A2540),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? '',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: _fetch,
              child: Text(
                'Retry',
                style: TextStyle(color: AppColors.navyBlue),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    final hasLocation = _lat != null && _lng != null;
    final hasTransaction =
        _ps('gatewayOrderId').isNotEmpty || _ps('gatewayPaymentId').isNotEmpty;

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        const SizedBox(height: 8),

        // Venue card
        _buildVenueCard(),

        // Map (only if lat/lng available)
        if (hasLocation) _buildMapCard(),

        // Venue section
        _buildSection(
          icon: Icons.location_city_rounded,
          title: 'VENUE',
          children: [
            _DetailRow(label: 'Ground', value: _s('groundName')),
            _DetailRow(label: 'Sport', value: _s('sport')),
            _DetailRow(
              label: 'Address',
              value: '${_s('venueCity')}, ${_s('venueState')}',
            ),
          ],
        ),

        // Schedule section
        _buildSection(
          icon: Icons.schedule_rounded,
          title: 'SCHEDULE',
          children: [
            _DetailRow(label: 'Date', value: _formattedDate),
            _DetailRow(label: 'Time', value: _timeSlot),
            _DetailRow(label: 'Duration', value: '${_i('durationMinutes')} min'),
            _DetailRow(
              label: 'Players',
              value: _i('numberOfPersons').toString(),
            ),
          ],
        ),

        // Payment section
        _buildPaymentSection(),

        // Transaction section (only if gateway IDs present)
        if (hasTransaction)
          _buildSection(
            icon: Icons.receipt_long_rounded,
            title: 'TRANSACTION',
            children: [
              if (_ps('gatewayOrderId').isNotEmpty)
                _DetailRow(
                  label: 'Order ID',
                  value: _ps('gatewayOrderId'),
                  small: true,
                ),
              if (_ps('gatewayPaymentId').isNotEmpty)
                _DetailRow(
                  label: 'Payment ID',
                  value: _ps('gatewayPaymentId'),
                  small: true,
                ),
            ],
          ),

        // Booking code card
        _buildBookingCodeCard(),

        // Get Directions button
        if (hasLocation) _buildDirectionsButton(),
      ],
    );
  }

  // ── Venue Card ──────────────────────────────────────────────────────────────

  Widget _buildVenueCard() {
    final imageUrl = _s('primaryVenueImage');
    final totalAmt = _s('totalAmount');
    final subcategory = _s('subcategoryName');

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(14),
              bottomLeft: Radius.circular(14),
            ),
            child: imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    width: 72,
                    height: 110,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stack) => Container(
                      width: 72,
                      height: 110,
                      color: AppColors.navyBlue.withValues(alpha: 0.15),
                      child: const Icon(
                        Icons.sports_outlined,
                        color: AppColors.navyBlue,
                      ),
                    ),
                  )
                : Container(
                    width: 72,
                    height: 110,
                    color: AppColors.navyBlue.withValues(alpha: 0.15),
                    child: const Icon(
                      Icons.sports_outlined,
                      color: AppColors.navyBlue,
                    ),
                  ),
          ),
          // Details
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _s('venueName'),
                    style: const TextStyle(
                      fontFamily: 'Jost',
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0A2540),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        size: 13,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          '${_s('venueCity')}, ${_s('venueState')}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (subcategory.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.limeGreen.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        subcategory,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.limeGreen.withValues(alpha: 0.85),
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  if (totalAmt.isNotEmpty)
                    Text(
                      '₹$totalAmt',
                      style: const TextStyle(
                        fontFamily: 'Anton',
                        fontSize: 18,
                        color: Color(0xFF0A2540),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Map Card ────────────────────────────────────────────────────────────────

  Widget _buildMapCard() {
    final lat = _lat!;
    final lng = _lng!;
    final center = LatLng(lat, lng);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(
          children: [
            SizedBox(
              height: 160,
              child: IgnorePointer(
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: center,
                    initialZoom: 15,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.bookplayz.app',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: center,
                          width: 36,
                          height: 36,
                          child: const Icon(
                            Icons.location_pin,
                            color: Colors.red,
                            size: 36,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Address strip
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _s('venueAddress'),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF0A2540),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _openMaps,
                    child: Text(
                      'Open Maps',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.limeGreen,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Generic Section ─────────────────────────────────────────────────────────

  Widget _buildSection({
    required IconData icon,
    required String title,
    required List<Widget> children,
    Widget? headerTrailing,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.navyBlue.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Icon(icon, size: 16, color: AppColors.navyBlue),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: AppColors.navyBlue,
                    ),
                  ),
                ),
                ?headerTrailing,
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)),
          ...children,
        ],
      ),
    );
  }

  // ── Payment Section ─────────────────────────────────────────────────────────

  Widget _buildPaymentSection() {
    final isPartPayment = _data?['isPartPayment'] == true;
    final basePrice = _d('basePrice') ?? 0.0;
    final serviceFee = _d('serviceFee') ?? 0.0;
    final couponDiscount = _d('couponDiscount') ?? 0.0;
    final totalAmount = _d('totalAmount') ?? 0.0;
    final paidAmount = _d('paidAmount') ?? 0.0;
    final remainingAmount = _d('remainingAmount') ?? 0.0;
    final paymentStatus = _ps('status').isNotEmpty
        ? _ps('status')
        : _s('paymentStatus');

    return _buildSection(
      icon: Icons.payments_rounded,
      title: 'PAYMENT',
      headerTrailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isPartPayment
              ? Colors.amber.withValues(alpha: 0.15)
              : AppColors.limeGreen.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          isPartPayment ? 'Part Payment' : 'Full Payment',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: isPartPayment ? Colors.amber.shade700 : AppColors.limeGreen,
          ),
        ),
      ),
      children: [
        _DetailRow(
          label: 'Booking type',
          value: _s('bookingType').isEmpty
              ? ''
              : _s('bookingType')[0].toUpperCase() +
                  _s('bookingType').substring(1),
        ),
        _DetailRow(
          label: 'Payment method',
          value: _s('paymentMethod').isEmpty
              ? ''
              : _s('paymentMethod')[0].toUpperCase() +
                  _s('paymentMethod').substring(1),
        ),
        _DetailRow(
          label: 'Base price',
          value: '₹${basePrice.toStringAsFixed(2)}',
        ),
        if (serviceFee > 0)
          _DetailRow(
            label: 'Service charge',
            value: '+₹${serviceFee.toStringAsFixed(2)}',
          ),
        if (couponDiscount > 0)
          _DetailRow(
            label: 'Coupon discount',
            value: '-₹${couponDiscount.toStringAsFixed(2)}',
            valueColor: const Color(0xFF22C55E),
          ),
        const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)),
        // Total row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: const Text(
                  'Total',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0A2540),
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  '₹${totalAmount.toStringAsFixed(2)}',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontFamily: 'Anton',
                    fontSize: 14,
                    color: AppColors.navyBlue,
                  ),
                ),
              ),
            ],
          ),
        ),
        _DetailRow(
          label: 'Amount paid',
          value: '₹${paidAmount.toStringAsFixed(2)}',
          valueColor: const Color(0xFF22C55E),
        ),
        if (remainingAmount > 0)
          _DetailRow(
            label: 'Remaining',
            value: '₹${remainingAmount.toStringAsFixed(2)}',
            valueColor: const Color(0xFFEF4444),
          ),
        // Payment status chip row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: const Text(
                  'Payment status',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: _StatusChip(status: paymentStatus),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Booking Code Card ───────────────────────────────────────────────────────

  Widget _buildBookingCodeCard() {
    final code = _s('bookingCode').isEmpty
        ? widget.bookingCode
        : _s('bookingCode');

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.navyBlue,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Booking Code',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  code,
                  style: const TextStyle(
                    fontFamily: 'Anton',
                    fontSize: 18,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy_rounded, color: Colors.white70),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: code));
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Booking code copied!'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  // ── Get Directions Button ───────────────────────────────────────────────────

  Widget _buildDirectionsButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton.icon(
          onPressed: _openMaps,
          icon: const Icon(
            Icons.directions_rounded,
            color: AppColors.navyBlue,
          ),
          label: const Text(
            'Get Directions',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.navyBlue,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.limeGreen,
            foregroundColor: AppColors.navyBlue,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _DetailRow
// ─────────────────────────────────────────────────────────────────────────────
class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool small;

  const _DetailRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    final fontSize = small ? 11.0 : 13.0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: fontSize,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                color: valueColor ?? const Color(0xFF0A2540),
              ),
              overflow: small ? TextOverflow.ellipsis : null,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _StatusChip
// ─────────────────────────────────────────────────────────────────────────────
class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  Color get _color {
    switch (status.toLowerCase()) {
      case 'paid':
      case 'completed':
        return const Color(0xFF22C55E);
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'failed':
        return const Color(0xFFEF4444);
      default:
        return Colors.grey;
    }
  }

  String get _label {
    if (status.isEmpty) return '';
    return status[0].toUpperCase() + status.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final c = _color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        border: Border.all(color: c.withValues(alpha: 0.30)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: c,
        ),
      ),
    );
  }
}
