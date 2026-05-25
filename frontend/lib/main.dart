import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'features/chat/providers/chat_provider.dart';
import 'features/chat/views/chat_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: MaterialApp(
        title: 'Atendente IA',
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.dark, // Enforce dark theme for premium vibes
        darkTheme: AppTheme.darkTheme,
        theme: AppTheme.darkTheme, // Fallback to darkTheme in light configurations too
        home: const ChatScreen(),
      ),
    );
  }
}
