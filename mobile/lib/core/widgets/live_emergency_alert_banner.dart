import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../network/api_client.dart';
import '../services/voice_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Polls `GET /api/v1/alerts/live` every 3 seconds.
/// When an officer clicks "Broadcast Alert" on the Government Dashboard
/// (`http://localhost:5173`), this widget immediately:
/// 1. Vibrates the phone (`HapticFeedback.heavyImpact`),
/// 2. Displays a flashing red Government Quarantine Alert banner & modal,
/// 3. Reads the Marathi outbreak warning aloud via `VoiceService`.
class LiveEmergencyAlertBanner extends StatefulWidget {
  const LiveEmergencyAlertBanner({super.key});

  @override
  State<LiveEmergencyAlertBanner> createState() =>
      _LiveEmergencyAlertBannerState();
}

class _LiveEmergencyAlertBannerState extends State<LiveEmergencyAlertBanner> {
  final ApiClient _api = ApiClient();
  final VoiceService _voice = VoiceService();
  Timer? _pollTimer;

  Map<String, dynamic>? _latestAlert;
  String? _lastAnnouncedAlertId;
  bool _initialLoadCompleted = false;
  bool _dialogOpen = false;

  @override
  void initState() {
    super.initState();
    _initPolling();
  }

  Future<void> _initPolling() async {
    await ApiClient.resolveBestBaseUrl();
    await _checkAlerts(isInitial: true);
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _checkAlerts(isInitial: false);
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _voice.stop();
    super.dispose();
  }

  String _buildSpokenMarathiWarning(Map<String, dynamic> alert) {
    final dist = (alert['affected_district'] ?? 'Satara').toString();
    final titleMr = (alert['title_mr'] ?? alert['title'] ?? '').toString();
    final bodyMr = (alert['body_mr'] ?? alert['message'] ?? '').toString();
    return 'सावधान! महाराष्ट्र शासन पशुसंवर्धन विभागाकडून तातडीचा रोग प्रतिबंधक इशारा. '
        'जिल्हा $dist. $titleMr. $bodyMr';
  }

  Future<void> _triggerEmergencySirenAndModal(
      Map<String, dynamic> alert) async {
    // Triple heavy impact vibration for emergency alert feel
    for (int i = 0; i < 3; i++) {
      await HapticFeedback.heavyImpact();
      await Future<void>.delayed(const Duration(milliseconds: 180));
    }

    final spoken = _buildSpokenMarathiWarning(alert);
    unawaited(_voice.speakEmergencyMarathi(spoken));

    if (!mounted || _dialogOpen) return;
    _dialogOpen = true;

    final dist = (alert['affected_district'] ?? 'Satara').toString();
    final severity =
        (alert['severity'] ?? 'HIGH').toString().toUpperCase();
    final titleMr = (alert['title_mr'] ?? alert['title'] ?? '').toString();
    final bodyMr = (alert['body_mr'] ?? alert['message'] ?? '').toString();
    final titleEn = (alert['title_en'] ?? alert['title'] ?? '').toString();
    final bodyEn = (alert['body_en'] ?? alert['message'] ?? '').toString();

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.alertCritical, width: 2.5),
          ),
          backgroundColor: const Color(0xFFFFF8F8),
          titlePadding: EdgeInsets.zero,
          title: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              color: AppColors.alertCritical,
              borderRadius: BorderRadius.vertical(top: Radius.circular(13)),
            ),
            child: Row(
              children: [
                const Icon(Icons.campaign_rounded,
                    color: Colors.white, size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🚨 तातडीचा शासकीय रोग इशारा',
                        style: AppTypography.cardTitle.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'GOVT OF MAHARASHTRA • $severity • ${dist.toUpperCase()}',
                        style: AppTypography.badge.copyWith(
                          color: Colors.white.withValues(alpha: 0.92),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  titleMr,
                  style: AppTypography.cardTitle.copyWith(
                    color: const Color(0xFF991B1B),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  bodyMr,
                  style: AppTypography.bodyDefault.copyWith(
                    color: AppColors.textPrimary,
                    height: 1.45,
                  ),
                ),
                const Divider(height: 20),
                Text(
                  titleEn,
                  style: AppTypography.badge.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  bodyEn,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_user,
                          size: 16, color: AppColors.alertCritical),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'पशुवैद्यकांनी पुष्टी केलेल्या रुग्णांवर आधारित इशारा (Based on veterinarian-confirmed cases).',
                          style: AppTypography.caption.copyWith(
                            color: const Color(0xFF991B1B),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actionsPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          actions: [
            OutlinedButton.icon(
              onPressed: () {
                _voice.speakEmergencyMarathi(spoken);
              },
              icon: const Icon(Icons.volume_up_rounded,
                  size: 18, color: AppColors.alertCritical),
              label: const Text(
                'पुन्हा ऐका (Voice)',
                style: TextStyle(
                  color: AppColors.alertCritical,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.alertCritical),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                _voice.stop();
                Navigator.of(ctx).pop();
              },
              icon: const Icon(Icons.check_circle_outline,
                  size: 18, color: Colors.white),
              label: const Text(
                'समजले / OK',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.alertCritical,
              ),
            ),
          ],
        );
      },
    );

    _dialogOpen = false;
  }

  Future<void> _checkAlerts({required bool isInitial}) async {
    final alerts = await _api.fetchLiveAlerts();
    if (!mounted || alerts.isEmpty) return;

    final newest = alerts.first;
    final newestId = (newest['id'] ?? '').toString();
    if (newestId.isEmpty) return;

    if (!_initialLoadCompleted) {
      setState(() {
        _latestAlert = newest;
        _lastAnnouncedAlertId = newestId;
        _initialLoadCompleted = true;
      });
      return;
    }

    if (newestId != _lastAnnouncedAlertId) {
      setState(() {
        _latestAlert = newest;
        _lastAnnouncedAlertId = newestId;
      });
      await _triggerEmergencySirenAndModal(newest);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_latestAlert == null) return const SizedBox.shrink();

    final alert = _latestAlert!;
    final titleMr = (alert['title_mr'] ?? alert['title'] ?? '').toString();
    final dist = (alert['affected_district'] ?? 'Satara').toString();

    return Material(
      color: const Color(0xFFB91C1C),
      child: InkWell(
        onTap: () => _triggerEmergencySirenAndModal(alert),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(
            12,
            MediaQuery.of(context).padding.top + 6,
            12,
            8,
          ),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF991B1B), Color(0xFFDC2626)],
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.campaign_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '🚨 [$dist] $titleMr',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.badge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.volume_up, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'ऐका',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
