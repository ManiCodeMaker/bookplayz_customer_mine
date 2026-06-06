import 'package:bookplayz/api/session_manager.dart';
import 'package:bookplayz/models/venue_detail_model.dart';
import 'package:bookplayz/models/booking_model.dart';

import 'api_service.dart';
import '../models/venue_model.dart';

// ── Constants ─────────────────────────────────────────────────────────────────
class ApiConstants {
  ApiConstants._();
  static const String baseUrl = 'https://api.bookplayz.com/api';
}

// ── Auth ──────────────────────────────────────────────────────────────────────
class AuthApi {
  AuthApi._();

  static const String requestOtpUrl   = '${ApiConstants.baseUrl}/auth/phone-auth/request';
  static const String verifyOtpUrl    = '${ApiConstants.baseUrl}/auth/phone-auth/verify';
  static const String refreshTokenUrl = '${ApiConstants.baseUrl}/auth/refresh-token';

  static Future<Map<String, dynamic>> requestOtp(String mobile) async {
    final res = await ApiService.instance.post(requestOtpUrl, {'mobile': mobile});
    return res['data'] as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> verifyOtp({
    required String mobile,
    required String otp,
  }) async {
    final res = await ApiService.instance.post(verifyOtpUrl, {'mobile': mobile, 'otp': otp});
    return res['data'] as Map<String, dynamic>;
  }
}

// ── Venues ────────────────────────────────────────────────────────────────────
class VenueApi {
  VenueApi._();

  static String _search({
    required double latitude,
    required double longitude,
    int page = 1,
    int limit = 12,
    double radius = 20,
    String? city,
  }) {
    var url = '${ApiConstants.baseUrl}/venues/search'
        '?page=$page&limit=$limit'
        '&latitude=$latitude&longitude=$longitude'
        '&radius=$radius';
    if (city != null && city.isNotEmpty) url += '&city=$city';
    return url;
  }

  static Future<List<String>> fetchCities(String q) async {
    final res = await ApiService.instance.get(
      '${ApiConstants.baseUrl}/venues/cities?q=$q',
    );
    return (res['data'] as List<dynamic>).map((e) => e as String).toList();
  }

  static Future<VenueSearchResult> search({
    required double latitude,
    required double longitude,
    int page = 1,
    int limit = 12,
    double radius = 20,
    String? city,
  }) async {
    final res = await ApiService.instance.get(_search(
      latitude: latitude,
      longitude: longitude,
      page: page,
      limit: limit,
      radius: radius,
      city: city,
    ));
    final data = res['data'] as Map<String, dynamic>;
    final list = (data['data'] as List<dynamic>)
        .map((e) => VenueModel.fromJson(e as Map<String, dynamic>))
        .toList();
    final pagination = VenuePagination.fromJson(
        data['pagination'] as Map<String, dynamic>);
    return VenueSearchResult(venues: list, pagination: pagination);
  }


}

// ── Favorites ─────────────────────────────────────────────────────────────────
class FavoritesApi {
  FavoritesApi._();

  static Future<List<int>> fetchIds() async {
    final res = await ApiService.instance.get(
      '${ApiConstants.baseUrl}/favorites/ids',
    );
    final list = res['data'] as List<dynamic>;
    final ids = list.map((e) => e as int).toList();
    SessionManager.instance.favoriteIds.value = ids.toSet();
    return ids;
  }

  static Future<String> toggle(int venueId) async {
    final res = await ApiService.instance.post(
      '${ApiConstants.baseUrl}/favorites/$venueId',
      {},
    );
    final action = res['data']['action'] as String;
    final current = Set<int>.from(SessionManager.instance.favoriteIds.value);
    if (action == 'added') {
      current.add(venueId);
    } else {
      current.remove(venueId);
    }
    SessionManager.instance.favoriteIds.value = current;
    return action;
  }
}

 

 class VenueDetailApi {
  VenueDetailApi._();
 
  static Future<VenueDetailModel> bySlug(String slug) async {
    final res = await ApiService.instance.get(
      '${ApiConstants.baseUrl}/venues/slug/$slug',
    );
    return VenueDetailModel.fromJson(res['data'] as Map<String, dynamic>);
  }
}
 
class BookingApi {
  BookingApi._();
 
  // GET subcategories with grounds for a venue category
  // GET /categories/venue-category/{venueCategoryId}/subcategories?status=Active&page=1&limit=20&venueId={venueId}
  static Future<List<BookingSubcategoryModel>> subcategoriesWithGrounds({
    required int venueCategoryId,
    required int venueId,
  }) async {
    final res = await ApiService.instance.get(
      '${ApiConstants.baseUrl}/categories/venue-category/$venueCategoryId'
      '/subcategories?status=Active&page=1&limit=20&venueId=$venueId',
    );
    final list = res['data'] as List<dynamic>? ?? [];
    return list
        .map((e) => BookingSubcategoryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
 
  // GET availability for a ground on a date
  // GET /pricing/availability?venueId&date&groundId
  static Future<GroundAvailabilityModel> availability({
    required int venueId,
    required int groundId,
    required String date, // "2026-06-01"
  }) async {
    final res = await ApiService.instance.get(
      '${ApiConstants.baseUrl}/pricing/availability'
      '?venueId=$venueId&date=$date&groundId=$groundId',
    );
    return GroundAvailabilityModel.fromJson(
        res['data'] as Map<String, dynamic>);
  }
 
  // POST booking description
  // POST /booking-description
  static Future<BookingDescriptionModel> bookingDescription(
      BookingDescriptionRequest request) async {
    final res = await ApiService.instance.post(
      '${ApiConstants.baseUrl}/booking-description',
      request.toJson(),
    );
    return BookingDescriptionModel.fromJson(
        res['data'] as Map<String, dynamic>);
  }
}

// ── Payment ───────────────────────────────────────────────────────────────────
// Add this class to api_constants.dart
// Also add import at top: import '../models/booking_model.dart'; (already there)

class PaymentApi {
  PaymentApi._();

  // POST /payments/order
  static Future<Map<String, dynamic>> createOrder(
      Map<String, dynamic> payload) async {
    final res = await ApiService.instance.post(
      '${ApiConstants.baseUrl}/payments/order',
      payload,
    );
    return res['data'] as Map<String, dynamic>;
  }

  // POST /payments/verify
  static Future<bool> verifyPayment({
    required String orderId,
    required String paymentId,
    required String signature,
  }) async {
    final res = await ApiService.instance.post(
      '${ApiConstants.baseUrl}/payments/verify',
      {
        'orderId':   orderId,
        'paymentId': paymentId,
        'signature': signature,
      },
    );
    return res['success'] == true;
  }

  // POST /bookings/slots/lock
  static Future<int> lockSlot({
    required int venueId,
    required int groundId,
    required String bookingDate,
    required String startTime,
    required String endTime,
    int? vgsId,
  }) async {
    final payload = <String, dynamic>{
      'venueId':     venueId,
      'groundId':    groundId,
      'bookingDate': bookingDate,
      'startTime':   startTime,
      'endTime':     endTime,
    };
    if (vgsId != null) payload['vgsId'] = vgsId;

    final res = await ApiService.instance.post(
      '${ApiConstants.baseUrl}/bookings/slots/lock',
      payload,
    );
    final id = res['data']?['id'] as int?;
    if (id == null) throw Exception('Failed to lock slot');
    return id;
  }

  // DELETE /bookings/slots/lock/{id}
  static Future<void> unlockSlot(int slotLockId) async {
    try {
      await ApiService.instance.delete(
        '${ApiConstants.baseUrl}/bookings/slots/lock/$slotLockId',
      );
    } catch (_) {} // best-effort, don't throw
  }

  // POST /bookings
  static Future<int> createBooking({
    required int venueId,
    required String bookingDate,
    required String startTime,
    required String endTime,
    required String gatewayOrderId,
    int? vgsId,
    int? groundId,
    String? couponCode,
    double? couponDiscountAmount,
  }) async {
    final payload = <String, dynamic>{
      'venueId':         venueId,
      'bookingDate':     bookingDate,
      'startTime':       startTime,
      'endTime':         endTime,
      'paymentMethod':   'online',
      'numberOfPersons': 1,
      'gatewayOrderId':  gatewayOrderId,
    };
    if (vgsId != null) {
      payload['vgsId'] = vgsId;
    } else if (groundId != null) {
      payload['groundId'] = groundId;
    }
    if (couponCode != null) {
      payload['couponCode'] = couponCode;
      payload['couponDiscountAmount'] = couponDiscountAmount;
    }

    final res = await ApiService.instance.post(
      '${ApiConstants.baseUrl}/bookings',
      payload,
    );
    final data = res['data'] as Map<String, dynamic>?;
    final bookingId = data?['booking']?['id'] ?? data?['id'];
    if (bookingId == null) throw Exception('Failed to create booking');
    return bookingId as int;
  }
}

// ── My Bookings ───────────────────────────────────────────────────────────────
class MyBookingsApi {
  MyBookingsApi._();

  static String upcoming({int page = 1, int limit = 9}) =>
      '${ApiConstants.baseUrl}/bookings/my/upcoming?page=$page&limit=$limit';

  static String history({int page = 1, int limit = 9}) =>
      '${ApiConstants.baseUrl}/bookings/my/history?page=$page&limit=$limit';
}

// ── Reviews ───────────────────────────────────────────────────────────────────
class ReviewApi {
  ReviewApi._();

  static const String _base = '${ApiConstants.baseUrl}/reviews';

  static String create()       => _base;
  static String byId(int id)   => '$_base/$id';
  static String update(int id) => '$_base/$id';
  static String delete(int id) => '$_base/$id';
}

// ── Booking Detail ─────────────────────────────────────────────────────────────
class BookingDetailApi {
  BookingDetailApi._();
  static String byId(int id) => '${ApiConstants.baseUrl}/bookings/$id';
}