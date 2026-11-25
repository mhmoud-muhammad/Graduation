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
import '../../widgets/app_map.dart';
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

  Widget _labeled(String label, IconData icon, Widget field) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 66, bottom: 4),
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.navy,
            ),
          ),
        ),
        Row(
          children: [
            IconBox(icon),
            const SizedBox(width: 12),
            Expanded(child: field),
          ],
        ),
      ],
    ),
  );

  InputDecoration get _pill => InputDecoration(
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(26)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(26),
      borderSide: const BorderSide(color: AppColors.border),
    ),
  );

  Widget _coord(
    String label,
    TextEditingController c,
    FormFieldValidator<String> v,
  ) => Expanded(
    child: Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.navy,
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: c,
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
          style: const TextStyle(fontSize: 18),
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
            signed: true,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.fieldTint,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onChanged: (_) => setState(() {}),
          validator: v,
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final point = _point;
    final hasPharmacy = widget.pharmacy != null;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const TealHeader(
            title: 'بيانات الصيدلية',
            backStyle: BackStyle.circle,
            titleSize: 28,
            curve: 14,
            trailing: Icon(Icons.add_business, color: Colors.white, size: 46),
          ),
          Expanded(
            child: WaveBackground(
              top: false,
              style: WaveStyle.teal,
              color: Colors.white,
              child: Form(
                key: _form,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 130),
                  children: [
                    _labeled(
                      'اسم الصيدلية',
                      Icons.storefront,
                      TextFormField(
                        controller: _name,
                        decoration: _pill.copyWith(
                          hintText: 'مثال: صيدلية النور',
                        ),
                        validator: (v) =>
                            Validators.required(v, 'اسم الصيدلية'),
                      ),
                    ),
                    _labeled(
                      'عنوان الصيدلية',
                      Icons.location_on,
                      TextFormField(
                        controller: _address,
                        decoration: _pill.copyWith(
                          hintText: 'مثال: عطبرة – السوق الكبير',
                        ),
                      ),
                    ),
                    _labeled(
                      'رقم الهاتف',
                      Icons.phone,
                      TextFormField(
                        controller: _phone,
                        keyboardType: TextInputType.phone,
                        decoration: _pill,
                        validator: Validators.optionalPhone,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(top: 12, bottom: 6),
                      child: Text(
                        'الموقع الجغرافي',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.navy,
                        ),
                      ),
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: SizedBox(
                        height: 200,
                        child: appMap(
                          {
                            if (point != null)
                              Marker(
                                markerId: const MarkerId('pharmacy'),
                                position: point,
                              ),
                          },
                          () => GoogleMap(
                            initialCameraPosition: CameraPosition(
                              target:
                                  point ??
                                  const LatLng(
                                    AppConfig.defaultLat,
                                    AppConfig.defaultLng,
                                  ),
                              zoom: point == null ? 13 : 16,
                            ),
                            onMapCreated: (c) => _map = c,
                            onTap: (p) => _setPoint(p, moveCamera: false),
                            markers: {
                              if (point != null)
                                Marker(
                                  markerId: const MarkerId('pharmacy'),
                                  position: point,
                                  draggable: true,
                                  onDragEnd: (p) =>
                                      _setPoint(p, moveCamera: false),
                                  infoWindow: const InfoWindow(
                                    title: 'موقع الصيدلية',
                                  ),
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
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _coord('خط العرض', _lat, Validators.latitude),
                        const SizedBox(width: 16),
                        _coord('خط الطول', _lng, Validators.longitude),
                      ],
                    ),
                    const SizedBox(height: 22),
                    LoadingButton(
                      label: 'تسجيل',
                      loading: _saving,
                      onPressed: () => _save(isNew: true),
                    ),
                    const SizedBox(height: 12),
                    LoadingButton(
                      label: 'تعديل',
                      loading: _saving,
                      onPressed: hasPharmacy ? () => _save(isNew: false) : null,
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(260, 50),
                          foregroundColor: AppColors.navy,
                        ),
                        icon: _locating
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(
                                Icons.location_on,
                                color: AppColors.navy,
                              ),
                        label: const Text('تحديد الموقع على الخريطة'),
                        onPressed: _locating ? null : _useMyLocation,
                      ),
                    ),
                    if (hasPharmacy)
                      const Padding(
                        padding: EdgeInsets.only(top: 10),
                        child: Text(
                          '"تسجيل" يضيف صيدلية جديدة بهذه البيانات، و"تعديل" '
                          'يحدّث بيانات الصيدلية الحالية.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 13,
                          ),
                        ),
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
