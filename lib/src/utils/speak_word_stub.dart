bool get canSpeakWords => false;

Future<void> speakWord(String word) async {
  throw UnsupportedError('当前平台暂不支持发音。');
}
