import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/config/app_settings.dart';
import '../../../core/network/api_client.dart';
import '../data/location_repository.dart';
import '../domain/location_models.dart';

class LocationState extends ChangeNotifier {
  LocationState({required this.settings, required this.repository})
    : latitude = settings.latitude,
      longitude = settings.longitude;

  final AppSettings settings;
  final LocationRepository repository;

  double latitude;
  double longitude;
  List<CommunityPlace> communities = const [];
  List<CommunityBuilding> buildings = const [];
  CommunityPlace? selectedCommunity;
  CommunityBuilding? selectedBuilding;
  bool isLoading = false;
  bool isLocating = false;
  String? errorMessage;
  int _requestVersion = 0;

  Future<void> initialize({String? communityName, String? buildingName}) async {
    await loadCommunities(
      latitude: settings.latitude,
      longitude: settings.longitude,
      preferredCommunityName: communityName,
      preferredBuildingName: buildingName,
    );
  }

  Future<void> loadCommunities({
    required double latitude,
    required double longitude,
    String? preferredCommunityName,
    String? preferredBuildingName,
  }) async {
    final version = ++_requestVersion;
    this.latitude = latitude;
    this.longitude = longitude;
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final result = await repository.fetchCommunities(
        latitude: latitude,
        longitude: longitude,
      );
      if (version != _requestVersion) return;
      communities = result;
      selectedCommunity =
          _findCommunity(preferredCommunityName) ??
          (result.isEmpty ? null : result.first);
      selectedBuilding = null;
      buildings = const [];
      final community = selectedCommunity;
      if (community != null) {
        await _loadBuildings(
          community,
          preferredBuildingName: preferredBuildingName,
          requestVersion: version,
        );
      }
    } on ApiException catch (error) {
      if (version == _requestVersion) {
        errorMessage = error.message;
      }
    } finally {
      if (version == _requestVersion) {
        isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> selectCommunity(CommunityPlace community) async {
    if (selectedCommunity?.id == community.id) return;
    final version = ++_requestVersion;
    selectedCommunity = community;
    selectedBuilding = null;
    buildings = const [];
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _loadBuildings(community, requestVersion: version);
    } on ApiException catch (error) {
      if (version == _requestVersion) {
        errorMessage = error.message;
      }
    } finally {
      if (version == _requestVersion) {
        isLoading = false;
        notifyListeners();
      }
    }
  }

  void selectBuilding(CommunityBuilding building) {
    selectedBuilding = building;
    latitude = building.latitude;
    longitude = building.longitude;
    notifyListeners();
  }

  Future<bool> locateDevice() async {
    isLocating = true;
    errorMessage = null;
    notifyListeners();
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        errorMessage = '请先开启系统定位';
        return false;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        errorMessage = '未获得定位权限';
        return false;
      }
      if (permission == LocationPermission.deniedForever) {
        errorMessage = '请在系统设置中允许定位';
        return false;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      await loadCommunities(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      return true;
    } catch (_) {
      errorMessage = '暂时无法获取当前位置';
      return false;
    } finally {
      isLocating = false;
      notifyListeners();
    }
  }

  Future<void> _loadBuildings(
    CommunityPlace community, {
    String? preferredBuildingName,
    required int requestVersion,
  }) async {
    final result = await repository.fetchBuildings(community.id);
    if (requestVersion != _requestVersion) return;
    buildings = result;
    selectedBuilding = _findBuilding(preferredBuildingName);
    notifyListeners();
  }

  CommunityPlace? _findCommunity(String? name) {
    if (name == null || name.isEmpty) return null;
    for (final community in communities) {
      if (community.name == name) return community;
    }
    return null;
  }

  CommunityBuilding? _findBuilding(String? name) {
    if (name == null || name.isEmpty) return null;
    for (final building in buildings) {
      if (building.name == name) return building;
    }
    return null;
  }
}
