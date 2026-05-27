import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/chat/models/message.dart';

void main() {
  test('Message.fromJson parses backend message contract', () {
    final message = Message.fromJson({
      'id': 42,
      'conversation_id': 7,
      'role': 'user',
      'content': 'Tenho interesse em uma moto',
      'created_at': '2026-05-25T10:15:30',
    });

    expect(message.id, '42');
    expect(message.content, 'Tenho interesse em uma moto');
    expect(message.isUser, isTrue);
    expect(message.timestamp, DateTime.parse('2026-05-25T10:15:30'));
  });

  test('Message.fromJson keeps compatibility with old local shape', () {
    final message = Message.fromJson({
      'id': 'local-1',
      'is_user': false,
      'content': 'Resposta local',
      'timestamp': '2026-05-25T11:00:00',
    });

    expect(message.id, 'local-1');
    expect(message.isUser, isFalse);
    expect(message.timestamp, DateTime.parse('2026-05-25T11:00:00'));
  });
}
