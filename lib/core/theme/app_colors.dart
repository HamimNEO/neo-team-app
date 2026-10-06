import 'package:flutter/material.dart';

class AppColors {
  static const Color brandLight = Color(0xFF0071E3);
  static const Color brandDark = Color(0xFF0A84FF);
  static const Color brandPressedLight = Color(0xFF005EC4);
  static const Color brandSubtleLight = Color(0xFFEAF3FF);
  static const Color brandSubtleDark = Color(0xFF001F3F);

  static const Color bgLight = Color(0xFFF2F2F7);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceSecondaryLight = Color(0xFFF2F2F7);
  static const Color bgDark = Color(0xFF000000);
  static const Color surfaceDark = Color(0xFF1C1C1E);
  static const Color surfaceSecondaryDark = Color(0xFF2C2C2E);
  static const Color surfaceElevatedDark = Color(0xFF2C2C2E);

  static const Color textPrimaryLight = Color(0xFF1C1C1E);
  static const Color textSecondaryLight = Color(0xC73C3C43);
  static const Color textTertiaryLight = Color(0x8F3C3C43);
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xBFEBEBF5);
  static const Color textTertiaryDark = Color(0x7FEBEBF5);
  static const Color textDisabledDark = Color(0x3FEBEBF5);

  static const Color separatorLight = Color(0x4A3C3C43);
  static const Color separatorDark = Color(0xA6545458);

  static const Color success = Color(0xFF34C759);
  static const Color warning = Color(0xFFFF9F0A);
  static const Color error = Color(0xFFFF3B30);
  static const Color neutral = Color(0xFF8E8E93);

  static const Color leadNew = Color(0xFF0071E3);
  static const Color leadContacted = Color(0xFF5856D6);
  static const Color leadInterested = Color(0xFF30B0C7);
  static const Color leadFollowup = Color(0xFFFF9F0A);
  static const Color leadVisit = Color(0xFFFF6B35);
  static const Color leadNegotiation = Color(0xFFBF5AF2);
  static const Color leadWon = Color(0xFF34C759);
  static const Color leadLost = Color(0xFFFF3B30);

  static const Color taskTodo = Color(0xFF8E8E93);
  static const Color taskInProgress = Color(0xFF0071E3);
  static const Color taskReview = Color(0xFFFF9F0A);
  static const Color taskCompleted = Color(0xFF34C759);

  static Color leadStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'new':
        return leadNew;
      case 'contacted':
        return leadContacted;
      case 'interested':
        return leadInterested;
      case 'follow-up':
        return leadFollowup;
      case 'visit':
        return leadVisit;
      case 'negotiation':
        return leadNegotiation;
      case 'won':
        return leadWon;
      case 'lost':
        return leadLost;
      default:
        return neutral;
    }
  }
}
