import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:my_flutter_notes/src/widgets/auto_checkbox.dart';

/// 40.0 comes from Checkbox Material 3 default splash radius which is 40.0 / 2
/// in Flutter (see [Checkbox] and it's [_CheckboxState.build] code which has
/// `effectiveSplashRadius` variable).
/// NOTE: There's also [kMinInteractiveDimension] which is 48.0!
const _kCheckboxSize = 40.0;

class CheckboxColumnData {
  final String label;
  final bool value;
  final void Function(bool value)? onChanged;

  const CheckboxColumnData({
    required this.label,
    required this.value,
    this.onChanged,
  });

  @override
  int get hashCode => Object.hash(label, value);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is CheckboxColumnData &&
        other.label == label &&
        other.value == value;
  }
}

class CheckboxColumnController with ChangeNotifier {
  final List<CheckboxColumnData> _data;
  final TextStyle? style;
  late TextStyle? _defaultStyle;
  final List<TextPainter> _painters = [];
  late double rowHeight;
  late double rowWidth;
  late double maxTextWidth;
  late Size layoutSize;
  final List<Widget> _checkboxes = [];
  final List<ValueNotifier<bool>> _checkboxValues;
  final void Function(int index, bool value)? onChanged;

  CheckboxColumnController({
    this.style,
    required List<CheckboxColumnData> data,
    required BuildContext context,
    this.onChanged,
  })  : _data = data,
        _checkboxValues =
            data.map((data) => ValueNotifier(data.value)).toList() {
    _update(context: context);
  }

  void _update({required BuildContext context, bool textOnly = false}) {
    _defaultStyle = _defaultStyleOf(context);
    _layout(textOnly: textOnly);
  }

  @override
  void dispose() {
    super.dispose();
    _disposeInternal();
  }

  void _disposeInternal() {
    _disposePainters();
    for (final value in _checkboxValues) {
      value.dispose();
    }
    _checkboxValues.clear();
  }

  void _disposePainters() {
    for (final painter in _painters) {
      painter.dispose();
    }
    _painters.clear();
  }

  void _layout({bool textOnly = false}) {
    double maxWidth = 0;
    double maxHeight = 0;
    _disposePainters();
    for (final data in _data) {
      final painter = TextPainter(
        text: TextSpan(
          text: data.label,
          style: style ?? _defaultStyle,
        ),
        textDirection: TextDirection.ltr,
      );
      painter.layout();
      _painters.add(painter);
      maxWidth = max(maxWidth, painter.width);
      maxHeight = max(maxHeight, painter.height);
    }
    maxTextWidth = maxWidth;
    rowHeight = max(maxHeight, _kCheckboxSize);
    rowWidth = maxWidth + _kCheckboxSize;

    layoutSize = Size(rowWidth, rowHeight * _data.length);

    if (textOnly) {
      return;
    }

    _checkboxes.clear();
    _checkboxes.addAll(
      _data.mapIndexed(
        (i, d) => Positioned(
          left: maxTextWidth,
          top: i * rowHeight + rowHeight / 2 - _kCheckboxSize / 2,
          width: _kCheckboxSize,
          height: _kCheckboxSize,
          child: AutoCheckbox(
            notifier: _checkboxValues[i],
            onChanged: (value) {
              onChanged?.call(i, value!);
              d.onChanged?.call(value!);
            },
          ),
        ),
      ),
    );
  }

  void setValueAt(int i, bool value) {
    _checkboxValues[i].value = value;
  }

  static _defaultStyleOf(BuildContext context) =>
      Theme.of(context).textTheme.bodyMedium!.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          );
}

class CheckboxColumn extends StatelessWidget {
  final CheckboxColumnController controller;

  const CheckboxColumn({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return _CheckboxColumn(
      controller: controller,
      defaultStyle: CheckboxColumnController._defaultStyleOf(context),
    );
  }
}

class _CheckboxColumn extends StatefulWidget {
  final CheckboxColumnController controller;
  final TextStyle defaultStyle;

  const _CheckboxColumn({
    required this.controller,
    required this.defaultStyle,
  });

  @override
  State<_CheckboxColumn> createState() => _CheckboxColumnState();
}

class _CheckboxColumnState extends State<_CheckboxColumn> {
  late final _CheckboxColumnPainter _painter;
  final _repaintNotifier = _RepaintNotifier();

  @override
  void initState() {
    super.initState();
    _painter = _CheckboxColumnPainter(
      repaint: _repaintNotifier,
      controller: widget.controller,
    );
  }

  @override
  void dispose() {
    super.dispose();
    _repaintNotifier.dispose();
  }

  @override
  void didUpdateWidget(covariant _CheckboxColumn oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.defaultStyle != widget.defaultStyle) {
      widget.controller._update(context: context);
      _repaintNotifier.notify();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        RepaintBoundary(
          child: CustomPaint(
            painter: _painter,
            size: widget.controller.layoutSize,
          ),
        ),
        ...widget.controller._checkboxes,
      ],
    );
  }
}

class _CheckboxColumnPainter extends CustomPainter {
  final CheckboxColumnController controller;

  _CheckboxColumnPainter({
    super.repaint,
    required this.controller,
  });

  @override
  void paint(Canvas canvas, Size size) {
    int i = 0;
    for (final painter in controller._painters) {
      painter.paint(
        canvas,
        Offset(
          controller.maxTextWidth - painter.width,
          i * controller.rowHeight +
              controller.rowHeight / 2 -
              painter.height / 2,
        ),
      );
      i++;
    }
  }

  @override
  bool shouldRepaint(covariant _CheckboxColumnPainter oldDelegate) =>
      oldDelegate.controller._data != controller._data ||
      oldDelegate.controller.style != controller.style;
}

class _RepaintNotifier extends ChangeNotifier {
  void notify() {
    notifyListeners();
  }
}
