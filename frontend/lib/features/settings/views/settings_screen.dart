import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../chat/providers/chat_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _urlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Pre-populate with current baseUrl
    final provider = context.read<ChatProvider>();
    _urlController.text = provider.baseUrl;
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _saveSettings() {
    final provider = context.read<ChatProvider>();
    final newUrl = _urlController.text.trim();
    if (newUrl.isNotEmpty) {
      provider.updateBaseUrl(newUrl);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Configurações salvas: $newUrl'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Geral',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accent,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              
              // Mock Mode Switch Card
              Card(
                child: Consumer<ChatProvider>(
                  builder: (context, provider, _) {
                    return SwitchListTile(
                      title: const Text(
                        'Modo Mock (Simulado)',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: const Text(
                        'Respostas simuladas localmente. Desative para conectar ao backend real.',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                      value: provider.useMockMode,
                      activeColor: AppColors.primary,
                      onChanged: (bool value) {
                        provider.toggleMockMode(value);
                      },
                    );
                  },
                ),
              ),
              
              const SizedBox(height: 24),
              const Text(
                'Servidor Backend (FastAPI)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accent,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),

              // Server URL Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Endereço do Servidor',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Insira a URL correspondente à sua API Python.',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _urlController,
                        decoration: const InputDecoration(
                          hintText: 'http://localhost:8000',
                          prefixIcon: Icon(Icons.dns_outlined, color: AppColors.textMuted),
                        ),
                        style: const TextStyle(color: AppColors.textPrimary),
                        keyboardType: TextInputType.url,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveSettings,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Salvar Alterações'),
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Project Info Card
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.settings_suggest_outlined,
                      size: 40,
                      color: AppColors.textMuted.withOpacity(0.5),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Trabalho Final POO • Atendente IA',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'v1.0.0 (Boilerplate)',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
