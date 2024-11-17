import 'package:dropdown_menu2/dropdown_menu2.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:my_flutter_notes/src/constants.dart';
import 'package:my_flutter_notes/src/providers/counter_provider.dart';
import 'package:my_flutter_notes/src/providers/enabled_provider.dart';
import 'package:my_flutter_notes/src/providers/error_provider.dart';
import 'package:my_flutter_notes/src/widgets/auto_checkbox.dart';
import 'package:my_flutter_notes/src/widgets/labeled_text_box.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

const choices = ['Choice 1', 'Choice 2', 'Choice 3'];

class WidgetsTab extends ConsumerStatefulWidget {
  const WidgetsTab({super.key});

  @override
  ConsumerState<WidgetsTab> createState() => _WidgetsTabState();
}

class _WidgetsTabState extends ConsumerState<WidgetsTab> {
  final _boolNotifiers = <String, ValueNotifier<bool>>{};
  final _stringNotifiers = <String, ValueNotifier<String>>{};

  @override
  void dispose() {
    super.dispose();
    for (final controller in _boolNotifiers.values) {
      controller.dispose();
    }
    for (final controller in _stringNotifiers.values) {
      controller.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final counter = ref.watch(counterProvider);
    final error = ref.watch(errorProvider);
    final enabled = ref.watch(enabledProvider);

    final theme = Theme.of(context);

    // NOTE: Scaffolds are not typically nested. Doing it to make FAB show up in
    // this tab only (with animations and all). Real app would probably use a
    // "FAB controller" of some sort.
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(mainAxisAlignment: MainAxisAlignment.start, children: [
          _buildWidgetRow(
            label: 'Non-dense',
            isDense: false,
            enabled: enabled,
            error: error,
            counter: counter,
            theme: theme,
          ),
          const SizedBox(height: 16.0),
          _buildWidgetRow(
            label: 'Dense',
            isDense: true,
            enabled: enabled,
            error: error,
            counter: counter,
            theme: theme,
          ),
        ]),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: enabled
            ? () => ref.read(counterProvider.notifier).increment()
            : null,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildWidgetRow({
    required String label,
    required bool isDense,
    required bool enabled,
    required bool error,
    required int counter,
    required ThemeData theme,
  }) {
    final infoStyle = theme.textTheme.bodySmall!.copyWith(
      fontStyle: FontStyle.italic,
    );

    return InputDecorator(
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        // Increasing top padding from default 20.0 to 28.0 so that nested
        // decorations with labels look better.
        contentPadding: const EdgeInsets.fromLTRB(12.0, 28.0, 12.0, 12.0),
        labelText: label,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Column(
              children: [
                Text(
                  'Just text with border',
                  maxLines: 1,
                  style: infoStyle,
                ),
                const SizedBox(height: 8),
                LabeledTextBox(
                  isDense: isDense,
                  // Increasing top padding from default 16.0 to 20.0 so that the
                  // size matches TextField with dense decorator.
                  contentPadding:
                      isDense ? const EdgeInsets.fromLTRB(12, 20, 12, 8) : null,
                  label: 'Counter',
                  text: '$counter',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 150,
            child: Column(
              children: [
                const _Info('TextField with border'),
                const SizedBox(height: 8),
                TextField(
                  decoration: InputDecoration(
                    isDense: isDense,
                    border: const OutlineInputBorder(),
                    labelText: 'Input something',
                    errorText: error ? 'Error message' : null,
                  ),
                  keyboardType: TextInputType.number,
                  enabled: enabled,
                  onChanged: enabled ? (value) {} : null,
                  onSubmitted: enabled ? (value) {} : null,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            children: [
              const _Info('Checkbox'),
              const SizedBox(height: 8),
              Padding(
                padding: isDense
                    ? const EdgeInsets.only(top: 4.0)
                    : const EdgeInsets.only(top: 8.0),
                child: _getCheckbox(label, enabled, error),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Column(
            children: [
              const _Info(
                'Flutter DropDownMenu',
                tooltip:
                    'Default Flutter\'s DropDownMenu. Dense version is a\nreal '
                    'hack and still doesn\'t work right. Try showing error\n'
                    'text and see how content text get misaligned.',
              ),
              const SizedBox(height: 8),
              _getDropdown(label, isDense, theme, enabled, error),
            ],
          ),
          const SizedBox(width: 16),
          Column(
            children: [
              const _Info(
                'Fixed DropDownMenu2',
                tooltip: 'Fixed DropDownMenu2 is just a copy of Flutter\'s '
                    'DropDownMenu\nwith a minor fix. Dense version works '
                    'great!',
              ),
              const SizedBox(height: 8),
              _getDropdown2(label, isDense, theme, enabled, error),
            ],
          ),
        ],
      ),
    );
  }

  Widget _getCheckbox(String label, bool enabled, bool error) {
    final controller = _boolNotifiers.putIfAbsent(
      label,
      () => ValueNotifier(false),
    );

    return AutoCheckbox(
      notifier: controller,
      onChanged: enabled ? (value) => controller.value = value! : null,
      isError: error,
    );
  }

  Widget _getDropdown(
    String label,
    bool isDense,
    ThemeData theme,
    bool enabled,
    bool error,
  ) {
    return DropdownMenu(
      // TODO: Figure out how to make this work with error text. Content text
      //  doesn't align properly when error text is present. There was also some
      //  misplacement on the icon which could be fixed with Transform.
      inputDecorationTheme: isDense
          ? InputDecorationTheme(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12.0),
              constraints:
                  BoxConstraints.tight(Size.fromHeight(error ? 60.0 : 40.0)),
              border: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(4.0)),
              ),
            )
          : null,
      errorText: error ? 'Error message' : null,
      initialSelection: choices.first,
      // Trailing icon gets offset when dense decoration is added. Transform it
      // back to its place. NOTE: When error message is present, the icon is
      // placed correctly and no Transform is required!
      trailingIcon: isDense && !error
          ? Transform(
              transform: Matrix4.translation(Vector3(0, -4, 0)),
              child: const Icon(
                Icons.arrow_drop_down,
              ),
            )
          : null,
      selectedTrailingIcon: isDense && !error
          ? Transform(
              transform: Matrix4.translation(Vector3(0, -4, 0)),
              child: const Icon(
                Icons.arrow_drop_up,
              ),
            )
          : null,
      enabled: enabled,
      textStyle: enabled
          ? null
          // DropdownMenu doesn't dim text when disabled, so we do it manually.
          : theme.textTheme.bodyLarge!.copyWith(
              color: theme.colorScheme.onSurface
                  .withOpacity(kDefaultDisabledOpacity),
            ),
      requestFocusOnTap: false,
      dropdownMenuEntries: choices.map((choice) {
        return DropdownMenuEntry(
          value: choice,
          label: choice,
        );
      }).toList(),
    );
  }

  Widget _getDropdown2(
    String label,
    bool isDense,
    ThemeData theme,
    bool enabled,
    bool error,
  ) {
    return DropdownMenu2(
      inputDecorationTheme: isDense
          ? InputDecorationTheme(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12.0),
              constraints:
                  BoxConstraints.tight(Size.fromHeight(error ? 60.0 : 40.0)),
              border: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(4.0)),
              ),
            )
          : null,
      errorText: error ? 'Error message' : null,
      initialSelection: choices.first,
      enabled: enabled,
      requestFocusOnTap: false,
      dropdownMenuEntries: choices.map((choice) {
        return DropdownMenuEntry(
          value: choice,
          label: choice,
        );
      }).toList(),
    );
  }
}

class _Info extends StatelessWidget {
  final String text;
  final String? tooltip;

  const _Info(this.text, {super.key, this.tooltip});

  @override
  Widget build(BuildContext context) {
    final infoStyle = Theme.of(context).textTheme.bodySmall!.copyWith(
          fontStyle: FontStyle.italic,
        );

    final textWidget = Text(
      text,
      maxLines: 1,
      style: infoStyle,
    );
    final infoPart = tooltip != null
        ? Row(
            children: [
              textWidget,
              const SizedBox(width: 4),
              Icon(Icons.info, size: infoStyle.fontSize ?? 16),
            ],
          )
        : textWidget;
    return tooltip != null
        ? Tooltip(
            message: tooltip!,
            child: infoPart,
          )
        : infoPart;
  }
}
