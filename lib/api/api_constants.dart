import 'dart:io';

import 'package:bookplayz/api/session_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:bookplayz/models/venue_detail_model.dart';
import 'package:bookplayz/models/booking_model.dart';
import 'package:bookplayz/models/venue_review_model.dart';
import 'package:bookplayz/models/tournament_model.dart';
import 'package:bookplayz/models/public_event_model.dart';
import 'package:bookplayz/models/page_image_model.dart';

import 'api_service.dart';
import '../models/venue_model.dart';

// ── Constants ─────────────────────────────────────────────────────────────────
class ApiConstants {
  ApiConstants._();
  static const String baseUrl = 'https://api.bookplayz.com/api';
}

const _base = ApiConstants.baseUrl;

// ── Location models ───────────────────────────────────────────────────────────

class StateModel {
  final int id;
  final String name;
  const StateModel({required this.id, required this.name});
  factory StateModel.fromJson(Map<String, dynamic> j) =>
      StateModel(id: j['id'] as int, name: j['name'] as String);
}

class DistrictModel {
  final int id;
  final String name;
  const DistrictModel({required this.id, required this.name});
  factory DistrictModel.fromJson(Map<String, dynamic> j) =>
      DistrictModel(id: j['id'] as int, name: j['name'] as String);
}

// ── Locations ─────────────────────────────────────────────────────────────────
class LocationsApi {
  LocationsApi._();
  static const String states = '$_base/locations/states';

  /// [limit] defaults to 500 — enough for any Indian state's districts.
  static String districts(int stateId, {int limit = 500}) =>
      '$_base/locations/districts?stateId=$stateId&limit=$limit';

  static Future<List<StateModel>> fetchStates() async {
    final res = await ApiService.instance.get(states);
    final list = res['data'] as List<dynamic>;
    return list.map((e) => StateModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<List<DistrictModel>> fetchDistricts(int stateId) async {
    final res = await ApiService.instance.get(districts(stateId));
    final list = res['data'] as List<dynamic>;
    return list.map((e) => DistrictModel.fromJson(e as Map<String, dynamic>)).toList();
  }
}

// ── Auth ──────────────────────────────────────────────────────────────────────
class AuthApi {
  AuthApi._();

  static const String requestOtpUrl   = '${ApiConstants.baseUrl}/auth/phone-auth/request';
  static const String verifyOtpUrl    = '${ApiConstants.baseUrl}/auth/phone-auth/verify';
  static const String refreshTokenUrl = '${ApiConstants.baseUrl}/auth/refresh-token';
  static const String ssoLoginUrl     = '${ApiConstants.baseUrl}/auth/sso/login';

  static Future<Map<String, dynamic>> requestOtp(String mobile) async {
    final res = await ApiService.instance.post(requestOtpUrl, {
      'mobile': mobile,
      'loginAs': 'user',
    });
    return res['data'] as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> verifyOtp({
    required String mobile,
    required String otp,
    String? deviceToken,
  }) async {
    final body = <String, dynamic>{
      'mobile': mobile,
      'otp': otp,
      'loginAs': 'user',
    };
    if (deviceToken != null) body['deviceToken'] = deviceToken;
    final res = await ApiService.instance.post(verifyOtpUrl, body);
    return res['data'] as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> ssoLogin({
    required String provider,
    required String token,
    String? deviceToken,
  }) async {
    final body = <String, dynamic>{
      'provider': provider,
      'token': token,
    };
    if (deviceToken != null) body['deviceToken'] = deviceToken;
    final res = await ApiService.instance.post(ssoLoginUrl, body);
    return res['data'] as Map<String, dynamic>;
  }
}

// ── Profile ───────────────────────────────────────────────────────────────────
class ProfileApi {
  ProfileApi._();
  static const String me = '${ApiConstants.baseUrl}/auth/me';
  static const String verifyEmailRequest = '${ApiConstants.baseUrl}/auth/verify-email/request';
  static const String verifyEmail        = '${ApiConstants.baseUrl}/auth/verify-email';
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

  static Future<VenueSearchResult> searchByCity({
    required String city,
    int page = 1,
    int limit = 12,
  }) async {
    final url = '${ApiConstants.baseUrl}/venues/search'
        '?page=$page&limit=$limit&city=$city';
    final res = await ApiService.instance.get(url);
    final data = res['data'] as Map<String, dynamic>;
    final list = (data['data'] as List<dynamic>)
        .map((e) => VenueModel.fromJson(e as Map<String, dynamic>))
        .toList();
    final pagination =
        VenuePagination.fromJson(data['pagination'] as Map<String, dynamic>);
    return VenueSearchResult(venues: list, pagination: pagination);
  }

  /// Fetches all venues — used by the map screen so every pin is visible
  /// regardless of where the user pans. No location filter is applied.
  static Future<VenueSearchResult> fetchAll({int limit = 100}) async {
    final url = '${ApiConstants.baseUrl}/venues/search?page=1&limit=$limit';
    final res = await ApiService.instance.get(url);
    final data = res['data'] as Map<String, dynamic>;
    final list = (data['data'] as List<dynamic>)
        .map((e) => VenueModel.fromJson(e as Map<String, dynamic>))
        .toList();
    final pagination =
        VenuePagination.fromJson(data['pagination'] as Map<String, dynamic>);
    return VenueSearchResult(venues: list, pagination: pagination);
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

// ── Tournaments ───────────────────────────────────────────────────────────────
class TournamentApi {
  TournamentApi._();

  static Future<TournamentSearchResult> fetchPublic({
    int page = 1,
    int limit = 20,
    String? search,
    String? category,
    String? genderCategory,
    String? date,
    bool upcoming = true,
  }) async {
    var url = '${ApiConstants.baseUrl}/tournaments/public'
        '?page=$page&limit=$limit&upcoming=$upcoming';
    if (search != null && search.isNotEmpty) url += '&search=$search';
    if (category != null && category.isNotEmpty) url += '&category=$category';
    if (genderCategory != null && genderCategory.isNotEmpty) {
      url += '&genderCategory=$genderCategory';
    }
    if (date != null && date.isNotEmpty) url += '&date=$date';

    final res = await ApiService.instance.get(url);
    final data = res['data'] as Map<String, dynamic>;
    final list = (data['data'] as List<dynamic>)
        .map((e) => TournamentModel.fromJson(e as Map<String, dynamic>))
        .toList();
    final pagination =
        TournamentPagination.fromJson(data['pagination'] as Map<String, dynamic>);
    return TournamentSearchResult(tournaments: list, pagination: pagination);
  }

  static Future<TournamentModel> fetchDetail(int id) async {
    final res = await ApiService.instance.get(
      '${ApiConstants.baseUrl}/tournaments/public/$id',
    );
    return TournamentModel.fromJson(res['data'] as Map<String, dynamic>);
  }

  static Future<List<TournamentModel>> fetchMoreEvents(int id, {int limit = 5}) async {
    final res = await ApiService.instance.get(
      '${ApiConstants.baseUrl}/tournaments/$id/more-events?limit=$limit',
    );
    final list = res['data'] as List<dynamic>? ?? [];
    return list
        .map((e) => TournamentModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // Tournaments don't carry their own images unless a bannerImage was
  // uploaded — fall back to the venue's primary image in that case.
  static final Map<int, Future<String?>> _venueImageCache = {};

  static Future<String?> fetchVenuePrimaryImage(int venueId) {
    return _venueImageCache.putIfAbsent(venueId, () async {
      try {
        final res = await ApiService.instance.get(
          '${ApiConstants.baseUrl}/venues/$venueId/images',
        );
        final list = (res['data'] as List<dynamic>? ?? [])
            .map((e) => VenueImageModel.fromJson(e as Map<String, dynamic>))
            .toList();
        if (list.isEmpty) return null;
        final primary = list.firstWhere(
          (img) => img.isPrimary,
          orElse: () => list.first,
        );
        return primary.imageUrl.isNotEmpty ? primary.imageUrl : null;
      } catch (_) {
        return null;
      }
    });
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
    required double amount,
    int? bookingId,
  }) async {
    final res = await ApiService.instance.post(
      '${ApiConstants.baseUrl}/payments/verify',
      {
        'orderId':   orderId,
        'paymentId': paymentId,
        'signature': signature,
        'amount':    amount,
        if (bookingId != null) 'bookingId': bookingId,
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

  static String venuePublic(int venueId, {int page = 1, int limit = 5}) =>
      '${ApiConstants.baseUrl}/reviews/venue/$venueId/public'
      '?page=$page&limit=$limit&sortBy=latest';

  static Future<({List<VenueReview> reviews, VenueReviewMeta meta})>
      fetchVenuePublic(int venueId, {int page = 1, int limit = 5}) async {
    final res = await ApiService.instance.get(
      venuePublic(venueId, page: page, limit: limit),
    );
    final reviews = (res['data'] as List<dynamic>)
        .map((e) => VenueReview.fromJson(e as Map<String, dynamic>))
        .toList();
    final meta =
        VenueReviewMeta.fromJson(res['meta'] as Map<String, dynamic>);
    return (reviews: reviews, meta: meta);
  }

  static String nearbyTop({
    required double latitude,
    required double longitude,
    double radius = 50,
    int page = 1,
    int limit = 10,
  }) =>
      '${ApiConstants.baseUrl}/reviews/nearby/top'
      '?latitude=$latitude&longitude=$longitude&radius=$radius'
      '&page=$page&limit=$limit';

  static Future<List<NearbyTopReview>> fetchNearbyTop({
    required double latitude,
    required double longitude,
    double radius = 50,
    int limit = 10,
  }) async {
    final res = await ApiService.instance.get(
      nearbyTop(latitude: latitude, longitude: longitude, radius: radius, limit: limit),
    );
    return (res['data'] as List<dynamic>)
        .map((e) => NearbyTopReview.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

// ── Booking Detail ─────────────────────────────────────────────────────────────
class BookingDetailApi {
  BookingDetailApi._();
  static String byId(int id) => '${ApiConstants.baseUrl}/bookings/$id';
}

// ── Cancellation ───────────────────────────────────────────────────────────────
class CancellationApi {
  CancellationApi._();
  static String preview(int id) => '${ApiConstants.baseUrl}/bookings/$id/cancellation-preview';
  static String cancel(int id)  => '${ApiConstants.baseUrl}/bookings/$id/cancel';
}

// ── Venue Events (Bulk / Corporate packages) ──────────────────────────────────
class EventsApi {
  EventsApi._();

  /// GET /events/venue/:venueId?limit= — published "packages" a venue is
  /// running, shown as selectable options in the Bulk / Corporate flow.
  static Future<List<PublicEventModel>> byVenue(
    int venueId, {
    int limit = 50,
  }) async {
    final res = await ApiService.instance.get(
      '${ApiConstants.baseUrl}/events/venue/$venueId?limit=$limit',
    );
    final data = res['data'];
    List<dynamic> list;
    if (data is List) {
      list = data;
    } else if (data is Map && data['data'] is List) {
      list = data['data'] as List;
    } else {
      list = const [];
    }
    return list
        .map((e) => PublicEventModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

// ── Enquiries (Bulk / Corporate submissions) ──────────────────────────────────
class EnquiryApi {
  EnquiryApi._();

  /// POST /enquiries — general venue-level corporate enquiry (no package
  /// selected).
  static Future<void> submitVenueEnquiry({
    required String firstName,
    required String lastName,
    required String phone,
    String? email,
    required String message,
    int? venueId,
  }) async {
    await ApiService.instance.post(
      '${ApiConstants.baseUrl}/enquiries',
      {
        'firstName': firstName,
        'lastName':  lastName,
        'phone':     phone,
        if (email != null && email.isNotEmpty) 'email': email,
        'message':   message,
        if (venueId != null) 'venueId': venueId,
      },
    );
  }

  /// POST /events-enquiries — enquiry raised against a specific package.
  static Future<void> submitEventEnquiry({
    required String name,
    required String mobileNumber,
    String? email,
    required String message,
    required int eventId,
  }) async {
    await ApiService.instance.post(
      '${ApiConstants.baseUrl}/events-enquiries',
      {
        'name':         name,
        'mobileNumber': mobileNumber,
        if (email != null && email.isNotEmpty) 'email': email,
        'message':      message,
        'eventId':      eventId,
      },
    );
  }
}

// ── Page Images ───────────────────────────────────────────────────────────────
class PageImagesApi {
  PageImagesApi._();

  /// GET /page-images?pageType=... — public, no auth required.
  /// [pageType] is the page type's slug (e.g. "user-app-splash-screen", "home").
  static Future<List<PageImageModel>> byPageType(String pageType) async {
    final res = await ApiService.instance.get(
      '${ApiConstants.baseUrl}/page-images'
      '?pageType=$pageType&status=Active&limit=50',
    );
    final list = res['data'] as List<dynamic>? ?? [];
    final images = list
        .map((e) => PageImageModel.fromJson(e as Map<String, dynamic>))
        .toList();
    images.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return images;
  }
}

// ── Push Devices ──────────────────────────────────────────────────────────────
class PushDevicesApi {
  PushDevicesApi._();

  static const String devices =
      '${ApiConstants.baseUrl}/push-notifications/devices';

  /// Registers/refreshes this device's FCM token with the backend.
  /// Best-effort — push registration must never break the calling flow.
  static Future<void> registerDevice(String token) async {
    try {
      await ApiService.instance.post(devices, {
        'token': token,
        'platform': Platform.isIOS ? 'ios' : 'android',
      });
    } catch (e) {
      debugPrint('[PushDevicesApi] device registration failed: $e');
    }
  }
}

// ── Notifications ──────────────────────────────────────────────────────────────
class NotificationModel {
  final int id;
  final String category;
  final String type;
  final String title;
  final String message;
  final Map<String, dynamic> data;
  final bool isRead;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.category,
    required this.type,
    required this.title,
    required this.message,
    required this.data,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> j) {
    return NotificationModel(
      id:        j['id'] as int,
      category:  j['category'] as String? ?? '',
      type:      j['type'] as String? ?? '',
      title:     j['title'] as String? ?? '',
      message:   j['message'] as String? ?? '',
      data:      (j['data'] as Map<String, dynamic>?) ?? {},
      isRead:    j['isRead'] as bool? ?? false,
      createdAt: DateTime.tryParse(j['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

class NotificationsApi {
  NotificationsApi._();

  static const String _unreadCountUrl = '${ApiConstants.baseUrl}/notifications/unread-count';
  static const String _readAllUrl     = '${ApiConstants.baseUrl}/notifications/read-all';
  static String list({int limit = 10}) =>
      '${ApiConstants.baseUrl}/notifications?limit=$limit';

  static Future<int> fetchUnreadCount() async {
    final res = await ApiService.instance.get(_unreadCountUrl);
    final data = res['data'] as Map<String, dynamic>?;
    return (data?['count'] as num?)?.toInt() ?? 0;
  }

  static Future<List<NotificationModel>> fetchList({int limit = 10}) async {
    final res = await ApiService.instance.get(list(limit: limit));
    final data = res['data'] as Map<String, dynamic>;
    final items = data['data'] as List<dynamic>;
    return items
        .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<void> markAllRead() async {
    await ApiService.instance.put(_readAllUrl, {});
  }
}