import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/settings_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sozlamalar')),
      body: Consumer<SettingsService>(
        builder: (context, settings, _) {
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // Til tanlash
              const Text('Ilova tili', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButton<Locale>(
                value: settings.locale,
                items: const [
                  DropdownMenuItem(value: Locale('uz'), child: Text('Oʻzbekcha')),
                  DropdownMenuItem(value: Locale('ru'), child: Text('Русский')),
                  DropdownMenuItem(value: Locale('en'), child: Text('English')),
                ],
                onChanged: (val) {
                  if (val != null) settings.setLocale(val);
                },
              ),
              const SizedBox(height: 24),
              SwitchListTile(
                title: const Text('Tungi rejim (Dark mode)'),
                value: settings.themeMode == ThemeMode.dark,
                onChanged: (val) => settings.toggleTheme(val),
              ),
              const SizedBox(height: 24),
              SwitchListTile(
                title: const Text('Bildirishnomalar'),
                value: settings.notificationsEnabled,
                onChanged: (val) => settings.setNotificationsEnabled(val),
              ),
            ],
          );
        },
      ),
    );
  }
} 