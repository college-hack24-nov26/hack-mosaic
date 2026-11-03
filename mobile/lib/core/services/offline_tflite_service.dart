import 'package:flutter/services.dart';
import '../../data/models/disease_report_model.dart';
import '../localization/app_strings.dart';
import 'gemini_service.dart';

/// Result from on-device TensorFlow Lite screening (`bovine_disease_classifier.tflite`
/// / `livestock_disease_classifier.tflite`).
/// Always a preliminary screening result, never a confirmed diagnosis (AGENTS.md §3.3).
class OfflineTfliteResult {
  final ScreeningResult screening;
  final String topRawLabel;
  final bool isHealthy;
  final int inferenceMs;

  const OfflineTfliteResult({
    required this.screening,
    required this.topRawLabel,
    required this.isHealthy,
    required this.inferenceMs,
  });

  String get localizedClassificationLabel {
    if (screening.inconclusive) {
      return AppStrings.t('tflite_inconclusive');
    }
    return isHealthy
        ? AppStrings.t('tflite_healthy')
        : AppStrings.t('tflite_suspected_disease');
  }

  /// Generates offline first-aid guidance and spoken TTS summary in the farmer's
  /// selected language (`mr` / `hi` / `en`) when no internet connection is available.
  GeminiGuidance toOfflineGuidance() {
    final lang = AppStrings.currentLang;
    final pct = (screening.topConfidence * 100).toStringAsFixed(1);

    if (isHealthy && !screening.inconclusive) {
      switch (lang) {
        case 'en':
          return GeminiGuidance(
            observations: [
              'On-device TFLite model ($pct% confidence, ${inferenceMs}ms) did not detect prominent external lesions or mouth/skin sores.',
              'Coat and visible surface appear within normal screening parameters.',
            ],
            possibleConditions: const [
              'No obvious external FMD/LSD skin lesion detected in this view',
            ],
            urgency: 'low',
            interimCare: const [
              'Continue normal clean drinking water and balanced fodder.',
              'Monitor body temperature, appetite, and milk yield over the next 24 hours.',
              'Keep the cattle shed clean, dry, and protected from flies and mosquitoes.',
            ],
            warningSigns: const [
              'Sudden high fever, drooling, lameness, or skin nodules appearing',
              'Refusal to eat fodder or sudden drop in milk production',
            ],
            spokenSummary:
                'On-device preliminary screening found no obvious external skin or mouth lesions with $pct percent confidence. Continue clean water and regular observation, and consult a veterinarian if any fever or symptoms appear.',
          );
        case 'hi':
          return GeminiGuidance(
            observations: [
              'ऑन-डिवाइस टीएफलाइट मॉडल ($pct% विश्वसनीयता, ${inferenceMs}ms) में बाहरी घाव या छाले के स्पष्ट संकेत नहीं दिखे।',
              'दिखने वाला हिस्सा सामान्य प्रारंभिक जांच की सीमा में है।',
            ],
            possibleConditions: const [
              'इस फोटो में खुरपका या लम्पी के स्पष्ट बाहरी घाव नहीं दिखे',
            ],
            urgency: 'low',
            interimCare: const [
              'पशु को साफ पीने का पानी और संतुलित चारा देना जारी रखें।',
              'अगले २४ घंटों तक बुखार, चारे और दूध की मात्रा पर नज़र रखें।',
              'गोशाला को साफ रखें और मक्खी-मच्छरों से बचाव करें।',
            ],
            warningSigns: const [
              'अचानक तेज़ बुखार, मुंह से लार गिरना, लंगड़ापन या त्वचा पर गांठें दिखना',
              'चारा छोड़ना या दूध में अचानक कमी आना',
            ],
            spokenSummary:
                'ऑन-डिवाइस प्रारंभिक जांच में $pct प्रतिशत विश्वसनीयता के साथ बाहरी घाव के स्पष्ट संकेत नहीं मिले हैं। पशु को साफ पानी दें और कोई भी लक्षण दिखने पर पशु चिकित्सक को दिखाएं।',
          );
        default:
          return GeminiGuidance(
            observations: [
              'ऑन-डिवाइस टीएफलाईट मॉडेलनुसार ($pct% विश्वासार्हता, ${inferenceMs}ms) बाह्य जखम किंवा फोडांचे स्पष्ट चिन्ह आढळले नाही.',
              'फोटोमधील भाग प्राथमिक तपासणीत सामान्य दिसत आहे.',
            ],
            possibleConditions: const [
              'या फोटोमध्ये लाळ्या खुरकूत किंवा लंपीचे स्पष्ट बाह्य घाव आढळले नाहीत',
            ],
            urgency: 'low',
            interimCare: const [
              'जनावरास स्वच्छ पिण्याचे पाणी आणि संतुलित चारा देणे सुरू ठेवा.',
              'पुढील २४ तास ताप, चारा खाणे आणि दुधाच्या प्रमाणावर लक्ष ठेवा.',
              'गोठा स्वच्छ व कोरडा ठेवा आणि माशा-डासांपासून संरक्षण करा.',
            ],
            warningSigns: const [
              'अचानक तीव्र ताप, तोंडातून लाळ गळणे, लंगडणे किंवा अंगावर गाठी येणे',
              'चारा न खाणे किंवा दुधात अचानक घट होणे',
            ],
            spokenSummary:
                'ऑन-डिव्हाइस प्राथमिक तपासणीत $pct टक्के विश्वासार्हतेसह बाह्य जखमेचे स्पष्ट चिन्ह आढळले नाही. जनावरास स्वच्छ पाणी द्या आणि कोणतीही लक्षणे दिसल्यास पशुवैद्यकास बोलवा.',
          );
      }
    }

    final urgency = screening.inconclusive
        ? 'medium'
        : (screening.topConfidence >= 0.80 ? 'high' : 'medium');

    switch (lang) {
      case 'en':
        return GeminiGuidance(
          observations: [
            'On-device TFLite model ($pct% confidence, ${inferenceMs}ms) detected visual patterns consistent with possible bovine skin/mouth lesions.',
            if (screening.inconclusive)
              'Confidence is below 65% (inconclusive); lighting or angle may affect clarity.',
          ],
          possibleConditions: const [
            'Possible Foot & Mouth Disease (FMD) or Lumpy Skin Disease (LSD) lesion pattern',
            'Possible localized dermal inflammation requiring veterinary inspection',
          ],
          urgency: urgency,
          interimCare: const [
            'Immediately isolate this animal from healthy cattle and buffaloes.',
            'Provide plenty of clean drinking water and soft, easily chewable green fodder.',
            'Keep the animal in a shaded, clean, fly-protected shed.',
            'Wash your hands and footwear with soap/disinfectant after handling the animal.',
            'Do not move the animal outside the farm until a veterinarian examines it.',
          ],
          warningSigns: const [
            'High fever, stringy salivation, or blisters on tongue and hooves',
            'Rapidly spreading skin nodules, swelling of legs, or breathing difficulty',
            'Complete refusal of water or inability to stand',
          ],
          spokenSummary:
              'On-device preliminary screening detected possible lesion signs with $pct percent confidence. Please keep this animal isolated from the herd, provide clean water and soft fodder in the shade, and send this report to a veterinarian for clinical confirmation.',
        );
      case 'hi':
        return GeminiGuidance(
          observations: [
            'ऑन-डिवाइस टीएफलाइट मॉडल ($pct% विश्वसनीयता, ${inferenceMs}ms) ने त्वचा या मुंह पर संभावित घाव के संकेत पहचाने हैं।',
            if (screening.inconclusive)
              'विश्वसनीयता ६५% से कम (अनिर्णायक) है; कृपया साफ रोशनी में भी जांच कराएं।',
          ],
          possibleConditions: const [
            'संभावित खुरपका-मुंहपका (FMD) या लम्पी त्वचा रोग (LSD) जैसे लक्षण',
            'त्वचा का संभावित संक्रमण जिसकी पशु चिकित्सक द्वारा जांच आवश्यक है',
          ],
          urgency: urgency,
          interimCare: const [
            'इस पशु को तुरंत अन्य स्वस्थ गाय-भैंसों से अलग बांधें।',
            'पशु को पर्याप्त साफ पानी और नरम हरा चारा छाया में दें।',
            'गोशाला में मक्खी और मच्छरों से बचाव रखें तथा जगह साफ रखें।',
            'बीमार पशु को छूने के बाद अपने हाथ और जूते साबुन से अच्छी तरह धोएं।',
            'पशु चिकित्सक के आने तक पशु को गांव में बाहर न घुमाएं।',
          ],
          warningSigns: const [
            'तेज़ बुखार, मुंह से लगातार लार गिरना या जीभ और खुरों में छाले होना',
            'शरीर पर तेजी से बढ़ती गांठें, पैरों में सूजन या सांस लेने में तकलीफ',
            'पानी पीना बंद करना या खड़े होने में असमर्थ होना',
          ],
          spokenSummary:
              'ऑन-डिवाइस प्रारंभिक जांच में $pct प्रतिशत विश्वसनीयता के साथ संभावित बीमारी के संकेत मिले हैं। पशु चिकित्सक के आने तक इस पशु को अन्य पशुओं से अलग रखें, साफ पानी और नरम चारा दें, और तुरंत पशु चिकित्सक को रिपोर्ट भेजें।',
        );
      default:
        return GeminiGuidance(
          observations: [
            'ऑन-डिवाइस टीएफलाईट मॉडेलने ($pct% विश्वासार्हता, ${inferenceMs}ms) त्वचा किंवा तोंडावरील संभाव्य जखम/गाठींचे संकेत ओळखले आहेत.',
            if (screening.inconclusive)
              'विश्वासार्हता ६५% पेक्षा कमी (अनिर्णित) आहे; पशुवैद्यकाची प्रत्यक्ष तपासणी आवश्यक आहे.',
          ],
          possibleConditions: const [
            'संभाव्य लाळ्या खुरकूत (FMD) किंवा लंपी त्वचा रोग (LSD) सदृश लक्षणे',
            'त्वचेचा संभाव्य संसर्ग — पशुवैद्यकीय तपासणी आवश्यक',
          ],
          urgency: urgency,
          interimCare: const [
            'या जनावरास ताबडतोब इतर निरोगी गाई-म्हशींपासून वेगळे बांधा.',
            'सावलीत स्वच्छ पिण्याचे पाणी आणि मऊ हिरवा चारा द्या.',
            'गोठा स्वच्छ ठेवा आणि माशा, गोचिड व डासांपासून संरक्षण करा.',
            'आजारी जनावराची काळजी घेतल्यानंतर हात आणि पादत्राणे साबणाने स्वच्छ धुवा.',
            'पशुवैद्यक येईपर्यंत जनावरास गोठ्याबाहेर किंवा बाजारात नेऊ नका.',
          ],
          warningSigns: const [
            'तीव्र ताप, तोंडातून सतत लाळ गळणे किंवा जिभेवर व खुरांत फोड येणे',
            'अंगावर वेगाने पसरणाऱ्या गाठी, पायांवर सूज किंवा श्वास घेण्यास त्रास',
            'पाणी पिणे पूर्ण बंद करणे किंवा उभे राहता न येणे',
          ],
          spokenSummary:
              'ऑन-डिव्हाइस प्राथमिक तपासणीत $pct टक्के विश्वासार्हतेसह संभाव्य आजाराची लक्षणे आढळली आहेत. पशुवैद्यक येईपर्यंत या जनावरास इतर जनावरांपासून वेगळे ठेवा, स्वच्छ पाणी व मऊ चारा द्या, आणि तात्काळ पशुवैद्यकाकडे अहवाल पाठवा.',
        );
    }
  }
}

class OfflineTfliteService {
  OfflineTfliteService._();

  static const MethodChannel _channel =
      MethodChannel('com.pashuvani.pashu_wani/tflite');

  /// Runs on-device TensorFlow Lite inference (`assets/ml/bovine_disease_classifier.tflite`
  /// for cattle/buffalo, `assets/ml/livestock_disease_classifier.tflite` for poultry).
  static Future<OfflineTfliteResult> classify({
    required String imagePath,
    String species = 'bovine',
  }) async {
    final raw = await _channel.invokeMethod<Map<Object?, Object?>>(
      'classifyImage',
      {
        'imagePath': imagePath,
        'species': species,
      },
    );

    if (raw == null) {
      throw PlatformException(code: 'EMPTY_RESULT', message: 'TFLite returned null');
    }

    final map = Map<String, dynamic>.from(raw);
    final rawScores = (map['scores'] as List? ?? const []);
    final scores = rawScores
        .whereType<Map>()
        .map((s) {
          final m = Map<String, dynamic>.from(s);
          return <String, dynamic>{
            'label': (m['label'] ?? '').toString(),
            'score': (m['score'] as num?)?.toDouble() ?? 0.0,
          };
        })
        .toList();

    final screening = ScreeningResult(
      modelVersion: (map['model_version'] ?? 'bovine_tflite_v1.0.0').toString(),
      topLabel: (map['top_label'] ?? 'suspected_bovine_disease').toString(),
      topConfidence: (map['top_confidence'] as num?)?.toDouble() ?? 0.0,
      inconclusive: map['inconclusive'] as bool? ?? false,
      scores: scores,
      ranAt: DateTime.now().toUtc(),
      disclaimer: 'preliminary_screening_not_a_diagnosis',
    );

    return OfflineTfliteResult(
      screening: screening,
      topRawLabel: (map['top_raw_label'] ?? screening.topLabel).toString(),
      isHealthy: map['is_healthy'] as bool? ?? false,
      inferenceMs: (map['inference_ms'] as num?)?.toInt() ?? 0,
    );
  }
}
