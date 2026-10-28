import 'dart:convert';

import 'package:bookplayz/models/venue_model.dart';

int _asInt(dynamic v, [int d = 0]) =>
    v is int ? v : (v is num ? v.toInt() : int.tryParse(v?.toString() ?? '') ?? d);

double? _asDouble(dynamic v) =>
    v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '');

bool _asBool(dynamic v) =>
    v is bool ? v : (v?.toString().toLowerCase() == 'true' || v?.toString() == '1');

String? _asStr(dynamic v) => v?.toString();

List<dynamic> _asList(dynamic v) {
  if (v is List) return v;
  if (v is String && v.trim().isNotEmpty) {
    try {
      final d = jsonDecode(v);
      if (d is List) return d;
    } catch (_) {}
  }
  return const [];
}

Map<String, dynamic> _asMap(dynamic v) =>
    v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};

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
      id:                    _asInt(j['id']),
      ownerId:               _asInt(j['ownerId']),
      name:                  _asStr(j['name']) ?? '',
      slug:                  _asStr(j['slug']) ?? '',
      description:           _asStr(j['description']),
      address:               _asStr(j['address']) ?? '',
      city:                  _asStr(j['city']) ?? '',
      state:                 _asStr(j['state']) ?? '',
      districtName:          _asStr(j['districtName']),
      latitude:              _asDouble(j['latitude']),
      longitude:             _asDouble(j['longitude']),
      phone:                 _asStr(j['phone']),
      email:                 _asStr(j['email']),
      slotDuration:          _asInt(j['slotDuration'], 60),
      openTime:              _asStr(j['openTime']) ?? '',
      closeTime:             _asStr(j['closeTime']) ?? '',
      advanceBookingDays:    _asInt(j['advanceBookingDays']),
      serviceFeeType:        _asStr(j['serviceFeeType']) ?? '',
      serviceFeeValue:       _asDouble(j['serviceFeeValue']) ?? 0.0,
      status:                _asStr(j['status']) ?? '',
      metaTitle:             _asStr(j['metaTitle']),
      metaDescription:       _asStr(j['metaDescription']),
      rating:                _asDouble(j['rating']) ?? 0.0,
      totalRatings:          _asInt(j['totalRatings']),
      totalBookings:         _asInt(j['totalBookings']),
      isFeatured:            _asBool(j['isFeatured']),
      membership:            _asBool(j['membership']),
      bulkOrCorporateBooking: _asBool(j['bulkOrCorporateBooking']),
      venueProfileImage:     _asStr(j['venueProfileImage']),
      venueDataId:           _asStr(j['venueDataId']),
      ownerName:             _asStr(j['ownerName']),
      rules:                 _asList(j['rules']).map((e) => e.toString()).toList(),
      amenities:             _asList(j['amenities'])
                               .map((e) => VenueDetailAmenityModel.fromJson(_asMap(e)))
                               .toList(),
      categories:            _asList(j['categories']).map((e) {
                                 final m = _asMap(e);
                                 return VenueCategoryModel(
                                   id:         _asInt(m['id']),
                                   categoryId: _asInt(m['categoryId']),
                                   name:       _asStr(m['categoryName']) ?? '',
                                   image:      _asStr(m['categoryImage']),
                                   color:      _asStr(m['categoryColor']),
                                 );
                               }).toList(),
      subcategories:         _asList(j['subcategories']).map((e) {
                                 final m = _asMap(e);
                                 return VenueSubcategoryModel(
                                   id:            _asInt(m['id']),
                                   subcategoryId: _asInt(m['subcategoryId']),
                                   name:          _asStr(m['subcategoryName']) ?? '',
                                 );
                               }).toList(),
      images:                _asList(j['images'])
                               .map((e) => VenueImageModel.fromJson(_asMap(e)))
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
        id:        _asInt(j['id']),
        amenityId: _asInt(j['amenityId']),
        name:      _asStr(j['name']) ?? '',
        slug:      _asStr(j['slug']) ?? '',
        icon:      _asStr(j['icon']),
        status:    _asStr(j['status']) ?? '',
      );
}