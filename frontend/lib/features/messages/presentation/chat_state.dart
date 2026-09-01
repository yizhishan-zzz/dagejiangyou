import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../../../core/config/app_settings.dart';
import '../../tasks/domain/task_models.dart';
import '../data/chat_repository.dart';
import '../domain/chat_models.dart';

class ChatState extends ChangeNotifier {
  ChatState({required this.repository, required this.settings});

  final ChatRepository repository;
  final AppSettings settings;

  String get currentUserId => settings.userId;

  List<ChatMessage> messages = const [];
  String? activeTaskId;
  bool isLoading = false;
  bool isSending = false;
  String? errorMessage;

  void clear() {
    messages = const [];
    activeTaskId = null;
    errorMessage = null;
    notifyListeners();
  }

  Future<void> loadForTask(TaskRecord? task, {bool force = false}) async {
    final taskId = task?.taskId;
    if (taskId == null) {
      if (activeTaskId != null || messages.isNotEmpty) {
        activeTaskId = null;
        messages = const [];
        notifyListeners();
      }
      return;
    }
    if (!force && (isLoading || activeTaskId == taskId)) {
      return;
    }
    activeTaskId = taskId;
    isLoading = true;
    notifyListeners();
    try {
      messages = await repository.fetchTaskMessages(taskId);
      errorMessage = null;
    } on ApiException catch (error) {
      errorMessage = error.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> sendForTask(TaskRecord task, String body) async {
    final receiverId = task.isCreator ? task.runnerId : task.creatorId;
    if (receiverId == null || receiverId.isEmpty) {
      errorMessage = '任务接单后才可以与对方沟通';
      notifyListeners();
      return false;
    }
    final text = body.trim();
    if (text.isEmpty) {
      return false;
    }
    isSending = true;
    notifyListeners();
    try {
      final message = await repository.sendTaskMessage(
        taskId: task.taskId,
        receiverId: receiverId,
        body: text,
      );
      messages = [...messages, message];
      errorMessage = null;
      return true;
    } on ApiException catch (error) {
      errorMessage = error.message;
      return false;
    } finally {
      isSending = false;
      notifyListeners();
    }
  }
}
