import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../utils/app_colors.dart';

class MapPickerResult {
  final double lat;
  final double lng;
  final String address;

  const MapPickerResult({
    required this.lat,
    required this.lng,
    required this.address,
  });
}

class MapPickerScreen extends StatefulWidget {
  final String title;
  final double? initialLat;
  final double? initialLng;

  const MapPickerScreen({
    super.key,
    this.title = 'Pick location',
    this.initialLat,
    this.initialLng,
  });

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  GoogleMapController? _mapController;
  LatLng _center = const LatLng(31.5204, 74.3587);
  String _address = 'Loading address...';
  bool _loadingAddress = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialLat != null &&
        widget.initialLng != null &&
        widget.initialLat != 0 &&
        widget.initialLng != 0) {
      _center = LatLng(widget.initialLat!, widget.initialLng!);
      _resolveAddress(_center);
    } else {
      _goToCurrentLocation();
    }
  }

  Future<void> _goToCurrentLocation() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      final pos = await Geolocator.getCurrentPosition();
      final latLng = LatLng(pos.latitude, pos.longitude);
      if (!mounted) return;
      setState(() => _center = latLng);
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 15));
      await _resolveAddress(latLng);
    } catch (_) {
      if (mounted) setState(() => _address = 'Move the map to choose a location');
    }
  }

  Future<void> _resolveAddress(LatLng latLng) async {
    setState(() {
      _loadingAddress = true;
      _address = 'Loading address...';
    });
    try {
      final marks = await placemarkFromCoordinates(
        latLng.latitude,
        latLng.longitude,
      ).timeout(const Duration(seconds: 5));
      if (!mounted) return;
      if (marks.isEmpty) {
        setState(() {
          _address =
              '${latLng.latitude.toStringAsFixed(5)}, ${latLng.longitude.toStringAsFixed(5)}';
          _loadingAddress = false;
        });
        return;
      }
      final p = marks.first;
      final label = [
        p.name,
        p.street,
        p.subLocality,
        p.locality,
        p.administrativeArea,
      ].where((v) => (v ?? '').trim().isNotEmpty).join(', ');
      setState(() {
        _address = label.isNotEmpty
            ? label
            : '${latLng.latitude.toStringAsFixed(5)}, ${latLng.longitude.toStringAsFixed(5)}';
        _loadingAddress = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _address =
            '${latLng.latitude.toStringAsFixed(5)}, ${latLng.longitude.toStringAsFixed(5)}';
        _loadingAddress = false;
      });
    }
  }

  void _onCameraIdle() {
    _resolveAddress(_center);
  }

  void _confirm() {
    Navigator.pop(
      context,
      MapPickerResult(
        lat: _center.latitude,
        lng: _center.longitude,
        address: _address,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.buttercream,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: AppColors.deepNavy,
        foregroundColor: AppColors.white,
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _center, zoom: 14),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            onMapCreated: (c) => _mapController = c,
            onCameraMove: (pos) => _center = pos.target,
            onCameraIdle: _onCameraIdle,
          ),
          const Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 36),
              child: Icon(
                Icons.location_pin,
                size: 48,
                color: AppColors.midnightBlue,
              ),
            ),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: SafeArea(
              child: FloatingActionButton.small(
                heroTag: 'map_picker_gps',
                backgroundColor: AppColors.white,
                onPressed: _goToCurrentLocation,
                child: const Icon(Icons.my_location, color: AppColors.midnightBlue),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.ivory),
                  boxShadow: AppColors.cardShadow,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _loadingAddress ? 'Loading address...' : _address,
                      style: const TextStyle(
                        color: AppColors.deepNavy,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _goToCurrentLocation,
                      icon: const Icon(Icons.my_location_outlined),
                      label: const Text('Use My Current Location'),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _loadingAddress ? null : _confirm,
                      child: const Text('Confirm Location'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

