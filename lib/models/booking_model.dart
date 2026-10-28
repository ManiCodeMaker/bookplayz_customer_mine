// ── lib/models/booking_model.dart ──

// ── Subcategory with grounds (from venue-category subcategories API) ──
class BookingSubcategoryModel {
  final int id;
  final String name;
  final int categoryId;
  final String categoryName;
  final String? categoryColor;
  final String? categoryImage;
  final String? image;
  final String? description;
  final String? color;
  final String status;
  final int venueSubcategoryId;
  final String venueSubcategoryStatus;
  final List<BookingGroundModel> grounds;

  const BookingSubcategoryModel({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.categoryName,
    this.categoryColor,
    this.categoryImage,
    this.image,
    this.description,
    this.color,
    required this.status,
    required this.venueSubcategoryId,
    required this.venueSubcategoryStatus,
    required this.grounds,
  });

  factory BookingSubcategoryModel.fromJson(Map<String, dynamic> j) =>
      BookingSubcategoryModel(
        id:                      j['id'] as int,
        name:                    j['name'] as String? ?? '',
        categoryId:              j['categoryId'] as int,
        categoryName:            j['categoryName'] as String? ?? '',
        categoryColor:           j['categoryColor'] as String?,
        categoryImage:           j['categoryImage'] as String?,
        image:                   j['image'] as String?,
        description:             j['description'] as String?,
        color:                   j['color'] as String?,
        status:                  j['status'] as String? ?? '',
        venueSubcategoryId:      j['venueSubcategoryId'] as int,
        venueSubcategoryStatus:  j['venueSubcategoryStatus'] as String? ?? '',
        grounds:                 (j['grounds'] as List<dynamic>? ?? [])
                                   .map((e) => BookingGroundModel.fromJson(
                                       e as Map<String, dynamic>))
                                   .toList(),
      );
}

// ── Ground model ──
class BookingGroundModel {
  final int id;
  final int venueId;
  final String name;
  final String? description;
  final String status;
  final int sortOrder;
  final int vgsId;
  final double pricePerHour;
  final double pricePerPerson;
  final int minBookingSlots;
  final int? maxCapacity;
  final String vgsStatus;

  const BookingGroundModel({
    required this.id,
    required this.venueId,
    required this.name,
    this.description,
    required this.status,
    required this.sortOrder,
    required this.vgsId,
    required this.pricePerHour,
    required this.pricePerPerson,
    required this.minBookingSlots,
    this.maxCapacity,
    required this.vgsStatus,
  });

  factory BookingGroundModel.fromJson(Map<String, dynamic> j) =>
      BookingGroundModel(
        id:               j['id'] as int,
        venueId:          j['venueId'] as int,
        name:             j['name'] as String? ?? '',
        description:      j['description'] as String?,
        status:           j['status'] as String? ?? '',
        sortOrder:        j['sortOrder'] as int? ?? 0,
        vgsId:            j['vgsId'] as int,
        pricePerHour:     double.tryParse(
                              j['pricePerHour']?.toString() ?? '0') ?? 0,
        pricePerPerson:   double.tryParse(
                              j['pricePerPerson']?.toString() ?? '0') ?? 0,
        minBookingSlots:  (j['minBookingSlots'] as num?)?.toInt() ?? 1,
        maxCapacity:      (j['maxCapacity'] as num?)?.toInt(),
        vgsStatus:        j['vgsStatus'] as String? ?? '',
      );
}

// ── Availability response ──
/// A booked / blocked time range in minutes from midnight, [startMin, endMin).
class UnavailableRange {
  final int startMin;
  final int endMin;
  const UnavailableRange(this.startMin, this.endMin);
}

class GroundAvailabilityModel {
  final int venueId;
  final String date;
  final int groundId;
  final List<String> unavailableSlots; // start times, e.g. ["12:00", "16:00"]
  // Full ranges — a 3-hour block is ONE entry (10:00–13:00), so checking only
  // start times would leave the 2nd and 3rd hour bookable.
  final List<UnavailableRange> ranges;

  const GroundAvailabilityModel({
    required this.venueId,
    required this.date,
    required this.groundId,
    required this.unavailableSlots,
    this.ranges = const [],
  });

  static int _toMin(String t) {
    final p = t.split(':');
    if (p.length < 2) return 0;
    return (int.tryParse(p[0]) ?? 0) * 60 + (int.tryParse(p[1]) ?? 0);
  }

  /// True when the slot starting at [slot] ("HH:MM", lasting [slotDuration]
  /// minutes) overlaps any booked or blocked range.
  bool isSlotUnavailable(String slot, int slotDuration) {
    final s = _toMin(slot);
    final e = s + slotDuration;
    return ranges.any((r) => s < r.endMin && e > r.startMin);
  }

  factory GroundAvailabilityModel.fromJson(Map<String, dynamic> j) {
    final rawSlots = j['unavailableSlots'] as List<dynamic>? ?? [];
    final slots = <String>[];
    final ranges = <UnavailableRange>[];

    for (final e in rawSlots) {
      if (e is String) {
        // old format: "12:00" — start only, treat as a single minute marker
        if (e.isEmpty) continue;
        slots.add(e);
        final s = _toMin(e);
        ranges.add(UnavailableRange(s, s + 1));
      } else if (e is Map<String, dynamic>) {
        // new format: { startTime: "12:00:00", endTime: "15:00:00", ... }
        final start = e['startTime'] as String? ?? '';
        if (start.isEmpty) continue;
        final end = e['endTime'] as String? ?? '';
        slots.add(start.length >= 5 ? start.substring(0, 5) : start);
        final s = _toMin(start);
        var en = end.isEmpty ? s + 60 : _toMin(end);
        if (en <= s) en += 24 * 60; // range ending at/after midnight ("00:00")
        ranges.add(UnavailableRange(s, en));
      }
    }

    return GroundAvailabilityModel(
      venueId:          j['venueId'] as int,
      date:             j['date'] as String? ?? '',
      groundId:         j['groundId'] as int,
      unavailableSlots: slots,
      ranges:           ranges,
    );
  }
}


// ── Booking description request ──
class BookingDescriptionRequest {
  final String venueSlug;
  final String timing;     // "08:00_10:00"
  final int categoryId;    // venueCategoryId
  final int subCategoryId; // venueSubcategoryId

  const BookingDescriptionRequest({
    required this.venueSlug,
    required this.timing,
    required this.categoryId,
    required this.subCategoryId,
  });

  Map<String, dynamic> toJson() => {
        'venueSlug':    venueSlug,
        'timing':       timing,
        'categoryId':   categoryId,
        'subCategoryId': subCategoryId,
      };
}

// ── Booking description response ──
class BookingDescriptionModel {
  final BookingDescVenue venue;
  final BookingDescCategory category;
  final BookingDescSubCategory subCategory;
  final BookingDescTiming timing;
  final BookingDescPricing pricing;
  final List<dynamic> discounts;

  const BookingDescriptionModel({
    required this.venue,
    required this.category,
    required this.subCategory,
    required this.timing,
    required this.pricing,
    required this.discounts,
  });

  factory BookingDescriptionModel.fromJson(Map<String, dynamic> j) =>
      BookingDescriptionModel(
        venue:       BookingDescVenue.fromJson(j['venue']),
        category:    BookingDescCategory.fromJson(j['category']),
        subCategory: BookingDescSubCategory.fromJson(j['subCategory']),
        timing:      BookingDescTiming.fromJson(j['timing']),
        pricing:     BookingDescPricing.fromJson(j['pricing']),
        discounts:   j['discounts'] as List<dynamic>? ?? [],
      );
}

class BookingDescVenue {
  final int id;
  final String name;
  final String slug;
  final String address;
  final String city;
  final String state;
  final String? primaryImage;
  final String openTime;
  final String closeTime;
  final int slotDuration;
  final String serviceFeeType;
  final double serviceFeeValue;

  const BookingDescVenue({
    required this.id,
    required this.name,
    required this.slug,
    required this.address,
    required this.city,
    required this.state,
    this.primaryImage,
    required this.openTime,
    required this.closeTime,
    required this.slotDuration,
    required this.serviceFeeType,
    required this.serviceFeeValue,
  });

  factory BookingDescVenue.fromJson(Map<String, dynamic> j) =>
      BookingDescVenue(
        id:               j['id'] as int,
        name:             j['name'] as String? ?? '',
        slug:             j['slug'] as String? ?? '',
        address:          j['address'] as String? ?? '',
        city:             j['city'] as String? ?? '',
        state:            j['state'] as String? ?? '',
        primaryImage:     j['primaryImage'] as String?,
        openTime:         j['openTime'] as String? ?? '',
        closeTime:        j['closeTime'] as String? ?? '',
        slotDuration:     (j['slotDuration'] as num?)?.toInt() ?? 60,
        serviceFeeType:   j['serviceFeeType'] as String? ?? '',
        serviceFeeValue:  double.tryParse(
                              j['serviceFeeValue']?.toString() ?? '0') ?? 0,
      );
}

class BookingDescCategory {
  final int id;
  final String name;
  final String? image;
  final String? color;
  final int venueCategoryId;

  const BookingDescCategory({
    required this.id,
    required this.name,
    this.image,
    this.color,
    required this.venueCategoryId,
  });

  factory BookingDescCategory.fromJson(Map<String, dynamic> j) =>
      BookingDescCategory(
        id:             j['id'] as int,
        name:           j['name'] as String? ?? '',
        image:          j['image'] as String?,
        color:          j['color'] as String?,
        venueCategoryId: j['venueCategoryId'] as int,
      );
}

class BookingDescSubCategory {
  final int id;
  final String name;
  final String? description;
  final int venueSubcategoryId;

  const BookingDescSubCategory({
    required this.id,
    required this.name,
    this.description,
    required this.venueSubcategoryId,
  });

  factory BookingDescSubCategory.fromJson(Map<String, dynamic> j) =>
      BookingDescSubCategory(
        id:                 j['id'] as int,
        name:               j['name'] as String? ?? '',
        description:        j['description'] as String?,
        venueSubcategoryId: j['venueSubcategoryId'] as int,
      );
}

class BookingDescTiming {
  final String raw;        // "08:00_10:00"
  final String startTime;  // "08:00:00"
  final String endTime;    // "10:00:00"
  final int durationHours;

  const BookingDescTiming({
    required this.raw,
    required this.startTime,
    required this.endTime,
    required this.durationHours,
  });

  factory BookingDescTiming.fromJson(Map<String, dynamic> j) =>
      BookingDescTiming(
        raw:           j['raw'] as String? ?? '',
        startTime:     j['startTime'] as String? ?? '',
        endTime:       j['endTime'] as String? ?? '',
        durationHours: (j['durationHours'] as num?)?.toInt() ?? 1,
      );
}

class BookingDescPricing {
  final int minPricePerHour;
  final int maxPricePerHour;
  final int groundCount;
  final int durationHours;
  final String note;
  final List<BookingDescGroundPrice> perGround;

  const BookingDescPricing({
    required this.minPricePerHour,
    required this.maxPricePerHour,
    required this.groundCount,
    required this.durationHours,
    required this.note,
    required this.perGround,
  });

  factory BookingDescPricing.fromJson(Map<String, dynamic> j) {
    final summary = j['summary'] as Map<String, dynamic>? ?? {};
    return BookingDescPricing(
      minPricePerHour: (summary['minPricePerHour'] as num?)?.round() ?? 0,
      maxPricePerHour: (summary['maxPricePerHour'] as num?)?.round() ?? 0,
      groundCount:     (summary['groundCount'] as num?)?.toInt() ?? 0,
      durationHours:   (summary['durationHours'] as num?)?.toInt() ?? 1,
      note:            summary['note'] as String? ?? '',
      perGround:       (j['perGround'] as List<dynamic>? ?? [])
                         .map((e) => BookingDescGroundPrice.fromJson(
                             e as Map<String, dynamic>))
                         .toList(),
    );
  }
}

class BookingDescGroundPrice {
  final int groundId;
  final String groundName;
  final int pricePerHour;
  final int pricePerPerson;
  final int minBookingSlots;
  final int? maxCapacity;
  final int basePrice;
  final bool allowPartPayment;
  final int advancePaymentPercent;
  final int? advancePaymentAmount;

  const BookingDescGroundPrice({
    required this.groundId,
    required this.groundName,
    required this.pricePerHour,
    required this.pricePerPerson,
    required this.minBookingSlots,
    this.maxCapacity,
    required this.basePrice,
    required this.allowPartPayment,
    required this.advancePaymentPercent,
    this.advancePaymentAmount,
  });

  factory BookingDescGroundPrice.fromJson(Map<String, dynamic> j) =>
      BookingDescGroundPrice(
        groundId:        j['groundId'] as int,
        groundName:      j['groundName'] as String? ?? '',
        pricePerHour:    (j['pricePerHour'] as num?)?.round() ?? 0,
        pricePerPerson:  (j['pricePerPerson'] as num?)?.round() ?? 0,
        minBookingSlots: (j['minBookingSlots'] as num?)?.toInt() ?? 1,
        maxCapacity:     (j['maxCapacity'] as num?)?.toInt(),
        basePrice:       (j['basePrice'] as num?)?.round() ?? 0,
        allowPartPayment:       j['allowPartPayment'] as bool? ?? false,
        advancePaymentPercent:  (j['advancePaymentPercent'] as num?)?.toInt() ?? 30,
        advancePaymentAmount:   (j['advancePaymentAmount'] as num?)?.ceil(),
      );
}