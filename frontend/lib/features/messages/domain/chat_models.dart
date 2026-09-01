class ChatMessage {
  const ChatMessage({
    required this.messageId,
    required this.taskId,
    required this.senderId,
    required this.receiverId,
    required this.body,
    required this.createdAt,
    this.readAt,
  });

  final String messageId;
  final String? taskId;
  final String senderId;
  final String receiverId;
  final String body;
  final DateTime createdAt;
  final DateTime? readAt;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      messageId: json['messageId'].toString(),
      taskId: json['taskId']?.toString(),
      senderId: json['senderId'].toString(),
      receiverId: json['receiverId'].toString(),
      body: json['body']?.toString() ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      readAt: DateTime.tryParse(json['readAt']?.toString() ?? ''),
    );
  }
}
