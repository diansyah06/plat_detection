import 'dart:convert';
import 'package:http/http.dart' as http;

import '../core/constants/api_constants.dart';
import '../models/plate_result.dart';

class ApiService {
  Future<PlateResult> detectPlate(String imagePath) async {
    print("🚀 START detectPlate()");
    print("🖼 Image path: $imagePath");

    final uri =
        Uri.parse(ApiConstants.baseUrl + ApiConstants.detectPlate);
    print("🌐 Endpoint: $uri");

    final request = http.MultipartRequest('POST', uri);

    request.files.add(
      await http.MultipartFile.fromPath('image', imagePath),
    );

    print("📤 Sending request to backend...");

    final response = await request.send();
    print("📥 HTTP status code: ${response.statusCode}");

    final body = await response.stream.bytesToString();
    print("📥 RAW RESPONSE BODY:");
    print(body);

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(body);

      print("🧠 JSON decoded successfully");
      print("🔑 status: ${jsonData['status']}");
      print("🆔 request_id: ${jsonData['request_id']}");
      print("⏱ processing_time_ms: ${jsonData['processing_time_ms']}");

      if (jsonData['status'] != 'success') {
        throw Exception("❌ API status is not success");
      }

      return PlateResult.fromJson(jsonData);
    } else {
      throw Exception(
          "❌ HTTP error ${response.statusCode}: $body");
    }
  }
}
