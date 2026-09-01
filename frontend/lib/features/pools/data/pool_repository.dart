import '../../../core/network/api_client.dart';

enum PoolStatus {
  open('OPEN'),
  full('FULL'),
  closed('CLOSED');

  const PoolStatus(this.apiValue);

  final String apiValue;

  static PoolStatus fromApi(String raw) {
    return values.firstWhere(
      (status) => status.apiValue == raw,
      orElse: () => PoolStatus.open,
    );
  }
}

class PoolShowcase {
  const PoolShowcase({
    required this.poolId,
    required this.title,
    required this.category,
    required this.storeName,
    required this.summary,
    required this.pickupPoint,
    required this.currentParticipants,
    required this.targetParticipants,
    required this.sharedFeePerUser,
    required this.countdownMinutes,
    required this.status,
  });

  final String poolId;
  final String title;
  final String category;
  final String storeName;
  final String summary;
  final String pickupPoint;
  final int currentParticipants;
  final int targetParticipants;
  final double sharedFeePerUser;
  final int countdownMinutes;
  final PoolStatus status;

  double get progress =>
      targetParticipants == 0 ? 0 : currentParticipants / targetParticipants;
  int get remainingSlots => targetParticipants - currentParticipants;

  factory PoolShowcase.fromJson(Map<String, dynamic> json) {
    return PoolShowcase(
      poolId: json['poolId'].toString(),
      title: json['title']?.toString() ?? '社区拼单',
      category: json['category']?.toString() ?? '社区拼单',
      storeName: json['storeName']?.toString() ?? '',
      summary: json['summary']?.toString() ?? '',
      pickupPoint: json['pickupPoint']?.toString() ?? '',
      currentParticipants: (json['currentParticipants'] as num?)?.toInt() ?? 1,
      targetParticipants: (json['targetParticipants'] as num?)?.toInt() ?? 2,
      sharedFeePerUser: (json['sharedFeePerUser'] as num?)?.toDouble() ?? 0,
      countdownMinutes: (json['countdownMinutes'] as num?)?.toInt() ?? 20,
      status: PoolStatus.fromApi(json['status']?.toString() ?? 'OPEN'),
    );
  }
}

class PoolCreatePayload {
  const PoolCreatePayload({
    required this.title,
    required this.storeName,
    required this.category,
    required this.summary,
    required this.pickupPoint,
    required this.freightFee,
    required this.deliveryFee,
    required this.targetParticipants,
    required this.countdownMinutes,
  });

  final String title;
  final String storeName;
  final String category;
  final String summary;
  final String pickupPoint;
  final double freightFee;
  final double deliveryFee;
  final int targetParticipants;
  final int countdownMinutes;

  Map<String, dynamic> toJson() => {
    'title': title,
    'storeName': storeName,
    'category': category,
    'summary': summary,
    'pickupPoint': pickupPoint,
    'freightFee': freightFee,
    'deliveryFee': deliveryFee,
    'targetParticipants': targetParticipants,
    'countdownMinutes': countdownMinutes,
  };
}

class PoolJoinReceipt {
  const PoolJoinReceipt({
    required this.poolId,
    required this.currentParticipants,
    required this.targetParticipants,
    required this.sharedFeePerUser,
    required this.yourSharedFee,
    required this.poolStatus,
  });

  final String poolId;
  final int currentParticipants;
  final int targetParticipants;
  final double sharedFeePerUser;
  final double yourSharedFee;
  final PoolStatus poolStatus;

  factory PoolJoinReceipt.fromJson(Map<String, dynamic> json) {
    return PoolJoinReceipt(
      poolId: json['poolId'].toString(),
      currentParticipants: (json['currentParticipants'] as num?)?.toInt() ?? 0,
      targetParticipants: (json['targetParticipants'] as num?)?.toInt() ?? 0,
      sharedFeePerUser: (json['sharedFeePerUser'] as num?)?.toDouble() ?? 0,
      yourSharedFee: (json['yourSharedFee'] as num?)?.toDouble() ?? 0,
      poolStatus: PoolStatus.fromApi(json['poolStatus']?.toString() ?? 'OPEN'),
    );
  }
}

class PoolRepository {
  const PoolRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<List<PoolShowcase>> fetchShowcase() async {
    final data = await _apiClient.get('/pools/showcase') as List<dynamic>;
    return data
        .whereType<Map<String, dynamic>>()
        .map(PoolShowcase.fromJson)
        .toList();
  }

  Future<PoolShowcase> createPool(PoolCreatePayload payload) async {
    final data =
        await _apiClient.post('/pools', data: payload.toJson())
            as Map<String, dynamic>;
    return PoolShowcase.fromJson(data);
  }

  Future<PoolJoinReceipt> joinPool({
    required String poolId,
    required int quantity,
    required double itemAmount,
  }) async {
    final data =
        await _apiClient.post(
              '/pools/$poolId/join',
              data: {'quantity': quantity, 'itemAmount': itemAmount},
            )
            as Map<String, dynamic>;
    return PoolJoinReceipt.fromJson(data);
  }
}
