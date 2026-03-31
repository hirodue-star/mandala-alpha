import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

// ─────────────────────────────────────────────────────────
// AudioMixerService — 8トラック並列ループ BGMミキサー
//
// 音源配置（assets/audio/ に追加してください）:
//   track_0.mp3 〜 track_7.mp3  ← 各マス対応楽器ループ（8〜16秒推奨）
//   orchestra.mp3               ← 孵化フルオーケストラ（15〜30秒）
//
// 全トラックは同じBPMで作成し、シームレスループが前提。
// ─────────────────────────────────────────────────────────

class AudioMixerService {
  static const int _trackCount = 8;

  // 各マスに対応する楽器ループ用プレイヤー
  final List<AudioPlayer> _trackPlayers =
      List.generate(_trackCount, (_) => AudioPlayer());

  // 孵化フルオーケストラ用プレイヤー
  final AudioPlayer _orchestraPlayer = AudioPlayer();

  // 各トラックの有効フラグ
  final List<bool> _enabled = List.filled(_trackCount, false);

  /// トラック名マッピング（楽器イメージ）
  static const List<String> trackNames = [
    'ピアノ',    // 0: 上
    'チェロ',    // 1: 右上
    'フルート',  // 2: 右
    'バイオリン', // 3: 右下
    'ドラム',    // 4: 下
    'トランペット', // 5: 左下
    'ギター',    // 6: 左
    'マリンバ',  // 7: 左上
  ];

  // ── 初期化 ───────────────────────────────────────────────

  Future<void> init() async {
    for (int i = 0; i < _trackCount; i++) {
      // ミュート状態でプリロード（一斉スタートで同期取るため）
      await _trackPlayers[i].setVolume(0);
      await _trackPlayers[i].setReleaseMode(ReleaseMode.loop);
      try {
        await _trackPlayers[i].setSource(AssetSource('audio/track_$i.mp3'));
      } catch (_) {
        // 音源ファイル未追加時はスキップ
        debugPrint('[AudioMixer] track_$i.mp3 not found — skipping');
      }
    }
  }

  // ── トラック制御 ─────────────────────────────────────────

  /// 指定インデックスのトラックを有効化（フェードイン）
  Future<void> enableTrack(int index) async {
    if (index < 0 || index >= _trackCount) return;
    if (_enabled[index]) return;
    _enabled[index] = true;

    try {
      final player = _trackPlayers[index];
      final state = player.state;

      if (state != PlayerState.playing) {
        await player.resume();
      }
      // 0 → 1.0 にフェードイン（500ms ステップ）
      for (double v = 0.0; v <= 1.0; v += 0.1) {
        await player.setVolume(v);
        await Future.delayed(const Duration(milliseconds: 50));
      }
      debugPrint('[AudioMixer] Track $index (${trackNames[index]}) ON');
    } catch (e) {
      debugPrint('[AudioMixer] enableTrack $index error: $e');
    }
  }

  /// 指定インデックスのトラックを無効化（フェードアウト）
  Future<void> disableTrack(int index) async {
    if (index < 0 || index >= _trackCount) return;
    if (!_enabled[index]) return;
    _enabled[index] = false;

    try {
      final player = _trackPlayers[index];
      for (double v = 1.0; v >= 0.0; v -= 0.1) {
        await player.setVolume(v.clamp(0.0, 1.0));
        await Future.delayed(const Duration(milliseconds: 50));
      }
      await player.pause();
      debugPrint('[AudioMixer] Track $index (${trackNames[index]}) OFF');
    } catch (e) {
      debugPrint('[AudioMixer] disableTrack $index error: $e');
    }
  }

  /// フルオーケストラを再生（孵化演出）
  Future<void> playOrchestra() async {
    // 個別トラックを徐々に下げつつオーケストラへクロスフェード
    try {
      await _orchestraPlayer.setReleaseMode(ReleaseMode.stop);
      await _orchestraPlayer.setSource(AssetSource('audio/orchestra.mp3'));
      await _orchestraPlayer.resume();
      debugPrint('[AudioMixer] Orchestra START');
    } catch (e) {
      debugPrint('[AudioMixer] playOrchestra error: $e');
    }

    // 既存トラックをフェードアウト
    for (int i = 0; i < _trackCount; i++) {
      if (_enabled[i]) {
        _trackPlayers[i].setVolume(0).ignore();
      }
    }
  }

  Future<void> stopAll() async {
    for (final p in _trackPlayers) {
      await p.stop();
      await p.setVolume(1.0);
    }
    await _orchestraPlayer.stop();
    for (int i = 0; i < _trackCount; i++) {
      _enabled[i] = false;
    }
  }

  Future<void> dispose() async {
    await stopAll();
    for (final p in _trackPlayers) {
      await p.dispose();
    }
    await _orchestraPlayer.dispose();
  }
}
