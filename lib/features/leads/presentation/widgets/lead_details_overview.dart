import 'package:flutter/material.dart';
import '../../domain/models/lead.dart';
import 'lead_info_group.dart';

class LeadDetailsOverview extends StatelessWidget {
  final Lead lead;

  const LeadDetailsOverview({super.key, required this.lead});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LeadInfoGroup(
            title: 'Contact',
            rows: [
              if (lead.contactName != null)
                LeadInfoRow('Name', lead.contactName!),
              if (lead.contactRole != null)
                LeadInfoRow('Role', lead.contactRole!),
              if (lead.phone != null) LeadInfoRow('Phone', lead.phone!),
              if (lead.email != null) LeadInfoRow('Email', lead.email!),
            ],
          ),
          const SizedBox(height: 16),
          LeadInfoGroup(
            title: 'Business',
            rows: [
              LeadInfoRow('Company', lead.company),
              LeadInfoRow('Type', lead.type),
              LeadInfoRow('Location', lead.location),
            ],
          ),
          if (lead.totalProperties != null || lead.interestedPlan != null) ...[
            const SizedBox(height: 16),
            LeadInfoGroup(
              title: 'Business Profile',
              rows: [
                if (lead.totalProperties != null)
                  LeadInfoRow('Properties', '${lead.totalProperties}'),
                if (lead.totalRooms != null)
                  LeadInfoRow('Rooms', '${lead.totalRooms}'),
                if (lead.interestedPlan != null)
                  LeadInfoRow('Plan', lead.interestedPlan!),
                if (lead.interestedServices.isNotEmpty)
                  LeadInfoRow('Services', lead.interestedServices.join(', ')),
                if (lead.currentHms != null)
                  LeadInfoRow('Current HMS', lead.currentHms!),
                if (lead.websiteStatus != null)
                  LeadInfoRow('Website', lead.websiteStatus!),
              ],
            ),
          ],
          const SizedBox(height: 16),
          LeadInfoGroup(
            title: 'Lead Info',
            rows: [
              LeadInfoRow('Status', lead.status),
              LeadInfoRow('Priority', lead.priority),
              if (lead.source != null) LeadInfoRow('Source', lead.source!),
              if (lead.assignedTo != null)
                LeadInfoRow('Assigned To', lead.assignedTo!),
            ],
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}
