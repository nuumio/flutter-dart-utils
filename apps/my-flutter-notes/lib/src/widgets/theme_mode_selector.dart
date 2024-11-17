import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:my_flutter_notes/src/flutter/theme_mode.dart';
import 'package:my_flutter_notes/src/providers/display_settings_provider.dart';

class ThemeModeSelector extends ConsumerWidget {
  const ThemeModeSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displaySettings = ref.watch(displaySettingsProvider);

    return DropdownMenu(
      initialSelection: displaySettings.themeMode,
      label: const Text('Theme mode'),
      onSelected: (value) {
        if (value != null) {
          ref.read(displaySettingsProvider.notifier).setThemeMode(value);
        }
      },
      requestFocusOnTap: false,
      dropdownMenuEntries: ThemeMode.values
          .map(
            (mode) => DropdownMenuEntry(
              value: mode,
              label: mode.label,
            ),
          )
          .toList(),
    );
  }
}
