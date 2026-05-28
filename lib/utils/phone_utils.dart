import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

String _normalizePhoneForPk(String phone) {
  var digits = phone.replaceAll(RegExp(r'[^\d+]'), '');
  if (digits.startsWith('+')) {
    digits = digits.substring(1);
  }
  if (digits.startsWith('00')) {
    digits = digits.substring(2);
  }
  if (digits.startsWith('92')) {
    return digits;
  }
  if (digits.startsWith('0')) {
    return '92${digits.substring(1)}';
  }
  return '92$digits';
}

Future<void> dialPhone(BuildContext context, String? phone) async {
  if (phone == null || phone.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Phone number not available'), duration: Duration(seconds: 2)),
    );
    return;
  }
  final normalized = '+${_normalizePhoneForPk(phone)}';
  final uri = Uri.parse('tel:$normalized');
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri);
  } else if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Cannot dial $normalized'), duration: const Duration(seconds: 2)),
    );
  }
}

Future<void> openWhatsApp(BuildContext context, String? phone) async {
  if (phone == null || phone.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Phone number not available'), duration: Duration(seconds: 2)),
    );
    return;
  }
  final whatsappNumber = _normalizePhoneForPk(phone);
  final appUri = Uri.parse('whatsapp://send?phone=$whatsappNumber');
  final webUri = Uri.parse('https://wa.me/$whatsappNumber');
  final apiUri = Uri.parse('https://api.whatsapp.com/send?phone=$whatsappNumber');

  try {
    final opened = await launchUrl(appUri, mode: LaunchMode.externalApplication);
    if (opened) return;
  } catch (_) {}
  try {
    final opened = await launchUrl(webUri, mode: LaunchMode.externalApplication);
    if (opened) return;
  } catch (_) {}
  try {
    final opened = await launchUrl(apiUri, mode: LaunchMode.externalApplication);
    if (opened) return;
  } catch (_) {}

  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Cannot open WhatsApp for +$whatsappNumber'), duration: const Duration(seconds: 2)),
    );
  }
}


