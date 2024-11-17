import 'package:flutter/material.dart';

class LabeledTextBox extends StatelessWidget {
  final String label;
  final String text;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool? isDense;
  final EdgeInsetsGeometry? contentPadding;

  const LabeledTextBox({
    super.key,
    required this.label,
    required this.text,
    this.maxLines,
    this.overflow,
    this.isDense,
    this.contentPadding,
  });

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        isDense: isDense,
        border: const OutlineInputBorder(),
        labelText: label,
        contentPadding: contentPadding,
      ),
      child: Text(
        text,
        maxLines: maxLines,
        overflow: overflow,
      ),
    );
  }
}
