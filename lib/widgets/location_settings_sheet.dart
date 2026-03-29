import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../theme/app_theme.dart';

class LocationSettingsSheet extends StatefulWidget {
  final String currentLocation;
  final LatLng currentLatLng;
  final double proximityRadius;
  final List<double> proximityOptions;
  final void Function(String location, LatLng latLng) onLocationChanged;
  final ValueChanged<double> onProximityChanged;

  const LocationSettingsSheet({
    super.key,
    required this.currentLocation,
    required this.currentLatLng,
    required this.proximityRadius,
    required this.proximityOptions,
    required this.onLocationChanged,
    required this.onProximityChanged,
  });

  @override
  State<LocationSettingsSheet> createState() => _LocationSettingsSheetState();
}

class _LocationSettingsSheetState extends State<LocationSettingsSheet> {
  late String _selectedLocation;
  late double _selectedProximity;
  late LatLng _currentLatLng;
  final MapController _mapController = MapController();
  bool _isGettingLocation = false;
  String _currentAddress = '';
  final TextEditingController _locationController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.currentLocation;
    _selectedProximity = widget.proximityRadius;
    _currentLatLng = widget.currentLatLng;
    
    _locationController.text = _selectedLocation;
    _reverseGeocode(_currentLatLng);
  }

  @override
  void dispose() {
    _mapController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  // Convert km radius to meters for the circle
  double get _radiusInMeters => _selectedProximity * 1000;

  // Reverse geocode coordinates to address
  Future<void> _reverseGeocode(LatLng location) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        String address = '';

        if (place.street != null && place.street!.isNotEmpty) {
          address = place.street!;
        }
        if (place.subLocality != null && place.subLocality!.isNotEmpty) {
          address = address.isEmpty
              ? place.subLocality!
              : '$address, ${place.subLocality}';
        }
        if (place.locality != null && place.locality!.isNotEmpty) {
          address = address.isEmpty
              ? place.locality!
              : '$address, ${place.locality}';
        }
        if (place.administrativeArea != null &&
            place.administrativeArea!.isNotEmpty) {
          address = address.isEmpty
              ? place.administrativeArea!
              : '$address, ${place.administrativeArea}';
        }

        setState(() {
          _currentAddress = address.isNotEmpty ? address : 'Selected Location';
        });
      }
    } catch (e) {
      setState(() {
        _currentAddress = 'Selected Location';
      });
    }
  }

  // Forward geocode address to coordinates
  Future<void> _geocodeAddress(String address) async {
    if (address.trim().isEmpty) return;

    setState(() => _isSearching = true);

    try {
      List<Location> locations = await locationFromAddress(address);

      if (locations.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location not found'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final newLocation = LatLng(
        locations.first.latitude,
        locations.first.longitude,
      );

      setState(() {
        _currentLatLng = newLocation;
        _selectedLocation = address;
      });

      // Move map and reverse geocode
      _mapController.move(newLocation, 14.0);
      await _reverseGeocode(newLocation);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to find location: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  // Get current location
  Future<void> _getCurrentLocation() async {
    setState(() => _isGettingLocation = true);

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please enable location services'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Location permission denied'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Location permissions are permanently denied. Please enable in settings.',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final newLocation = LatLng(position.latitude, position.longitude);

      setState(() {
        _currentLatLng = newLocation;
        _selectedLocation = 'Current Location';
        _locationController.text = 'Current Location';
      });

      // Move map and reverse geocode
      _mapController.move(newLocation, 14.0);
      await _reverseGeocode(newLocation);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to get location: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGettingLocation = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: FreshCycleTheme.borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Location Settings',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: FreshCycleTheme.textPrimary,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    final locationName = _currentAddress.isNotEmpty
                        ? _currentAddress
                        : _selectedLocation;
                    widget.onLocationChanged(locationName, _currentLatLng);
                    widget.onProximityChanged(_selectedProximity);
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Apply',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: FreshCycleTheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _currentLatLng,
                    initialZoom: 12.0,
                    onTap: (tapPosition, point) async {
                      setState(() {
                        _currentLatLng = point;
                      });
                      await _reverseGeocode(point);
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.flutter_application_1',
                    ),
                    CircleLayer(
                      circles: [
                        CircleMarker(
                          point: _currentLatLng,
                          radius: _radiusInMeters,
                          useRadiusInMeter: true,
                          color: FreshCycleTheme.primary.withOpacity(0.15),
                          borderColor: FreshCycleTheme.primary,
                          borderStrokeWidth: 2,
                        ),
                      ],
                    ),
                    // Pin marker
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _currentLatLng,
                          width: 40,
                          height: 40,
                          child: const LocationPin(),
                        ),
                      ],
                    ),
                  ],
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 16,
                          color: FreshCycleTheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _currentAddress.isNotEmpty
                                ? _currentAddress
                                : _selectedLocation,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: FreshCycleTheme.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${_selectedProximity.toStringAsFixed(1)} km',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: FreshCycleTheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Use current location button
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: FloatingActionButton.small(
                    heroTag: 'currentLocation',
                    onPressed: _isGettingLocation ? null : _getCurrentLocation,
                    backgroundColor: Colors.white,
                    foregroundColor: FreshCycleTheme.primary,
                    child: _isGettingLocation
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: FreshCycleTheme.primary,
                            ),
                          )
                        : const Icon(Icons.my_location),
                  ),
                ),
              ],
            ),
          ),
          // Location selector and proximity slider
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Search Location',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: FreshCycleTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: FreshCycleTheme.borderColor,
                      width: 0.5,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TextField(
                    controller: _locationController,
                    decoration: InputDecoration(
                      hintText: 'Enter address or place name...',
                      prefixIcon: const Icon(
                        Icons.search,
                        size: 20,
                        color: FreshCycleTheme.textSecondary,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      suffixIcon: _isSearching
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: FreshCycleTheme.primary,
                                ),
                              ),
                            )
                          : _locationController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    _locationController.clear();
                                  },
                                )
                              : null,
                    ),
                    onSubmitted: (value) {
                      if (value.isNotEmpty) {
                        _geocodeAddress(value);
                      }
                    },
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Search Radius',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: FreshCycleTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Show listings within ${_selectedProximity.toStringAsFixed(1)} km radius',
                  style: const TextStyle(
                    fontSize: 12,
                    color: FreshCycleTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                // Continuous slider with more granular control
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: FreshCycleTheme.primary,
                    inactiveTrackColor: FreshCycleTheme.primary.withOpacity(
                      0.2,
                    ),
                    thumbColor: FreshCycleTheme.primary,
                    overlayColor: FreshCycleTheme.primary.withOpacity(0.1),
                    valueIndicatorColor: FreshCycleTheme.primary,
                    valueIndicatorTextStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                    showValueIndicator: ShowValueIndicator.always,
                  ),
                  child: Slider(
                    value: _selectedProximity,
                    min: 1.0, // 1km minimum
                    max: 10.0, // 10km maximum
                    divisions: 90, 
                    label: '${_selectedProximity.toStringAsFixed(1)} km',
                    onChanged: (value) {
                      setState(() {
                        _selectedProximity = value;
                      });
                    },
                  ),
                ),
                // Radius preset buttons for quick selection
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildRadiusChip(1.0),
                    _buildRadiusChip(2.0),
                    _buildRadiusChip(5.0),
                    _buildRadiusChip(7.5),
                    _buildRadiusChip(10.0),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRadiusChip(double radius) {
    final isSelected = (_selectedProximity - radius).abs() < 0.1;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedProximity = radius);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? FreshCycleTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? FreshCycleTheme.primary
                : FreshCycleTheme.borderColor,
            width: 0.5,
          ),
        ),
        child: Text(
          '${radius.toInt()} km',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : FreshCycleTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}

// Custom location pin widget
class LocationPin extends StatelessWidget {
  const LocationPin({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Pin shadow
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
        ),
        // Pin icon
        Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            color: FreshCycleTheme.primary,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.location_on, color: Colors.white, size: 20),
        ),
        // Pin center dot
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }
}