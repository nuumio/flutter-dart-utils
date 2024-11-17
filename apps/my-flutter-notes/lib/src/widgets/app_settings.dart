import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:my_flutter_notes/src/providers/enabled_provider.dart';
import 'package:my_flutter_notes/src/providers/error_provider.dart';
import 'package:my_flutter_notes/src/widgets/checkbox_column.dart';

class AppSettings extends ConsumerStatefulWidget {
  final bool expands;
  const AppSettings({super.key, this.expands = false});

  @override
  ConsumerState<AppSettings> createState() => _AppSettingsState();
}

class _AppSettingsState extends ConsumerState<AppSettings> {
  CheckboxColumnController? controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final error = ref.read(errorProvider);
    final enabled = ref.read(enabledProvider);

    controller ??= CheckboxColumnController(
      context: context,
      data: [
        CheckboxColumnData(
          label: 'Enabled',
          value: enabled,
          onChanged: (value) =>
              ref.read(enabledProvider.notifier).setEnabled(value),
        ),
        CheckboxColumnData(
          label: 'Error',
          value: error,
          onChanged: (value) =>
              ref.read(errorProvider.notifier).setError(value),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(enabledProvider, (prev, next) {
      controller?.setValueAt(0, next);
    });
    ref.listen(errorProvider, (prev, next) {
      controller?.setValueAt(1, next);
    });

    // From InputDecoration.contentPadding: M3 / non-dense
    const paddingX = 24.0;

    return SizedBox(
      width: widget.expands
          ? double.infinity
          : controller!.layoutSize.width + paddingX,
      child: InputDecorator(
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'Widget states',
        ),
        child: CheckboxColumn(
          controller: controller!,
        ),
      ),
    );
  }
}
