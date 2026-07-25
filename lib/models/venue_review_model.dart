class VenueReview {
  final int id;
  final double rating;
  final String content;
  final String userName;
  final String? subcategoryName;
  final String? categoryName;
  final String approvedAt;
  final List<String> imageUrls;

  const VenueReview({
    required this.id,
    required this.rating,
    required this.content,
    required this.userName,
    this.subcategoryName,
    this.categoryName,
    required this.approvedAt,
    required this.imageUrls,
  });

  factory VenueReview.fromJson(Map<String, dynamic> j) {
    return VenueReview(
      id:              j['id'] as int,
      rating:          double.tryParse(j['rating']?.toString() ?? '0') ?? 0.0,
      content:         j['content'] as String? ?? '',
      userName:        j['userName'] as String? ?? 'User',
      subcategoryName: j['subcategoryName'] as String?,
      categoryName:    j['categoryName'] as String?,
      approvedAt:      j['approvedAt'] as String? ?? '',
      imageUrls:       (j['images'] as List<dynamic>? ?? [])
                           .map((e) => (e as Map<String, dynamic>)['imageUrl'] as String)
                           .toList(),
    );
  }
}

// ── Top review per nearby venue (GET /reviews/nearby/top) ──
class NearbyTopReview {
  final int reviewId;
  final double rating;
  final String content;
  final int helpfulCount;
  final String userName;
  final String? groundName;
  final double distance;
  final int venueId;
  final String venueName;
  final String? primaryImage;

  const NearbyTopReview({
    required this.reviewId,
    required this.rating,
    required this.content,
    required this.helpfulCount,
    required this.userName,
    this.groundName,
    required this.distance,
    required this.venueId,
    required this.venueName,
    this.primaryImage,
  });

  /// Some backends return relative upload paths — resolve against the API
  /// host (minus the trailing /api), same as elsewhere in the app.
  String? get resolvedImage {
    final url = primaryImage;
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('http')) return url;
    const apiBase = 'https://api.bookplayz.com/api';
    final serverBase = apiBase.replaceFirst(RegExp(r'/api$'), '');
    return '$serverBase$url';
  }

  factory NearbyTopReview.fromJson(Map<String, dynamic> j) {
    return NearbyTopReview(
      reviewId:     j['reviewId'] as int? ?? 0,
      rating:       double.tryParse(j['rating']?.toString() ?? '0') ?? 0.0,
      content:      j['content'] as String? ?? '',
      helpfulCount: j['helpfulCount'] as int? ?? 0,
      userName:     j['userName'] as String? ?? 'User',
      groundName:   j['groundName'] as String?,
      distance:     double.tryParse(j['distance']?.toString() ?? '0') ?? 0.0,
      venueId:      j['venueId'] as int? ?? 0,
      venueName:    j['venueName'] as String? ?? '',
      primaryImage: j['primaryImage'] as String?,
    );
  }
}

class VenueReviewMeta {
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final bool hasNext;
  final bool hasPrev;

  const VenueReviewMeta({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
    required this.hasNext,
    required this.hasPrev,
  });

  factory VenueReviewMeta.fromJson(Map<String, dynamic> j) {
    return VenueReviewMeta(
      page:       j['page'] as int? ?? 1,
      limit:      j['limit'] as int? ?? 5,
      total:      j['total'] as int? ?? 0,
      totalPages: j['totalPages'] as int? ?? 0,
      hasNext:    j['hasNext'] as bool? ?? false,
      hasPrev:    j['hasPrev'] as bool? ?? false,
    );
  }
}
