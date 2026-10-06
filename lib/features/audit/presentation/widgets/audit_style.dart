import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/models/audit_entry.dart';

Color auditCategoryColor(AuditCategory category) {
  switch (category) {
    case AuditCategory.access:
      return const Color(0xFFBF5AF2);
    case AuditCategory.employees:
      return const Color(0xFF5856D6);
    case AuditCategory.leads:
      return const Color(0xFF007AFF);
    case AuditCategory.modules:
      return const Color(0xFFFF6B35);
    case AuditCategory.settings:
      return const Color(0xFFFF9F0A);
    case AuditCategory.system:
      return const Color(0xFF8E8E93);
  }
}

Color auditActorColor(String actor) =>
    actor == 'Priya Nair' ? const Color(0xFFBF5AF2) : const Color(0xFF0071E3);

String auditDayLabel(DateTime timestamp) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = DateTime(now.year, now.month, now.day - 1);
  final day = DateTime(timestamp.year, timestamp.month, timestamp.day);
  if (day == today) return 'Today';
  if (day == yesterday) return 'Yesterday';
  return DateFormat('MMM d, yyyy').format(timestamp);
}

String auditTimestampLabel(DateTime timestamp) =>
    '${auditDayLabel(timestamp)} · ${DateFormat('h:mm a').format(timestamp)}';
