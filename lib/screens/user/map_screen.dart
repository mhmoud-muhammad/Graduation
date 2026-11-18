import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/material.dart';

import '../../core/app_config.dart';
import '../../core/app_theme.dart';
import '../../core/formatters.dart';
import '../../core/launchers.dart';
import '../../models/search_models.dart';
import '../../services/services.dart';

/// واجهة الخريطة: مواقع الصيدليات المتوفر فيها الدواء وموقع المستخدم.
class MapScreen extends StatefulWidget {
  const MapScreen({
    super.key,
    required this.title,
    required this.offers,
    this.focus,
  });

  final String title;
  final List<PharmacyOffer> offers;
  final PharmacyOffer? focus;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _controller;
  late PharmacyOffer? _selected =
      widget.focus ?? (widget.offers.isEmpty ? null : widget.offers.first);

  LatLng get _initialTarget {
    final s = _selected;
    if (s != null) return LatLng(s.pharmacy.latitude, s.pharmacy.longitude);
    final me = Services.I.location.lastKnown;
    if (me != null) return LatLng(me.latitude, me.longitude);
    return const LatLng(AppConfig.defaultLat, AppConfig.defaultLng);
  }

  Set<Marker> get _markers => {
    for (final o in widget.offers)
      Marker(
        markerId: MarkerId(o.pharmacy.pharmacyId),
        position: LatLng(o.pharmacy.latitude, o.pharmacy.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          identical(o, _selected)
              ? BitmapDescriptor.hueAzure
              : BitmapDescriptor.hueRed,
        ),
        infoWindow: InfoWindow(
          title: o.pharmacy.pharmacyName,
          snippet: [
            Fmt.price(o.availability.price),
            if (o.distanceKm != null) Fmt.distance(o.distanceKm),
          ].join(' • '),
        ),
        onTap: () => setState(() => _selected = o),
      ),
  };

  Future<void> _fitAll() async {
    final c = _controller;
    if (c == null || widget.focus != null) return;
    final points = [
      for (final o in widget.offers)
        LatLng(o.pharmacy.latitude, o.pharmacy.longitude),
      if (Services.I.location.lastKnown case final me?)
        LatLng(me.latitude, me.longitude),
    ];
    if (points.length < 2) return;
    double minLat = points.first.latitude, maxLat = minLat;
    double minLng = points.first.longitude, maxLng = minLng;
    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
    await Future<void>.delayed(const Duration(milliseconds: 300));
    await c.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        70,
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('الخريطة • ${widget.title}'),
        backgroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _initialTarget,
              zoom: 14,
            ),
            markers: _markers,
            myLocationEnabled: Services.I.location.lastKnown != null,
            myLocationButtonEnabled: true,
            onMapCreated: (c) {
              _controller = c;
              _fitAll();
            },
          ),
          if (_selected != null)
            Positioned(
              left: 14,
              right: 14,
              bottom: 20,
              child: _PharmacySheet(offer: _selected!),
            ),
        ],
      ),
    );
  }
}

class _PharmacySheet extends StatelessWidget {
  const _PharmacySheet({required this.offer});
  final PharmacyOffer offer;

  @override
  Widget build(BuildContext context) {
    final p = offer.pharmacy;
    return Card(
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.location_on,
                  color: AppColors.danger,
                  size: 30,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    p.pharmacyName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navy,
                    ),
                  ),
                ),
                if (offer.distanceKm != null)
                  Text(
                    Fmt.distance(offer.distanceKm),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
              ],
            ),
            Text(
              [
                if (p.address != null) p.address!,
                'السعر ${Fmt.price(offer.availability.price)}',
                'الكمية ${offer.availability.quantity}',
              ].join(' • '),
              style: const TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF1A5FD0),
                      minimumSize: const Size.fromHeight(44),
                    ),
                    icon: const Icon(Icons.directions),
                    label: const Text('الاتجاهات'),
                    onPressed: () => openDirections(p.latitude, p.longitude),
                  ),
                ),
                if (p.phone != null) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(44),
                      ),
                      icon: const Icon(Icons.call_outlined),
                      label: const Text('اتصال'),
                      onPressed: () => callPhone(p.phone!),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
