import '../../../core/network/api_client.dart';
import '../domain/task_models.dart';

class TaskRepository {
  const TaskRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<List<NearbyTask>> fetchNearbyTasks({
    required double latitude,
    required double longitude,
  }) async {
    final data =
        await _apiClient.get(
              '/tasks/nearby',
              queryParameters: {'latitude': latitude, 'longitude': longitude},
            )
            as List<dynamic>;
    return data
        .whereType<Map<String, dynamic>>()
        .map(NearbyTask.fromJson)
        .toList();
  }

  Future<TaskRecord> createTask(CreateTaskPayload payload) async {
    final data =
        await _apiClient.post('/tasks', data: payload.toJson())
            as Map<String, dynamic>;
    return TaskRecord.fromJson(data);
  }

  Future<TaskRecord> fetchTask(String taskId) async {
    final data = await _apiClient.get('/tasks/$taskId') as Map<String, dynamic>;
    return TaskRecord.fromJson(data);
  }

  Future<List<TaskRecord>> fetchMyTasks() async {
    final data = await _apiClient.get('/tasks/mine') as List<dynamic>;
    return data
        .whereType<Map<String, dynamic>>()
        .map(TaskRecord.fromJson)
        .toList();
  }

  Future<TaskAcceptResult> acceptTask({
    required String taskId,
    required double latitude,
    required double longitude,
  }) async {
    final data =
        await _apiClient.post(
              '/tasks/$taskId/accept',
              queryParameters: {'latitude': latitude, 'longitude': longitude},
            )
            as Map<String, dynamic>;
    return TaskAcceptResult.fromJson(data);
  }

  Future<TaskAcceptResult> acceptTaskByCode({
    required String taskCode,
    required double latitude,
    required double longitude,
  }) async {
    final data =
        await _apiClient.post(
              '/tasks/by-code/${Uri.encodeComponent(taskCode.trim())}/accept',
              queryParameters: {'latitude': latitude, 'longitude': longitude},
            )
            as Map<String, dynamic>;
    return TaskAcceptResult.fromJson(data);
  }

  Future<TaskStatusSnapshot> updateTaskStatus({
    required String taskId,
    required TaskStatus targetStatus,
    String? proofToken,
  }) async {
    final data =
        await _apiClient.post(
              '/tasks/$taskId/update-status',
              data: {
                'targetStatus': targetStatus.apiValue,
                if (proofToken != null && proofToken.isNotEmpty)
                  'proofToken': proofToken,
              },
            )
            as Map<String, dynamic>;
    return TaskStatusSnapshot.fromJson(data);
  }

  Future<TaskSettlement> confirmTask(String taskId) async {
    final data =
        await _apiClient.post('/tasks/$taskId/confirm') as Map<String, dynamic>;
    return TaskSettlement.fromJson(data);
  }

  Future<TaskRecord> cancelTask(String taskId) async {
    final data =
        await _apiClient.post('/tasks/$taskId/cancel') as Map<String, dynamic>;
    return TaskRecord.fromJson(data);
  }
}
