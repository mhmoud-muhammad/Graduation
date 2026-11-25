import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/app_config.dart';
import '../../core/app_theme.dart';
import '../../core/messages.dart';
import '../../core/validators.dart';
import '../../models/app_user.dart';
import '../../models/pharmacy.dart';
import '../../services/services.dart';
import '../../widgets/common.dart';

/// واجهة بيانات الصيدلية (FR-08): الاسم والعنوان والهاتف والموقع الجغرافي
/// (خط الطول والعرض)، مع زر "تسجيل" لصيدلية جديدة وزر "تعديل" للحالية.
///
/// تعيد الصيدلية المحفوظة عند الرجوع.
class PharmacyInfoScreen extends StatefulWidget {
  const PharmacyInfoScreen({super.key, required this.owner, this.pharmacy});

  final AppUser owner;

  /// الصيدلية الحالية (null إذا لم يسجّل الصيدلي أي صيدلية بعد).
  final Pharmacy? pharmacy;

  @override
  State<PharmacyInfoScreen> createState() => _PharmacyInfoScreenState();
}

class _PharmacyInfoScreenState extends State<PharmacyInfoScreen> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.pharmacy?.pharmacyName);
  late final _address = TextEditingController(text: widget.pharmacy?.address);
  late final _phone = TextEditingController(
    text: widget.pharmacy?.phone ?? widget.owner.phone,
  );
  late final _lat = TextEditingController(
    text: widget.pharmacy?.latitude.toStringAsFixed(6),
  );
  late final _lng = TextEditingController(
    text: widget.pharmacy?.longitude.toStringAsFixed(6),
  );
  GoogleMapController? _map;
  bool _saving = false;
  bool _locating = false;

  LatLng? get _point {
    final lat = double.tryParse(_lat.text.trim());
    final lng = double.tryParse(_lng.text.trim());
    if (lat == null || lng == null) return null;
    return LatLng(lat, lng);
  }

  @override
  void dispose() {
    for (final c in [_name, _address, _phone, _lat, _lng]) {
      c.dispose();
    }
    _map?.dispose();
    super.dispose();
  }

  void _setPoint(LatLng p, {bool moveCamera = true}) {
    setState(() {
      _lat.text = p.latitude.toStringAsFixed(6);
      _lng.text = p.longitude.toStringAsFixed(6);
    });
    if (moveCamera) _map?.animateCamera(CameraUpdate.newLatLngZoom(p, 16));
  }

  Future<void> _useMyLocation() async {
    setState(() => _locating = true);
    final pos = await Services.I.location.requestAndGet();
    if (!mounted) return;
    setState(() => _locating = false);
    if (pos == null) {
      showSnack(
        context,
        'تعذر تحديد الموقع، فعّل خدمة الموقع وامنح الإذن أو اضغط على الخريطة',
        error: true,
      );
      return;
    }
    _setPoint(LatLng(pos.latitude, pos.longitude));
  }

  /// تسلسل حفظ / تعديل بيانات الصيدلية: إدخال البيانات ← الضغط على
  /// "تسجيل" أو "تعديل" ← التحقق من اكتمال البيانات وصحتها:
  /// - ضعف الإنترنت: "تعذرت العملية، الرجاء إعادة المحاولة عند توفر اتصال"
  /// - غير مكتملة: رسالة "الرجاء تصحيح البيانات" دون حفظ
  /// - صحيحة: حفظ البيانات في pharmacies ← "تم الحفظ بنجاح".
  Future<void> _save({required bool isNew}) async {
    final valid = _form.currentState!.validate() && _point != null;
    if (!valid) {
      await showErrorDialog(
        context,
        title: isNew ? Msg.invalidOrIncomplete : Msg.incomplete,
        reason: _point == null ? Msg.pickLocation : null,
      );
      return;
    }
    final p = _point!;
    final data = Pharmacy(
      pharmacyId: isNew ? '' : widget.pharmacy!.pharmacyId,
      ownerId: widget.owner.userId,
      pharmacyName: _name.text.trim(),
      address: _address.text,
      phone: _phone.text,
      latitude: p.latitude,
      longitude: p.longitude,
    );
    setState(() => _saving = true);
    Pharmacy? saved;
    final ok = await runWithRetry(
      context,
      () async {
        if (isNew) {
          saved = await Services.I.pharmacies.create(data);
        } else {
          await Services.I.pharmacies.update(data);
          saved = data;
        }
      },
      networkMessage: Msg.operationNetwork,
      errorTitle: Msg.invalidOrIncomplete,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      showSnack(context, Msg.savedSuccess);
      Navigator.pop(context, saved);
    }
  }

  @override
  Widget build(BuildContext context) {
    final point = _point;
    final hasPharmacy = widget.pharmacy != null;
    return Scaffold(
      appBar: AppBar(
        title: const Text('بيانات الصيدلية'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        titleTextStyle: const TextStyle(
          fontFamily: 'Cairo',
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            const FieldLabel('اسم الصيدلية'),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(
                hintText: 'مثال: صيدلية النور',
                prefixIcon: Icon(Icons.storefront_outlined),
              ),
              validator: (v) => Validators.required(v, 'اسم الصيدلية'),
            ),
            const FieldLabel('عنوان الصيدلية'),
            TextFormField(
              controller: _address,
              decoration: const InputDecoration(
                hintText: 'مثال: الخرطوم – السوق العربي',
                prefixIcon: Icon(Icons.place_outlined),
              ),
            ),
            const FieldLabel('رقم الهاتف'),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              textDirection: TextDirection.ltr,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              validator: Validators.optionalPhone,
            ),
            const FieldLabel('الموقع الجغرافي (اضغط على الخريطة لتحديده)'),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: 220,
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target:
                        point ??
                        const LatLng(
                          AppConfig.defaultLat,
                          AppConfig.defaultLng,
                        ),
                    zoom: point == null ? 12 : 16,
                  ),
                  onMapCreated: (c) => _map = c,
                  onTap: (p) => _setPoint(p, moveCamera: false),
                  markers: {
                    if (point != null)
                      Marker(
                        markerId: const MarkerId('pharmacy'),
                        position: point,
                        draggable: true,
                        onDragEnd: (p) => _setPoint(p, moveCamera: false),
                        infoWindow: const InfoWindow(title: 'موقع الصيدلية'),
                      ),
                  },
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: true,
                  gestureRecognizers: {
                    Factory<OneSequenceGestureRecognizer>(
                      EagerGestureRecognizer.new,
                    ),
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const FieldLabel('خط العرض'),
                      TextFormField(
                        controller: _lat,
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.ltr,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        onChanged: (_) => setState(() {}),
                        validator: Validators.latitude,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const FieldLabel('خط الطول'),
                      TextFormField(
                        controller: _lng,
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.ltr,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        onChanged: (_) => setState(() {}),
                        validator: Validators.longitude,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            LoadingButton(
              icon: Icons.add_business_outlined,
              label: 'تسجيل',
              loading: _saving,
              onPressed: () => _save(isNew: true),
            ),
            const SizedBox(height: 12),
            LoadingButton(
              icon: Icons.edit_outlined,
              label: 'تعديل',
              loading: _saving,
              onPressed: hasPharmacy ? () => _save(isNew: false) : null,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: _locating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location),
              label: const Text('تحديد الموقع على الخريطة'),
              onPressed: _locating ? null : _useMyLocation,
            ),
            if (hasPharmacy)
              const Padding(
                padding: EdgeInsets.only(top: 10),
                child: Text(
                  '"تسجيل" يضيف صيدلية جديدة بهذه البيانات، و"تعديل" يحدّث '
                  'بيانات الصيدلية الحالية.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.muted, fontSize: 13),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
