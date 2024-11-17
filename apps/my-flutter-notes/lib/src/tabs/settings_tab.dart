import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:my_flutter_notes/src/widgets/app_settings.dart';
import 'package:my_flutter_notes/src/widgets/theme_mode_selector.dart';

class SettingsTab extends ConsumerWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final titleStyle = Theme.of(context).textTheme.headlineMedium!;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('App', style: titleStyle),
          const SizedBox(height: 16.0),
          const AppSettings(),
          const SizedBox(height: 16.0),
          Text('Display', style: titleStyle),
          const SizedBox(height: 16.0),
          const ThemeModeSelector(),
        ],
      ),
    );
  }
}
