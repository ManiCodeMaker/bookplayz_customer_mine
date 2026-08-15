import 'package:bookplayz/api/api_constants.dart';
import 'package:bookplayz/api/api_service.dart';
import 'package:bookplayz/api/session_manager.dart';
import 'package:bookplayz/models/my_booking_model.dart';
import 'package:bookplayz/screens/my-booking/booking_detail_screen.dart';
import 'package:bookplayz/screens/my-booking/write_review.dart';
import 'package:bookplayz/theme/app_constants.dart';
import 'package:bookplayz/widgets/app_loader.dart';
import 'package:bookplayz/widgets/app_snackbar.dart';
import 'package:bookplayz/widgets/cancellation_sheet.dart';
import 'package:bookplayz/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

// ─────────────────────────────────────────────────────────
// Tab enum
// ─────────────────────────────────────────────────────────
enum _BookingTab { upcoming, completed, cancelled }

// ─────────────────────────────────────────────────────────
// MyBookingScreen
// ─────────────────────────────────────────────────────────
class MyBookingScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final GlobalKey<NavigatorState>? navigatorKey;

  const MyBookingScreen({
    super.key,
    this.onBack,
    this.navigatorKey,
  });

  @override
  MyBookingScreenState createState() => MyBookingScreenState();
}

class MyBookingScreenState extends State<MyBookingScreen> {
  late final GlobalKey<NavigatorState> _navigatorKey =
      widget.navigatorKey ?? GlobalKey<NavigatorState>();

  final GlobalKey<_BookingHomeState> _homeKey = GlobalKey<_BookingHomeState>();

  List<MyBookingModel> _upcomingBookings  = [];
  List<MyBookingModel> _completedBookings = [];
  List<MyBookingModel> _cancelledBookings = [];
  bool    _loading = false;
  String? _loadError;

  // Always re-fetch fresh data and reset to Upcoming tab.
  void onTabActivated() {
    _homeKey.currentState?.resetToUpcoming();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    if (mounted) setState(() { _loading = true; _loadError = null; });

    try {
      final results = await Future.wait([
        ApiService.instance.get(MyBookingsApi.upcoming()),
        ApiService.instance.get(MyBookingsApi.history()),
      ]);

      final upcomingList = _parseList(results[0]);
      final historyList  = _parseList(results[1]);

      if (mounted) {
        setState(() {
          _upcomingBookings  = upcomingList;
          _completedBookings = historyList.where((b) => b.isCompleted).toList();
          _cancelledBookings = historyList.where((b) => b.isCancelled).toList();
          _loading   = false;
          _loadError = null;
        });
      }
    } catch (e) {
      debugPrint('[MyBookings] Error: $e');
      if (mounted) setState(() { _loading = false; _loadError = e.toString(); });
    }
  }

  // Handles both flat `data: [...]` and paginated `data: {data: [...]}` shapes.
  static List<MyBookingModel> _parseList(Map<String, dynamic> res) {
    final raw = res['data'];
    List<dynamic> items;
    if (raw is List) {
      items = raw;
    } else if (raw is Map) {
      final inner = raw['data'];
      items = inner is List ? inner : [];
    } else {
      items = [];
    }
    return items
        .whereType<Map<String, dynamic>>()
        .map(MyBookingModel.fromJson)
        .toList();
  }

  void _handlePop() {
    if (_navigatorKey.currentState?.canPop() ?? false) {
      _navigatorKey.currentState?.pop();
    } else {
      widget.onBack?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handlePop();
      },
      child: Navigator(
        key: _navigatorKey,
        onGenerateRoute: (settings) => MaterialPageRoute(
          builder: (_) => _BookingHome(
            key:               _homeKey,
            onRefresh:         _loadBookings,
            upcomingBookings:  _upcomingBookings,
            completedBookings: _completedBookings,
            cancelledBookings: _cancelledBookings,
            loading:           _loading,
            loadError:         _loadError,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Booking Home
// ─────────────────────────────────────────────────────────
class _BookingHome extends StatefulWidget {
  final Future<void> Function()? onRefresh;
  final List<MyBookingModel> upcomingBookings;
  final List<MyBookingModel> completedBookings;
  final List<MyBookingModel> cancelledBookings;
  final bool    loading;
  final String? loadError;

  const _BookingHome({
    super.key,
    this.onRefresh,
    this.upcomingBookings  = const [],
    this.completedBookings = const [],
    this.cancelledBookings = const [],
    this.loading   = false,
    this.loadError,
  });

  @override
  State<_BookingHome> createState() => _BookingHomeState();
}

class _BookingHomeState extends State<_BookingHome> {
  _BookingTab _tab = _BookingTab.upcoming;

  void resetToUpcoming() => setState(() => _tab = _BookingTab.upcoming);

  List<MyBookingModel> get _currentList {
    switch (_tab) {
      case _BookingTab.upcoming:  return widget.upcomingBookings;
      case _BookingTab.completed: return widget.completedBookings;
      case _BookingTab.cancelled: return widget.cancelledBookings;
    }
  }

  String get _emptyTitle {
    switch (_tab) {
      case _BookingTab.upcoming:  return 'No Upcoming Bookings';
      case _BookingTab.completed: return 'No Completed Bookings';
      case _BookingTab.cancelled: return 'No Cancelled Bookings';
    }
  }

  String get _emptySubtitle {
    switch (_tab) {
      case _BookingTab.upcoming:
        return 'Your confirmed bookings will appear here';
      case _BookingTab.completed:
        return 'Bookings you have completed will appear here';
      case _BookingTab.cancelled:
        return 'Bookings that were cancelled will appear here';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.navyBlue,
      child: Column(
        children: [
          // ── Title bar ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Center(
              child: Text(
                'My Bookings',
                style: TextStyle(
                  fontFamily: 'Anton',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Card area with floating toggle ───────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // ── Main card container ──────────────────────────
                  Container(
                    margin: const EdgeInsets.only(top: 30),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F4E8),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: RefreshIndicator(
                      color:           AppColors.limeGreen,
                      backgroundColor: AppColors.navyBlue,
                      onRefresh: () async => widget.onRefresh?.call(),
                      child: widget.loading
                          ? const Center(
                              child: AppLoader(color: AppLoaderColor.black),
                            )
                          : widget.loadError != null
                              ? ListView(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  children: [
                                    SizedBox(
                                      height: 300,
                                      child: _EmptyState(
                                        title:    'Could not load bookings',
                                        subtitle: 'Pull down to retry',
                                        isError:  true,
                                      ),
                                    ),
                                  ],
                                )
                          : _currentList.isEmpty
                              ? ListView(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  children: [
                                    SizedBox(
                                      height: 300,
                                      child: _EmptyState(
                                        title:    _emptyTitle,
                                        subtitle: _emptySubtitle,
                                      ),
                                    ),
                                  ],
                                )
                              : ListView.separated(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  padding: const EdgeInsets.fromLTRB(
                                      16, 30, 16, 20),
                                  itemCount: _currentList.length,
                                  separatorBuilder: (_, _) =>
                                      const SizedBox(height: 16),
                                  itemBuilder: (_, i) => _BookingCard(
                                    booking: _currentList[i],
                                    onCancelled: widget.onRefresh,
                                  ),
                                ),
                    ),
                  ),

                  // ── Floating 3-tab toggle ────────────────────────
                  Positioned(
                    top:   0,
                    left:  0,
                    right: 0,
                    child: Center(
                      child: _BookingToggle3Switch(
                        activeTab: _tab,
                        onChanged: (t) => setState(() => _tab = t),
                      ),
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
}

// ─────────────────────────────────────────────────────────
// 3-Tab Toggle Switch
// ─────────────────────────────────────────────────────────
class _BookingToggle3Switch extends StatelessWidget {
  final _BookingTab activeTab;
  final ValueChanged<_BookingTab> onChanged;

  const _BookingToggle3Switch({
    required this.activeTab,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width * 0.9;
    final segW  = width / 3;

    const tabs   = [_BookingTab.upcoming, _BookingTab.completed, _BookingTab.cancelled];
    const labels = ['Upcoming', 'Completed', 'Cancelled'];
    final activeIndex = tabs.indexOf(activeTab);

    return Container(
      height: 50,
      width:  width,
      decoration: BoxDecoration(
        color:        const Color(0xFFDEE4CB),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Stack(
        children: [
          // ── Animated pill ──────────────────────────────────────
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve:    Curves.easeInOut,
            left:     activeIndex * segW + 4,
            top:      3,
            bottom:   4,
            width:    segW - 8,
            child: Container(
              decoration: BoxDecoration(
                color:        AppColors.white,
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color:      Colors.black.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset:     const Offset(0, 4),
                  ),
                ],
              ),
            ),
          ),

          // ── Labels ─────────────────────────────────────────────
          Row(
            children: List.generate(tabs.length, (i) {
              final isActive = activeTab == tabs[i];
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap:    () => onChanged(tabs[i]),
                  child: Center(
                    child: Text(
                      labels[i],
                      style: TextStyle(
                        fontSize:   12,
                        fontWeight: FontWeight.w600,
                        color: isActive ? AppColors.navyBlue : Colors.black54,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Booking Card
// ─────────────────────────────────────────────────────────
class _BookingCard extends StatefulWidget {
  final MyBookingModel booking;
  final Future<void> Function()? onCancelled;

  const _BookingCard({required this.booking, this.onCancelled});

  @override
  State<_BookingCard> createState() => _BookingCardState();
}

class _BookingCardState extends State<_BookingCard> {
  int? _reviewId;
  bool _isCancelling = false;

  bool _payingBalance = false;
  double? _chargedAmount;
  late Razorpay _razorpay;

  @override
  void initState() {
    super.initState();
    _reviewId = widget.booking.reviewId;
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onBalancePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onBalancePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, (_) {
      if (mounted) setState(() => _payingBalance = false);
    });
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  // ── Pay remaining balance online ─────────────────────────────────────────────
  Future<void> _payRemainingBalance() async {
    if (_payingBalance) return;
    setState(() => _payingBalance = true);
    try {
      final orderData = await PaymentApi.createOrder({
        'bookingId':     widget.booking.id,
        'paymentMethod': 'online',
      });
      final gatewayConfig = orderData['gatewayConfig'] as Map<String, dynamic>?;
      if (gatewayConfig == null) throw Exception('Failed to create payment order.');

      final gatewayAmountPaise = gatewayConfig['amount'];
      _chargedAmount = gatewayAmountPaise is num
          ? gatewayAmountPaise.toDouble() / 100
          : null;

      final user = SessionManager.instance.currentUser;
      final options = {
        'key':         gatewayConfig['key'] ?? gatewayConfig['keyId'],
        'amount':      gatewayConfig['amount'],
        'currency':    gatewayConfig['currency'] ?? 'INR',
        'order_id':    gatewayConfig['order_id'] ?? gatewayConfig['orderId'],
        'name':        'BookPlayz',
        'description': 'Balance payment for Booking #${widget.booking.id}',
        'prefill': {
          'name':    user?.fullName ?? '',
          'email':   user?.email ?? '',
          'contact': user?.mobile ?? '',
        },
        'theme': {'color': '#9CCE00'},
      };
      _razorpay.open(options);
    } catch (e) {
      if (mounted) {
        setState(() => _payingBalance = false);
        AppSnackbar.showError(
            context, e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  Future<void> _onBalancePaymentSuccess(PaymentSuccessResponse response) async {
    try {
      await PaymentApi.verifyPayment(
        orderId:   response.orderId!,
        paymentId: response.paymentId!,
        signature: response.signature!,
        amount:    _chargedAmount ?? 0,
        bookingId: widget.booking.id,
      );
      if (mounted) {
        setState(() => _payingBalance = false);
        AppSnackbar.showSuccess(context, 'Balance payment successful!');
      }
      await widget.onCancelled?.call();
    } catch (e) {
      if (mounted) {
        setState(() => _payingBalance = false);
        AppSnackbar.showError(context,
            'Payment succeeded but update failed. Please contact support.');
      }
    }
  }

  void _onBalancePaymentError(PaymentFailureResponse response) {
    if (!mounted) return;
    setState(() => _payingBalance = false);
    final msg = response.message ?? '';
    final isCancelled = response.code == Razorpay.PAYMENT_CANCELLED ||
        msg.isEmpty || msg.toLowerCase() == 'undefined';
    AppSnackbar.showError(context, isCancelled ? 'Payment cancelled.' : msg);
  }

  Future<void> _showCancelSheet() async {
    await showCancellationSheet(
      context: context,
      bookingId: widget.booking.id,
      onCancelled: () => widget.onCancelled?.call(),
      setLoading: (v) { if (mounted) setState(() => _isCancelling = v); },
    );
  }

  void _openDetails(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => BookingDetailScreen(
        bookingId:   widget.booking.id,
        bookingCode: widget.booking.bookingCode,
      ),
    ));
  }

  Future<void> _openReviewSheet() async {
    final result = await showModalBottomSheet<Map<String, dynamic>?>(
      context:              context,
      isScrollControlled:   true,
      backgroundColor:      Colors.transparent,
      useRootNavigator:     true,
      builder: (_) => WriteReviewSheet(
        booking:  widget.booking,
        reviewId: _reviewId,
      ),
    );
    if (result == null || !mounted) return;
    if (result['deleted'] == true) {
      setState(() => _reviewId = null);
      AppSnackbar.showSuccess(context, 'Review deleted');
    } else if (result['id'] != null) {
      final wasEdit = _reviewId != null;
      setState(() => _reviewId = result['id'] as int);
      AppSnackbar.showSuccess(
        context,
        wasEdit ? 'Review updated successfully' : 'Review submitted for approval',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    final isPartial = booking.paymentStatus == 'partial';
    return Container(
      height: isPartial ? 240 : 200,
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withValues(alpha: 0.3),
            blurRadius: 14,
            offset:     const Offset(0, 0),
          ),
        ],
      ),
      child: Row(
        children: [
          // ── Left: image + status badge ─────────────────────────
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft:    Radius.circular(10),
              bottomLeft: Radius.circular(10),
            ),
            child: Stack(
              children: [
                booking.primaryVenueImage != null &&
                        booking.primaryVenueImage!.isNotEmpty
                    ? Image.network(
                        booking.primaryVenueImage!,
                        width:  120,
                        height: double.infinity,
                        fit:    BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            const _NoImagePlaceholder(),
                        loadingBuilder: (_, child, progress) =>
                            progress == null
                                ? child
                                : Container(
                                    width: 120,
                                    color: AppColors.navyBlue
                                        .withValues(alpha: 0.3),
                                    child: const Center(
                                      child: AppLoader(
                                        size: 60,
                                        color: AppLoaderColor.black,
                                      ),
                                    ),
                                  ),
                      )
                    : const _NoImagePlaceholder(),

                // Status badge
                Positioned(
                  top:  12,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color:        booking.statusColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color:      booking.statusColor.withValues(alpha: 0.35),
                          blurRadius: 14,
                          spreadRadius: 1,
                          offset:     const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Text(
                      booking.statusLabel,
                      style: const TextStyle(
                        fontSize:   10,
                        fontWeight: FontWeight.w700,
                        color:      Colors.white,
                      ),
                    ),
                  ),
                ),

                // Partial payment badge
                if (booking.paymentStatus == 'partial')
                  Positioned(
                    bottom: 12,
                    left:   10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color:        Colors.amber.shade700,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color:      Colors.amber.withValues(alpha: 0.35),
                            blurRadius: 14,
                            spreadRadius: 1,
                            offset:     const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Text(
                        'Partial Payment',
                        style: TextStyle(
                          fontSize:   10,
                          fontWeight: FontWeight.w700,
                          color:      Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── Right: details + buttons ───────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    booking.sport,
                    style: const TextStyle(
                      fontSize:   16,
                      fontWeight: FontWeight.w800,
                      color:      Color(0xFF0A2540),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  _InfoRow(
                    imagePath: AppImages.bookingDate,
                    text:      booking.formattedDate,
                  ),
                  const SizedBox(height: 5),
                  _InfoRow(
                    imagePath: AppImages.bookingPrice,
                    text:      booking.displayAmount,
                  ),
                  const SizedBox(height: 5),
                  _InfoRow(
                    imagePath: AppImages.bookingTime,
                    text:      booking.timeSlot,
                  ),
                  const SizedBox(height: 5),

                  // Location row
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size:  16,
                        color: Color(0xFF295282),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          booking.location,
                          style: const TextStyle(
                            fontSize:   12,
                            fontWeight: FontWeight.w400,
                            color:      Color(0xFF9CA4AB),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: _ActionButton(
                          label:     'View Details',
                          color:     AppColors.limeGreen,
                          textColor: Colors.white,
                          onTap:     () => _openDetails(context),
                        ),
                      ),
                      if (booking.status == 'pending' ||
                          booking.status == 'confirmed') ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: _ActionButton(
                            label:     _isCancelling ? '...' : 'Cancel',
                            color:     const Color(0xFFFF5252),
                            textColor: Colors.white,
                            onTap:     _isCancelling ? null : _showCancelSheet,
                          ),
                        ),
                      ],
                      if (booking.isCompleted) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: _ActionButton(
                            label:    _reviewId == null
                                ? 'Write Review'
                                : 'Edit Review',
                            color:    Colors.white,
                            textColor: AppColors.navyBlue,
                            bordered:  true,
                            onTap:     _openReviewSheet,
                          ),
                        ),
                      ],
                    ],
                  ),

                  if (isPartial) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: _ActionButton(
                        label: _payingBalance
                            ? 'Processing…'
                            : 'Pay Remaining Balance Online',
                        color: const Color(0xFFFF7A1A),
                        textColor: Colors.white,
                        onTap: _payingBalance ? null : _payRemainingBalance,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Info Row
// ─────────────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final String imagePath;
  final String text;

  const _InfoRow({required this.imagePath, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width:  24,
          height: 24,
          decoration: BoxDecoration(
            color:        AppColors.navyBlue.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Image.asset(imagePath, fit: BoxFit.contain),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontFamily: 'Anton',
              fontSize:   13,
              fontWeight: FontWeight.w600,
              color:      Color(0xFF0A2540),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────
// Action Button
// ─────────────────────────────────────────────────────────
class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;
  final bool bordered;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.label,
    required this.color,
    required this.textColor,
    this.bordered = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 24,
        decoration: BoxDecoration(
          color:        color,
          borderRadius: BorderRadius.circular(25),
          border: bordered
              ? Border.all(color: AppColors.navyBlue, width: 1)
              : null,
          boxShadow: bordered
              ? null
              : [
                  BoxShadow(
                    color:        color.withValues(alpha: 0.35),
                    blurRadius:   14,
                    spreadRadius: 1,
                    offset:       const Offset(0, 6),
                  ),
                ],
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize:   10,
                fontWeight: FontWeight.w700,
                color:      textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// No Image Placeholder
// ─────────────────────────────────────────────────────────
class _NoImagePlaceholder extends StatelessWidget {
  const _NoImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width:  120,
      height: double.infinity,
      color:  AppColors.navyBlue.withValues(alpha: 0.12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported_outlined,
            size:  32,
            color: AppColors.navyBlue.withValues(alpha: 0.45),
          ),
          const SizedBox(height: 6),
          Text(
            'No Image',
            style: TextStyle(
              fontSize:   10,
              fontWeight: FontWeight.w600,
              color:      AppColors.navyBlue.withValues(alpha: 0.45),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Empty State
// ─────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool   isError;

  const _EmptyState({
    required this.title,
    required this.subtitle,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isError ? Icons.wifi_off_rounded : Icons.calendar_today_outlined,
              size:  56,
              color: (isError ? Colors.red : AppColors.navyBlue)
                  .withValues(alpha: 0.35),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize:   16,
                fontWeight: FontWeight.w700,
                color:      Color(0xFF0A2540),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize:   13,
                color:      Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
