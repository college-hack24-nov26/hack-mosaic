import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Backgrounds & Surfaces
  static const Color background = Color(0xFFF7F4EE); // Warm rural wheat
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceContainer = Color(0xFFEBF2DF); // Sage tint
  static const Color surfaceContainerHigh = Color(0xFFE1EAD2);

  // Brand Greens
  static const Color primary = Color(0xFF2E6314); // Deep farm green
  static const Color primaryLight = Color(0xFF488424);
  static const Color primaryDark = Color(0xFF1B4208);
  static const Color brandAccent = Color(0xFF76C426); // Lime sprout

  // Status & Alerts
  static const Color alertCritical = Color(0xFFD32F2F); // High danger / Confirmed
  static const Color cautionAmber = Color(0xFFE67E22); // Pending / Under Review
  static const Color successGreen = Color(0xFF2E7D32); // Resolved / Healthy
  static const Color infoBlue = Color(0xFF1976D2); // Screening / Info

  // Neutral & Typography
  static const Color textPrimary = Color(0xFF1A2214);
  static const Color textSecondary = Color(0xFF56624D);
  static const Color textMuted = Color(0xFF83907A);
  static const Color border = Color(0xFFDCE4D0);
  static const Color borderSubtle = Color(0xFFECEFE6);

  // Status Color Mapping
  static Color statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return alertCritical;
      case 'under_review':
        return infoBlue;
      case 'submitted':
        return cautionAmber;
      case 'rejected':
        return textMuted;
      case 'flagged':
        return cautionAmber;
      case 'healthy':
        return successGreen;
      default:
        return primary;
    }
  }
}
