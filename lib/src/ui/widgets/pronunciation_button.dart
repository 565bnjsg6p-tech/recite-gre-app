import 'package:flutter/material.dart';

import '../../utils/speak_word.dart';

class PronunciationButton extends StatefulWidget {
  const PronunciationButton({
    super.key,
    required this.word,
    this.tooltip = '播放发音',
    this.visualDensity,
  });

  final String word;
  final String tooltip;
  final VisualDensity? visualDensity;

  @override
  State<PronunciationButton> createState() => _PronunciationButtonState();
}

class _PronunciationButtonState extends State<PronunciationButton> {
  bool _isSpeaking = false;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: widget.tooltip,
      visualDensity: widget.visualDensity,
      onPressed: _isSpeaking || widget.word.trim().isEmpty ? null : _speak,
      icon: _isSpeaking
          ? const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.volume_up_rounded),
    );
  }

  Future<void> _speak() async {
    if (!canSpeakWords) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('当前平台暂不支持发音。')));
      return;
    }
    setState(() => _isSpeaking = true);
    try {
      await speakWord(widget.word);
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('发音失败：$error')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSpeaking = false);
      }
    }
  }
}
