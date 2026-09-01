import '../../../core/network/api_client.dart';
import '../domain/location_models.dart';

class LocationRepository {
  const LocationRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<List<CommunityPlace>> fetchCommunities({
    required double latitude,
    required double longitude,
  }) async {
    final data = await _apiClient.get(
      '/locations/communities',
      withAuth: false,
      queryParameters: {'latitude': latitude, 'longitude': longitude},
    );
    return (data as List<dynamic>)
        .map((item) => CommunityPlace.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<List<CommunityBuilding>> fetchBuildings(String communityId) async {
    final data = await _apiClient.get(
      '/locations/communities/$communityId/buildings',
      withAuth: false,
    );
    return (data as List<dynamic>)
        .map((item) => CommunityBuilding.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }
}
