// lib/models/public_event_model.dart
//
// GET /events/venue/:venueId — venue promotional "packages" shown in the
// Bulk / Corporate enquiry flow (mirrors the web's BulkCorporateModal).

class PublicEventModel {
  final int id;
  final String eventTitle;
  final String eventDescription;
  final String? image;
  final String? categoryName;
  final String? categoryImage;
  final String? fromDateTime;
  final String? toDateTime;

  const PublicEventModel({
    required this.id,
    required this.eventTitle,
    required this.eventDescription,
    this.image,
    this.categoryName,
    this.categoryImage,
    this.fromDateTime,
    this.toDateTime,
  });

  factory PublicEventModel.fromJson(Map<String, dynamic> j) {
    return PublicEventModel(
      id: j['id'] as int,
      eventTitle: j['eventTitle'] as String? ?? '',
      eventDescription: j['eventDescription'] as String? ?? '',
      image: j['image'] as String?,
      categoryName: j['categoryName'] as String?,
      categoryImage: j['categoryImage'] as String?,
      fromDateTime: j['fromDateTime'] as String?,
      toDateTime: j['toDateTime'] as String?,
    );
  }

  /// Some backends still return relative upload paths — resolve against the
  /// API host (minus the trailing /api) just like the web client does.
  static String? resolveUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('http')) return url;
    const apiBase = 'https://api.bookplayz.com/api';
    final serverBase = apiBase.replaceFirst(RegExp(r'/api$'), '');
    return '$serverBase$url';
  }

  String? get resolvedImage => resolveUrl(image);
  String? get resolvedCategoryImage => resolveUrl(categoryImage);

  String get dateRangeLabel {
    if (fromDateTime == null || fromDateTime!.isEmpty) return '';
    final from = DateTime.tryParse(fromDateTime!);
    if (from == null) return '';
    final to = toDateTime != null ? DateTime.tryParse(toDateTime!) : null;
    String fmt(DateTime d) {
      const months = [
        '',
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${d.day} ${months[d.month]} ${d.year}';
    }

    if (to == null) return fmt(from);
    final startLabel = fmt(from);
    final endLabel = fmt(to);
    return startLabel == endLabel ? startLabel : '$startLabel – $endLabel';
  }
}
