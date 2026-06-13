import 'package:bookplayz/api/api_constants.dart';
import 'package:bookplayz/api/api_service.dart';
import 'package:flutter/material.dart';

// Shows the cancellation preview bottom sheet.
// Caller is responsible for fetching the preview and passing it in.
class CancellationSheet extends StatefulWidget {
  final Map<String, dynamic> preview;
  final int bookingId;
  final VoidCallback onCancelled;

  const CancellationSheet({
    super.key,
    required this.preview,
    required this.bookingId,
    required this.onCancelled,
  });

  @override
  State<CancellationSheet> createState() => _CancellationSheetState();
}

class _CancellationSheetState extends State<CancellationSheet> {
  bool _cancelling = false;

  double _amt(String key) {
    final v = widget.preview[key];
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  Future<void> _confirmCancel() async {
    setState(() => _cancelling = true);
    try {
      await ApiService.instance.put(
        CancellationApi.cancel(widget.bookingId),
        {},
      );
      if (mounted) Navigator.of(context).pop();
      widget.onCancelled();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
        setState(() => _cancelling = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final refundAmount  = _amt('currentRefundAmount');
    final refundPercent = widget.preview['currentRefundPercent'];
    final amountPaid    = _amt('amountPaid');
    final serviceFee    = _amt('serviceFee');
    final isCancellable = widget.preview['isCancellable'] == true;
    final scenarios = (widget.preview['scenarios'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Cancel Booking',
                    style: TextStyle(
                      fontFamily: 'Jost',
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0A2540),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _cancelling ? null : () => Navigator.of(context).pop(),
                  child: const Icon(Icons.close_rounded, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Refund highlight card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FFF4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text(
                    "You'll receive a refund of",
                    style: TextStyle(fontSize: 13, color: Color(0xFF22C55E)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${refundAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontFamily: 'Anton',
                      fontSize: 28,
                      color: Color(0xFF22C55E),
                    ),
                  ),
                  Text(
                    '$refundPercent% of refundable amount',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF22C55E)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _SheetRow(
              label: 'Amount paid',
              value: '₹${amountPaid.toStringAsFixed(2)}',
            ),
            _SheetRow(
              label: 'Service fee (non-refundable)',
              value: '₹${serviceFee.toStringAsFixed(2)}',
            ),
            const SizedBox(height: 14),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Cancellation policy',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0A2540),
                ),
              ),
            ),
            const SizedBox(height: 8),
            ...scenarios.map((s) {
              final isActive = s['refundPercent']?.toString() ==
                  refundPercent?.toString();
              return _PolicyRow(
                label: s['label']?.toString() ?? '',
                value: '${s['refundPercent']}% (₹${s['refundAmount']})',
                isActive: isActive,
              );
            }),
            const SizedBox(height: 20),
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed:
                        _cancelling ? null : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.shade400),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'Keep Booking',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0A2540),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed:
                        (isCancellable && !_cancelling) ? _confirmCancel : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      disabledBackgroundColor:
                          const Color(0xFFEF4444).withValues(alpha: 0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _cancelling
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Confirm',  
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Helpers ──────────────────────────────────────────────────────────────────

class _SheetRow extends StatelessWidget {
  final String label;
  final String value;

  const _SheetRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0A2540),
            ),
          ),
        ],
      ),
    );
  }
}

class _PolicyRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isActive;

  const _PolicyRow({
    required this.label,
    required this.value,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFF3B82F6);
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFEFF6FF) : Colors.transparent,
        border: Border.all(
          color: isActive ? activeColor : const Color(0xFFE5E7EB),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                color: isActive ? activeColor : const Color(0xFF374151),
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isActive ? activeColor : const Color(0xFF374151),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Static helper to fetch preview + show sheet ───────────────────────────────

Future<void> showCancellationSheet({
  required BuildContext context,
  required int bookingId,
  required VoidCallback onCancelled,
  required void Function(bool) setLoading,
}) async {
  setLoading(true);
  try {
    final res = await ApiService.instance.get(
      CancellationApi.preview(bookingId),
    );
    final preview = res['data'] as Map<String, dynamic>;
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => CancellationSheet(
        preview: preview,
        bookingId: bookingId,
        onCancelled: onCancelled,
      ),
    );
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  } finally {
    setLoading(false);
  }
}
