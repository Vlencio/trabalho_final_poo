class Message {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;

  Message({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    final role = json['role'] as String?;
    final isUserValue = json['is_user'];
    final rawTimestamp = json['created_at'] ?? json['timestamp'];

    return Message(
      id: rawId?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      content: json['content'] as String? ?? '',
      isUser: isUserValue is bool ? isUserValue : role == 'user',
      timestamp: rawTimestamp != null
          ? DateTime.parse(rawTimestamp as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'is_user': isUser,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  Message copyWith({
    String? id,
    String? content,
    bool? isUser,
    DateTime? timestamp,
  }) {
    return Message(
      id: id ?? this.id,
      content: content ?? this.content,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
