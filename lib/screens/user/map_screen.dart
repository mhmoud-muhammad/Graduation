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
        title: const Text('الخريطة'),
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

  void _details(BuildContext context) {
    final p = offer.pharmacy;
    final a = offer.availability;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(p.pharmacyName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (p.address != null) Text('العنوان: ${p.address}'),
            if (p.phone != null) Text('الهاتف: ${p.phone}'),
            Text('السعر: ${Fmt.price(a.price)}'),
            Text('الكمية: ${a.quantity}'),
            if (offer.distanceKm != null)
              Text('المسافة: ${Fmt.distance(offer.distanceKm)}'),
          ],
        ),
        actions: [
          if (p.phone != null)
            TextButton.icon(
              icon: const Icon(Icons.call),
              label: const Text('اتصال'),
              onPressed: () => callPhone(p.phone!),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = offer.pharmacy;
    return Card(
      elevation: 10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD2D9),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.local_hospital,
                  color: Color(0xFFE53935),
                  size: 40,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        [
                          p.pharmacyName,
                          if (offer.distanceKm != null)
                            Fmt.distance(offer.distanceKm),
                        ].join('  '),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1A1F36),
                        ),
                      ),
                      Text(
                        [
                          'السعر ${Fmt.price(offer.availability.price)}',
                          'الكمية ${offer.availability.quantity}',
                          if (p.address != null) p.address!,
                        ].join(' • '),
                        style: const TextStyle(color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.directions,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      textStyle: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    icon: const Icon(Icons.directions),
                    label: const Text('الاتجاهات'),
                    onPressed: () => openDirections(p.latitude, p.longitude),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1A1F36),
                      side: const BorderSide(color: Color(0xFF9AA5B1)),
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.info_outline),
                    label: const Text('تفاصيل'),
                    onPressed: () => _details(context),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
