import 'package:flutter/material.dart';

class MyBookingModel {
  final int id;
  final String bookingCode;
  final int userId;
  final int venueId;
  final String bookingDate;
  final String startTime;
  final String endTime;
  final int durationMinutes;
  final int numberOfPersons;
  final String sport;
  final String basePrice;
  final String serviceFee;
  final String discount;
  final String totalAmount;
  final String status;
  final String bookingType;
  final String paymentStatus;
  final String paymentMethod;
  final String? notes;
  final String? cancelledAt;
  final String? cancelReason;
  final String? completedAt;
  final String venueName;
  final String? primaryVenueImage;
  final String venueSlug;
  final String venueAddress;
  final String venueCity;
  final String groundName;
  final String subcategoryName;
  final String categoryName;
  final String? categoryColor;
  final String? categoryImage;
  final int groundId;
  final int? reviewId;
  final String? reviewStatus;
  final double? reviewRating;

  const MyBookingModel({
    required this.id,
    required this.bookingCode,
    required this.userId,
    required this.venueId,
    required this.bookingDate,
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
    required this.numberOfPersons,
    required this.sport,
    required this.basePrice,
    required this.serviceFee,
    required this.discount,
    required this.totalAmount,
    required this.status,
    required this.bookingType,
    required this.paymentStatus,
    required this.paymentMethod,
    this.notes,
    this.cancelledAt,
    this.cancelReason,
    this.completedAt,
    required this.venueName,
    this.primaryVenueImage,
    required this.venueSlug,
    required this.venueAddress,
    required this.venueCity,
    required this.groundName,
    required this.subcategoryName,
    required this.categoryName,
    this.categoryColor,
    this.categoryImage,
    required this.groundId,
    this.reviewId,
    this.reviewStatus,
    this.reviewRating,
  });

  factory MyBookingModel.fromJson(Map<String, dynamic> json) => MyBookingModel(
        id:              _parseInt(json['id']) ?? 0,
        bookingCode:     json['bookingCode']?.toString() ?? '',
        userId:          _parseInt(json['userId']) ?? 0,
        venueId:         _parseInt(json['venueId']) ?? 0,
        bookingDate:     json['bookingDate']?.toString() ?? '',
        startTime:       json['startTime']?.toString() ?? '',
        endTime:         json['endTime']?.toString() ?? '',
        durationMinutes: _parseInt(json['durationMinutes']) ?? 0,
        numberOfPersons: _parseInt(json['numberOfPersons']) ?? 1,
        sport:           json['sport']?.toString() ?? '',
        basePrice:       json['basePrice']?.toString() ?? '0',
        serviceFee:      json['serviceFee']?.toString() ?? '0',
        discount:        json['discount']?.toString() ?? '0',
        totalAmount:     json['totalAmount']?.toString() ?? '0',
        status:          json['status']?.toString() ?? '',
        bookingType:     json['bookingType']?.toString() ?? '',
        paymentStatus:   json['paymentStatus']?.toString() ?? '',
        paymentMethod:   json['paymentMethod']?.toString() ?? '',
        notes:           json['notes']?.toString(),
        cancelledAt:     json['cancelledAt']?.toString(),
        cancelReason:    json['cancelReason']?.toString(),
        completedAt:     json['completedAt']?.toString(),
        venueName:       json['venueName']?.toString() ?? '',
        primaryVenueImage: json['primaryVenueImage']?.toString(),
        venueSlug:       json['venueSlug']?.toString() ?? '',
        venueAddress:    json['venueAddress']?.toString() ?? '',
        venueCity:       json['venueCity']?.toString() ?? '',
        groundName:      json['groundName']?.toString() ?? '',
        subcategoryName: json['subcategoryName']?.toString() ?? '',
        categoryName:    json['categoryName']?.toString() ?? '',
        categoryColor:   json['categoryColor']?.toString(),
        categoryImage:   json['categoryImage']?.toString(),
        groundId:        _parseInt(json['groundId']) ?? 0,
        reviewId:        _parseInt(json['reviewId']),
        reviewStatus:    json['reviewStatus']?.toString(),
        reviewRating:    _parseDouble(json['reviewRating']),
      );

  static int? _parseInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  static double? _parseDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  // ── Computed getters ──────────────────────────────────────────────────────

  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';

  String get formattedDate {
    try {
      final dt = DateTime.parse(bookingDate);
      return '${dt.day.toString().padLeft(2, '0')}-'
          '${dt.month.toString().padLeft(2, '0')}-'
          '${dt.year}';
    } catch (_) {
      return bookingDate;
    }
  }

  String get timeSlot => '${_fmt(startTime)} - ${_fmt(endTime)}';

  String get displayAmount => '₹ $totalAmount';

  String get location => '$groundName, $venueCity';

  String _fmt(String t) {
    try {
      final parts = t.split(':');
      final h = int.parse(parts[0]);
      final m = parts[1];
      final period = h >= 12 ? 'PM' : 'AM';
      final hour = h > 12 ? h - 12 : (h == 0 ? 12 : h);
      return '$hour:$m $period';
    } catch (_) {
      return t;
    }
  }

  Color get statusColor {
    switch (status) {
      case 'pending':   return const Color(0xFFF59E0B);
      case 'confirmed': return const Color(0xFF2196F3);
      case 'completed': return const Color(0xFF4CAF50);
      case 'cancelled': return const Color(0xFFFF5252);
      default:          return Colors.grey;
    }
  }

  String get statusLabel {
    switch (status) {
      case 'pending':   return 'Pending';
      case 'confirmed': return 'Confirmed';
      case 'completed': return 'Completed';
      case 'cancelled': return 'Cancelled';
      default:
        return status.isNotEmpty
            ? status[0].toUpperCase() + status.substring(1)
            : '';
    }
  }
}
