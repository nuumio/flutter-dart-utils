import 'package:flutter/material.dart';

class AutoCheckbox extends StatefulWidget {
  final ValueNotifier<bool> notifier;
  final void Function(bool? value)? onChanged;
  final bool isError;

  const AutoCheckbox({
    super.key,
    required this.notifier,
    this.onChanged,
    this.isError = false,
  });

  @override
  State<AutoCheckbox> createState() => AutoCheckboxState();
}

class AutoCheckboxState extends State<AutoCheckbox> {
  @override
  void initState() {
    super.initState();
    widget.notifier.addListener(_onValueUpdated);
  }

  @override
  void dispose() {
    super.dispose();
    widget.notifier.removeListener(_onValueUpdated);
  }

  void _onValueUpdated() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return Checkbox(
      value: widget.notifier.value,
      onChanged: widget.onChanged,
      isError: widget.isError,
    );
  }
}
