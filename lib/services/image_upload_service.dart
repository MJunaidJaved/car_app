import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ImageUploadService {
  // Apni API Key yahan paste karo
  static const String _apiKey = 'f3e1d9b185dbeda5209741c804c2c705'; // 🔴 Change karo

  static Future<String?> uploadImage(File imageFile) async {
    try {
      // Read image bytes
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      // API call
      final response = await http.post(
        Uri.parse('https://api.imgbb.com/1/upload?key=$_apiKey'),
        body: {
          'image': base64Image,
          'name': 'car_pool_${DateTime.now().millisecondsSinceEpoch}',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final imageUrl = data['data']['url'];
        print('✅ Image uploaded: $imageUrl');
        return imageUrl;
      } else {
        print('❌ Upload failed: ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Error uploading image: $e');
      return null;
    }
  }

  // Multiple images upload
  static Future<List<String?>> uploadMultipleImages(List<File> images) async {
    final List<String?> urls = [];
    for (final image in images) {
      final url = await uploadImage(image);
      urls.add(url);
    }
    return urls;
  }
}