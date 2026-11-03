import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../localization/app_strings.dart';

/// Result of an online Gemini image screening. Always a preliminary
/// observation, never a diagnosis (AGENTS.md §3.3).
class GeminiGuidance {
  final List<String> observations;
  final List<String> possibleConditions;
  final String urgency; // low | medium | high
  final List<String> interimCare;
  final List<String> warningSigns;
  final String spokenSummary;

  const GeminiGuidance({
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
    return GeminiGuidance(
      observations: list('observations'),
      possibleConditions: list('possible_conditions'),
      urgency: (j['urgency'] ?? 'medium').toString().toLowerCase(),
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
Look at the attached photo of ${animalLabel ?? 'a cattle/buffalo'} and give a PRELIMINARY screening only.
Strict rules:
- This is NOT a diagnosis. Never state a disease as confirmed. Use words like "may be", "possible signs of".
- Do not give medicine names or dosages. Only safe, simple interim care (isolation, clean water, shade, hygiene, avoid moving animals, wash hands).
- If the photo does not clearly show an animal or a lesion, say so in observations and set urgency to "low".
- Always advise the farmer to contact a veterinarian.
- Write ALL text values in ${_languageName()} using simple words a farmer understands. Do not mix languages.
Return ONLY JSON with keys:
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

