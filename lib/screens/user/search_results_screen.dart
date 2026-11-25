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

  @override
  Widget build(BuildContext context) {
    final r = _current;
    return Scaffold(
      appBar: AppBar(
        title: const Text('نتائج البحث'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        titleTextStyle: const TextStyle(
          fontFamily: 'Cairo',
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 32),
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
          const SectionTitle('الصيدليات المتوفرة:'),
          if (r.offers.isEmpty)
            const EmptyState(
              icon: Icons.inventory_2_outlined,
              title: Msg.medicineNotAvailableNow,
            )
          else ...[
            if (!widget.outcome.sortedByDistance)
              const Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: Card(
                  color: AppColors.sky,
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
              const SizedBox(height: 12),
            ],
            FilledButton.icon(
              icon: const Icon(Icons.map_outlined),
              label: const Text('عرض الصيدليات على الخريطة'),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.medication,
              size: 42,
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
                  m.scientificName,
                  style: const TextStyle(color: AppColors.muted, fontSize: 16),
                ),
                Text(
                  'الشكل الصيدلاني: ${m.pharmaceuticalForm}',
                  style: const TextStyle(color: AppColors.navy),
                ),
              ],
            ),
          ),
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
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 6, 12),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primary,
                child: Icon(Icons.location_on, color: Colors.white),
              ),
              const SizedBox(width: 12),
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
                    Text(line, style: const TextStyle(color: AppColors.navy)),
                    Text(
                      'الشكل الصيدلاني: $form',
                      style: const TextStyle(color: AppColors.muted),
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
                              Icons.phone_outlined,
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
              const Icon(Icons.chevron_left, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }
}
