import 'package:bookplayz/models/venue_model.dart';

class VenueDetailModel {
  final int id;
  final int ownerId;
  final String name;
  final String slug;
  final String? description;
  final String address;
  final String city;
  final String state;
  final String? districtName;
  final double? latitude;
  final double? longitude;
  final String? phone;
  final String? email;
  final int slotDuration;
  final String openTime;
  final String closeTime;
  final int advanceBookingDays;
  final String serviceFeeType;
  final double serviceFeeValue;
  final String status;
  final String? metaTitle;
  final String? metaDescription;
  final double rating;
  final int totalRatings;
  final int totalBookings;
  final bool isFeatured;
  final bool membership;
  final bool bulkOrCorporateBooking;
  final String? venueProfileImage;
  final String? venueDataId;
  final String? ownerName;
  final List<String> rules;
  final List<VenueDetailAmenityModel> amenities;
  final List<VenueCategoryModel> categories;
  final List<VenueSubcategoryModel> subcategories;
  final List<VenueImageModel> images;

  const VenueDetailModel({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.slug,
    this.description,
    required this.address,
    required this.city,
    required this.state,
    this.districtName,
    this.latitude,
    this.longitude,
    this.phone,
    this.email,
    required this.slotDuration,
    required this.openTime,
    required this.closeTime,
    required this.advanceBookingDays,
    required this.serviceFeeType,
    required this.serviceFeeValue,
    required this.status,
    this.metaTitle,
    this.metaDescription,
    required this.rating,
    required this.totalRatings,
    required this.totalBookings,
    required this.isFeatured,
    required this.membership,
    required this.bulkOrCorporateBooking,
    this.venueProfileImage,
    this.venueDataId,
    this.ownerName,
    required this.rules,
    required this.amenities,
    required this.categories,
    required this.subcategories,
    required this.images,
  });

  /// Primary image — isPrimary flag first, then first in list
  String? get primaryImage {
    if (images.isEmpty) return venueProfileImage;
    final primary = images.where((i) => i.isPrimary).toList();
    if (primary.isNotEmpty) return primary.first.imageUrl;
    return images.first.imageUrl;
  }

  /// Formatted timing string e.g. "06:00 AM – 11:00 PM"
  String get timingLabel {
    String _fmt(String t) {
      final parts = t.split(':');
      if (parts.length < 2) return t;
      final h = int.tryParse(parts[0]) ?? 0;
      final m = parts[1];
      final period = h >= 12 ? 'PM' : 'AM';
      final h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
      return '$h12:$m $period';
    }
    return '${_fmt(openTime)} – ${_fmt(closeTime)}';
  }

  factory VenueDetailModel.fromJson(Map<String, dynamic> j) {
    return VenueDetailModel(
      id:                    j['id'] as int,
      ownerId:               j['ownerId'] as int? ?? 0,
      name:                  j['name'] as String? ?? '',
      slug:                  j['slug'] as String? ?? '',
      description:           j['description'] as String?,
      address:               j['address'] as String? ?? '',
      city:                  j['city'] as String? ?? '',
      state:                 j['state'] as String? ?? '',
      districtName:          j['districtName'] as String?,
      latitude:              (j['latitude'] as num?)?.toDouble(),
      longitude:             (j['longitude'] as num?)?.toDouble(),
      phone:                 j['phone'] as String?,
      email:                 j['email'] as String?,
      slotDuration:          j['slotDuration'] as int? ?? 60,
      openTime:              j['openTime'] as String? ?? '',
      closeTime:             j['closeTime'] as String? ?? '',
      advanceBookingDays:    j['advanceBookingDays'] as int? ?? 0,
      serviceFeeType:        j['serviceFeeType'] as String? ?? '',
      serviceFeeValue:       double.tryParse(j['serviceFeeValue']?.toString() ?? '0') ?? 0.0,
      status:                j['status'] as String? ?? '',
      metaTitle:             j['metaTitle'] as String?,
      metaDescription:       j['metaDescription'] as String?,
      rating:                double.tryParse(j['rating']?.toString() ?? '0') ?? 0.0,
      totalRatings:          j['totalRatings'] as int? ?? 0,
      totalBookings:         j['totalBookings'] as int? ?? 0,
      isFeatured:            j['isFeatured'] as bool? ?? false,
      membership:            j['membership'] as bool? ?? false,
      bulkOrCorporateBooking: j['bulkOrCorporateBooking'] as bool? ?? false,
      venueProfileImage:     j['venueProfileImage'] as String?,
      venueDataId:           j['venueDataId'] as String?,
      ownerName:             j['ownerName'] as String?,
      rules:                 (j['rules'] as List<dynamic>? ?? [])
                               .map((e) => e.toString())
                               .toList(),
      amenities:             (j['amenities'] as List<dynamic>? ?? [])
                               .map((e) => VenueDetailAmenityModel.fromJson(e as Map<String, dynamic>))
                               .toList(),
      categories:            (j['categories'] as List<dynamic>? ?? [])
                               .map((e) {
                                 final m = e as Map<String, dynamic>;
                                 return VenueCategoryModel(
                                   id:         m['id'] as int,
                                   categoryId: m['categoryId'] as int,
                                   name:       m['categoryName'] as String? ?? '',
                                   image:      m['categoryImage'] as String?,
                                   color:      m['categoryColor'] as String?,
                                 );
                               })
                               .toList(),
      subcategories:         (j['subcategories'] as List<dynamic>? ?? [])
                               .map((e) {
                                 final m = e as Map<String, dynamic>;
                                 return VenueSubcategoryModel(
                                   id:            m['id'] as int,
                                   subcategoryId: m['subcategoryId'] as int,
                                   name:          m['subcategoryName'] as String? ?? '',
                                 );
                               })
                               .toList(),
      images:                (j['images'] as List<dynamic>? ?? [])
                               .map((e) => VenueImageModel.fromJson(e as Map<String, dynamic>))
                               .toList(),
    );
  }
}

class VenueDetailAmenityModel {
  final int id;
  final int amenityId;
  final String name;
  final String slug;
  final String? icon;
  final String status;

  const VenueDetailAmenityModel({
    required this.id,
    required this.amenityId,
    required this.name,
    required this.slug,
    this.icon,
    required this.status,
  });

  factory VenueDetailAmenityModel.fromJson(Map<String, dynamic> j) =>
      VenueDetailAmenityModel(
        id:        j['id'] as int,
        amenityId: j['amenityId'] as int,
        name:      j['name'] as String? ?? '',
        slug:      j['slug'] as String? ?? '',
        icon:      j['icon'] as String?,
        status:    j['status'] as String? ?? '',
      );
}