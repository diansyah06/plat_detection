import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/plate_result.dart';
import '../services/api_service.dart';

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final picker = ImagePicker();
  final apiService = ApiService();

  PlateResult? result;
  bool isLoading = false;

  Future<void> pickImage() async {
    print("📸 Opening camera...");

    final image = await picker.pickImage(source: ImageSource.camera);

    if (image == null) {
      print("❌ Image picking cancelled");
      return;
    }

    print("✅ Image selected: ${image.path}");

    setState(() => isLoading = true);

    try {
      final detection = await apiService.detectPlate(image.path);

      print("🎯 Detection success");

      setState(() {
        result = detection;
      });
    } catch (e) {
      print("🔥 ERROR during detection:");
      print(e);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Deteksi gagal")));
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Deteksi Plat Nomor")),
      floatingActionButton: FloatingActionButton(
        onPressed: pickImage,
        child: const Icon(Icons.add_a_photo),
      ),
      body: Center(
        child: isLoading
            ? const CircularProgressIndicator()
            : result == null
            ? const Text("Belum ada hasil deteksi")
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Plat Nomor",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    result!.formattedPlate,
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(height: 8),
                  Text("Daerah: ${result!.daerah ?? "Tidak terdeteksi"}"),
                  Text("Provinsi: ${result!.provinsi ?? "Tidak terdeteksi"}"),
                  Text("Alamat Samsat: ${result!.alamatSamsat ?? "-"}"),
                  const SizedBox(height: 8),
                  Text(
                    "Confidence: ${(result!.confidence * 100).toStringAsFixed(2)}%",
                  ),
                ],
              ),
      ),
    );
  }
}
