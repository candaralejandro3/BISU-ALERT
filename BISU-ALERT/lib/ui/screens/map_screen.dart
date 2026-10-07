import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/mock/mock_data.dart';
import '../../data/model/campus_location.dart';
import '../theme/app_colors.dart';

enum MapFilter {
  all,
  emergencyHubs,
  clinic,
  security,
  fireEquipment,
  evacuationZones,
  emergencyExits,
  fireExtinguishers,
  buildings,
  myLocation,
}

extension MapFilterExtension on MapFilter {
  String get label {
    switch (this) {
      case MapFilter.all:
        return 'All Landmarks';
      case MapFilter.emergencyHubs:
        return '🟢 Emergency Hubs';
      case MapFilter.clinic:
        return '🏥 Clinic';
      case MapFilter.security:
        return '🛡️ Security';
      case MapFilter.fireEquipment:
        return '🚒 Fire Equipment';
      case MapFilter.evacuationZones:
        return '🟡 Evacuation Zones';
      case MapFilter.emergencyExits:
        return '🚪 Emergency Exits';
      case MapFilter.fireExtinguishers:
        return '💧 Fire Extinguishers';
      case MapFilter.buildings:
        return '🏢 Buildings';
      case MapFilter.myLocation:
        return '📍 My Location';
    }
  }
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const LatLng _campusCenter = LatLng(9.71888, 124.10883);
  static const LatLng _userLocation = LatLng(9.71860, 124.10920);

  GoogleMapController? _mapController;

  static const List<LatLng> _campusBoundary = [
    LatLng(9.7183961, 124.1114733),
    LatLng(9.7165832, 124.1103364),
    LatLng(9.7166844, 124.1097760),
    LatLng(9.7173327, 124.1087834),
    LatLng(9.7170571, 124.1077396),
    LatLng(9.7163301, 124.1065112),
    LatLng(9.7163248, 124.1062081),
    LatLng(9.7163962, 124.1059157),
    LatLng(9.7166711, 124.1055912),
    LatLng(9.7176387, 124.1049850),
    LatLng(9.7187121, 124.1059774),
    LatLng(9.7196797, 124.1063690),
    LatLng(9.7201238, 124.1060364),
    LatLng(9.7215302, 124.1064978),
    LatLng(9.7221727, 124.1081178),
    LatLng(9.7207556, 124.1089520),
    LatLng(9.7200612, 124.1095416),
    LatLng(9.7197563, 124.1098988),
    LatLng(9.7192910, 124.1106203),
    LatLng(9.7190161, 124.1105184),
  ];

  MapFilter _selectedFilter = MapFilter.all;
  String _searchQuery = '';
  MapType _mapType = MapType.normal;

  // Evacuation Mode State
  bool _isEvacuationMode = false;
  String? _activeNavigationRouteName;
  Set<Polyline> _polylines = {};

  bool get _isSatellite => _mapType == MapType.hybrid;

  Iterable<CampusLocation> get _filteredLocations {
    Iterable<CampusLocation> locations;

    switch (_selectedFilter) {
      case MapFilter.all:
        locations = MockData.campusLocations;
        break;
      case MapFilter.emergencyHubs:
        locations = MockData.campusLocations.where((e) =>
            e.type == LocationType.emergencyHub ||
            e.type == LocationType.clinic ||
            e.type == LocationType.security);
        break;
      case MapFilter.clinic:
        locations = MockData.campusLocations.where((e) => e.type == LocationType.clinic);
        break;
      case MapFilter.security:
        locations = MockData.campusLocations.where((e) => e.type == LocationType.security);
        break;
      case MapFilter.fireEquipment:
        locations = MockData.campusLocations.where((e) => e.type == LocationType.fireEquipment);
        break;
      case MapFilter.evacuationZones:
        locations = MockData.campusLocations.where((e) => e.type == LocationType.evacuationZone);
        break;
      case MapFilter.emergencyExits:
        locations = MockData.campusLocations.where((e) => e.type == LocationType.emergencyExit);
        break;
      case MapFilter.fireExtinguishers:
        locations = MockData.campusLocations.where((e) => e.type == LocationType.fireExtinguisher);
        break;
      case MapFilter.buildings:
        locations = MockData.campusLocations.where((e) => e.type == LocationType.building);
        break;
      case MapFilter.myLocation:
        locations = [];
        break;
    }

    if (_searchQuery.isNotEmpty) {
      locations = locations.where((loc) =>
          loc.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          loc.description.toLowerCase().contains(_searchQuery.toLowerCase()));
    }

    return locations;
  }

  Set<Marker> get _markers {
    final Set<Marker> markers = _filteredLocations.map((location) {
      final double hue = switch (location.type) {
        LocationType.clinic => BitmapDescriptor.hueRed,
        LocationType.security => BitmapDescriptor.hueAzure,
        LocationType.emergencyHub => BitmapDescriptor.hueGreen,
        LocationType.evacuationZone => BitmapDescriptor.hueYellow,
        LocationType.emergencyExit => BitmapDescriptor.hueCyan,
        LocationType.fireEquipment => BitmapDescriptor.hueOrange,
        LocationType.fireExtinguisher => BitmapDescriptor.hueMagenta,
        LocationType.building => BitmapDescriptor.hueViolet,
      };

      return Marker(
        markerId: MarkerId(location.id),
        position: LatLng(location.latitude, location.longitude),
        infoWindow: InfoWindow(title: location.name, snippet: location.type.label),
        icon: BitmapDescriptor.defaultMarkerWithHue(hue),
        onTap: () => _showLocationDetails(location),
      );
    }).toSet();

    // Add My Location marker
    markers.add(
      Marker(
        markerId: const MarkerId('user_location'),
        position: _userLocation,
        infoWindow: const InfoWindow(title: 'My Location', snippet: 'GPS Accuracy: ±4m'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ),
    );

    return markers;
  }

  void _navigateToNearestSafeZone() {
    // Assembly Area A coordinates
    const LatLng safeZone = LatLng(9.719900, 124.107900);

    setState(() {
      _activeNavigationRouteName = 'Assembly Area A (Disaster Grounds)';
      _polylines = {
        const Polyline(
          polylineId: PolylineId('route_safe_zone'),
          points: [
            _userLocation,
            LatLng(9.71900, 124.10880),
            LatLng(9.71950, 124.10820),
            safeZone,
          ],
          color: Color(0xFF2E7D32),
          width: 5,
        ),
      };
    });

    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(const LatLng(9.7192, 124.1085), 17.5),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Color(0xFF2E7D32),
        content: Text('Safe Route: ~180 m to Assembly Area A (Estimated walk: 2 mins).'),
      ),
    );
  }

  void _navigateToNearestEmergencyFacility() {
    // Campus Medical Clinic coordinates
    const LatLng clinic = LatLng(9.717639, 124.109396);

    setState(() {
      _activeNavigationRouteName = 'Campus Medical Clinic';
      _polylines = {
        const Polyline(
          polylineId: PolylineId('route_clinic'),
          points: [
            _userLocation,
            LatLng(9.71810, 124.10940),
            clinic,
          ],
          color: Color(0xFFD32F2F),
          width: 5,
        ),
      };
    });

    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(const LatLng(9.7181, 124.1093), 18.0),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Color(0xFFD32F2F),
        content: Text('Emergency Route: ~110 m to Campus Medical Clinic.'),
      ),
    );
  }

  void _toggleEvacuationMode() {
    setState(() {
      _isEvacuationMode = !_isEvacuationMode;
      if (_isEvacuationMode) {
        _navigateToNearestSafeZone();
      } else {
        _polylines = {};
        _activeNavigationRouteName = null;
      }
    });
  }

  static Future<void> _dialNumber(BuildContext context, String phone) async {
    final Uri uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cannot place call to $phone.')),
        );
      }
    }
  }

  void _showLocationDetails(CampusLocation location) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: location.type.color.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(location.type.icon, color: location.type.color, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          location.name,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                        ),
                        Text(
                          location.type.label,
                          style: TextStyle(color: location.type.color, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                location.description,
                style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.4),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.phone, size: 15, color: Colors.black54),
                  const SizedBox(width: 6),
                  Text(
                    'Contact: ${location.contactNumber}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: location.type.color,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        setState(() {
                          _polylines = {
                            Polyline(
                              polylineId: PolylineId('route_${location.id}'),
                              points: [
                                _userLocation,
                                LatLng(location.latitude, location.longitude),
                              ],
                              color: location.type.color,
                              width: 4,
                            ),
                          };
                          _activeNavigationRouteName = location.name;
                        });
                        _mapController?.animateCamera(
                          CameraUpdate.newLatLngZoom(LatLng(location.latitude, location.longitude), 17.5),
                        );
                      },
                      icon: const Icon(Icons.navigation, size: 18),
                      label: const Text('Navigate Here', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      _dialNumber(context, location.contactNumber);
                    },
                    icon: const Icon(Icons.phone, size: 18),
                    label: const Text('Call'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: _campusCenter,
              zoom: 16.8,
            ),
            mapType: _mapType,
            markers: _markers,
            polylines: _polylines,
            polygons: {
              Polygon(
                polygonId: const PolygonId('campus_boundary'),
                points: _campusBoundary,
                strokeColor: const Color(0xFF2E7D32),
                strokeWidth: 2,
                fillColor: const Color(0xFF2E7D32).withValues(alpha: 0.08),
              ),
            },
            onMapCreated: (controller) => _mapController = controller,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),

          // Top Header & Search Bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Search & Map Mode Bar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                    child: Row(
                      children: [
                        const Icon(Icons.search, color: Colors.black54, size: 22),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(
                              hintText: 'Search clinic, gym, safe zone...',
                              border: InputBorder.none,
                              isDense: true,
                            ),
                            onChanged: (val) => setState(() => _searchQuery = val),
                          ),
                        ),
                        IconButton(
                          tooltip: _isSatellite ? 'Normal Map' : 'Satellite View',
                          icon: Icon(
                            _isSatellite ? Icons.map : Icons.satellite_alt,
                            color: AppColors.primary,
                          ),
                          onPressed: () {
                            setState(() {
                              _mapType = _isSatellite ? MapType.normal : MapType.hybrid;
                            });
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Horizontal Category Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: MapFilter.values.map((filter) {
                        final bool isSelected = _selectedFilter == filter;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: FilterChip(
                            label: Text(filter.label),
                            selected: isSelected,
                            onSelected: (_) {
                              setState(() => _selectedFilter = filter);
                              if (filter == MapFilter.myLocation) {
                                _mapController?.animateCamera(
                                  CameraUpdate.newLatLngZoom(_userLocation, 18),
                                );
                              }
                            },
                            selectedColor: AppColors.primary.withValues(alpha: 0.15),
                            backgroundColor: Colors.white,
                            labelStyle: TextStyle(
                              fontSize: 11.5,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                              color: isSelected ? AppColors.primary : Colors.black87,
                            ),
                            side: BorderSide(
                              color: isSelected ? AppColors.primary : Colors.black12,
                            ),
                            visualDensity: VisualDensity.compact,
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  // Active Evacuation Mode Alert Banner
                  if (_isEvacuationMode) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFD32F2F), Color(0xFFED6C02)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 28),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '⚠️ CAMPUS EVACUATION IN EFFECT',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12.5,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Proceed to: Assembly Area A • Distance: 180 m\nFollow the highlighted safe route.',
                                  style: TextStyle(color: Colors.white, fontSize: 11, height: 1.3),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white, size: 20),
                            onPressed: _toggleEvacuationMode,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Bottom Quick Routing Action Floating Controls
          Positioned(
            left: 14,
            right: 14,
            bottom: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_activeNavigationRouteName != null) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.black12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.directions, color: AppColors.primary, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Routing to: $_activeNavigationRouteName',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 16),
                          onPressed: () {
                            setState(() {
                              _activeNavigationRouteName = null;
                              _polylines = {};
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],

                Row(
                  children: [
                    // Navigate to nearest safe zone
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 3,
                        ),
                        onPressed: _navigateToNearestSafeZone,
                        icon: const Icon(Icons.health_and_safety, size: 16),
                        label: const Text(
                          'Nearest Safe Zone',
                          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Navigate to nearest emergency facility
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFD32F2F),
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 3,
                        ),
                        onPressed: _navigateToNearestEmergencyFacility,
                        icon: const Icon(Icons.local_hospital, size: 16),
                        label: const Text(
                          'Nearest Facility',
                          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Evacuation Mode Toggle
                    InkWell(
                      onTap: _toggleEvacuationMode,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _isEvacuationMode ? const Color(0xFFD32F2F) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _isEvacuationMode ? Colors.transparent : Colors.black12,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.warning_rounded,
                          color: _isEvacuationMode ? Colors.white : const Color(0xFFED6C02),
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
