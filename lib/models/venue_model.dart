import 'dart:math';
import 'package:bookplayz/api/session_manager.dart';
double? _calcDistance(double? vLat, double? vLng) {
  final uLat = SessionManager.instance.latitude;
  final uLng = SessionManager.instance.longitude;
  if (vLat == null || vLng == null || uLat == null || uLng == null) return null;
  const R = 6371.0;
  final dLat = (vLat - uLat) * pi / 180;
  final dLng = (vLng - uLng) * pi / 180;
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(uLat * pi / 180) * cos(vLat * pi / 180) *
      sin(dLng / 2) * sin(dLng / 2);
  final c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return double.parse((R * c).toStringAsFixed(1));
}
class VenueModel {
  final int id;
  final String name;
  final String slug;
  final String? description;
  final String address;
  final String city;
  final String state;
  final String? districtName;
  final double? latitude;
  final double? longitude;
  final double rating;
  final int totalRatings;
  final String? primaryImage;
  final List<VenueCategoryModel> categories;
  final List<VenueSubcategoryModel> subcategories;
  final List<VenueImageModel> images;
  final double? distance;

  const VenueModel({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    required this.address,
    required this.city,
    required this.state,
    this.districtName,
    this.latitude,
    this.longitude,
    required this.rating,
    required this.totalRatings,
    this.primaryImage,
    required this.categories,
    required this.subcategories,
    required this.images,
    this.distance,
  });

  factory VenueModel.fromJson(Map<String, dynamic> j) => VenueModel(
        id:             j['id'] as int,
        name:           j['name'] as String? ?? '',
        slug:           j['slug'] as String? ?? '',
        description:    j['description'] as String?,
        address:        j['address'] as String? ?? '',
        city:           j['city'] as String? ?? '',
        state:          j['state'] as String? ?? '',
        districtName:   j['districtName'] as String?,
        latitude:       (j['latitude'] as num?)?.toDouble(),
        longitude:      (j['longitude'] as num?)?.toDouble(),
        rating:         double.tryParse(j['rating']?.toString() ?? '0') ?? 0.0,
        totalRatings:   j['totalRatings'] as int? ?? 0,
        primaryImage:   j['primaryImage'] as String?,
        categories:     (j['categories'] as List<dynamic>? ?? [])
            .map((e) => VenueCategoryModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        subcategories:  (j['subcategories'] as List<dynamic>? ?? [])
            .map((e) => VenueSubcategoryModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        images:         (j['images'] as List<dynamic>? ?? [])
            .map((e) => VenueImageModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        distance: (j['distance'] as num?)?.toDouble() ??
          _calcDistance(
            (j['latitude'] as num?)?.toDouble(),
            (j['longitude'] as num?)?.toDouble(),
          ),
      );
}

class VenueCategoryModel {
  final int id;
  final int categoryId;
  final String name;
  final String? image;
  final String? color;

  const VenueCategoryModel({
    required this.id,
    required this.categoryId,
    required this.name,
    this.image,
    this.color,
  });

  factory VenueCategoryModel.fromJson(Map<String, dynamic> j) =>
      VenueCategoryModel(
        id:         j['id'] as int,
        categoryId: j['categoryId'] as int,
           name:       j['name'] as String? ?? '',
        image:      j['image'] as String?,
        color:      j['color'] as String?,
      );
}

class VenueSubcategoryModel {
  final int id;
  final int subcategoryId;
  final String name;

  const VenueSubcategoryModel({
    required this.id,
    required this.subcategoryId,
    required this.name,
  });

  factory VenueSubcategoryModel.fromJson(Map<String, dynamic> j) =>
      VenueSubcategoryModel(
        id:            j['id'] as int,
        subcategoryId: j['subcategoryId'] as int,
         name:          j['name'] as String? ?? '',
      );
}

class VenueImageModel {
  final int id;
  final String imageUrl;
  final bool isPrimary;
  final int sortOrder;

  const VenueImageModel({
    required this.id,
    required this.imageUrl,
    required this.isPrimary,
    required this.sortOrder,
  });

  factory VenueImageModel.fromJson(Map<String, dynamic> j) => VenueImageModel(
        id:        j['id'] as int,
        imageUrl:  j['imageUrl'] as String? ?? '',
        isPrimary: j['isPrimary'] as bool? ?? false,
        sortOrder: j['sortOrder'] as int? ?? 0,
      );
}

class VenuePagination {
  final int total;
  final int page;
  final int limit;
  final int pages;

  const VenuePagination({
    required this.total,
    required this.page,
    required this.limit,
    required this.pages,
  });

  bool get hasNext => page < pages;

  factory VenuePagination.fromJson(Map<String, dynamic> j) => VenuePagination(
        total: j['total'] as int,
        page:  j['page'] as int,
        limit: j['limit'] as int,
        pages: j['pages'] as int,
      );
}

class VenueSearchResult {
  final List<VenueModel> venues;
  final VenuePagination pagination;

  const VenueSearchResult({required this.venues, required this.pagination});
}