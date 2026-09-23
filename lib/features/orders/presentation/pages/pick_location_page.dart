import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Result of picking a location.
class PickedLocation {
  const PickedLocation({
    required this.lat,
    required this.lng,
    required this.address,
  });
  final double lat;
  final double lng;
  final String address;
}

class PickLocationPage extends StatefulWidget {
  const PickLocationPage({
    super.key,
    this.initialLat,
    this.initialLng,
    this.title = 'Pick location',
  });

  final double? initialLat;
  final double? initialLng;
  final String title;

  @override
  State<PickLocationPage> createState() => _PickLocationPageState();
}

class _PickLocationPageState extends State<PickLocationPage> {
  /// Addis Ababa — Meskel Square, used when no initial location is provided.
  static const _fallback = LatLng(9.0192, 38.7525);

  late final LatLng _initialCenter;
  LatLng _selected = _fallback;

  String? _address;
  bool _loadingAddress = false;
  bool _mapReady = false;

  GoogleMapController? _controller;
  Timer? _geocodeDebounce;
  int _geocodeSeq = 0;

  bool get _isMountedSafe => mounted;

  @override
  void initState() {
    super.initState();

    // Only use the initial coords if BOTH are provided.
    final lat = widget.initialLat;
    final lng = widget.initialLng;
    _initialCenter = (lat != null && lng != null)
        ? LatLng(lat, lng)
        : _fallback;
    _selected = _initialCenter;

    // Kick off the first reverse-geocode
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _reverseGeocode(_initialCenter);
    });
  }

  @override
  void dispose() {
    _geocodeDebounce?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _onMapCreated(GoogleMapController c) async {
    _controller = c;
    if (_isMountedSafe) setState(() => _mapReady = true);
  }

  void _onCameraMove(CameraPosition pos) {
    _selected = pos.target;
    // Don't setState here — this fires ~60 times per drag.
    // Only update on idle.
  }

  void _onCameraIdle() {
    _geocodeDebounce?.cancel();
    _geocodeDebounce = Timer(const Duration(milliseconds: 350), () {
      if (_isMountedSafe) _reverseGeocode(_selected);
    });
  }

  Future<void> _reverseGeocode(LatLng p) async {
    // Sequence guard — ignore responses that arrive out of order
    final seq = ++_geocodeSeq;
    if (_isMountedSafe) {
      setState(() {
        _loadingAddress = true;
        _address = null;
      });
    }

    String? address;
    try {
      final placemarks =
          await placemarkFromCoordinates(p.latitude, p.longitude);
      if (placemarks.isNotEmpty) {
        final pl = placemarks.first;
        final parts = <String?>[
          pl.name,
          pl.street,
          pl.subLocality,
          pl.locality,
          pl.administrativeArea,
        ].where((s) => s != null && s.trim().isNotEmpty).toList();
        if (parts.isNotEmpty) address = parts.join(', ');
      }
    } on MissingPluginException {
      // Geocoding plugin not registered (rare) — no address, coords only
      address = null;
    } on PlatformException {
      // Network or quota issue — same fallback
      address = null;
    } catch (_) {
      address = null;
    }

    // Ignore if a newer geocode is in flight
    if (seq != _geocodeSeq) return;
    if (!_isMountedSafe) return;

    setState(() {
      _address = address;
      _loadingAddress = false;
    });
  }

  void _confirm() {
    HapticFeedback.selectionClick();
    Navigator.of(context).pop(
      PickedLocation(
        lat: _selected.latitude,
        lng: _selected.longitude,
        address: _address ?? '',
      ),
    );
  }

  Future<void> _recenter() async {
    HapticFeedback.selectionClick();
    final c = _controller;
    if (c == null) return;
    await c.animateCamera(
      CameraUpdate.newLatLng(_initialCenter),
    );
    if (_isMountedSafe) _reverseGeocode(_initialCenter);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          TextButton(
            onPressed: _confirm,
            child: const Text('Use'),
          ),
        ],
      ),
      body: Stack(
        children: [
          // ── Map ──
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _initialCenter,
              zoom: 15,
            ),
            onMapCreated: _onMapCreated,
            onCameraMove: _onCameraMove,
            onCameraIdle: _onCameraIdle,
            // Turn OFF my-location by default (needs permission).
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: true,
            padding: const EdgeInsets.only(bottom: 220),
          ),

          // ── Loading overlay for the map ──
          if (!_mapReady)
            const ColoredBox(
              color: Colors.black12,
              child: Center(child: CircularProgressIndicator()),
            ),

          // ── Center pin ──
          const IgnorePointer(
            child: Center(
              child: Padding(
                padding: EdgeInsets.only(bottom: 40),
                child: Icon(
                  Icons.location_pin,
                  size: 48,
                  color: Colors.red,
                ),
              ),
            ),
          ),

          // ── Recenter FAB ──
          Positioned(
            right: 16,
            bottom: 220,
            child: FloatingActionButton.small(
              heroTag: 'recenter',
              onPressed: _recenter,
              tooltip: 'Recenter',
              child: const Icon(Icons.my_location),
            ),
          ),

          // ── Bottom card ──
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _BottomCard(
              address: _address,
              loading: _loadingAddress,
              lat: _selected.latitude,
              lng: _selected.longitude,
              onConfirm: _confirm,
              scheme: scheme,
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomCard extends StatelessWidget {
  const _BottomCard({
    required this.address,
    required this.loading,
    required this.lat,
    required this.lng,
    required this.onConfirm,
    required this.scheme,
  });

  final String? address;
  final bool loading;
  final double lat;
  final double lng;
  final VoidCallback onConfirm;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final hasAddress = (address ?? '').trim().isNotEmpty;

    return Material(
      color: scheme.surface,
      elevation: 8,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.place, color: scheme.primary),
                  const SizedBox(width: 8),
                  const Text(
                    'Deliver here',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (loading)
                const Row(
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 10),
                    Text('Finding address…'),
                  ],
                )
              else
                Text(
                  hasAddress
                      ? address!
                      : 'No address found — coordinates will be sent',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: hasAddress ? null : Colors.black54,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 4),
              Text(
                '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}',
                style: const TextStyle(
                    fontSize: 11.5, color: Colors.black54),
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: onConfirm,
                icon: const Icon(Icons.check),
                label: const Text('Confirm location'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
