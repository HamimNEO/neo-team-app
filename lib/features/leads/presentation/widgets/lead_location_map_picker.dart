import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/nec_button.dart';
import '../../data/services/location_search_service.dart';

class LocationPickResult {
  final String locationName;
  final double latitude;
  final double longitude;

  const LocationPickResult({
    required this.locationName,
    required this.latitude,
    required this.longitude,
  });
}

class LeadLocationMapPicker extends StatefulWidget {
  final String? initialLocation;
  final double? initialLatitude;
  final double? initialLongitude;

  const LeadLocationMapPicker({
    super.key,
    this.initialLocation,
    this.initialLatitude,
    this.initialLongitude,
  });

  static Future<LocationPickResult?> show(
    BuildContext context, {
    String? initialLocation,
    double? initialLatitude,
    double? initialLongitude,
  }) {
    return showModalBottomSheet<LocationPickResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LeadLocationMapPicker(
        initialLocation: initialLocation,
        initialLatitude: initialLatitude,
        initialLongitude: initialLongitude,
      ),
    );
  }

  @override
  State<LeadLocationMapPicker> createState() => _LeadLocationMapPickerState();
}

class _LeadLocationMapPickerState extends State<LeadLocationMapPicker> {
  GoogleMapController? _mapController;
  final _searchController = TextEditingController();
  final _addressController = TextEditingController();
  Timer? _debounceTimer;

  late LatLng _selectedPoint;
  bool _isSearching = false;
  bool _isReverseGeocoding = false;
  List<LocationSearchResult> _searchResults = [];

  static const _defaultCoxBazar = LatLng(21.4272, 92.0058);

  @override
  void initState() {
    super.initState();

    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      _selectedPoint =
          LatLng(widget.initialLatitude!, widget.initialLongitude!);
    } else {
      _selectedPoint = _defaultCoxBazar;
    }

    _addressController.text = widget.initialLocation ?? "Cox's Bazar";

    if (widget.initialLocation == null || widget.initialLocation!.isEmpty) {
      _performReverseGeocode(_selectedPoint.latitude, _selectedPoint.longitude);
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _addressController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 380), () async {
      setState(() => _isSearching = true);
      final results = await LocationSearchService.instance.search(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    });
  }

  void _selectSearchResult(LocationSearchResult item) {
    FocusScope.of(context).unfocus();
    final point = LatLng(item.latitude, item.longitude);
    setState(() {
      _selectedPoint = point;
      _addressController.text = item.title;
      _searchResults = [];
      _searchController.clear();
    });

    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(point, 15.5),
    );
  }

  void _onMapTapped(LatLng point) {
    setState(() {
      _selectedPoint = point;
    });
    _performReverseGeocode(point.latitude, point.longitude);
  }

  Future<void> _performReverseGeocode(double lat, double lng) async {
    setState(() => _isReverseGeocoding = true);
    final placeName =
        await LocationSearchService.instance.reverseGeocode(lat, lng);
    if (mounted) {
      setState(() {
        _isReverseGeocoding = false;
        if (placeName != null && placeName.isNotEmpty) {
          _addressController.text = placeName;
        } else {
          _addressController.text =
              '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';
        }
      });
    }
  }

  void _zoomIn() {
    _mapController?.animateCamera(CameraUpdate.zoomIn());
  }

  void _zoomOut() {
    _mapController?.animateCamera(CameraUpdate.zoomOut());
  }

  void _recenterOnPin() {
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(_selectedPoint, 15.5),
    );
  }

  void _jumpToHub(LocationSearchResult hub) {
    final point = LatLng(hub.latitude, hub.longitude);
    setState(() {
      _selectedPoint = point;
      _addressController.text = hub.title;
      _searchResults = [];
    });
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(point, 14.0),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    final mediaQuery = MediaQuery.of(context);
    final height = mediaQuery.size.height * 0.88;

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: nec.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 16, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: nec.brand.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    CupertinoIcons.map_pin_ellipse,
                    color: nec.brand,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Google Maps Location',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: nec.textPrimary,
                        ),
                      ),
                      Text(
                        'Search via Google Places or tap map to pin',
                        style: TextStyle(
                          fontSize: 12,
                          color: nec.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(CupertinoIcons.xmark_circle_fill,
                      color: nec.textTertiary, size: 24),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Container(
              decoration: BoxDecoration(
                color: nec.bg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: nec.separator.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  Icon(CupertinoIcons.search,
                      size: 18, color: nec.textTertiary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      style: TextStyle(fontSize: 14, color: nec.textPrimary),
                      decoration: InputDecoration(
                        hintText:
                            'Search Google Places (hotel, area, landmark)...',
                        hintStyle: TextStyle(
                          fontSize: 14,
                          color: nec.textTertiary,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  if (_isSearching)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: CupertinoActivityIndicator(radius: 8),
                    )
                  else if (_searchController.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(CupertinoIcons.clear_thick_circled,
                          size: 16),
                      color: nec.textTertiary,
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchResults = []);
                      },
                    ),
                ],
              ),
            ),
          ),
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              itemCount: LocationSearchService.popularHubs.take(5).length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final hub = LocationSearchService.popularHubs[i];
                return InkWell(
                  onTap: () => _jumpToHub(hub),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: nec.bg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: nec.separator.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(CupertinoIcons.location_fill,
                            size: 11, color: nec.brand),
                        const SizedBox(width: 4),
                        Text(
                          hub.title,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: nec.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _selectedPoint,
                    zoom: 14.0,
                  ),
                  onMapCreated: (controller) => _mapController = controller,
                  onTap: _onMapTapped,
                  markers: {
                    Marker(
                      markerId: const MarkerId('picked_location'),
                      position: _selectedPoint,
                      infoWindow: InfoWindow(title: _addressController.text),
                    ),
                  },
                  myLocationEnabled: false,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                  compassEnabled: true,
                ),
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: Column(
                    children: [
                      _MapCircleButton(
                        icon: CupertinoIcons.scope,
                        tooltip: 'Recenter on Pin',
                        onTap: _recenterOnPin,
                      ),
                      const SizedBox(height: 8),
                      _MapCircleButton(
                        icon: CupertinoIcons.add,
                        tooltip: 'Zoom In',
                        onTap: _zoomIn,
                      ),
                      const SizedBox(height: 8),
                      _MapCircleButton(
                        icon: CupertinoIcons.minus,
                        tooltip: 'Zoom Out',
                        onTap: _zoomOut,
                      ),
                    ],
                  ),
                ),
                if (_searchResults.isNotEmpty)
                  Positioned(
                    top: 0,
                    left: 16,
                    right: 16,
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 260),
                      decoration: BoxDecoration(
                        color: nec.surface,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.18),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        itemCount: _searchResults.length,
                        separatorBuilder: (_, __) => Divider(
                          height: 1,
                          color: nec.separator.withValues(alpha: 0.2),
                        ),
                        itemBuilder: (context, idx) {
                          final item = _searchResults[idx];
                          return ListTile(
                            dense: true,
                            leading: Icon(CupertinoIcons.location_solid,
                                color: nec.brand, size: 20),
                            title: Text(
                              item.title,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: nec.textPrimary,
                              ),
                            ),
                            subtitle: Text(
                              item.subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: nec.textTertiary,
                              ),
                            ),
                            trailing: Text(
                              '${item.latitude.toStringAsFixed(2)}, ${item.longitude.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: nec.textTertiary,
                              ),
                            ),
                            onTap: () => _selectSearchResult(item),
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            decoration: BoxDecoration(
              color: nec.surface,
              border: Border(
                top: BorderSide(
                  color: nec.separator.withValues(alpha: 0.25),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(CupertinoIcons.placemark_fill,
                        color: AppColors.error, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'SELECTED GOOGLE LOCATION',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: nec.textTertiary,
                                  letterSpacing: 0.6,
                                ),
                              ),
                              if (_isReverseGeocoding) ...[
                                const SizedBox(width: 8),
                                const CupertinoActivityIndicator(radius: 6),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          TextField(
                            controller: _addressController,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: nec.textPrimary,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Location Name',
                              hintStyle: TextStyle(color: nec.textTertiary),
                              isDense: true,
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: nec.brand.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${_selectedPoint.latitude.toStringAsFixed(5)}, ${_selectedPoint.longitude.toStringAsFixed(5)}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: nec.brand,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                NecButton(
                  label: 'Confirm Location',
                  icon: const Icon(CupertinoIcons.checkmark_alt,
                      color: Colors.white, size: 18),
                  onPressed: () {
                    final cleanName = _addressController.text.trim();
                    final finalName = cleanName.isNotEmpty
                        ? cleanName
                        : '${_selectedPoint.latitude.toStringAsFixed(5)}, ${_selectedPoint.longitude.toStringAsFixed(5)}';

                    Navigator.of(context).pop(
                      LocationPickResult(
                        locationName: finalName,
                        latitude: _selectedPoint.latitude,
                        longitude: _selectedPoint.longitude,
                      ),
                    );
                  },
                  fullWidth: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MapCircleButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _MapCircleButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final nec = Theme.of(context).extension<NecColors>()!;
    return Material(
      color: nec.surface,
      elevation: 4,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onTap,
          child: Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            child: Icon(icon, color: nec.textPrimary, size: 20),
          ),
        ),
      ),
    );
  }
}
