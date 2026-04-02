import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

// ─────────────────────────────────────────────────────────
// StorageCounter — 画像付きマンダラの保存件数管理
//
// 有料化への布石: 無料枠の保存件数制限。
// ─────────────────────────────────────────────────────────

class StorageQuota {
  final int usedCount;          // 使用済み件数
  final int maxFreeCount;       // 無料枠上限
  final int totalSizeKb;        // 合計サイズ(KB)
  final bool isPremium;         // プレミアム会員

  const StorageQuota({
    this.usedCount = 0,
    this.maxFreeCount = 10,
    this.totalSizeKb = 0,
    this.isPremium = false,
  });

  bool get isOverQuota => !isPremium && usedCount >= maxFreeCount;
  int get remaining => isPremium ? 999 : (maxFreeCount - usedCount).clamp(0, maxFreeCount);
  double get usagePercent => isPremium ? 0 : (usedCount / maxFreeCount).clamp(0.0, 1.0);

  StorageQuota copyWith({
    int? usedCount, int? maxFreeCount, int? totalSizeKb, bool? isPremium,
  }) => StorageQuota(
    usedCount: usedCount ?? this.usedCount,
    maxFreeCount: maxFreeCount ?? this.maxFreeCount,
    totalSizeKb: totalSizeKb ?? this.totalSizeKb,
    isPremium: isPremium ?? this.isPremium,
  );
}

class StorageCounterNotifier extends StateNotifier<StorageQuota> {
  StorageCounterNotifier() : super(const StorageQuota()) {
    _load();
  }

  static const _fileName = 'storage_quota.json';

  Future<File> get _file async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  Future<void> _load() async {
    try {
      final file = await _file;
      if (await file.exists()) {
        final json = jsonDecode(await file.readAsString());
        state = StorageQuota(
          usedCount: json['usedCount'] as int? ?? 0,
          totalSizeKb: json['totalSizeKb'] as int? ?? 0,
          isPremium: json['isPremium'] as bool? ?? false,
        );
      }
    } catch (_) {}
  }

  Future<void> _save() async {
    final file = await _file;
    await file.writeAsString(jsonEncode({
      'usedCount': state.usedCount,
      'totalSizeKb': state.totalSizeKb,
      'isPremium': state.isPremium,
    }));
  }

  /// 画像保存時にカウント増加
  Future<bool> recordSave(int sizeKb) async {
    if (state.isOverQuota) return false;
    state = state.copyWith(
      usedCount: state.usedCount + 1,
      totalSizeKb: state.totalSizeKb + sizeKb,
    );
    await _save();
    return true;
  }

  /// プレミアムアップグレード
  Future<void> upgradeToPremium() async {
    state = state.copyWith(isPremium: true);
    await _save();
  }

  /// カウンターリセット（管理用）
  Future<void> reset() async {
    state = const StorageQuota();
    await _save();
  }
}

final storageCounterProvider = StateNotifierProvider<StorageCounterNotifier, StorageQuota>(
    (ref) => StorageCounterNotifier());
