import 'availability.dart';
import 'medicine.dart';
import 'pharmacy.dart';

/// صيدلية يتوفر فيها الدواء مع السعر والكمية والمسافة (إن توفر الموقع).
class PharmacyOffer {
  const PharmacyOffer({
    required this.pharmacy,
    required this.availability,
    this.distanceKm,
  });

  final Pharmacy pharmacy;
  final Availability availability;
  final double? distanceKm;
}

/// نتيجة بحث لدواء واحد مع الصيدليات المتوفر فيها.
class MedicineSearchResult {
  const MedicineSearchResult({required this.medicine, required this.offers});

  final Medicine medicine;
  final List<PharmacyOffer> offers;
}

/// نتيجة البحث كاملة: الأدوية + هل رُتبت الصيدليات حسب القرب (FR-15).
class SearchOutcome {
  const SearchOutcome({required this.results, required this.sortedByDistance});

  final List<MedicineSearchResult> results;
  final bool sortedByDistance;

  bool get isEmpty => results.isEmpty;
  bool get noneAvailable => results.every((r) => r.offers.isEmpty);
}

/// المعلومات التي يستخرجها Gemini من صورة العبوة أو الروشتة (FR-13).
class ImageAnalysis {
  const ImageAnalysis({
    required this.readable,
    this.tradeNames = const [],
    this.scientificNames = const [],
    this.forms = const [],
    this.note,
  });

  final bool readable;
  final List<String> tradeNames;
  final List<String> scientificNames;
  final List<String> forms;
  final String? note;

  bool get isEmpty => tradeNames.isEmpty && scientificNames.isEmpty;

  List<String> get allNames => {...tradeNames, ...scientificNames}.toList();

  factory ImageAnalysis.fromJson(Map<String, dynamic> j) {
    List<String> list(String k) => ((j[k] as List?) ?? const [])
        .map((e) => e.toString().trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();
    return ImageAnalysis(
      readable: j['readable'] != false,
      tradeNames: list('tradeNames'),
      scientificNames: list('scientificNames'),
      forms: list('pharmaceuticalForms'),
      note: j['note'] as String?,
    );
  }
}

/// دواء في قائمة صيدلية (الدواء + سجل توفره: السعر والكمية).
class StockItem {
  const StockItem(this.medicine, this.availability);
  final Medicine medicine;
  final Availability availability;
}
