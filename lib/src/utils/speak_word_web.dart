// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;

bool get canSpeakWords => true;

Future<void> speakWord(String word) async {
  final text = word.trim();
  if (text.isEmpty) {
    return;
  }
  final synthesis = html.window.speechSynthesis!;
  synthesis.cancel();
  final utterance = html.SpeechSynthesisUtterance(text)
    ..lang = 'en-US'
    ..rate = 0.88
    ..pitch = 1.0;
  final voices = synthesis.getVoices();
  final englishVoice = voices
      .where((voice) => (voice.lang ?? '').toLowerCase().startsWith('en'))
      .cast<html.SpeechSynthesisVoice?>()
      .firstWhere((voice) => voice != null, orElse: () => null);
  if (englishVoice != null) {
    utterance.voice = englishVoice;
  }
  synthesis.speak(utterance);
}
