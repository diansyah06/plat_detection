class PlateResult {
  final String formattedPlate;
  final double confidence;

  final String? daerah;
  final String? provinsi;
  final String? alamatSamsat;

  PlateResult({
    required this.formattedPlate,
    required this.confidence,
    this.daerah,
    this.provinsi,
    this.alamatSamsat,
  });

  factory PlateResult.fromJson(Map<String, dynamic> json) {
    print("📦 Parsing PlateResult...");

    final data = json['data'];
    final plate = data['plate'];

    // vehicle_region BISA NULL
    final region = data['vehicle_region'];

    print("➡️ Plate formatted: ${plate['formatted']}");
    print("➡️ Confidence: ${plate['confidence']}");

    if (region == null) {
      print("⚠️ vehicle_region is NULL (lookup failed)");
    } else {
      print("➡️ Daerah: ${region['daerah']}");
    }

    return PlateResult(
      formattedPlate: plate['formatted'],
      confidence: (plate['confidence'] as num).toDouble(),
      daerah: region?['daerah'],
      provinsi: region?['provinsi'],
      alamatSamsat: region?['alamat_samsat'],
    );
  }
}
