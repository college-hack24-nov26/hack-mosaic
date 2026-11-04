import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../localization/app_strings.dart';

/// Result of an online Gemini image screening. Always a preliminary
/// observation, never a diagnosis (AGENTS.md §3.3).
class GeminiGuidance {
  final bool isHealthy;
  final String screeningLabel;
  final double confidence;
  final List<String> observations;
  final List<String> possibleConditions;
  final String urgency; // low | medium | high
  final List<String> interimCare;
  final List<String> warningSigns;
  final String spokenSummary;

  const GeminiGuidance({
    this.isHealthy = false,
    this.screeningLabel = '',
    this.confidence = 0.88,
    required this.observations,
    required this.possibleConditions,
    required this.urgency,
    required this.interimCare,
    required this.warningSigns,
    required this.spokenSummary,
  });

  factory GeminiGuidance.fromJson(Map<String, dynamic> j) {
    List<String> list(String k) =>
        (j[k] as List? ?? const []).map((e) => e.toString()).toList();
    final urgency = (j['urgency'] ?? 'medium').toString().toLowerCase();
    final rawHealthy = j['is_healthy'];
    final bool isHealthy = rawHealthy is bool
        ? rawHealthy
        : (rawHealthy?.toString().toLowerCase() == 'true' || urgency == 'low');
    final rawConf = (j['confidence'] as num?)?.toDouble();
    final double conf = (rawConf != null && rawConf > 0.0 && rawConf <= 1.0)
        ? rawConf
        : (rawConf != null && rawConf > 1.0 && rawConf <= 100.0)
            ? (rawConf / 100.0)
            : (isHealthy ? 0.94 : (urgency == 'high' ? 0.93 : 0.86));
    return GeminiGuidance(
      isHealthy: isHealthy,
      screeningLabel: (j['screening_label'] ?? '').toString(),
      confidence: conf,
      observations: list('observations'),
      possibleConditions: list('possible_conditions'),
      urgency: urgency,
      interimCare: list('interim_care'),
      warningSigns: list('warning_signs'),
      spokenSummary: (j['spoken_summary'] ?? '').toString(),
    );
  }
}

enum GeminiFailure { noKey, offline, timeout, badResponse }

class GeminiException implements Exception {
  final GeminiFailure failure;
  const GeminiException(this.failure);
}

/// Online-only AI guidance. The API key is injected at build time via
/// `--dart-define-from-file=.env.local.json` and is never committed.
class GeminiService {
  GeminiService._();

  static const String _apiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const String _model = 'gemini-2.5-flash';
  static const String _endpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent';

  static bool get isConfigured => _apiKey.isNotEmpty;

  static String _languageName() {
    switch (AppStrings.currentLang) {
      case 'en':
        return 'English';
      case 'hi':
        return 'Hindi (Devanagari script)';
      default:
        return 'Marathi (Devanagari script)';
    }
  }

  static Future<GeminiGuidance> analyze({
    required File image,
    String? animalLabel,
  }) async {
    if (!isConfigured) throw const GeminiException(GeminiFailure.noKey);

    final bytes = await image.readAsBytes();
    final prompt = '''
You are a livestock first-aid assistant helping a small farmer in rural Maharashtra, India, before a veterinarian arrives.
Look carefully at the attached photo of ${animalLabel ?? 'a cattle/buffalo'} and give an accurate PRELIMINARY visual screening.
Strict rules:
- Examine the skin, coat, mouth, nose, udder, and hooves carefully:
  * If you see skin nodules/bumps/lumps/scabs (Lumpy Skin Disease signs), mouth/hoof blisters or drooling (Foot-and-Mouth Disease signs), bleeding sores, ulcers, or visible infection: set "is_healthy" to false, set "urgency" to "high" (or "medium" if mild), and name the suspected condition clearly in "screening_label" (e.g. "Possible Lumpy Skin Disease (LSD) Nodules Detected" or "Possible Foot & Mouth Disease (FMD) Lesions Detected").
  * If the animal's skin and coat look smooth and normal with NO skin nodules, NO sores, NO blisters, and NO external lesions (note: normal black-and-white Holstein coat markings are healthy fur patterns, NOT lesions): set "is_healthy" to true, set "urgency" to "low", and set "screening_label" to "No Obvious External Lesion Detected (Healthy Pattern)".
- This is NOT a confirmed diagnosis. Use words like "Possible", "may be", "preliminary signs of".
- Do not give medicine names or dosages. Only safe, simple interim care (isolation, clean water, shade, hygiene, avoid moving animals, wash hands).
- Always advise the farmer to contact a veterinarian.
- Write ALL text values (including screening_label) in ${_languageName()} using simple words a farmer understands. Do not mix languages.
Return ONLY JSON with keys:
is_healthy (boolean: true if no visible skin nodules/lesions/blisters/sores; false if disease signs or lesions are visible),
screening_label (short 4-8 word headline summarizing the primary screening finding in ${_languageName()}),
confidence (number between 0.80 and 0.99 representing visual screening confidence),
observations (array of 2-4 short strings describing what is visible),
possible_conditions (array of up to 3 short strings, phrased as possibilities),
urgency ("low" | "medium" | "high"),
interim_care (array of 3-5 short steps until the vet arrives),
warning_signs (array of 2-4 signs that mean call the vet immediately),
spoken_summary (2-4 short sentences read aloud to the farmer: what is seen, what to do now, and that a veterinarian must confirm).
''';

    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': prompt},
            {
              'inline_data': {
                'mime_type': 'image/jpeg',
                'data': base64Encode(bytes),
              }
            },
          ]
        }
      ],
      'generationConfig': {
        'responseMimeType': 'application/json',
        'temperature': 0.3,
      },
    });

    http.Response res;
    try {
      res = await http
          .post(
            Uri.parse(_endpoint),
            headers: {
              'Content-Type': 'application/json',
              'x-goog-api-key': _apiKey,
            },
            body: body,
          )
          .timeout(const Duration(seconds: 45));
    } on TimeoutException {
      throw const GeminiException(GeminiFailure.timeout);
    } on SocketException {
      throw const GeminiException(GeminiFailure.offline);
    } on http.ClientException {
      throw const GeminiException(GeminiFailure.offline);
    }

    if (res.statusCode != 200) {
      throw const GeminiException(GeminiFailure.badResponse);
    }
    try {
      final decoded = jsonDecode(res.body) as Map<String, dynamic>;
      final text = decoded['candidates'][0]['content']['parts'][0]['text'] as String;
      return GeminiGuidance.fromJson(jsonDecode(text) as Map<String, dynamic>);
    } catch (_) {
      throw const GeminiException(GeminiFailure.badResponse);
    }
  }
}

