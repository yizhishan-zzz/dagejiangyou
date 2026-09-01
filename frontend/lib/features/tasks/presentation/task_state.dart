import 'package:flutter/foundation.dart';

import '../../../core/config/app_settings.dart';
import '../../../core/network/api_client.dart';
import '../data/task_repository.dart';
import '../domain/task_models.dart';

class TaskState extends ChangeNotifier {
  TaskState({required this.settings, required this.repository});

  final AppSettings settings;
  final TaskRepository repository;

  List<NearbyTask> nearbyTasks = const [];
  List<TaskRecord> myTasks = const [];
  TaskRecord? trackedTask;
  TaskSettlement? lastSettlement;
  bool isRefreshing = false;
  bool isPublishing = false;
  bool isMutating = false;
  String? errorMessage;

  void clear() {
    nearbyTasks = const [];
    myTasks = const [];
    trackedTask = null;
    lastSettlement = null;
    errorMessage = null;
    notifyListeners();
  }

  Future<void> refreshNearby() async {
    if (!settings.isLoggedIn) return;
    isRefreshing = true;
    notifyListeners();
    try {
      nearbyTasks = await repository.fetchNearbyTasks(
        latitude: settings.latitude,
        longitude: settings.longitude,
      );
      errorMessage = null;
    } on ApiException catch (error) {
      errorMessage = error.message;
    } finally {
      isRefreshing = false;
      notifyListeners();
    }
  }

  Future<void> refreshMyTasks() async {
    if (!settings.isLoggedIn) return;
    try {
      myTasks = await repository.fetchMyTasks();
      final current = trackedTask;
      if (current != null) {
        trackedTask = myTasks
            .where((task) => task.taskId == current.taskId)
            .firstOrNull;
      }
      errorMessage = null;
    } on ApiException catch (error) {
      errorMessage = error.message;
    }
    notifyListeners();
  }

  Future<TaskRecord?> loadTaskDetail(String taskId) async {
    try {
      final task = await repository.fetchTask(taskId);
      trackedTask = task;
      errorMessage = null;
      notifyListeners();
      return task;
    } on ApiException catch (error) {
      errorMessage = error.message;
      notifyListeners();
      return null;
    }
  }

  Future<bool> publishTask(CreateTaskPayload payload) async {
    isPublishing = true;
    notifyListeners();
    try {
      trackedTask = await repository.createTask(payload);
      lastSettlement = null;
      errorMessage = null;
      await refreshNearby();
      await refreshMyTasks();
      return true;
    } on ApiException catch (error) {
      errorMessage = error.message;
      return false;
    } finally {
      isPublishing = false;
      notifyListeners();
    }
  }

  Future<void> acceptTask(NearbyTask task) async {
    await acceptTaskId(task.taskId);
  }

  Future<void> acceptTaskId(String taskId) async {
    isMutating = true;
    notifyListeners();
    try {
      await repository.acceptTask(
        taskId: taskId,
        latitude: settings.latitude,
        longitude: settings.longitude,
      );
      await loadTaskDetail(taskId);
      await refreshNearby();
      await refreshMyTasks();
    } on ApiException catch (error) {
      errorMessage = error.message;
    } finally {
      isMutating = false;
      notifyListeners();
    }
  }

  Future<bool> acceptTaskByCode(String taskCode) async {
    if (taskCode.trim().isEmpty) {
      errorMessage = '请输入任务码';
      notifyListeners();
      return false;
    }
    isMutating = true;
    errorMessage = null;
    notifyListeners();
    try {
      final result = await repository.acceptTaskByCode(
        taskCode: taskCode,
        latitude: settings.latitude,
        longitude: settings.longitude,
      );
      await loadTaskDetail(result.taskId);
      await refreshNearby();
      await refreshMyTasks();
      return true;
    } on ApiException catch (error) {
      errorMessage = error.message;
      return false;
    } finally {
      isMutating = false;
      notifyListeners();
    }
  }

  Future<void> updateTrackedTaskStatus(
    TaskStatus status, {
    String? proofToken,
  }) async {
    final current = trackedTask;
    if (current == null) return;
    isMutating = true;
    notifyListeners();
    try {
      await repository.updateTaskStatus(
        taskId: current.taskId,
        targetStatus: status,
        proofToken: proofToken,
      );
      await loadTaskDetail(current.taskId);
      await refreshMyTasks();
      errorMessage = null;
    } on ApiException catch (error) {
      errorMessage = error.message;
    } finally {
      isMutating = false;
      notifyListeners();
    }
  }

  Future<void> confirmTrackedTask() async {
    final current = trackedTask;
    if (current == null) return;
    isMutating = true;
    notifyListeners();
    try {
      lastSettlement = await repository.confirmTask(current.taskId);
      await loadTaskDetail(current.taskId);
      await refreshNearby();
      await refreshMyTasks();
      errorMessage = null;
    } on ApiException catch (error) {
      errorMessage = error.message;
    } finally {
      isMutating = false;
      notifyListeners();
    }
  }

  Future<void> cancelTask(String taskId) async {
    isMutating = true;
    notifyListeners();
    try {
      trackedTask = await repository.cancelTask(taskId);
      await refreshNearby();
      await refreshMyTasks();
      errorMessage = null;
    } on ApiException catch (error) {
      errorMessage = error.message;
    } finally {
      isMutating = false;
      notifyListeners();
    }
  }
}
