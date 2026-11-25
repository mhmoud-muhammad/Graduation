import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../core/formatters.dart';
import '../../core/launchers.dart';
import '../../core/messages.dart';
import '../../models/search_models.dart';
import '../../widgets/common.dart';
import 'map_screen.dart';

/// واجهة نتائج البحث (FR-14): الدواء والصيدليات المتوفر لديها مع السعر
/// والكمية والموقع والشكل الصيدلاني، مرتبة حسب القرب عند السماح بالموقع.
class SearchResultsScreen extends StatefulWidget {
  const SearchResultsScreen({
    super.key,
    required this.outcome,
    required this.query,
  });

  final SearchOutcome outcome;
  final String query;

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  int _selected = 0;

  List<MedicineSearchResult> get _results => widget.outcome.results;
  MedicineSearchResult get _current => _results[_selected];

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

  DateTime? get _lastUpdate {
    final dates = _current.offers
        .map((o) => o.availability.updatedAt)
        .whereType<DateTime>();
    if (dates.isEmpty) return null;
    return dates.reduce((a, b) => a.isAfter(b) ? a : b);
  }

  @override
  Widget build(BuildContext context) {
    final r = _current;
    final updated = _lastUpdate;
    return Scaffold(
      backgroundColor: AppColors.header,
      appBar: AppBar(
        toolbarHeight: 70,
        backgroundColor: AppColors.header,
        foregroundColor: Colors.white,
        centerTitle: false,
        titleTextStyle: const TextStyle(
          fontFamily: 'Cairo',
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
        title: const Text('نتائج البحث'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 22, 18, 32),
          children: [
            if (_results.length > 1) ...[
              Text(
                'تم العثور على ${_results.length} أدوية مطابقة',
                style: const TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _results.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (_, i) => ChoiceChip(
                    label: Text(_results[i].medicine.tradeName),
                    selected: i == _selected,
                    onSelected: (_) => setState(() => _selected = i),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            _MedicineHeader(result: r),
            const SizedBox(height: 18),
            const Text(
              'الصيدليات المتوفرة:',
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A1F36),
              ),
            ),
            const SizedBox(height: 12),
            if (r.offers.isEmpty)
              const EmptyState(
                icon: Icons.inventory_2_outlined,
                title: Msg.medicineNotAvailableNow,
              )
            else ...[
              if (!widget.outcome.sortedByDistance)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Card(
                    color: AppColors.waveLight,
                    child: ListTile(
                      leading: Icon(Icons.location_off_outlined),
                      subtitle: Text(Msg.locationDenied),
                    ),
                  ),
                ),
              for (final o in r.offers) ...[
                _OfferCard(
                  offer: o,
                  form: r.medicine.pharmaceuticalForm,
                  onTap: () => _openMap(focus: o),
                ),
                const SizedBox(height: 14),
              ],
              OutlinedButton.icon(
                icon: const Icon(Icons.map_outlined),
                label: const Text('عرض الصيدليات على الخريطة'),
                onPressed: _openMap,
              ),
              if (updated != null)
                Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: Text(
                    'آخر تحديث: ${Fmt.date(updated)}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.muted),
                  ),
                ),
            ],
          ],
        ),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.resultCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m.tradeName,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1F36),
                  ),
                ),
                Text(
                  m.scientificName,
                  style: const TextStyle(
                    color: Color(0xFF4A5568),
                    fontSize: 19,
                  ),
                ),
                Text(
                  'الشكل الصيدلاني: ${m.pharmaceuticalForm}',
                  style: const TextStyle(color: Color(0xFF4A5568)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const Illustration('medicine_thumb', height: 90, radius: 12),
        ],
      ),
    );
  }
}

class _OfferCard extends StatelessWidget {
  const _OfferCard({
    required this.offer,
    required this.form,
    required this.onTap,
  });

  final PharmacyOffer offer;
  final String form;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = offer.pharmacy;
    final a = offer.availability;
    final line = [
      if (offer.distanceKm != null) Fmt.distance(offer.distanceKm),
      'السعر ${Fmt.price(a.price)}',
      'الكمية: ${a.quantity}',
    ].join(' • ');
    const sub = TextStyle(color: Color(0xFF1A1F36), fontSize: 14.5);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 14, 14, 14),
          child: Row(
            children: [
              const Icon(
                Icons.chevron_right,
                color: AppColors.header,
                size: 32,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.pharmacyName,
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A1F36),
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 17,
                          color: AppColors.header,
                        ),
                        const SizedBox(width: 3),
                        Expanded(child: Text(line, style: sub)),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.medication,
                          size: 17,
                          color: AppColors.header,
                        ),
                        const SizedBox(width: 3),
                        Text('الشكل الصيدلاني: $form', style: sub),
                      ],
                    ),
                    if (p.address != null)
                      Text(
                        p.address!,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 13,
                        ),
                      ),
                    if (p.phone != null)
                      InkWell(
                        onTap: () => callPhone(p.phone!),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.phone,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              p.phone!,
                              textDirection: TextDirection.ltr,
                              style: const TextStyle(color: AppColors.primary),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const CircleAvatar(
                radius: 25,
                backgroundColor: Color(0xFF1FB2A7),
                child: Icon(Icons.location_on, color: Colors.white, size: 30),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
