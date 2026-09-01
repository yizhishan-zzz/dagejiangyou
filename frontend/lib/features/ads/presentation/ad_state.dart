import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../data/ad_repository.dart';
import '../domain/ad_models.dart';

class AdState extends ChangeNotifier {
  AdState({required this.repository});

  final AdRepository repository;
  final Map<String, List<AdSlot>> _slots = {};
  final Set<String> _loading = {};

  List<AdSlot> slotsFor(String placement) =>
      List.unmodifiable(_slots[placement] ?? const []);

  Future<void> load(String placement) async {
    if (_loading.contains(placement)) return;
    _loading.add(placement);
    try {
      _slots[placement] = await repository.fetchActive(placement);
    } on ApiException {
      // Advertising is optional content and must never block the main flow.
      _slots[placement] = const [];
    } finally {
      _loading.remove(placement);
      notifyListeners();
    }
  }
}
