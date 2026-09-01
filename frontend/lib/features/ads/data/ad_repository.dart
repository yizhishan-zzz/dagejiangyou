import '../../../core/network/api_client.dart';
import '../domain/ad_models.dart';

class AdRepository {
  const AdRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<List<AdSlot>> fetchActive(String placement) async {
    final data =
        await _apiClient.get(
              '/ad-slots',
              queryParameters: {'placement': placement},
            )
            as List<dynamic>;
    return data.whereType<Map<String, dynamic>>().map(AdSlot.fromJson).toList();
  }
}
