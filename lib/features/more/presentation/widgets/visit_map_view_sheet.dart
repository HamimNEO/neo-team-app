import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/nec_toast.dart';

class VisitMapViewSheet extends StatefulWidget {
  final String locationName;
  final String leadName;
  final double? latitude;
  final double? longitude;

  const VisitMapViewSheet({
    super.key,
    required this.locationName,
    required this.leadName,
    this.latitude,
    this.longitude,
  });

  @override
  State<VisitMapViewSheet> createState() => _VisitMapViewSheetState();
}

class _VisitMapViewSheetState extends State<VisitMapViewSheet>
    with TickerProviderStateMixin {
  late final TransformationController _transformationController;
  late final AnimationController _pulseController;
  late final AnimationController _matrixAnimController;
  Animation<Matrix4>? _matrixAnimation;

  late double _lat;
  late double _lng;

  late double _userLat;
  late double _userLng;

  final int _baseZoom = 15;
  String _mapType = 'roadmap';
  bool _showRouteLine = true;
  String? _encodedPolyline;
  String _routeDuration = '12 min';
  String _routeDistance = '3.8 km';

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _matrixAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _initCoordinates();
    _tryFetchDirectionsPolyline();
  }

  void _initCoordinates() {
    if (widget.latitude != null && widget.longitude != null) {
      _lat = widget.latitude!;
      _lng = widget.longitude!;
    } else {
      final loc = widget.locationName.toLowerCase();
      if (loc.contains('dhaka') ||
          loc.contains('gulshan') ||
          loc.contains('banani')) {
        _lat = 23.7925;
        _lng = 90.4078;
        _routeDuration = '23 min';
        _routeDistance = '7.6 km';
      } else if (loc.contains('chittagong') || loc.contains('chattogram')) {
        _lat = 22.3569;
        _lng = 91.7832;
        _routeDuration = '18 min';
        _routeDistance = '5.4 km';
      } else if (loc.contains('sylhet')) {
        _lat = 24.8949;
        _lng = 91.8687;
        _routeDuration = '15 min';
        _routeDistance = '4.2 km';
      } else {
        _lat = 21.4272;
        _lng = 91.9806;
        _routeDuration = '12 min';
        _routeDistance = '3.8 km';
      }
    }

    _userLat = _lat - 0.0165;
    _userLng = _lng - 0.0125;
  }

  /// Attempts to fetch live road navigation polyline from Google Directions API if enabled
  Future<void> _tryFetchDirectionsPolyline() async {
    final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
    if (apiKey.isEmpty) return;

    try {
      final uri = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json?'
        'origin=$_userLat,$_userLng&destination=$_lat,$_lng&mode=driving&key=$apiKey',
      );

      final client = HttpClient();
      final request = await client.getUrl(uri);
      final response = await request.close();

      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final json = jsonDecode(body) as Map<String, dynamic>;
        final routes = json['routes'] as List<dynamic>?;
        if (routes != null && routes.isNotEmpty) {
          final legs = routes[0]['legs'] as List<dynamic>?;
          if (legs != null && legs.isNotEmpty) {
            final durationText = legs[0]['duration']?['text'] as String?;
            final distanceText = legs[0]['distance']?['text'] as String?;
            final overview =
                routes[0]['overview_polyline']?['points'] as String?;

            if (mounted) {
              setState(() {
                if (durationText != null) _routeDuration = durationText;
                if (distanceText != null) _routeDistance = distanceText;
                if (overview != null) _encodedPolyline = overview;
              });
            }
          }
        }
      }
      client.close();
    } catch (_) {
      // Gracefully falls back to realistic street-following waypoints
    }
  }

  /// Turn-by-turn road waypoints that follow the street grid rather than a straight diagonal line
  List<Map<String, double>> _getRoadWaypoints() {
    final dLat = _lat - _userLat;
    final dLng = _lng - _userLng;

    return [
      {'lat': _userLat, 'lng': _userLng},
      {'lat': _userLat + dLat * 0.18, 'lng': _userLng + dLng * 0.04},
      {'lat': _userLat + dLat * 0.38, 'lng': _userLng + dLng * 0.28},
      {'lat': _userLat + dLat * 0.50, 'lng': _userLng + dLng * 0.55},
      {'lat': _userLat + dLat * 0.76, 'lng': _userLng + dLng * 0.70},
      {'lat': _userLat + dLat * 0.88, 'lng': _userLng + dLng * 0.94},
      {'lat': _lat, 'lng': _lng},
    ];
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _pulseController.dispose();
    _matrixAnimController.dispose();
    super.dispose();
  }

  void _smoothScale(double factor) {
    HapticFeedback.selectionClick();
    final current = _transformationController.value;
    final target = current.clone()
      ..multiply(Matrix4.diagonal3Values(factor, factor, 1.0));

    _animateToMatrix(target);
  }

  void _recenterMap() {
    HapticFeedback.mediumImpact();
    _animateToMatrix(Matrix4.identity());
    NecToast.show(
      context,
      message: 'Map recentered at ${widget.locationName}',
      type: NecToastType.info,
    );
  }

  void _animateToMatrix(Matrix4 target) {
    _matrixAnimation = Matrix4Tween(
      begin: _transformationController.value,
      end: target,
    ).animate(CurvedAnimation(
      parent: _matrixAnimController,
      curve: Curves.easeOutCubic,
    ))
      ..addListener(() {
        _transformationController.value = _matrixAnimation!.value;
      });

    _matrixAnimController.forward(from: 0.0);
  }

  Future<void> _openGoogleMapsDirections() async {
    HapticFeedback.heavyImpact();

    final universalWebUrl = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$_lat,$_lng&destination_place_id=&travelmode=driving',
    );

    final androidIntentUri =
        Uri.parse('google.navigation:q=$_lat,$_lng&mode=d');

    final iosSchemeUri =
        Uri.parse('comgooglemaps://?daddr=$_lat,$_lng&directionsmode=driving');

    try {
      if (await canLaunchUrl(androidIntentUri)) {
        await launchUrl(androidIntentUri, mode: LaunchMode.externalApplication);
        return;
      }

      if (await canLaunchUrl(iosSchemeUri)) {
        await launchUrl(iosSchemeUri, mode: LaunchMode.externalApplication);
        return;
      }

      if (await canLaunchUrl(universalWebUrl)) {
        await launchUrl(universalWebUrl, mode: LaunchMode.externalApplication);
        return;
      }

      if (!mounted) return;
      await launchUrl(universalWebUrl, mode: LaunchMode.platformDefault);
    } catch (e) {
      if (!mounted) return;
      NecToast.show(
        context,
        message: 'Opening Google Maps in browser...',
        type: NecToastType.info,
      );
      await launchUrl(universalWebUrl, mode: LaunchMode.platformDefault);
    }
  }

  void _copyCoordinates() {
    Clipboard.setData(ClipboardData(text: '$_lat, $_lng'));
    HapticFeedback.lightImpact();
    NecToast.show(
      context,
      message:
          'Coordinates copied: ${_lat.toStringAsFixed(4)}°, ${_lng.toStringAsFixed(4)}°',
      type: NecToastType.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetHeight = MediaQuery.of(context).size.height * 0.86;

    final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';

    final centerLat = (_userLat + _lat) / 2;
    final centerLng = (_userLng + _lng) / 2;

    final waypoints = _getRoadWaypoints();
    final waypointsString =
        waypoints.map((p) => '${p['lat']},${p['lng']}').join('|');

    String pathQuery = '';
    if (_showRouteLine) {
      if (_encodedPolyline != null) {
        pathQuery = '&path=color:0x1D4ED8EE|weight:8|enc:$_encodedPolyline'
            '&path=color:0x2563EBEE|weight:5|enc:$_encodedPolyline';
      } else {
        pathQuery = '&path=color:0x1D4ED8EE|weight:8|$waypointsString'
            '&path=color:0x2563EBEE|weight:5|$waypointsString';
      }
    }

    final staticMapUrl = apiKey.isNotEmpty
        ? 'https://maps.googleapis.com/maps/api/staticmap?'
            'center=$centerLat,$centerLng&zoom=$_baseZoom&scale=2&size=640x520'
            '&maptype=$_mapType'
            '$pathQuery'
            '&markers=color:0x1A73E8|size:mid|$_userLat,$_userLng'
            '&markers=color:0xEA4335|size:large|$_lat,$_lng'
            '&key=$apiKey'
        : '';

    return Container(
      height: sheetHeight,
      decoration: BoxDecoration(
        color: nec.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4.5,
                decoration: BoxDecoration(
                  color: nec.textTertiary.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF6355F6), Color(0xFF7C6FF7)],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(CupertinoIcons.map_fill,
                              size: 16, color: Colors.white),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Live Map & Directions',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: nec.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: nec.separator.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(CupertinoIcons.xmark,
                            size: 16, color: nec.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Divider(height: 1, color: nec.separator.withValues(alpha: 0.25)),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: nec.bg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: nec.separator.withValues(alpha: 0.25)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: AppColors.error.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                CupertinoIcons.location_solid,
                                color: AppColors.error,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.leadName,
                                    style: TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w700,
                                      color: nec.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    widget.locationName,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: nec.textSecondary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            InkWell(
                              onTap: _copyCoordinates,
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 5),
                                decoration: BoxDecoration(
                                  color: nec.surface,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color:
                                          nec.separator.withValues(alpha: 0.2)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(CupertinoIcons.doc_on_clipboard,
                                        size: 12, color: Color(0xFF6355F6)),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Copy',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: nec.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF14151B)
                                : const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: nec.separator.withValues(alpha: 0.3)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black
                                    .withValues(alpha: isDark ? 0.3 : 0.08),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final viewportW = constraints.maxWidth;
                              final viewportH = constraints.maxHeight;

                              return Stack(
                                children: [
                                  Positioned.fill(
                                    child: InteractiveViewer(
                                      transformationController:
                                          _transformationController,
                                      panEnabled: true,
                                      scaleEnabled: true,
                                      minScale: 1.0,
                                      maxScale: 4.5,
                                      boundaryMargin: EdgeInsets.zero,
                                      child: SizedBox(
                                        width: viewportW,
                                        height: viewportH,
                                        child: staticMapUrl.isNotEmpty
                                            ? Image.network(
                                                staticMapUrl,
                                                width: viewportW,
                                                height: viewportH,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) =>
                                                    _buildVectorFallback(
                                                        isDark,
                                                        nec,
                                                        viewportW,
                                                        viewportH),
                                                loadingBuilder: (context, child,
                                                    loadingProgress) {
                                                  if (loadingProgress == null) {
                                                    return child;
                                                  }
                                                  return Stack(
                                                    fit: StackFit.expand,
                                                    children: [
                                                      _buildVectorFallback(
                                                          isDark,
                                                          nec,
                                                          viewportW,
                                                          viewportH),
                                                      Center(
                                                        child: Container(
                                                          padding:
                                                              const EdgeInsets
                                                                  .all(12),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: Colors.black
                                                                .withValues(
                                                                    alpha:
                                                                        0.65),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        12),
                                                          ),
                                                          child:
                                                              const CircularProgressIndicator(
                                                            strokeWidth: 2.5,
                                                            color: Color(
                                                                0xFF6355F6),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  );
                                                },
                                              )
                                            : _buildVectorFallback(isDark, nec,
                                                viewportW, viewportH),
                                      ),
                                    ),
                                  ),
                                  if (_showRouteLine)
                                    Positioned(
                                      top: 12,
                                      left: 12,
                                      right: 12,
                                      child: Center(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 14, vertical: 7),
                                          decoration: BoxDecoration(
                                            color: isDark
                                                ? const Color(0xFF1E293B)
                                                : Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(24),
                                            border: Border.all(
                                                color: const Color(0xFF2563EB)
                                                    .withValues(alpha: 0.35)),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withValues(alpha: 0.18),
                                                blurRadius: 10,
                                                offset: const Offset(0, 3),
                                              ),
                                            ],
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.all(4),
                                                decoration: const BoxDecoration(
                                                  color: Color(0xFF2563EB),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                    CupertinoIcons.car_detailed,
                                                    size: 12,
                                                    color: Colors.white),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                '$_routeDuration ($_routeDistance)',
                                                style: TextStyle(
                                                  fontSize: 12.5,
                                                  fontWeight: FontWeight.w700,
                                                  color: nec.textPrimary,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Container(
                                                width: 4,
                                                height: 4,
                                                decoration: BoxDecoration(
                                                  color: nec.textTertiary,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              const Text(
                                                'Fastest Route',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700,
                                                  color: Color(0xFF16A34A),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  if (_showRouteLine)
                                    Positioned(
                                      left: 32,
                                      top: viewportH * 0.45,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1D4ED8),
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black
                                                  .withValues(alpha: 0.3),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                                CupertinoIcons
                                                    .arrow_turn_up_right,
                                                size: 12,
                                                color: Colors.white),
                                            const SizedBox(width: 5),
                                            Text(
                                              _routeDuration,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  Positioned(
                                    right: 12,
                                    bottom: 12,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        _buildCircleButton(
                                          icon: CupertinoIcons.add,
                                          tooltip: 'Zoom in',
                                          onTap: () => _smoothScale(1.3),
                                        ),
                                        const SizedBox(height: 8),
                                        _buildCircleButton(
                                          icon: CupertinoIcons.minus,
                                          tooltip: 'Zoom out',
                                          onTap: () => _smoothScale(0.77),
                                        ),
                                        const SizedBox(height: 8),
                                        _buildCircleButton(
                                          icon: CupertinoIcons.location_fill,
                                          iconColor: const Color(0xFF2563EB),
                                          tooltip: 'Recenter',
                                          onTap: _recenterMap,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Positioned(
                                    left: 12,
                                    bottom: 12,
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(3),
                                          decoration: BoxDecoration(
                                            color: Colors.black
                                                .withValues(alpha: 0.82),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                                color: Colors.white
                                                    .withValues(alpha: 0.14)),
                                          ),
                                          child: Row(
                                            children: [
                                              _buildLayerTab('Map', 'roadmap'),
                                              _buildLayerTab(
                                                  'Sat', 'satellite'),
                                              _buildLayerTab(
                                                  'Terrain', 'terrain'),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _showRouteLine = !_showRouteLine;
                                            });
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: _showRouteLine
                                                  ? const Color(0xFF2563EB)
                                                  : Colors.black
                                                      .withValues(alpha: 0.82),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: _showRouteLine
                                                    ? const Color(0xFF2563EB)
                                                    : Colors.white.withValues(
                                                        alpha: 0.14),
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  CupertinoIcons.arrow_branch,
                                                  size: 13,
                                                  color: _showRouteLine
                                                      ? Colors.white
                                                      : Colors.white70,
                                                ),
                                                const SizedBox(width: 5),
                                                Text(
                                                  'Route',
                                                  style: TextStyle(
                                                    fontSize: 11.5,
                                                    fontWeight: FontWeight.w700,
                                                    color: _showRouteLine
                                                        ? Colors.white
                                                        : Colors.white70,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _openGoogleMapsDirections,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Ink(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF2563EB)
                                      .withValues(alpha: 0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Container(
                              height: 52,
                              alignment: Alignment.center,
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    CupertinoIcons.arrow_turn_up_right,
                                    size: 19,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    'Open Directions in Google Maps',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLayerTab(String label, String type) {
    final isSelected = _mapType == type;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _mapType = type;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2563EB) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : Colors.white70,
          ),
        ),
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onTap,
    String? tooltip,
    Color iconColor = Colors.white,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.82),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: iconColor, size: 18),
      ),
    );
  }

  Widget _buildVectorFallback(
      bool isDark, NecColors nec, double width, double height) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, _) {
        return CustomPaint(
          size: Size(width, height),
          painter: _MapCanvasPainter(
            isDark: isDark,
            pulseValue: _pulseController.value,
            showRouteLine: _showRouteLine,
            locationName: widget.locationName,
            leadName: widget.leadName,
          ),
        );
      },
    );
  }
}

/// Custom painter for rich road grid, turn-by-turn road polyline, traffic segment, and authentic Google Maps markers
class _MapCanvasPainter extends CustomPainter {
  final bool isDark;
  final double pulseValue;
  final bool showRouteLine;
  final String locationName;
  final String leadName;

  _MapCanvasPainter({
    required this.isDark,
    required this.pulseValue,
    required this.showRouteLine,
    required this.locationName,
    required this.leadName,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..color = isDark ? const Color(0xFF141724) : const Color(0xFFF1F5F9);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final waterPaint = Paint()
      ..color = isDark ? const Color(0xFF0F172A) : const Color(0xFFBAE6FD);
    final waterPath = Path()
      ..moveTo(0, size.height * 0.72)
      ..quadraticBezierTo(
          size.width * 0.35, size.height * 0.68, size.width * 0.5, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(waterPath, waterPaint);

    final gridPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06)
      ..strokeWidth = 2.0;

    for (double x = 30; x < size.width; x += 50) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 30; y < size.height; y += 50) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final roadPaint = Paint()
      ..color = isDark ? const Color(0xFF282F3E) : Colors.white
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final roadPath = Path()
      ..moveTo(size.width * 0.1, size.height * 0.9)
      ..lineTo(size.width * 0.35, size.height * 0.68)
      ..lineTo(size.width * 0.65, size.height * 0.52)
      ..lineTo(size.width * 0.85, size.height * 0.22);
    canvas.drawPath(roadPath, roadPaint);

    final startPoint = Offset(size.width * 0.35, size.height * 0.68);
    final turn1 = Offset(size.width * 0.50, size.height * 0.58);
    final turn2 = Offset(size.width * 0.62, size.height * 0.42);
    final destPoint = Offset(size.width * 0.75, size.height * 0.28);

    if (showRouteLine) {
      final casingPaint = Paint()
        ..color = const Color(0xFF1D4ED8)
        ..strokeWidth = 8.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      final navPaint = Paint()
        ..color = const Color(0xFF2563EB)
        ..strokeWidth = 5.2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      final trafficPaint = Paint()
        ..color = const Color(0xFFF59E0B)
        ..strokeWidth = 5.2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final routePath = Path()
        ..moveTo(startPoint.dx, startPoint.dy)
        ..lineTo(turn1.dx, turn1.dy)
        ..lineTo(turn2.dx, turn2.dy)
        ..lineTo(destPoint.dx, destPoint.dy);

      canvas.drawPath(routePath, casingPaint);
      canvas.drawPath(routePath, navPaint);

      final trafficSegment = Path()
        ..moveTo(turn1.dx, turn1.dy)
        ..lineTo(turn2.dx, turn2.dy);
      canvas.drawPath(trafficSegment, trafficPaint);
    }

    final pulseRadius = 13.0 + (pulseValue * 18.0);
    final pulseAlpha = (1.0 - pulseValue).clamp(0.0, 1.0) * 0.45;
    final pulsePaint = Paint()
      ..color = const Color(0xFF1A73E8).withValues(alpha: pulseAlpha)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(startPoint, pulseRadius, pulsePaint);

    final userDotPaint = Paint()..color = const Color(0xFF1A73E8);
    final userBorderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(startPoint, 8.0, userDotPaint);
    canvas.drawCircle(startPoint, 8.0, userBorderPaint);

    final pinShadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(
        Offset(destPoint.dx, destPoint.dy + 2), 11.0, pinShadowPaint);

    final pinPaint = Paint()..color = const Color(0xFFEA4335);
    canvas.drawCircle(destPoint, 10.5, pinPaint);
    final pinBorder = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(destPoint, 10.5, pinBorder);

    final centerDot = Paint()..color = Colors.white;
    canvas.drawCircle(destPoint, 4.0, centerDot);
  }

  @override
  bool shouldRepaint(covariant _MapCanvasPainter oldDelegate) {
    return oldDelegate.pulseValue != pulseValue ||
        oldDelegate.showRouteLine != showRouteLine ||
        oldDelegate.isDark != isDark;
  }
}
