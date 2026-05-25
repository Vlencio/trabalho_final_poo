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
    return Message(
      id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      content: json['content'] as String? ?? '',
      isUser: json['is_user'] as bool? ?? false,
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp'] as String) 
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
