import 'package:flutter_tts/flutter_tts.dart';
import '../localization/app_strings.dart';

/// Reads guidance aloud in the active app language (mr / hi / en).
class VoiceService {
  VoiceService();

  final FlutterTts _tts = FlutterTts();

  String get _locale {
    switch (AppStrings.currentLang) {
      case 'en':
        return 'en-IN';
      case 'hi':
        return 'hi-IN';
      default:
        return 'mr-IN';
    }
  }

  /// Returns false if the device has no voice for the language.
  Future<bool> speak(String text) async {
    final available = await _tts.isLanguageAvailable(_locale);
    if (available != true) return false;
    await _tts.setLanguage(_locale);
    await _tts.setSpeechRate(0.45);
    await _tts.speak(text);
    return true;
  }

  Future<void> stop() => _tts.stop();
}

