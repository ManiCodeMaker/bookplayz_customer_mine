import 'dart:convert';
import 'dart:ui' as ui;

import 'package:http/http.dart' as http;
import 'package:bookplayz/api/api_constants.dart';
import 'package:bookplayz/api/session_manager.dart';
import 'package:bookplayz/models/venue_model.dart';
import 'package:bookplayz/theme/app_constants.dart';
import 'package:bookplayz/theme/app_theme.dart';
import 'package:bookplayz/widgets/app_loader.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class VenueMapScreen extends StatefulWidget {
  const VenueMapScreen({super.key});

  @override
  State<VenueMapScreen> createState() => _VenueMapScreenState();
}

class _VenueMapScreenState extends State<VenueMapScreen> {
  GoogleMapController? _mapController;
  List<VenueModel> _venues = [];
  List<VenueModel> _filtered = [];
  bool _loading = true;
  String? _error;
  int _selectedIndex = -1;
  Set<Marker> _markers = {};
  final PageController _pageController = PageController(viewportFraction: 0.88);
  final TextEditingController _searchController = TextEditingController();
  final Map<String, BitmapDescriptor> _markerCache = {};

  static const _kFallbackLatLng = LatLng(20.5937, 78.9629);

  // City passed from _MapBanner (or null when opened via GPS flow).
  String? _cityArg;
  // Geocoded centre of _cityArg — used to position the map when no venue
  // pins are available (venues exist but have no lat/lng yet).
  LatLng? _cityCenter;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    // city arg is read after first frame so route arguments are available.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cityArg = ModalRoute.of(context)?.settings.arguments as String?;
      _loadVenues();
    });
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _pageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ── Data ───────────────────────────────────────────────────────────────────

  Future<void> _loadVenues() async {
    // Load ALL venues so every pin is visible as the user pans freely.
    // City / GPS only controls where the camera starts.
    try {
      final result = await VenueApi.fetchAll();

      final withCoords = result.venues
          .where((v) => v.latitude != null && v.longitude != null)
          .toList();

      if (!mounted) return;
      setState(() {
        _venues = withCoords;
        _filtered = withCoords;
        _selectedIndex = withCoords.isNotEmpty ? 0 : -1;
        _loading = false;
      });
      await _rebuildMarkers();

      // ── Camera: geocode selected city → GPS → fit all pins ──
      final city = _cityArg ?? SessionManager.instance.city;
      if (city != null) {
        final pos = await _geocodeCity(city);
        if (!mounted) return;
        if (pos != null) {
          setState(() => _cityCenter = pos);
          _mapController?.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(target: pos, zoom: 12),
            ),
          );
          return;
        }
      }
      final lat = SessionManager.instance.latitude;
      final lng = SessionManager.instance.longitude;
      if (lat != null && lng != null) {
        _mapController?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: LatLng(lat, lng), zoom: 12),
          ),
        );
      } else if (withCoords.isNotEmpty) {
        _fitMapBounds();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  /// Geocodes [city] using Nominatim (OSM) — no API key required.
  Future<LatLng?> _geocodeCity(String city) async {
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?q=${Uri.encodeComponent('$city, India')}'
        '&format=json&limit=1',
      );
      final response = await http.get(
        uri,
        headers: {'User-Agent': 'bookplayz-app/1.0'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        if (data.isNotEmpty) {
          final lat = double.tryParse(data[0]['lat'] as String);
          final lon = double.tryParse(data[0]['lon'] as String);
          if (lat != null && lon != null) return LatLng(lat, lon);
        }
      }
    } catch (_) {}
    return null;
  }

  void _onSearchChanged() {
    final q = _searchController.text.trim().toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? _venues
          : _venues.where((v) => v.name.toLowerCase().contains(q)).toList();
      _selectedIndex = _filtered.isNotEmpty ? 0 : -1;
    });
    _rebuildMarkers();
    if (_filtered.isNotEmpty) _fitMapBounds();
  }

  // ── Markers ────────────────────────────────────────────────────────────────

  Future<void> _rebuildMarkers() async {
    if (_filtered.isEmpty) {
      if (mounted) setState(() => _markers = {});
      return;
    }

    final icons = await Future.wait(
      _filtered.asMap().entries.map(
        (e) => _cachedMarkerIcon(e.value, e.key == _selectedIndex),
      ),
    );

    if (!mounted) return;
    final markers = _filtered.asMap().entries.map((e) {
      final i = e.key;
      final v = e.value;
      return Marker(
        markerId: MarkerId('v${v.id}'),
        position: LatLng(v.latitude!, v.longitude!),
        icon: icons[i],
        anchor: const Offset(0.5, 1.0),
        onTap: () => _selectVenue(i),
      );
    }).toSet();

    setState(() => _markers = markers);
  }

  Future<BitmapDescriptor> _cachedMarkerIcon(VenueModel venue, bool selected) async {
    final key = '${venue.id}_$selected';
    return _markerCache[key] ??=
        await _buildCircleMarker(venue.primaryImage, venue.rating, selected);
  }

  // Circular venue-photo marker with rating badge, rendered via dart:ui canvas.
  // Rendered at 3× logical size so it stays sharp on high-DPI screens.
  static Future<BitmapDescriptor> _buildCircleMarker(
    String? imageUrl,
    double rating,
    bool selected,
  ) async {
    const double scale = 3.0;          // render 3× for crisp HiDPI display
    const double logicalSize = 64;     // dp size on screen
    const double logicalTail = 10;

    final double s = logicalSize * scale;
    final double tail = logicalTail * scale;
    final double totalH = s + tail;
    final double r = s / 2;
    final center = Offset(r, r);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, s, totalH));

    // ── 1. Outer ring (border colour) ────────────────────────────────────────
    canvas.drawCircle(
      center,
      r,
      Paint()..color = selected ? AppColors.limeGreen : Colors.white,
    );

    // ── 2. Venue image clipped to inner circle ───────────────────────────────
    final double imgR = r - 4 * scale;
    bool drewImage = false;

    if (imageUrl != null && imageUrl.isNotEmpty) {
      try {
        final response = await http
            .get(Uri.parse(imageUrl))
            .timeout(const Duration(seconds: 6));
        if (response.statusCode == 200) {
          // Decode at full resolution — no downscale here to keep quality
          final codec = await ui.instantiateImageCodec(response.bodyBytes);
          final frame = await codec.getNextFrame();
          final img = frame.image;

          canvas.save();
          canvas.clipPath(
            Path()..addOval(Rect.fromCircle(center: center, radius: imgR)),
          );
          canvas.drawImageRect(
            img,
            Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
            Rect.fromCircle(center: center, radius: imgR),
            Paint()..filterQuality = FilterQuality.high,
          );
          canvas.restore();
          drewImage = true;
        }
      } catch (_) {}
    }

    if (!drewImage) {
      canvas.drawCircle(center, imgR, Paint()..color = AppColors.limeGreen);
    }

    // ── 3. Border ring ───────────────────────────────────────────────────────
    canvas.drawCircle(
      center,
      r - 2 * scale,
      Paint()
        ..color = selected ? AppColors.limeGreen : Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3 * scale,
    );

    // ── 4. Tail ──────────────────────────────────────────────────────────────
    final tailPath = Path()
      ..moveTo(r - 7 * scale, s - 3 * scale)
      ..lineTo(r + 7 * scale, s - 3 * scale)
      ..lineTo(r, totalH)
      ..close();
    canvas.drawPath(
      tailPath,
      Paint()..color = selected ? AppColors.limeGreen : Colors.white,
    );

    // ── 5. Rating badge ──────────────────────────────────────────────────────
    final double bw = 36 * scale, bh = 17 * scale;
    final double bx = (s - bw) / 2;
    final double by = s - bh - 5 * scale;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(bx, by, bw, bh),
        Radius.circular(9 * scale),
      ),
      Paint()..color = Colors.white,
    );

    final tp = TextPainter(
      text: TextSpan(
        text: '★ ${rating.toStringAsFixed(1)}',
        style: TextStyle(
          color: AppColors.limeGreen,
          fontSize: 10 * scale,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: bw);
    tp.paint(canvas, Offset(bx + (bw - tp.width) / 2, by + (bh - tp.height) / 2));

    // ── 6. Finalise at 3× and tell Maps the pixel ratio ──────────────────────
    final img = await recorder.endRecording().toImage(s.toInt(), totalH.toInt());
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(
      bytes!.buffer.asUint8List(),
      imagePixelRatio: scale,
    );
  }

  // ── Navigation ─────────────────────────────────────────────────────────────

  void _selectVenue(int i) {
    setState(() => _selectedIndex = i);
    _pageController.animateToPage(
      i,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
    _panToVenue(_filtered[i]);
    _rebuildMarkers();
  }

  void _panToVenue(VenueModel v) {
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: LatLng(v.latitude!, v.longitude!), zoom: 15),
      ),
    );
  }

  void _fitMapBounds() {
    if (_filtered.isEmpty || _mapController == null) return;
    double minLat = _filtered.first.latitude!;
    double maxLat = _filtered.first.latitude!;
    double minLng = _filtered.first.longitude!;
    double maxLng = _filtered.first.longitude!;
    for (final v in _filtered) {
      if (v.latitude! < minLat) minLat = v.latitude!;
      if (v.latitude! > maxLat) maxLat = v.latitude!;
      if (v.longitude! < minLng) minLng = v.longitude!;
      if (v.longitude! > maxLng) maxLng = v.longitude!;
    }
    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat - 0.008, minLng - 0.008),
          northeast: LatLng(maxLat + 0.008, maxLng + 0.008),
        ),
        80,
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Start at GPS location if available, otherwise India centre.
    // _loadVenues will animateCamera to the selected city once venues load.
    final initialTarget = LatLng(
      SessionManager.instance.latitude ?? _kFallbackLatLng.latitude,
      SessionManager.instance.longitude ?? _kFallbackLatLng.longitude,
    );

    return Scaffold(
      body: Stack(
        children: [
          // ── Google Map ────────────────────────────────────────────────────
          GoogleMap(
            mapType: MapType.normal,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            compassEnabled: false,
            markers: _markers,
            initialCameraPosition: CameraPosition(
              target: initialTarget,
              zoom: 12,
            ),
            onMapCreated: (c) {
              _mapController = c;
              if (_filtered.isNotEmpty) {
                _fitMapBounds();
              } else if (_cityCenter != null) {
                c.animateCamera(
                  CameraUpdate.newCameraPosition(
                    CameraPosition(target: _cityCenter!, zoom: 12),
                  ),
                );
              }
            },
            onTap: (_) {
              setState(() => _selectedIndex = -1);
              _rebuildMarkers();
            },
          ),

          // ── Top overlay ───────────────────────────────────────────────────
          SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title row
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                  child: Row(
                    children: [
                      // Back button
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: AppColors.limeGreen,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_back_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          _cityArg != null
                              ? 'Venues in $_cityArg'
                              : 'Nearby Venues',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Jost',
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppColors.navyBlue,
                            shadows: [
                              Shadow(
                                color: Colors.white,
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 40), // balance for back button
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Search bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(
                        fontFamily: 'Jost',
                        fontSize: 14,
                        color: AppColors.navyBlue,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search...',
                        hintStyle: const TextStyle(
                          fontFamily: 'Jost',
                          fontSize: 14,
                          color: AppColors.inputPlceholder,
                        ),
                        prefixIcon: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Image.asset(
                            AppImages.searchIcon,
                            width: 18,
                            height: 18,
                            color: AppColors.mediumGray,
                          ),
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(
                                  Icons.close_rounded,
                                  size: 18,
                                  color: AppColors.mediumGray,
                                ),
                                onPressed: _searchController.clear,
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 13),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Loading ───────────────────────────────────────────────────────
          if (_loading)
            const Center(child: AppLoader()),

          // ── Error ─────────────────────────────────────────────────────────
          if (!_loading && _error != null)
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Jost',
                    fontSize: 14,
                    color: AppColors.navyBlue,
                  ),
                ),
              ),
            ),

          // ── Bottom venue cards ────────────────────────────────────────────
          if (!_loading && _error == null && _filtered.isNotEmpty)
            Positioned(
              left: 0,
              right: 0,
              bottom: 20,
              height: 120,
              child: PageView.builder(
                controller: _pageController,
                itemCount: _filtered.length,
                onPageChanged: (i) {
                  setState(() => _selectedIndex = i);
                  _panToVenue(_filtered[i]);
                  _rebuildMarkers();
                },
                itemBuilder: (context, i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: _VenueMapCard(
                    venue: _filtered[i],
                    isSelected: i == _selectedIndex,
                    onBookNow: () => Navigator.pushNamed(
                      context,
                      AppRoutes.venueDetail,
                      arguments: _filtered[i].slug,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Venue bottom card ──────────────────────────────────────────────────────────

class _VenueMapCard extends StatelessWidget {
  final VenueModel venue;
  final bool isSelected;
  final VoidCallback onBookNow;

  const _VenueMapCard({
    required this.venue,
    required this.isSelected,
    required this.onBookNow,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isSelected
            ? Border.all(color: AppColors.limeGreen, width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isSelected ? 0.15 : 0.08),
            blurRadius: isSelected ? 18 : 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Venue image
          ClipRRect(
            borderRadius:
                const BorderRadius.horizontal(left: Radius.circular(16)),
            child: venue.primaryImage != null && venue.primaryImage!.isNotEmpty
                ? Image.network(
                    venue.primaryImage!,
                    width: 90,
                    height: 120,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _placeholder(),
                  )
                : _placeholder(),
          ),

          // Info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Name + rating
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          venue.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Jost',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.navyBlue,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.star_rounded,
                        color: Color(0xFFF5A623),
                        size: 14,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        venue.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontFamily: 'Jost',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.navyBlue,
                        ),
                      ),
                    ],
                  ),

                  // City
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        color: AppColors.mediumGray,
                        size: 12,
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          '${venue.city}, ${venue.state}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Jost',
                            fontSize: 11,
                            color: AppColors.mediumGray,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Distance + Book Now
                  Row(
                    children: [
                      if (venue.distance != null) ...[
                        const Icon(
                          Icons.near_me_rounded,
                          color: AppColors.limeGreen,
                          size: 12,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${venue.distance!.toStringAsFixed(1)} km',
                          style: const TextStyle(
                            fontFamily: 'Jost',
                            fontSize: 11,
                            color: AppColors.limeGreen,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const Spacer(),
                      GestureDetector(
                        onTap: onBookNow,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.limeGreen,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Book Now',
                                style: TextStyle(
                                  fontFamily: 'Jost',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 3),
                              Icon(
                                Icons.arrow_outward_rounded,
                                color: Colors.white,
                                size: 11,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 90,
      height: 120,
      color: AppColors.lightLimeGreen,
      child: const Icon(
        Icons.sports_soccer_rounded,
        color: AppColors.limeGreen,
        size: 32,
      ),
    );
  }
}
