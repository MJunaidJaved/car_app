import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> dialPhone(BuildContext context, String? phone) async {
  if (phone == null || phone.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Phone number not available')),
    );
    return;
  }
  final digits = phone.replaceAll(RegExp(r'[^\d+]'), '');
  final normalized = digits.startsWith('+') ? digits : '+92${digits.replaceFirst(RegExp(r'^0'), '')}';
  final uri = Uri.parse('tel:$normalized');
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri);
  } else if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Cannot dial $normalized')),
    );
  }
}
