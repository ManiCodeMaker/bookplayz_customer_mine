import 'dart:convert';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'package:flutter/foundation.dart';

const _kSessionKey = 'bookplayz_customer_session';

class SessionManager {
  SessionManager._();
  static final SessionManager instance = SessionManager._();
  final ValueNotifier<Set<int>> favoriteIds = ValueNotifier<Set<int>>({});
  final ValueNotifier<String?> cityNotifier = ValueNotifier<String?>(null);

  /// City name resolved from the GPS coordinates (reverse geocoding).
  /// Independent of [cityNotifier], which is the user's manual city pick.
  final ValueNotifier<String?> gpsCityNotifier = ValueNotifier<String?>(null);

  SessionUser? _user;
  String?      _accessToken;
  String?      _refreshToken;
  double?      _latitude;
  double?      _longitude;

  SessionUser? get currentUser    => _user;
  set user(SessionUser? u)        => _user = u;
  String?      get accessToken    => _accessToken;
  bool         get isLoggedIn     => _accessToken != null && _user != null;
  double?      get latitude       => _latitude;
  double?      get longitude      => _longitude;
  String?      get city           => cityNotifier.value;
  String?      get gpsCity        => gpsCityNotifier.value;


  // ── Location ──────────────────────────────────────────────────────────────

  Future<void> restoreLocation() async {
    final prefs = await SharedPreferences.getInstance();
    _latitude  = prefs.getDouble('bpz_lat');
    _longitude = prefs.getDouble('bpz_lng');
    cityNotifier.value    = prefs.getString('bpz_city');
    gpsCityNotifier.value = prefs.getString('bpz_gps_city');

    // Existing installs have lat/lng saved but never geocoded them.
    if (gpsCityNotifier.value == null && _latitude != null && _longitude != null) {
      _resolveGpsCity(_latitude!, _longitude!);
    }
  }

  Future<void> fetchAndStoreLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      _latitude  = pos.latitude;
      _longitude = pos.longitude;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('bpz_lat', pos.latitude);
      await prefs.setDouble('bpz_lng', pos.longitude);

      await _resolveGpsCity(pos.latitude, pos.longitude);
    } catch (_) {
      // silently fall back — callers null-check lat/lng
    }
  }

  /// Reverse-geocodes lat/lng into a city name for the topbar.
  /// Failure is non-fatal: the UI falls back to 'Using current location'.
  Future<void> _resolveGpsCity(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isEmpty) return;

      final p = placemarks.first;
      final city = [p.locality, p.subAdministrativeArea, p.administrativeArea]
          .firstWhere((s) => s != null && s.trim().isNotEmpty, orElse: () => null);
      if (city == null) return;

      gpsCityNotifier.value = city;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('bpz_gps_city', city);
    } catch (_) {
      // geocoder unavailable (no network / no Play services) — keep fallback text
    }
  }

  // ── Save after login ──────────────────────────────────────────────────────

  Future<void> saveSession({
    required SessionUser user,
    required String accessToken,
    required String refreshToken,
  }) async {
    _user         = user;
    _accessToken  = accessToken;
    _refreshToken = refreshToken;

    ApiService.instance.setToken(accessToken);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSessionKey, jsonEncode({
      'user':         user.toJson(),
      'accessToken':  accessToken,
      'refreshToken': refreshToken,
    }));
  }

  Future<void> saveCity(String city) async {
    cityNotifier.value = city;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('bpz_city', city);
  }

  Future<void> clearCity() async {
    cityNotifier.value = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('bpz_city');
  }

  // ── Restore on app launch ─────────────────────────────────────────────────

  Future<bool> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final raw   = prefs.getString(_kSessionKey);
    if (raw == null) return false;

    try {
      final json         = jsonDecode(raw) as Map<String, dynamic>;
      final refreshToken = json['refreshToken'] as String;

      final newToken = await ApiService.instance.refreshAccessToken(refreshToken);
      if (newToken == null) {
        await clearSession();
        return false;
      }

      _user         = SessionUser.fromJson(json['user'] as Map<String, dynamic>);
      _accessToken  = newToken;
      _refreshToken = refreshToken;
      ApiService.instance.setToken(newToken);

      await prefs.setString(_kSessionKey, jsonEncode({
        'user':         _user!.toJson(),
        'accessToken':  newToken,
        'refreshToken': refreshToken,
      }));
      return true;
    } catch (_) {
      await clearSession();
      return false;
    }
  }

  // ── Clear on logout ───────────────────────────────────────────────────────

  Future<void> clearSession() async {
    _user         = null;
    _accessToken  = null;
    _refreshToken = null;
    ApiService.instance.clearToken();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kSessionKey);
  }
}

// ── Model ─────────────────────────────────────────────────────────────────────

class SessionUser {
  final int     id;
  final String? mobile;
  final String  fullName;
  final String? email;
  final String  role;
  final String  status;
  final bool    emailVerified;
  final bool    mobileVerified;
  final String? profileImage;

  const SessionUser({
    required this.id,
    this.mobile,
    required this.fullName,
    this.email,
    required this.role,
    required this.status,
    this.emailVerified  = false,
    this.mobileVerified = false,
    this.profileImage,
  });

  factory SessionUser.fromJson(Map<String, dynamic> j) => SessionUser(
    id:             j['id'] as int,
    mobile:         j['mobile'] as String?,
    fullName:       j['fullName'] as String? ?? '',
    email:          j['email'] as String?,
    role:           j['role'] as String,
    status:         j['status'] as String,
    emailVerified:  j['emailVerified'] as bool? ?? false,
    mobileVerified: j['mobileVerified'] as bool? ?? false,
    profileImage:   j['profileImage'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id':             id,
    'mobile':         mobile,
    'fullName':       fullName,
    'email':          email,
    'role':           role,
    'status':         status,
    'emailVerified':  emailVerified,
    'mobileVerified': mobileVerified,
    'profileImage':   profileImage,
  };

  SessionUser copyWith({
    String? fullName,
    String? email,
    String? mobile,
    bool?   emailVerified,
    bool?   mobileVerified,
    String? profileImage,
  }) => SessionUser(
    id:             id,
    mobile:         mobile ?? this.mobile,
    fullName:       fullName       ?? this.fullName,
    email:          email          ?? this.email,
    role:           role,
    status:         status,
    emailVerified:  emailVerified  ?? this.emailVerified,
    mobileVerified: mobileVerified ?? this.mobileVerified,
    profileImage:   profileImage   ?? this.profileImage,
  );
}