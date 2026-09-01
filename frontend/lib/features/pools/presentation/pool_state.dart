import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../data/pool_repository.dart';

class PoolState extends ChangeNotifier {
  PoolState({required this.repository});

  final PoolRepository repository;

  List<PoolShowcase> showcasePools = const [];
  PoolShowcase? lastCreatedPool;
  PoolJoinReceipt? lastJoinReceipt;
  bool isLoading = false;
  bool isJoining = false;
  String? errorMessage;

  void clear() {
    showcasePools = const [];
    lastCreatedPool = null;
    lastJoinReceipt = null;
    errorMessage = null;
    notifyListeners();
  }

  Future<void> initialize() async {
    await refreshShowcase();
  }

  Future<void> refreshShowcase() async {
    isLoading = true;
    notifyListeners();

    try {
      showcasePools = await repository.fetchShowcase();
      errorMessage = null;
    } on ApiException catch (error) {
      errorMessage = error.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> joinPool({
    required String poolId,
    required int quantity,
    required double itemAmount,
  }) async {
    isJoining = true;
    notifyListeners();

    try {
      lastJoinReceipt = await repository.joinPool(
        poolId: poolId,
        quantity: quantity,
        itemAmount: itemAmount,
      );
      errorMessage = null;
      await refreshShowcase();
      return true;
    } on ApiException catch (error) {
      errorMessage = error.message;
      return false;
    } finally {
      isJoining = false;
      notifyListeners();
    }
  }

  Future<bool> createPool(PoolCreatePayload payload) async {
    isJoining = true;
    notifyListeners();

    try {
      lastCreatedPool = await repository.createPool(payload);
      errorMessage = null;
      await refreshShowcase();
      return true;
    } on ApiException catch (error) {
      errorMessage = error.message;
      return false;
    } finally {
      isJoining = false;
      notifyListeners();
    }
  }
}
