import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/gacha_collection.dart';

class CollectionState {
  final Set<String> ownedCostumes;
  final String? equippedCostume;
  final int gachaTickets;

  const CollectionState({
    this.ownedCostumes = const {},
    this.equippedCostume,
    this.gachaTickets = 0,
  });

  CollectionState copyWith({
    Set<String>? ownedCostumes,
    String? equippedCostume,
    int? gachaTickets,
  }) => CollectionState(
    ownedCostumes: ownedCostumes ?? this.ownedCostumes,
    equippedCostume: equippedCostume ?? this.equippedCostume,
    gachaTickets: gachaTickets ?? this.gachaTickets,
  );
}

class CollectionNotifier extends StateNotifier<CollectionState> {
  CollectionNotifier() : super(const CollectionState());

  void addTicket() => state = state.copyWith(gachaTickets: state.gachaTickets + 1);

  /// ガチャを回す → 獲得アイテムを返す
  CostumeItem? spinGacha() {
    if (state.gachaTickets <= 0) return null;

    final rng = Random();
    final roll = rng.nextDouble();

    // レアリティ抽選: 60% common, 30% rare, 10% super rare
    final CostumeRarity targetRarity;
    if (roll < 0.10) {
      targetRarity = CostumeRarity.superRare;
    } else if (roll < 0.40) {
      targetRarity = CostumeRarity.rare;
    } else {
      targetRarity = CostumeRarity.common;
    }

    final pool = allCostumes.where((c) => c.rarity == targetRarity).toList();
    final item = pool[rng.nextInt(pool.length)];

    state = state.copyWith(
      gachaTickets: state.gachaTickets - 1,
      ownedCostumes: {...state.ownedCostumes, item.id},
    );
    return item;
  }

  void equip(String costumeId) {
    state = state.copyWith(equippedCostume: costumeId);
  }

  void unequip() {
    state = CollectionState(
      ownedCostumes: state.ownedCostumes,
      equippedCostume: null,
      gachaTickets: state.gachaTickets,
    );
  }
}

final collectionProvider = StateNotifierProvider<CollectionNotifier, CollectionState>(
    (ref) => CollectionNotifier());
