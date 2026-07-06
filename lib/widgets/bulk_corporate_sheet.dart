// lib/widgets/bulk_corporate_sheet.dart
//
// Mobile port of the web's BulkCorporateModal — lets a visitor either pick
// one of the venue's active "packages" (events) or submit a general
// corporate enquiry straight to the venue.

import 'package:bookplayz/api/api_constants.dart';
import 'package:bookplayz/models/public_event_model.dart';
import 'package:bookplayz/theme/app_theme.dart';
import 'package:bookplayz/widgets/app_loader.dart';
import 'package:flutter/material.dart';

// Accepts a 10-digit Indian mobile number, optionally prefixed with +91/91/0.
final RegExp _mobileRe = RegExp(r'^(\+91|91|0)?[6-9]\d{9}$');
final RegExp _emailRe = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

Future<void> showBulkCorporateSheet(
  BuildContext context, {
  required int venueId,
  String? venueName,
  PublicEventModel? initialEvent,
  bool skipEvents = false,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => BulkCorporateSheet(
      venueId: venueId,
      venueName: venueName,
      initialEvent: initialEvent,
      skipEvents: skipEvents,
    ),
  );
}

enum _BulkView { loading, list, form, success }

class BulkCorporateSheet extends StatefulWidget {
  final int venueId;
  final String? venueName;
  // Pre-selected event (e.g. tapped from the inline Events section) — skips
  // straight to the form for that event.
  final PublicEventModel? initialEvent;
  // Entry from the sidebar "Bulk / Corporate" button — skips the package
  // list and goes straight to the general enquiry form.
  final bool skipEvents;

  const BulkCorporateSheet({
    super.key,
    required this.venueId,
    this.venueName,
    this.initialEvent,
    this.skipEvents = false,
  });

  @override
  State<BulkCorporateSheet> createState() => _BulkCorporateSheetState();
}

class _BulkCorporateSheetState extends State<BulkCorporateSheet> {
  _BulkView _view = _BulkView.loading;
  List<PublicEventModel> _events = [];
  PublicEventModel? _selectedEvent;

  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();

  String? _firstNameErr;
  String? _lastNameErr;
  String? _mobileErr;
  String? _emailErr;
  String? _messageErr;

  bool _submitting = false;
  String? _submitError;

  @override
  void initState() {
    super.initState();
    // Pre-selected event from the inline events section → go straight to form.
    if (widget.initialEvent != null) {
      _selectedEvent = widget.initialEvent;
      _view = _BulkView.form;
      return;
    }
    // Bulk/Corporate button entry → skip the package list entirely.
    if (widget.skipEvents) {
      _view = _BulkView.form;
      return;
    }
    _loadEvents();
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _mobileCtrl.dispose();
    _emailCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    try {
      final events = await EventsApi.byVenue(widget.venueId, limit: 50);
      if (!mounted) return;
      setState(() {
        _events = events;
        _view = events.isNotEmpty ? _BulkView.list : _BulkView.form;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _view = _BulkView.form);
    }
  }

  void _selectEvent(PublicEventModel evt) {
    setState(() {
      _selectedEvent = evt;
      _submitError = null;
      _view = _BulkView.form;
    });
  }

  void _back() {
    if (_events.isEmpty) return;
    setState(() {
      _view = _BulkView.list;
      _selectedEvent = null;
      _submitError = null;
    });
  }

  bool _validate() {
    setState(() {
      _firstNameErr = _firstNameCtrl.text.trim().isEmpty
          ? 'First name is required'
          : null;
      _lastNameErr = _lastNameCtrl.text.trim().isEmpty
          ? 'Last name is required'
          : null;

      final mobile = _mobileCtrl.text.trim().replaceAll(RegExp(r'[\s\-]'), '');
      _mobileErr = mobile.isEmpty
          ? 'Mobile number is required'
          : (!_mobileRe.hasMatch(mobile)
                ? 'Enter a valid 10-digit Indian mobile number'
                : null);

      final email = _emailCtrl.text.trim();
      _emailErr = email.isNotEmpty && !_emailRe.hasMatch(email)
          ? 'Enter a valid email address'
          : null;

      final message = _messageCtrl.text.trim();
      _messageErr = message.isEmpty ? 'Message is required' : null;
    });
    return _firstNameErr == null &&
        _lastNameErr == null &&
        _mobileErr == null &&
        _emailErr == null &&
        _messageErr == null;
  }

  Future<void> _submit() async {
    if (!_validate()) return;
    setState(() {
      _submitting = true;
      _submitError = null;
    });

    final firstName = _firstNameCtrl.text.trim();
    final lastName = _lastNameCtrl.text.trim();
    final mobile = _mobileCtrl.text.trim().replaceAll(RegExp(r'[\s\-]'), '');
    final email = _emailCtrl.text.trim();
    final message = _messageCtrl.text.trim();

    try {
      if (_selectedEvent != null) {
        await EnquiryApi.submitEventEnquiry(
          name: '$firstName $lastName'.trim(),
          mobileNumber: mobile,
          email: email.isNotEmpty ? email : null,
          message: message,
          eventId: _selectedEvent!.id,
        );
      } else {
        await EnquiryApi.submitVenueEnquiry(
          firstName: firstName,
          lastName: lastName,
          phone: mobile,
          email: email.isNotEmpty ? email : null,
          message: message,
          venueId: widget.venueId,
        );
      }
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _view = _BulkView.success;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _submitError = 'Failed to submit enquiry. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Flexible(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_view) {
      case _BulkView.loading:
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 60),
          child: Center(child: AppLoader()),
        );
      case _BulkView.list:
        return _buildList();
      case _BulkView.form:
        return _buildForm();
      case _BulkView.success:
        return _buildSuccess();
    }
  }

  // ── Event / package list ────────────────────────────────────────────────
  Widget _buildList() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Corporate Sports Day Out',
                  style: TextStyle(
                    fontFamily: 'Jost',
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0A2540),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.close_rounded, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Choose a package or submit a general enquiry',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 14),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _events.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (_, i) => _PackageCard(
                event: _events[i],
                onTap: () => _selectEvent(_events[i]),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: () => setState(() {
                _selectedEvent = null;
                _view = _BulkView.form;
              }),
              child: const Text(
                'Submit a general enquiry instead',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.limeGreen,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Enquiry form ─────────────────────────────────────────────────────────
  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (_events.isNotEmpty)
                GestureDetector(
                  onTap: _back,
                  child: const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: Icon(
                      Icons.arrow_back_rounded,
                      color: Color(0xFF0A2540),
                    ),
                  ),
                ),
              Expanded(
                child: Text(
                  _selectedEvent?.eventTitle ?? 'Corporate Enquiry',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Jost',
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0A2540),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.close_rounded, color: Colors.grey),
              ),
            ],
          ),
          if (_selectedEvent?.dateRangeLabel.isNotEmpty ?? false) ...[
            const SizedBox(height: 4),
            Text(
              _selectedEvent!.dateRangeLabel,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _FormField(
                  controller: _firstNameCtrl,
                  hint: 'First Name *',
                  errorText: _firstNameErr,
                  onChanged: (_) => setState(() => _firstNameErr = null),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _FormField(
                  controller: _lastNameCtrl,
                  hint: 'Last Name *',
                  errorText: _lastNameErr,
                  onChanged: (_) => setState(() => _lastNameErr = null),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _FormField(
                  controller: _mobileCtrl,
                  hint: 'Mobile *',
                  keyboardType: TextInputType.phone,
                  errorText: _mobileErr,
                  onChanged: (_) => setState(() => _mobileErr = null),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _FormField(
                  controller: _emailCtrl,
                  hint: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  errorText: _emailErr,
                  onChanged: (_) => setState(() => _emailErr = null),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _FormField(
            controller: _messageCtrl,
            hint: 'Message *',
            maxLines: 5,
            errorText: _messageErr,
            onChanged: (_) => setState(() => _messageErr = null),
          ),
          if (_submitError != null) ...[
            const SizedBox(height: 10),
            Text(
              _submitError!,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: Colors.red,
              ),
            ),
          ],
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.limeGreen,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'SEND',
                      style: TextStyle(
                        fontFamily: 'Jost',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Success ──────────────────────────────────────────────────────────────
  Widget _buildSuccess() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.limeGreen.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColors.limeGreen,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Thank you for your enquiry!',
            style: TextStyle(
              fontFamily: 'Jost',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0A2540),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "We've received your details and our team will get back to you shortly.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: Colors.grey.shade600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.limeGreen,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'DONE',
                style: TextStyle(
                  fontFamily: 'Jost',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PackageCard extends StatelessWidget {
  final PublicEventModel event;
  final VoidCallback onTap;
  const _PackageCard({required this.event, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: event.resolvedImage != null
                  ? Image.network(
                      event.resolvedImage!,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _thumbFallback(),
                    )
                  : _thumbFallback(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.eventTitle.toUpperCase(),
                    style: const TextStyle(
                      fontFamily: 'Jost',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0A2540),
                    ),
                  ),
                  if (event.eventDescription.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      event.eventDescription,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                  if (event.dateRangeLabel.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      event.dateRangeLabel,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.limeGreen,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        'Know More',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 13,
                        color: Colors.grey.shade700,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _thumbFallback() => Container(
    width: 64,
    height: 64,
    color: const Color(0xFFEFF3FB),
    child: const Icon(
      Icons.emoji_events_outlined,
      color: Color(0xFFB0B8C1),
      size: 26,
    ),
  );
}

class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final TextInputType keyboardType;
  final String? errorText;
  final ValueChanged<String>? onChanged;

  const _FormField({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
    this.errorText,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: errorText != null
                  ? Colors.red.shade300
                  : const Color(0xFFE5E7EB),
            ),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            onChanged: onChanged,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: Color(0xFF0A2540),
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              hintText: hint,
              hintStyle: const TextStyle(
                color: Color(0xFFB0B8C1),
                fontSize: 13,
              ),
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 4),
          Text(
            errorText!,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: Colors.red,
            ),
          ),
        ],
      ],
    );
  }
}
