import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class WorkDeliveryDetails extends StatelessWidget {
  const WorkDeliveryDetails({super.key, required this.metadata});

  final Map<String, dynamic> metadata;

  @override
  Widget build(BuildContext context) {
    final journey =
        metadata['journey'] is Map ? metadata['journey'] as Map : const {};
    final values = {...metadata, ...journey};
    final status = values['sms_delivery_status'];
    final link = values['meeting_link']?.toString();
    if (status == null &&
        link == null &&
        values['travel_duration_minutes'] == null &&
        values['travel_duration'] == null) {
      return const SizedBox.shrink();
    }
    return Card(
        child: Padding(
            padding: const EdgeInsets.all(16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (link != null && link.isNotEmpty)
                TextButton.icon(
                    onPressed: () async {
                      final uri = Uri.tryParse(link);
                      if (uri != null &&
                          ['https', 'http'].contains(uri.scheme)) {
                        await launchUrl(uri,
                            mode: LaunchMode.externalApplication);
                      }
                    },
                    icon: const Icon(Icons.videocam_outlined),
                    label: const Text('Open meeting link')),
              if (status != null)
                Text('SMS: ${status.toString().replaceAll('_', ' ')}'),
              if (status == 'failed')
                const Text(
                    'Delivery failed. The server can retry this reminder.'),
              if (values['sms_sent_at'] != null)
                Text('Sent: ${values['sms_sent_at']}'),
              if (values['travel_duration_minutes'] != null)
                Text('Travel time: ${values['travel_duration_minutes']} min')
              else if (values['travel_duration'] != null)
                Text('Travel time: ${values['travel_duration']}'),
              for (final key in ['started_at', 'arrived_at'])
                if (values[key] != null)
                  Text('${key.replaceAll('_', ' ')}: ${values[key]}'),
            ])));
  }
}
