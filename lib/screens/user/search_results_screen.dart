import 'package:material_ui/material_ui.dart';

import '../../core/app_theme.dart';
import '../../core/formatters.dart';
import '../../core/launchers.dart';
import '../../models/search_models.dart';
import '../../services/services.dart';
import '../../widgets/common.dart';
import 'map_screen.dart';

/// واجهة نتائج البحث: الدواء والصيدليات المتوفر فيها مع السعر والكمية
/// والمسافة، مرتبة حسب القرب.
class SearchResultsScreen extends StatefulWidget {
  const SearchResultsScreen({
    super.key,
    required this.results,
    required this.query,
  });

  final List<MedicineSearchResult> results;
  final String query;

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  int _selected = 0;

  MedicineSearchResult get _current => widget.results[_selected];

  bool get _hasLocation =>
      _current.offers.any((o) => o.distanceKm != null) ||
      Services.I.location.lastKnown != null;

  void _openMap({PharmacyOffer? focus}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MapScreen(
          title: _current.medicine.tradeName,
          offers: _current.offers,
          focus: focus,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = _current;
    return Scaffold(
      appBar: AppBar(title: const Text('نتائج البحث عن الدواء')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 4, 18, 32),
        children: [
          if (widget.results.length > 1) ...[
            Text(
              'تم العثور على ${widget.results.length} أدوية مطابقة',
              style: const TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: widget.results.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, i) => ChoiceChip(
                  label: Text(widget.results[i].medicine.tradeName),
                  selected: i == _selected,
                  onSelected: (_) => setState(() => _selected = i),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          _MedicineHeader(result: r),
          SectionTitle('الصيدليات المتوفر فيها', icon: Icons.storefront),
          if (!_hasLocation && r.offers.isNotEmpty)
            Card(
              color: AppColors.sky,
              child: ListTile(
                leading: const Icon(Icons.location_off_outlined),
                title: const Text('الموقع غير مفعّل'),
                subtitle: const Text(
                  'فعّل خدمة الموقع لترتيب الصيدليات حسب الأقرب إليك. '
                  'النتائج الآن مرتبة حسب السعر.',
                ),
                onTap: Services.I.location.openSettings,
              ),
            ),
          if (r.offers.isEmpty)
            const EmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'الدواء غير متوفر حالياً',
              message: 'لا توجد صيدلية مسجلة لديها هذا الدواء في الوقت الحالي.',
            )
          else ...[
            for (final o in r.offers) ...[
              _OfferCard(
                offer: o,
                onShowOnMap: () => _openMap(focus: o),
              ),
              const SizedBox(height: 12),
            ],
            FilledButton.icon(
              icon: const Icon(Icons.map_outlined),
              label: const Text('عرض الكل على الخريطة'),
              onPressed: _openMap,
            ),
          ],
        ],
      ),
    );
  }
}

class _MedicineHeader extends StatelessWidget {
  const _MedicineHeader({required this.result});
  final MedicineSearchResult result;

  @override
  Widget build(BuildContext context) {
    final m = result.medicine;
    final available = result.offers.isNotEmpty;
    final lowest = result.lowestPrice;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: AppColors.sky,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.medication,
                size: 46,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    m.tradeName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navy,
                    ),
                  ),
                  Text(
                    [m.scientificName, if (m.form != null) m.form!].join(' • '),
                    style: const TextStyle(color: AppColors.muted),
                  ),
                  if (m.barcode != null)
                    Text(
                      'الباركود: ${m.barcode}',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _StatusBadge(available: available),
                      const Spacer(),
                      if (lowest != null)
                        Text(
                          'من ${Fmt.price(lowest)}',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryDark,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.available});
  final bool available;

  @override
  Widget build(BuildContext context) {
    final c = available ? AppColors.success : AppColors.danger;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            available ? Icons.check_circle : Icons.cancel,
            size: 16,
            color: c,
          ),
          const SizedBox(width: 4),
          Text(
            available ? 'متوفر' : 'غير متوفر',
            style: TextStyle(color: c, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _OfferCard extends StatelessWidget {
  const _OfferCard({required this.offer, required this.onShowOnMap});

  final PharmacyOffer offer;
  final VoidCallback onShowOnMap;

  @override
  Widget build(BuildContext context) {
    final p = offer.pharmacy;
    final a = offer.availability;
    final subtitle = [
      if (p.address != null) p.address!,
      if (offer.distanceKm != null) Fmt.distance(offer.distanceKm),
    ].join(' • ');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.local_pharmacy_outlined,
                  color: AppColors.primary,
                  size: 32,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.pharmacyName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.navy,
                        ),
                      ),
                      if (subtitle.isNotEmpty)
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 16,
                              color: AppColors.muted,
                            ),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                subtitle,
                                style: const TextStyle(color: AppColors.muted),
                              ),
                            ),
                          ],
                        ),
                      if (p.phone != null)
                        Row(
                          children: [
                            const Icon(
                              Icons.phone_outlined,
                              size: 16,
                              color: AppColors.muted,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              p.phone!,
                              textDirection: TextDirection.ltr,
                              style: const TextStyle(color: AppColors.muted),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'متوفر • الكمية: ${a.quantity}',
                  style: const TextStyle(
                    color: AppColors.success,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  Fmt.price(a.price),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                      textStyle: const TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    icon: const Icon(Icons.map_outlined, size: 20),
                    label: const Text('عرض على الخريطة'),
                    onPressed: onShowOnMap,
                  ),
                ),
                if (p.phone != null) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(44),
                      ),
                      icon: const Icon(Icons.call_outlined, size: 20),
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
