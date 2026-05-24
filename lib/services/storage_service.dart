import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class StorageService {
  Future<String> uploadUserFile({
    required File file,
    required String path,
  }) async {
    final cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '';
    final uploadPreset = 'cnic_uploads'; // create this in Cloudinary dashboard

    final cloudinary = CloudinaryPublic(cloudName, uploadPreset);

    final response = await cloudinary.uploadFile(
      CloudinaryFile.fromFile(
        file.path,
        folder: 'carpool/cnic',
        resourceType: CloudinaryResourceType.Image,
      ),
    );

    return response.secureUrl;
  }
}