import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/nec_toast.dart';

class PhoneService {
  PhoneService._();

  static Future<void> call(BuildContext context, String phone) async {
    final clean = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (clean.isEmpty) {
      NecToast.show(context,
          message: 'Invalid phone number', type: NecToastType.error);
      return;
    }

    final uri = Uri.parse('tel:$clean');
    try {
      final launched =
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        } else if (context.mounted) {
          NecToast.show(context,
              message: 'Could not launch dialer for $phone',
              type: NecToastType.error);
        }
      }
    } catch (_) {
      try {
        await launchUrl(uri);
      } catch (e) {
        if (context.mounted) {
          NecToast.show(context,
              message: 'Could not launch dialer for $phone',
              type: NecToastType.error);
        }
      }
    }
  }

  static Future<void> mail(BuildContext context, String email) async {
    final clean = email.trim();
    if (clean.isEmpty) return;
    final uri = Uri.parse('mailto:$clean');
    try {
      final launched =
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        } else if (context.mounted) {
          NecToast.show(context,
              message: 'Could not open mail app for $email',
              type: NecToastType.error);
        }
      }
    } catch (_) {
      try {
        await launchUrl(uri);
      } catch (e) {
        if (context.mounted) {
          NecToast.show(context,
              message: 'Could not open mail app for $email',
              type: NecToastType.error);
        }
      }
    }
  }
}
