enum TaskType {
  packagePickup('PACKAGE_PICKUP'),
  errand('ERRAND'),
  pool('POOL');

  const TaskType(this.apiValue);

  final String apiValue;

  static TaskType fromApi(String raw) {
    return values.firstWhere(
      (type) => type.apiValue == raw,
      orElse: () => TaskType.errand,
    );
  }
}

enum TaskStatus {
  open('OPEN'),
  accepted('ACCEPTED'),
  pickedUp('PICKED_UP'),
  arrived('ARRIVED'),
  completed('COMPLETED'),
  cancelled('CANCELLED');

  const TaskStatus(this.apiValue);

  final String apiValue;

  static TaskStatus fromApi(String raw) {
    return values.firstWhere(
      (status) => status.apiValue == raw,
      orElse: () => TaskStatus.open,
    );
  }
}

class CreateTaskPayload {
  const CreateTaskPayload({
    required this.title,
    required this.description,
    required this.taskType,
    required this.baseFee,
    required this.weightKg,
    required this.weatherSurcharge,
    required this.pickupFloor,
    required this.dropoffFloor,
    required this.pickupHasElevator,
    required this.dropoffHasElevator,
    required this.pickupLatitude,
    required this.pickupLongitude,
    required this.dropoffLatitude,
    required this.dropoffLongitude,
    this.isPublic = true,
  });

  final String title;
  final String description;
  final TaskType taskType;
  final double baseFee;
  final double weightKg;
  final double weatherSurcharge;
  final int pickupFloor;
  final int dropoffFloor;
  final bool pickupHasElevator;
  final bool dropoffHasElevator;
  final double pickupLatitude;
  final double pickupLongitude;
  final double dropoffLatitude;
  final double dropoffLongitude;
  final bool isPublic;

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'taskType': taskType.apiValue,
      'baseFee': baseFee,
      'weightKg': weightKg,
      'weatherSurcharge': weatherSurcharge,
      'pickupFloor': pickupFloor,
      'dropoffFloor': dropoffFloor,
      'pickupHasElevator': pickupHasElevator,
      'dropoffHasElevator': dropoffHasElevator,
      'pickupLatitude': pickupLatitude,
      'pickupLongitude': pickupLongitude,
      'dropoffLatitude': dropoffLatitude,
      'dropoffLongitude': dropoffLongitude,
      'isPublic': isPublic,
    };
  }
}

class NearbyTask {
  const NearbyTask({
    required this.taskId,
    required this.title,
    required this.description,
    required this.taskType,
    required this.status,
    required this.suggestedTip,
    required this.distanceMeters,
    required this.pickupFloor,
    required this.dropoffFloor,
  });

  final String taskId;
  final String title;
  final String description;
  final TaskType taskType;
  final TaskStatus status;
  final double suggestedTip;
  final double distanceMeters;
  final int pickupFloor;
  final int dropoffFloor;

  factory NearbyTask.fromJson(Map<String, dynamic> json) {
    return NearbyTask(
      taskId: json['taskId'].toString(),
      title: json['title']?.toString() ?? '即时任务',
      description: json['description']?.toString() ?? '点击查看详情',
      taskType: TaskType.fromApi(json['taskType']?.toString() ?? 'ERRAND'),
      status: TaskStatus.fromApi(json['status']?.toString() ?? 'OPEN'),
      suggestedTip: (json['suggestedTip'] as num?)?.toDouble() ?? 0,
      distanceMeters: (json['distanceMeters'] as num?)?.toDouble() ?? 0,
      pickupFloor: (json['pickupFloor'] as num?)?.toInt() ?? 1,
      dropoffFloor: (json['dropoffFloor'] as num?)?.toInt() ?? 1,
    );
  }
}

class TaskRecord {
  const TaskRecord({
    required this.taskId,
    required this.title,
    required this.description,
    required this.taskType,
    required this.status,
    required this.suggestedTip,
    required this.escrowAmount,
    this.runnerId,
    this.photoProofToken,
    this.creatorId,
    this.pickupFloor = 1,
    this.dropoffFloor = 1,
    this.pickupHasElevator = true,
    this.dropoffHasElevator = true,
    this.weightKg = 0,
    this.pickupLatitude,
    this.pickupLongitude,
    this.dropoffLatitude,
    this.dropoffLongitude,
    this.isCreator = false,
    this.isRunner = false,
    this.isPublic = true,
    this.taskCode,
  });

  final String taskId;
  final String title;
  final String description;
  final TaskType taskType;
  final TaskStatus status;
  final double suggestedTip;
  final double escrowAmount;
  final String? runnerId;
  final String? photoProofToken;
  final String? creatorId;
  final int pickupFloor;
  final int dropoffFloor;
  final bool pickupHasElevator;
  final bool dropoffHasElevator;
  final double weightKg;
  final double? pickupLatitude;
  final double? pickupLongitude;
  final double? dropoffLatitude;
  final double? dropoffLongitude;
  final bool isCreator;
  final bool isRunner;
  final bool isPublic;
  final String? taskCode;

  TaskRecord copyWith({
    TaskStatus? status,
    String? runnerId,
    String? photoProofToken,
  }) {
    return TaskRecord(
      taskId: taskId,
      title: title,
      description: description,
      taskType: taskType,
      status: status ?? this.status,
      suggestedTip: suggestedTip,
      escrowAmount: escrowAmount,
      runnerId: runnerId ?? this.runnerId,
      photoProofToken: photoProofToken ?? this.photoProofToken,
      creatorId: creatorId,
      pickupFloor: pickupFloor,
      dropoffFloor: dropoffFloor,
      pickupHasElevator: pickupHasElevator,
      dropoffHasElevator: dropoffHasElevator,
      weightKg: weightKg,
      pickupLatitude: pickupLatitude,
      pickupLongitude: pickupLongitude,
      dropoffLatitude: dropoffLatitude,
      dropoffLongitude: dropoffLongitude,
      isCreator: isCreator,
      isRunner: isRunner,
      isPublic: isPublic,
      taskCode: taskCode,
    );
  }

  factory TaskRecord.fromJson(Map<String, dynamic> json) {
    return TaskRecord(
      taskId: json['taskId'].toString(),
      title: json['title']?.toString() ?? '新任务',
      description: json['description']?.toString() ?? '',
      taskType: TaskType.fromApi(json['taskType']?.toString() ?? 'ERRAND'),
      status: TaskStatus.fromApi(json['status']?.toString() ?? 'OPEN'),
      suggestedTip: (json['suggestedTip'] as num?)?.toDouble() ?? 0,
      escrowAmount: (json['escrowAmount'] as num?)?.toDouble() ?? 0,
      runnerId: json['runnerId']?.toString(),
      photoProofToken: json['photoProofToken']?.toString(),
      creatorId: json['creatorId']?.toString(),
      pickupFloor: (json['pickupFloor'] as num?)?.toInt() ?? 1,
      dropoffFloor: (json['dropoffFloor'] as num?)?.toInt() ?? 1,
      pickupHasElevator: json['pickupHasElevator'] != false,
      dropoffHasElevator: json['dropoffHasElevator'] != false,
      weightKg: (json['weightKg'] as num?)?.toDouble() ?? 0,
      pickupLatitude: (json['pickupLatitude'] as num?)?.toDouble(),
      pickupLongitude: (json['pickupLongitude'] as num?)?.toDouble(),
      dropoffLatitude: (json['dropoffLatitude'] as num?)?.toDouble(),
      dropoffLongitude: (json['dropoffLongitude'] as num?)?.toDouble(),
      isCreator: json['isCreator'] == true,
      isRunner: json['isRunner'] == true,
      isPublic: json['isPublic'] != false,
      taskCode: json['taskCode']?.toString(),
    );
  }
}

class TaskAcceptResult {
  const TaskAcceptResult({
    required this.taskId,
    required this.orderId,
    required this.status,
    required this.runnerId,
  });

  final String taskId;
  final String orderId;
  final TaskStatus status;
  final String runnerId;

  factory TaskAcceptResult.fromJson(Map<String, dynamic> json) {
    return TaskAcceptResult(
      taskId: json['taskId'].toString(),
      orderId: json['orderId'].toString(),
      status: TaskStatus.fromApi(json['status']?.toString() ?? 'ACCEPTED'),
      runnerId: json['runnerId'].toString(),
    );
  }
}

class TaskStatusSnapshot {
  const TaskStatusSnapshot({
    required this.taskId,
    required this.status,
    this.proofToken,
  });

  final String taskId;
  final TaskStatus status;
  final String? proofToken;

  factory TaskStatusSnapshot.fromJson(Map<String, dynamic> json) {
    return TaskStatusSnapshot(
      taskId: json['taskId'].toString(),
      status: TaskStatus.fromApi(json['status']?.toString() ?? 'OPEN'),
      proofToken: json['proofToken']?.toString(),
    );
  }
}

class TaskSettlement {
  const TaskSettlement({
    required this.taskId,
    required this.orderId,
    required this.grossAmount,
    required this.platformFee,
    required this.runnerPayout,
  });

  final String taskId;
  final String orderId;
  final double grossAmount;
  final double platformFee;
  final double runnerPayout;

  factory TaskSettlement.fromJson(Map<String, dynamic> json) {
    return TaskSettlement(
      taskId: json['taskId'].toString(),
      orderId: json['orderId'].toString(),
      grossAmount: (json['grossAmount'] as num?)?.toDouble() ?? 0,
      platformFee: (json['platformFee'] as num?)?.toDouble() ?? 0,
      runnerPayout: (json['runnerPayout'] as num?)?.toDouble() ?? 0,
    );
  }
}
