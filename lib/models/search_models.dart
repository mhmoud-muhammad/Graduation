import 'availability.dart';
import 'medicine.dart';
import 'pharmacy.dart';

/// صيدلية يتوفر فيها الدواء مع السعر والكمية والمسافة.
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

  double? get lowestPrice => offers.isEmpty
      ? null
      : offers.map((o) => o.availability.price).reduce((a, b) => a < b ? a : b);
}

/// المعلومات التي يستخرجها Gemini من صورة العبوة أو الروشتة.
class ImageAnalysis {
  const ImageAnalysis({
    required this.readable,
    this.tradeNames = const [],
    this.scientificNames = const [],
    this.barcodes = const [],
    this.note,
  });

  final bool readable;
  final List<String> tradeNames;
  final List<String> scientificNames;
  final List<String> barcodes;
  final String? note;

  bool get isEmpty =>
      tradeNames.isEmpty && scientificNames.isEmpty && barcodes.isEmpty;

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
      barcodes: list('barcodes'),
      note: j['note'] as String?,
    );
  }
}

/// نوع الصورة المرسلة للتحليل.
enum ImageKind {
  package('عبوة دواء'),
  prescription('روشتة طبية');

  const ImageKind(this.label);
  final String label;
}
