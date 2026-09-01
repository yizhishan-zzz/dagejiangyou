class CommunityPlace {
  const CommunityPlace({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.serviceRadiusMeters,
    required this.distanceMeters,
  });

  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final int serviceRadiusMeters;
  final double? distanceMeters;

  factory CommunityPlace.fromJson(Map<String, dynamic> json) {
    return CommunityPlace(
      id: json['id'].toString(),
      name: json['name']?.toString() ?? '',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      serviceRadiusMeters:
          (json['serviceRadiusMeters'] as num?)?.toInt() ?? 500,
      distanceMeters: (json['distanceMeters'] as num?)?.toDouble(),
    );
  }
}

class CommunityBuilding {
  const CommunityBuilding({
    required this.id,
    required this.communityId,
    required this.name,
    required this.latitude,
    required this.longitude,
  });

  final String id;
  final String communityId;
  final String name;
  final double latitude;
  final double longitude;

  factory CommunityBuilding.fromJson(Map<String, dynamic> json) {
    return CommunityBuilding(
      id: json['id'].toString(),
      communityId: json['communityId'].toString(),
      name: json['name']?.toString() ?? '',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }
}
