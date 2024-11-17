import 'package:flutter/material.dart';

class TabDragBrakeController extends ChangeNotifier {
  int _counter = 0;

  bool get isOn => _counter > 0;

  void brake() {
    ++_counter;
    notifyListeners();
  }

  void unbrake() {
    if (_counter > 0) {
      --_counter;
      notifyListeners();
    }
  }
}

class TabDragBrake extends StatefulWidget {
  final Widget child;
  final TabDragBrakeController controller;

  const TabDragBrake({
    super.key,
    required this.controller,
    required this.child,
  });

  @override
  State<TabDragBrake> createState() => _TabDragBrakeState();

  static TabDragBrakeController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_TabDragBrake>()
        ?.controller;
  }

  static TabDragBrakeController of(BuildContext context) {
    return maybeOf(context)!;
  }
}

class _TabDragBrakeState extends State<TabDragBrake> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_update);
  }

  @override
  void dispose() {
    super.dispose();
    widget.controller.removeListener(_update);
  }

  void _update() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return _TabDragBrake(
      controller: widget.controller,
      isOn: widget.controller.isOn,
      child: widget.child,
    );
  }
}

class _TabDragBrake extends InheritedWidget {
  final TabDragBrakeController controller;
  final bool isOn;

  const _TabDragBrake({
    required this.controller,
    required this.isOn,
    required super.child,
  });

  @override
  bool updateShouldNotify(covariant _TabDragBrake oldWidget) =>
      oldWidget.isOn != isOn;
}
