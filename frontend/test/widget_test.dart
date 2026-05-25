import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';
import 'package:frontend/features/chat/widgets/chat_bubble.dart';
import 'package:frontend/features/chat/widgets/chat_input.dart';

void main() {
  testWidgets('Atendente IA Smoke Test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MainApp());

    // Verify that the title "Atendente IA" is displayed in the AppBar
    expect(find.text('Atendente IA'), findsOneWidget);

    // Verify that the initial welcome greeting is present
    expect(
      find.text('Olá! Sou seu assistente inteligente. Como posso ajudar você hoje?'),
      findsOneWidget
    );

    // Verify that the chat bubble widget is rendered
    expect(find.byType(ChatBubble), findsOneWidget);

    // Verify that the chat input bar is rendered and visible
    expect(find.byType(ChatInput), findsOneWidget);
  });
}
