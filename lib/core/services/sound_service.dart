import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class SoundService {
  SoundService._();

  static final SoundService instance = SoundService._();

  AudioPlayer? _player;

  Future<void> playTaskDone() async {
    try {
      _player ??= AudioPlayer();
      await _player!.stop();
      _player!.audioCache.prefix = 'assets/';
      await _player!.play(
        AssetSource('sounds/crystal.wav'),
        mode: PlayerMode.lowLatency,
      );
    } catch (e) {
      debugPrint('[SoundService] Could not play task completion sound: $e');
    }
  }

  void dispose() {
    _player?.dispose();
    _player = null;
  }
}
