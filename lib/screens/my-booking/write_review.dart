import 'dart:io';

import 'package:bookplayz/api/api_constants.dart';
import 'package:bookplayz/api/api_service.dart';
import 'package:bookplayz/models/my_booking_model.dart';
import 'package:bookplayz/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

// ─────────────────────────────────────────────────────────
// WriteReviewSheet
//
// Usage:
//   final result = await showModalBottomSheet<Map<String, dynamic>?>(
//     context: context,
//     isScrollControlled: true,
//     backgroundColor: Colors.transparent,
//     useRootNavigator: true,
//     builder: (_) => WriteReviewSheet(booking: booking, reviewId: reviewId),
//   );
//
// Result on submit  : {'id': int, 'status': String}
// Result on delete  : {'deleted': true}
// Result on cancel  : null
// ─────────────────────────────────────────────────────────
class WriteReviewSheet extends StatefulWidget {
  final MyBookingModel booking;
  final int? reviewId;

  const WriteReviewSheet({
    super.key,
    required this.booking,
    this.reviewId,
  });

  @override
  State<WriteReviewSheet> createState() => _WriteReviewSheetState();
}

class _WriteReviewSheetState extends State<WriteReviewSheet> {
  bool get _isEdit => widget.reviewId != null;

  bool   _loadingDetail = false;
  double _rating        = 0;
  String? _reviewStatus;

  final _contentCtrl = TextEditingController();

  final List<XFile>               _pickedImages   = [];
  final List<Map<String, dynamic>> _existingImages = [];

  bool    _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (_isEdit) _loadDetail();
  }

  @override
  void dispose() {
    _contentCtrl.dispose();
    super.dispose();
  }

  // ── Load existing review ──────────────────────────────────────────────────
  Future<void> _loadDetail() async {
    setState(() => _loadingDetail = true);
    try {
      final res  = await ApiService.instance.get(ReviewApi.byId(widget.reviewId!));
      final data = res['data'] as Map<String, dynamic>;
      setState(() {
        _rating       = (double.tryParse(data['rating']?.toString() ?? '0') ?? 0);
        _contentCtrl.text = data['content'] as String? ?? '';
        _reviewStatus     = data['status'] as String?;
        _existingImages
          ..clear()
          ..addAll(((data['images'] as List?) ?? [])
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList());
        _loadingDetail = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingDetail = false);
    }
  }

  // ── Image helpers ─────────────────────────────────────────────────────────
  int get _totalImages => _existingImages.length + _pickedImages.length;

  Future<void> _pickImages() async {
    final remaining = 5 - _totalImages;
    if (remaining <= 0) return;
    final images = await ImagePicker().pickMultiImage(limit: remaining);
    if (images.isEmpty) return;
    setState(() => _pickedImages.addAll(images.take(remaining)));
  }

  static MediaType _mediaType(String path) {
    switch (path.split('.').last.toLowerCase()) {
      case 'png':  return MediaType('image', 'png');
      case 'gif':  return MediaType('image', 'gif');
      case 'webp': return MediaType('image', 'webp');
      default:     return MediaType('image', 'jpeg');
    }
  }

  // ── Submit ────────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    if (_rating == 0) {
      setState(() => _error = 'Please select a rating');
      return;
    }
    setState(() { _submitting = true; _error = null; });

    try {
      Map<String, dynamic> data;

      if (_pickedImages.isEmpty) {
        // ── JSON path (no new images) ────────────────────────────────────
        final body = <String, dynamic>{'rating': _rating};
        final content = _contentCtrl.text.trim();
        if (content.isNotEmpty) body['content'] = content;

        if (!_isEdit) {
          body['bookingId'] = widget.booking.id;
          body['venueId']   = widget.booking.venueId;
          if (widget.booking.groundId != 0) body['groundId'] = widget.booking.groundId;
        }

        final res = _isEdit
            ? await ApiService.instance.put(ReviewApi.update(widget.reviewId!), body)
            : await ApiService.instance.post(ReviewApi.create(), body);
        data = _extractData(res);
      } else {
        // ── Multipart path (with new images) ────────────────────────────
        final fields = <String, String>{'rating': _rating.toStringAsFixed(1)};
        final content = _contentCtrl.text.trim();
        if (content.isNotEmpty) fields['content'] = content;

        if (!_isEdit) {
          fields['bookingId'] = widget.booking.id.toString();
          fields['venueId']   = widget.booking.venueId.toString();
          if (widget.booking.groundId != 0) {
            fields['groundId'] = widget.booking.groundId.toString();
          }
        }

        final files = <http.MultipartFile>[];
        for (final xf in _pickedImages) {
          files.add(await http.MultipartFile.fromPath(
            'images',
            xf.path,
            filename:    xf.name,
            contentType: _mediaType(xf.path),
          ));
        }

        final res = _isEdit
            ? await ApiService.instance.putMultipart(
                ReviewApi.update(widget.reviewId!), fields, files: files)
            : await ApiService.instance.postMultipart(
                ReviewApi.create(), fields, files: files);
        data = _extractData(res);
      }

      if (mounted) Navigator.pop(context, data);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e is ApiException ? e.message : e.toString();
        _submitting = false;
      });
    }
  }

  // Safely extract the data map from the API response regardless of shape.
  static Map<String, dynamic> _extractData(Map<String, dynamic> res) {
    final raw = res['data'];
    if (raw is Map<String, dynamic>) return raw;
    // Some APIs return {"success": true} with no data; fall back to full response
    return res;
  }

  // ── Delete ────────────────────────────────────────────────────────────────
  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 40),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete_outline_rounded,
                    color: Color(0xFFEF4444), size: 28),
              ),
              const SizedBox(height: 16),
              const Text('Delete Review?',
                  style: TextStyle(
                      fontFamily: 'Jost', fontSize: 18,
                      fontWeight: FontWeight.w800, color: Color(0xFF0A2540))),
              const SizedBox(height: 10),
              const Text(
                'This action cannot be undone.',
                style: TextStyle(
                    fontFamily: 'Inter', fontSize: 13,
                    height: 1.5, color: Color(0xFF6B7280)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFDDDDDD)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    child: const Text('Cancel',
                        style: TextStyle(
                            fontFamily: 'Inter', fontSize: 13,
                            fontWeight: FontWeight.w600, color: Colors.black54)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    child: const Text('Delete',
                        style: TextStyle(
                            fontFamily: 'Inter', fontSize: 13,
                            fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );

    if (confirmed != true) return;

    setState(() { _submitting = true; _error = null; });
    try {
      await ApiService.instance.delete(ReviewApi.delete(widget.reviewId!));
      if (mounted) Navigator.pop(context, {'deleted': true});
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e is ApiException ? e.message : e.toString();
        _submitting = false;
      });
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.92,
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: Container(
          color: Colors.white,
          child: Stack(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
            children: [
              // ── Drag handle ──────────────────────────────────────────────
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDDDDDD),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // ── Header ───────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isEdit ? 'Edit Your Review' : 'Write a Review',
                            style: const TextStyle(
                              fontFamily: 'Jost', fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0A2540),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            widget.booking.subcategoryName.toUpperCase(),
                            style: const TextStyle(
                              fontFamily: 'Inter', fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          if (_isEdit && _reviewStatus == 'pending') ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: const Color(0xFFF59E0B)
                                        .withValues(alpha: 0.4)),
                              ),
                              child: const Text(
                                'Pending Approval',
                                style: TextStyle(
                                  fontFamily: 'Inter', fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFF59E0B),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 30, height: 30,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF3F4F6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded,
                            size: 16, color: Colors.black54),
                      ),
                    ),
                  ],
                ),
              ),

              const Padding(
                padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Divider(color: Color(0xFFEEEEEE), height: 1),
              ),

              // ── Scrollable body ──────────────────────────────────────────
              Flexible(
                child: _loadingDetail
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40),
                          child: CircularProgressIndicator(
                              color: AppColors.limeGreen),
                        ),
                      )
                    : SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(20, 16, 20, bottom + 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Error banner
                            if (_error != null) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEF4444)
                                      .withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: const Color(0xFFEF4444)
                                          .withValues(alpha: 0.3)),
                                ),
                                child: Row(children: [
                                  const Icon(Icons.error_outline_rounded,
                                      color: Color(0xFFEF4444), size: 16),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(_error!,
                                        style: const TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 12,
                                            color: Color(0xFFEF4444))),
                                  ),
                                ]),
                              ),
                              const SizedBox(height: 14),
                            ],

                            // ── Star rating ──────────────────────────────
                            _Label('Your Rating', required: true),
                            const SizedBox(height: 8),
                            _buildStars(),
                            const SizedBox(height: 4),
                            _rating == 0
                                ? const Text('Click a star to rate',
                                    style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 11,
                                        color: Color(0xFF9CA3AF)))
                                : Text(
                                    '${_rating.toStringAsFixed(1)} / 5',
                                    style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.limeGreen),
                                  ),
                            const SizedBox(height: 18),

                            // ── Review text ──────────────────────────────
                            _Label('Your Review', optional: true),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _contentCtrl,
                              maxLines:   5,
                              maxLength:  2000,
                              onChanged:  (_) => setState(() {}),
                              style: const TextStyle(
                                  fontFamily: 'Inter', fontSize: 13,
                                  color: Color(0xFF0A2540)),
                              decoration: InputDecoration(
                                hintText: 'Share your experience at this venue...',
                                hintStyle: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 13,
                                    color: Color(0xFF9CA3AF)),
                                counterText:
                                    '${_contentCtrl.text.length} / 2000',
                                counterStyle: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 11,
                                    color: Color(0xFF9CA3AF)),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                        color: Color(0xFFE5E7EB))),
                                enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                        color: Color(0xFFE5E7EB))),
                                focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                        color: AppColors.limeGreen)),
                                contentPadding: const EdgeInsets.all(12),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // ── Photos ───────────────────────────────────
                            _Label('Photos', optional: true,
                                suffix: '(optional, max 5)'),
                            const SizedBox(height: 8),
                            _buildPhotos(),
                            const SizedBox(height: 28),

                            // ── Footer buttons ───────────────────────────
                            Row(
                              children: [
                                if (_isEdit) ...[
                                  _DeleteOutlineBtn(
                                      onTap: _submitting ? null : _delete),
                                  const SizedBox(width: 10),
                                ],
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: _submitting
                                        ? null
                                        : () => Navigator.pop(context),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(
                                          color: Color(0xFFDDDDDD)),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 14),
                                    ),
                                    child: const Text('Cancel',
                                        style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black54)),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  flex: 2,
                                  child: ElevatedButton(
                                    onPressed: _submitting ? null : _submit,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.navyBlue,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 14),
                                    ),
                                    child: _submitting
                                        ? const SizedBox(
                                            width: 18, height: 18,
                                            child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2),
                                          )
                                        : Text(
                                            _isEdit
                                                ? 'Update Review'
                                                : 'Submit Review',
                                            style: const TextStyle(
                                                fontFamily: 'Inter',
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
              if (_submitting)
                Positioned.fill(
                  child: _UploadingOverlay(
                    hasImages: _pickedImages.isNotEmpty,
                  ),
                ),
            ],        // Stack children
          ),          // Stack
          ),          // Container
        ),            // ClipRRect
      ),              // ConstrainedBox
    );                // SafeArea
  }

  // ── Star row ──────────────────────────────────────────────────────────────
  Widget _buildStars() {
    return Row(
      children: List.generate(5, (i) {
        final val    = i + 1;
        final filled = _rating >= val;
        return GestureDetector(
          onTap: () => setState(() { _rating = val.toDouble(); _error = null; }),
          child: Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Icon(
              filled ? Icons.star_rounded : Icons.star_outline_rounded,
              size:  36,
              color: filled
                  ? const Color(0xFFF59E0B)
                  : const Color(0xFFD1D5DB),
            ),
          ),
        );
      }),
    );
  }

  // ── Photo grid ────────────────────────────────────────────────────────────
  Widget _buildPhotos() {
    return Wrap(
      spacing:    8,
      runSpacing: 8,
      children: [
        // Existing network images
        for (var i = 0; i < _existingImages.length; i++)
          _Thumbnail(
            child: Image.network(
              _existingImages[i]['imageUrl'] as String,
              fit:          BoxFit.cover,
              errorBuilder: (_, _, _) => const Icon(
                  Icons.broken_image_outlined, color: Colors.grey),
            ),
            onRemove: () => setState(() => _existingImages.removeAt(i)),
          ),

        // Newly picked local images
        for (var i = 0; i < _pickedImages.length; i++)
          _Thumbnail(
            child:    Image.file(File(_pickedImages[i].path), fit: BoxFit.cover),
            onRemove: () => setState(() => _pickedImages.removeAt(i)),
          ),

        // Add button
        if (_totalImages < 5)
          GestureDetector(
            onTap: _pickImages,
            child: Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                border: Border.all(
                    color: const Color(0xFFE5E7EB),
                    style: BorderStyle.solid),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_rounded,
                      size: 22, color: Color(0xFF9CA3AF)),
                  const SizedBox(height: 2),
                  Text(
                    _totalImages == 0 ? 'Add Photos' : 'Add More',
                    style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        color: Color(0xFF9CA3AF)),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────
// Label widget
// ─────────────────────────────────────────────────────────
class _Label extends StatelessWidget {
  final String text;
  final bool required;
  final bool optional;
  final String? suffix;

  const _Label(this.text,
      {this.required = false, this.optional = false, this.suffix});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(text,
            style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151))),
        if (required)
          const Text(' *',
              style: TextStyle(color: Color(0xFFEF4444), fontSize: 13)),
        if (optional || suffix != null) ...[
          const SizedBox(width: 4),
          Text(suffix ?? '(optional)',
              style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  color: Color(0xFF9CA3AF))),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────
// Image thumbnail with X remove button
// ─────────────────────────────────────────────────────────
class _Thumbnail extends StatelessWidget {
  final Widget child;
  final VoidCallback onRemove;

  const _Thumbnail({required this.child, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72, height: 72,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(width: 72, height: 72, child: child),
          ),
          Positioned(
            top:   -6,
            right: -6,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 20, height: 20,
                decoration: const BoxDecoration(
                  color: Color(0xFFEF4444), shape: BoxShape.circle),
                child: const Icon(Icons.close_rounded,
                    size: 12, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Delete outline button
// ─────────────────────────────────────────────────────────
class _DeleteOutlineBtn extends StatelessWidget {
  final VoidCallback? onTap;
  const _DeleteOutlineBtn({this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFEF4444)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text('Delete',
              style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFEF4444))),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Uploading overlay — shown over the sheet while submitting
// ─────────────────────────────────────────────────────────
class _UploadingOverlay extends StatelessWidget {
  final bool hasImages;
  const _UploadingOverlay({this.hasImages = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.93),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/gif/football-loader.gif',
            width:  130,
            height: 130,
            fit:    BoxFit.contain,
          ),
          const SizedBox(height: 14),
          Text(
            hasImages ? 'Uploading photos...' : 'Saving review...',
            style: const TextStyle(
              fontFamily: 'Jost',
              fontSize:   16,
              fontWeight: FontWeight.w700,
              color:      Color(0xFF0A2540),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Please wait a moment',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize:   12,
              color:      Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }
}
