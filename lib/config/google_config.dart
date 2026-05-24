import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Google Maps / Places API key (same key as AndroidManifest.xml).
class GoogleConfig {
  static const String mapsApiKey = 'AIzaSyA2jauIr0PY3aEEsAEJ0CFTGWi_yaTSMiw';
  static String get placesApiKey => dotenv.env['PLACES_API_KEY'] ?? '';
}

