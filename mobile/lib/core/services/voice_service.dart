import 'package:flutter_tts/flutter_tts.dart';
import '../localization/app_strings.dart';

/// Reads guidance and emergency outbreak alerts aloud in Marathi / Hindi / English.
class VoiceService {
  VoiceService();

  final FlutterTts _tts = FlutterTts();

  List<String> get _preferredLocales {
    switch (AppStrings.currentLang) {
      case 'en':
        return ['en-IN', 'en-US'];
      case 'hi':
        return ['hi-IN', 'mr-IN', 'en-IN'];
      default:
        return ['mr-IN', 'hi-IN', 'en-IN'];
    }
  }

  /// Speaks text in the active language with automatic Devanagari fallback.
  Future<bool> speak(String text) async {
    try {
      String chosen = _preferredLocales.first;
      for (final loc in _preferredLocales) {
        final available = await _tts.isLanguageAvailable(loc);
        if (available == true) {
          chosen = loc;
          break;
        }
      }
      await _tts.setLanguage(chosen);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      await _tts.setSpeechRate(0.46);
      await _tts.speak(text);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Speaks an urgent Government Quarantine Alert aloud in Marathi (with Hindi/Indian TTS fallback).
  Future<bool> speakEmergencyMarathi(String marathiAlertText) async {
    try {
      String chosen = 'mr-IN';
      for (final loc in const ['mr-IN', 'hi-IN', 'en-IN']) {
        final available = await _tts.isLanguageAvailable(loc);
        if (available == true) {
          chosen = loc;
          break;
        }
      }
      await _tts.stop();
      await _tts.setLanguage(chosen);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.05);
      await _tts.setSpeechRate(0.45);
      await _tts.speak(marathiAlertText);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> stop() => _tts.stop();
}
