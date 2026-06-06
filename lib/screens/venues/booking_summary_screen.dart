import 'package:bookplayz/api/api_constants.dart';
import 'package:bookplayz/api/api_service.dart';
import 'package:bookplayz/api/session_manager.dart';
import 'package:bookplayz/models/booking_model.dart';
import 'package:bookplayz/models/venue_detail_model.dart';
import 'package:bookplayz/screens/venues/booking_confirmation_screen.dart';
import 'package:bookplayz/widgets/app_snackbar.dart';
import 'package:bookplayz/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class BookingSummaryScreen extends StatefulWidget {
  final VenueDetailModel venue;
  final BookingDescriptionRequest request;
  final DateTime selectedDate;
  final BookingGroundModel? selectedGround;
  final String timingLabel;
  final String categoryName;
  final String subcategoryName;
  final VoidCallback? onMyBookings;

  const BookingSummaryScreen({
    super.key,
    required this.venue,
    required this.request,
    required this.selectedDate,
    required this.selectedGround,
    required this.timingLabel,
    required this.categoryName,
    required this.subcategoryName,
    this.onMyBookings,
  });

  @override
  State<BookingSummaryScreen> createState() => _BookingSummaryScreenState();
}

class _BookingSummaryScreenState extends State<BookingSummaryScreen> {
  BookingDescriptionModel? _desc;
  bool _loading = true;
  String? _error;

  // Payment state
  bool _paymentLoading = false;
  int? _slotLockId;
  int? _bookingId; // stored after createBooking succeeds
  late Razorpay _razorpay;

  // Coupon
  final _couponController = TextEditingController();
  bool _couponLoading = false;
  String? _couponError;
  Map<String, dynamic>? _appliedCoupon;

  int _activeStep = 1;

  @override
  void initState() {
    super.initState();
    _fetchDescription();
    _initRazorpay();
  }

  void _initRazorpay() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);
  }

 Future<void> _openGoogleMaps() async {
    final lat = widget.venue.latitude;
    final lng = widget.venue.longitude;

    if (lat == null || lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location not available')),
      );
      return;
    }

    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );

    await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
  }
  @override
  void dispose() {
    _razorpay.clear();
    _couponController.dispose();
    // Unlock slot if user leaves without completing payment
    if (_slotLockId != null) {
      PaymentApi.unlockSlot(_slotLockId!);
    }
    super.dispose();
  }

  // ── Fetch booking description ──
  Future<void> _fetchDescription() async {
    try {
      final desc = await BookingApi.bookingDescription(widget.request);
      if (mounted) setState(() { _desc = desc; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  // ── Computed values ──
  String get _bookingDate {
    final d = widget.selectedDate;
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  String get _startTime => widget.request.timing.split('_')[0]; // "08:00"
  String get _endTime   => widget.request.timing.split('_')[1]; // "10:00"

  String get _formattedDate {
    final d = widget.selectedDate;
    const days   = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${days[d.weekday - 1]}, ${d.day} ${months[d.month - 1]} ${d.year}';
  }

  int get _slotCost {
    if (_desc == null) return 0;
    final duration = _desc!.timing.durationHours;
    if (widget.selectedGround != null) {
      return (widget.selectedGround!.pricePerHour * duration).toInt();
    }
    return _desc!.pricing.minPricePerHour * duration;
  }

  double get _serviceFee {
    if (_desc == null) return 0;
    if (_desc!.venue.serviceFeeType == 'percentage') {
      return _slotCost * _desc!.venue.serviceFeeValue / 100;
    }
    return _desc!.venue.serviceFeeValue;
  }

  double get _couponDiscount =>
      (_appliedCoupon?['discountAmount'] as num?)?.toDouble() ?? 0;

  int get _totalAmount =>
      (_slotCost + _serviceFee - _couponDiscount).toInt().clamp(0, 999999);

  // ── Make Payment ──
  Future<void> _makePayment() async {
    if (_paymentLoading) return;
    setState(() => _paymentLoading = true);

    try {
      // 1. Lock slot
      final ground = widget.selectedGround;
      if (ground == null) {
        _showError('Please select a ground before payment.');
        return;
      }

      int lockId;
      if (_slotLockId != null) {
        lockId = _slotLockId!;
      } else {
        lockId = await PaymentApi.lockSlot(
          venueId:     widget.venue.id,
          groundId:    ground.id,
          bookingDate: _bookingDate,
          startTime:   _startTime,
          endTime:     _endTime,
          vgsId:       ground.vgsId,
        );
        _slotLockId = lockId;
      }

      // 2. Create Razorpay order
      final orderData = await PaymentApi.createOrder({
        'venueId':      widget.venue.id,
        'groundId':     ground.id,
        'bookingDate':  _bookingDate,
        'startTime':    _startTime,
        'endTime':      _endTime,
        'paymentMethod': 'online',
        if (_appliedCoupon != null) 'couponCode': _appliedCoupon!['code'],
      });

      final gatewayConfig = orderData['gatewayConfig'] as Map<String, dynamic>?;
      if (gatewayConfig == null) throw Exception('Failed to create payment order.');

      final user = SessionManager.instance.currentUser;

      // 3. Open Razorpay
      final options = {
        'key':         gatewayConfig['key'] ?? gatewayConfig['keyId'],
        'amount':      gatewayConfig['amount'],
        'currency':    gatewayConfig['currency'] ?? 'INR',
        'order_id':    gatewayConfig['order_id'] ?? gatewayConfig['orderId'],
        'name':        widget.venue.name,
        'description': '${widget.categoryName} — ${widget.subcategoryName}',
        'prefill': {
          'name':    user?.fullName ?? '',
          'email':   user?.email ?? '',
          'contact': user?.mobile ?? '',
        },
        'theme': {'color': '#9CCE00'},
      };

      _razorpay.open(options);

    } catch (e) {
      final msg = e.toString();
      if (msg.contains('409') || msg.toLowerCase().contains('locked')) {
        // Release stale lock and show error
        if (_slotLockId != null) {
          await PaymentApi.unlockSlot(_slotLockId!);
          _slotLockId = null;
        }
        _showError('Slot is temporarily locked. Please go back and choose a different slot.');
      } else {
        _showError(msg.replaceAll('Exception: ', ''));
      }
      if (mounted) setState(() => _paymentLoading = false);
    }
  }

  // ── Razorpay callbacks ──
  Future<void> _onPaymentSuccess(PaymentSuccessResponse response) async {
    try {
      // 4. Verify payment
      await PaymentApi.verifyPayment(
        orderId:   response.orderId!,
        paymentId: response.paymentId!,
        signature: response.signature!,
      );

      // 5. Create booking
      final ground = widget.selectedGround!;
      final createdId = await PaymentApi.createBooking(
        venueId:      widget.venue.id,
        bookingDate:  _bookingDate,
        startTime:    _startTime,
        endTime:      _endTime,
        gatewayOrderId: response.orderId!,
        vgsId:        ground.vgsId,
        groundId:     ground.id,
        couponCode:   _appliedCoupon?['code'] as String?,
        couponDiscountAmount: _couponDiscount > 0 ? _couponDiscount : null,
      );
      _bookingId = createdId;

      // 6. Release lock
      if (_slotLockId != null) {
        await PaymentApi.unlockSlot(_slotLockId!);
        _slotLockId = null;
      }

      if (mounted) {
        setState(() {
          _paymentLoading = false;
          _activeStep = 2; // Move to Enjoy the Play step
        });
        
        // Navigator.pushAndRemoveUntil(
        //   context,
        //   MaterialPageRoute(
        //     builder: (_) => BookingConfirmationScreen(
        //       bookingId:     _bookingId!,
        //       bookingCode:   'PBZ-BK-$_bookingId',
        //       venueName:     widget.venue.name,
        //       venueAddress:  '${widget.venue.address}, ${widget.venue.city}, ${widget.venue.state}',
        //       venueLat:      widget.venue.latitude,
        //       venueLng:      widget.venue.longitude,
        //       formattedDate: _formattedDate,
        //       timeSlot:      widget.timingLabel,
        //       onMyBookings:  () {
        //         Navigator.of(context).popUntil((route) => route.isFirst);
        //         widget.onMyBookings?.call();
        //       },
        //     ),
        //   ),
        //   (route) => route.isFirst,
        // );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _paymentLoading = false);
        _showError('Payment succeeded but booking failed. Please contact support.');
      }
    }
  }

  void _onPaymentError(PaymentFailureResponse response) async {
    // Release slot lock on failure
    if (_slotLockId != null) {
      await PaymentApi.unlockSlot(_slotLockId!);
      _slotLockId = null;
    }
    if (mounted) {
      setState(() => _paymentLoading = false);
      _showError(response.message ?? 'Payment failed. Please try again.');
    }
  }

  void _onExternalWallet(ExternalWalletResponse response) {
    if (mounted) setState(() => _paymentLoading = false);
  }

  // ── Apply coupon ──
  Future<void> _applyCoupon() async {
    final code = _couponController.text.trim().toUpperCase();
    if (code.isEmpty) return;

    setState(() { _couponLoading = true; _couponError = null; });
    try {
      final res = await ApiService.instance.post(
        '${ApiConstants.baseUrl}/coupons/validate',
        {
          'code':        code,
          'orderAmount': _slotCost,
          'venueId':     widget.venue.id,
        },
      );
      if (mounted) {
        setState(() {
          _appliedCoupon = res['data'] as Map<String, dynamic>?;
          _couponLoading = false;
        });
        _showSuccess('Coupon applied!');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _couponError = e.toString().replaceAll('Exception: ', '');
          _couponLoading = false;
          _appliedCoupon = null;
        });
      }
    }
  }

  void _removeCoupon() {
    setState(() {
      _appliedCoupon = null;
      _couponController.clear();
      _couponError = null;
    });
  }

  void _showError(String msg) {
    if (!mounted) return;
    AppSnackbar.showError(context, msg);
  }

  void _showSuccess(String msg) {
    if (!mounted) return;
    AppSnackbar.showSuccess(context, msg);
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.navyBlue,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.limeGreen))
          : _error != null
              ? _buildError()
             
                  : Stack(
                      children: [
                        CustomScrollView(
                          slivers: [
                            SliverAppBar(
                              automaticallyImplyLeading: false,
                              expandedHeight: topPad + 140,
                              pinned: false,
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
                            SliverToBoxAdapter(
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: AppColors.navyBlue,
                                  borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(24)),
                                ),
                                child: Column(
                                  children: [
                                    const SizedBox(height: 20),
                                    Text(widget.categoryName,
                                        style: const TextStyle(
                                          fontFamily: 'Jost',
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        )),
                                    const SizedBox(height: 16),
                                    _buildStepIndicator(activeStep: _activeStep),
                                    const SizedBox(height: 20),
                                 _activeStep == 1
                                  ? _buildPaymentContent()
                                  : _buildConfirmationContent(),
                                    const SizedBox(height: 140),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Back button
                        Positioned(
                          top: topPad + 8,
                          left: 16,
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              width: 36, height: 36,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.45),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.arrow_back_rounded,
                                  color: Colors.white, size: 20),
                            ),
                          ),
                        ),

                        // Make Payment bar
                        if (_activeStep == 1)
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: _buildPaymentBar(),
                          ),
                      ],
                    ),
    );
  }


Widget _buildStepIndicator({int activeStep = 1}) {
  const steps = [
    'Book a Slot',
    'Payment',
    'Enjoy the Play'
  ];

  const icons = [
    Icons.person_rounded,
    Icons.payment_rounded,
    Icons.sports_soccer_rounded,
  ];

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Row(
      children: List.generate(steps.length * 2 - 1, (idx) {
        if (idx.isOdd) {
          final lineIndex = idx ~/ 2;

          return Expanded(
            child: Container(
              height: 2,
              margin: const EdgeInsets.only(bottom: 22),
              color: lineIndex < activeStep
                  ? AppColors.limeGreen
                  : Colors.white.withValues(alpha: 0.15),
            ),
          );
        }

        final stepIndex = idx ~/ 2;
        final isCompleted = stepIndex < activeStep;
        final isActive = stepIndex == activeStep;

        return SizedBox(
          width: 90,
          child: Column(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: (isCompleted || isActive)
                      ? AppColors.limeGreen
                      : Colors.white.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isCompleted ? Icons.check : icons[stepIndex],
                  color: (isCompleted || isActive)
                      ? AppColors.navyBlue
                      : Colors.white.withValues(alpha: 0.4),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                steps[stepIndex],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: (isCompleted || isActive)
                      ? AppColors.limeGreen
                      : Colors.white.withValues(alpha: 0.35),
                ),
              ),
            ],
          ),
        );
      }),
    ),
  );
}


Widget _buildPaymentContent() {
  return Column(
    children: [
      _buildVenueInfoRow(),
      const SizedBox(height: 16),
      _buildDateTimeRow(),
      const SizedBox(height: 20),

      Divider(
        color: Colors.white.withValues(alpha: 0.08),
        height: 1,
      ),

      const SizedBox(height: 20),

      _buildCostBreakdown(),

      const SizedBox(height: 20),

      Divider(
        color: Colors.white.withValues(alpha: 0.08),
        height: 1,
      ),

      const SizedBox(height: 20),

      _buildCouponSection(),

      const SizedBox(height: 140),
    ],
  );
}
  Widget _buildVenueInfoRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.venue.name,
                    style: const TextStyle(
                      fontFamily: 'Jost', fontSize: 17,
                      fontWeight: FontWeight.w700, color: Colors.white,
                    )),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.location_on_rounded,
                      color: AppColors.limeGreen, size: 12),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text('${widget.venue.city}, ${widget.venue.state}',
                        style: TextStyle(fontFamily: 'Inter', fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.6))),
                  ),
                ]),
              ],
            ),
          ),
          Row(children: [
            const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
            const SizedBox(width: 4),
            Text(widget.venue.rating.toStringAsFixed(1),
                style: const TextStyle(fontFamily: 'Inter', fontSize: 13,
                    fontWeight: FontWeight.w700, color: Colors.amber)),
          ]),
        ],
      ),
    );
  }

  Widget _buildDateTimeRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.play_arrow_rounded, color: AppColors.limeGreen, size: 14),
              const SizedBox(width: 6),
              Text(_formattedDate,
                  style: TextStyle(fontFamily: 'Inter', fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.85))),
            ]),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.access_time_rounded, color: AppColors.limeGreen, size: 14),
              const SizedBox(width: 6),
              Text(widget.timingLabel,
                  style: TextStyle(fontFamily: 'Inter', fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.85))),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildCostBreakdown() {
    final desc = _desc!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(children: [
        _CostRow(label: 'Slot Cost',
            value: '₹${_slotCost.toStringAsFixed(2)}'),
        const SizedBox(height: 12),
        if (_serviceFee > 0) ...[
          _CostRow(
            label: 'Service Fee (${desc.venue.serviceFeeValue.toStringAsFixed(0)}%)',
            value: '₹${_serviceFee.toStringAsFixed(2)}'),
          const SizedBox(height: 12),
        ],
        if (_couponDiscount > 0) ...[
          _CostRow(
            label: 'Coupon (${_appliedCoupon!['code']})',
            value: '− ₹${_couponDiscount.toStringAsFixed(2)}',
            isDiscount: true),
          const SizedBox(height: 12),
        ],
        Divider(color: Colors.white.withValues(alpha: 0.08)),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Total Payment:',
                style: TextStyle(fontFamily: 'Jost', fontSize: 16,
                    fontWeight: FontWeight.w700, color: Colors.white)),
            Text('₹$_totalAmount',
                style: const TextStyle(fontFamily: 'Jost', fontSize: 18,
                    fontWeight: FontWeight.w700, color: AppColors.limeGreen)),
          ],
        ),
      ]),
    );
  }

  Widget _buildCouponSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_appliedCoupon != null) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.limeGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.limeGreen.withValues(alpha: 0.3)),
              ),
              child: Row(children: [
                const Icon(Icons.local_offer_rounded,
                    color: AppColors.limeGreen, size: 16),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${_appliedCoupon!['code']} — Save ₹${_appliedCoupon!['discountAmount']}',
                    style: const TextStyle(fontFamily: 'Inter', fontSize: 13,
                        fontWeight: FontWeight.w600, color: AppColors.limeGreen)),
                ),
                GestureDetector(
                  onTap: _removeCoupon,
                  child: Text('Remove',
                      style: TextStyle(fontFamily: 'Inter', fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.red.shade300)),
                ),
              ]),
            ),
          ] else ...[
            Row(children: [
              Expanded(
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                  ),
                  child: TextField(
                    controller: _couponController,
                    textCapitalization: TextCapitalization.characters,
                    style: const TextStyle(fontFamily: 'Inter',
                        fontSize: 13, color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Enter Coupon',
                      hintStyle: TextStyle(fontFamily: 'Inter', fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.35)),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16),
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => _applyCoupon(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _couponLoading ? null : _applyCoupon,
                child: Container(
                  height: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: AppColors.limeGreen,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: _couponLoading
                        ? const SizedBox(width: 18, height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('Apply',
                            style: TextStyle(fontFamily: 'Inter',
                                fontSize: 14, fontWeight: FontWeight.w700,
                                color: Colors.white)),
                  ),
                ),
              ),
            ]),
            if (_couponError != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_couponError!,
                    style: TextStyle(fontFamily: 'Inter', fontSize: 12,
                        color: Colors.red.shade300)),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
      color: AppColors.navyBlue,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.monetization_on_rounded,
                color: AppColors.limeGreen, size: 16),
            const SizedBox(width: 6),
            Text(
              'Slot Price : ₹$_totalAmount for ${_desc?.timing.durationHours ?? 1} Hr${(_desc?.timing.durationHours ?? 1) > 1 ? 's' : ''}',
              style: TextStyle(fontFamily: 'Inter', fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.85)),
            ),
          ]),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _paymentLoading ? null : _makePayment,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 54,
              decoration: BoxDecoration(
                color: _paymentLoading
                    ? AppColors.limeGreen.withValues(alpha: 0.6)
                    : AppColors.limeGreen,
                borderRadius: BorderRadius.circular(16),
                boxShadow: _paymentLoading ? [] : [
                  BoxShadow(
                    color: AppColors.limeGreen.withValues(alpha: 0.4),
                    blurRadius: 16, offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Center(
                child: _paymentLoading
                    ? const Row(mainAxisSize: MainAxisSize.min, children: [
                        SizedBox(width: 20, height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white)),
                        SizedBox(width: 10),
                        Text('Processing…',
                            style: TextStyle(fontFamily: 'Jost',
                                fontSize: 17, fontWeight: FontWeight.w700,
                                color: Colors.white)),
                      ])
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Make Payment',
                              style: TextStyle(fontFamily: 'Jost',
                                  fontSize: 17, fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward_rounded,
                              color: Colors.white, size: 20),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.error_outline_rounded, color: Colors.white54, size: 48),
        const SizedBox(height: 12),
        const Text('Failed to load booking details',
            style: TextStyle(fontFamily: 'Jost', fontSize: 16,
                color: Colors.white, fontWeight: FontWeight.w600)),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: () {
            setState(() { _loading = true; _error = null; });
            _fetchDescription();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.limeGreen,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text('Retry',
                style: TextStyle(fontFamily: 'Inter',
                    fontWeight: FontWeight.w600, color: Colors.white)),
          ),
        ),
      ]),
    );
  }

  Widget _buildConfirmationContent() {
    return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
            const SizedBox(height: 20),
            // Confirmation check circle
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.limeGreen.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.limeGreen.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: AppColors.limeGreen,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Booking Confirmed
            const Text(
              'Booking  Confirmed !!',
              style: TextStyle(
                fontFamily: 'Jost',
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.limeGreen,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Booking ID: PBZ-BK-${_bookingId ?? ''}',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 24),
            Divider(color: Colors.white.withValues(alpha: 0.1)),
            const SizedBox(height: 24),
            // Venue name
            Text(
              widget.venue.name,
              style: const TextStyle(
                fontFamily: 'Jost',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '${widget.venue.address}, ${widget.venue.city}, ${widget.venue.state}',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.6),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // Date + Time chips
            Row(
              children: [
                Expanded(
                  child: _InfoChip(
                    icon: Icons.calendar_today_rounded,
                    label: _formattedDate,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _InfoChip(
                    icon: Icons.access_time_rounded,
                    label: widget.timingLabel,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: _ActionBtn(
                    icon: Icons.directions_rounded,
                    label: 'Get Direction',
                    onTap: _openGoogleMaps,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionBtn(
                    icon: Icons.book_online_rounded,
                    label: 'My Bookings',
                    onTap: widget.onMyBookings,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
          ),
        );
  }
  // Add these helper widgets
  Widget _InfoChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.limeGreen, size: 22),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.limeGreen,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  Widget _ActionBtn({required IconData icon, required String label, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.limeGreen,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.limeGreen.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CostRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isDiscount;
  const _CostRow({required this.label, required this.value,
      this.isDiscount = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontFamily: 'Inter', fontSize: 14,
            color: Colors.white.withValues(alpha: 0.75))),
        Text(value, style: TextStyle(fontFamily: 'Inter', fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDiscount ? AppColors.limeGreen : Colors.white)),
      ],
    );
  }
}



