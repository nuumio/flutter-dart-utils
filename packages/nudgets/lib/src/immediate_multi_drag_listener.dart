// Copyright (c) 2024 Jari Hämäläinen
// SPDX-License-Identifier: MIT

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

class ImmediateMultiDragListener extends StatefulWidget {
  final void Function(DragUpdateDetails details, int pointer)? onDragDown;

  final void Function(DragUpdateDetails details, int pointer)? onDragMove;

  final void Function(DragEndDetails details, int pointer)? onDragEnd;

  final void Function(DragUpdateDetails lastUpdate, int pointer)? onDragCancel;

  final Widget child;

  const ImmediateMultiDragListener({
    super.key,
    this.onDragDown,
    this.onDragMove,
    this.onDragEnd,
    this.onDragCancel,
    required this.child,
  });

  // const ImmediateMultiDragListener({super.key, required this.child});

  @override
  State<ImmediateMultiDragListener> createState() =>
      _ImmediateMultiDragListenerState();
}

class _ImmediateMultiDragListenerState
    extends State<ImmediateMultiDragListener> {
  late final _DragHandler _handler;

  @override
  void initState() {
    super.initState();
    _handler = _DragHandler(
      onDragDown: widget.onDragDown,
      onDragMove: widget.onDragMove,
      onDragEnd: widget.onDragEnd,
      onDragCancel: widget.onDragCancel,
    );
  }

  @override
  Widget build(BuildContext context) {
    return RawGestureDetector(
      gestures: <Type, GestureRecognizerFactory>{
        ImmediateMultiDragGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<
                ImmediateMultiDragGestureRecognizer>(
          () => ImmediateMultiDragGestureRecognizer(),
          (ImmediateMultiDragGestureRecognizer instance) {
            instance.onStart = (Offset offset) {
              if (!mounted) return null;
              RenderBox renderBox = context.findRenderObject() as RenderBox;
              return _handler.onDragGestureStart(offset, renderBox);
            };
          },
        ),
      },
      child: widget.child,
    );
  }
}

class _Drag extends Drag {
  final _DragHandler _handler;
  final int pointer;
  final RenderBox renderBox;
  late DragUpdateDetails _lastDetails;
  int updateCount = 0;

  _Drag({
    required _DragHandler handler,
    required this.pointer,
    required this.renderBox,
  }) : _handler = handler;

  @override
  void update(DragUpdateDetails details) {
    super.update(details);
    _lastDetails = DragUpdateDetails(
      globalPosition: details.globalPosition,
      localPosition: renderBox.globalToLocal(details.globalPosition),
      delta: details.delta,
      primaryDelta: details.primaryDelta,
      sourceTimeStamp: details.sourceTimeStamp,
    );
    if (updateCount == 0) {
      _handler.onDragDown?.call(_lastDetails, pointer);
    } else {
      _handler.onDragMove?.call(_lastDetails, pointer);
    }
    updateCount++;
  }

  @override
  void end(DragEndDetails details) {
    super.end(details);
    // _lastDetails = details;
    _handler.onDragEnd?.call(
        DragEndDetails(
          globalPosition: details.globalPosition,
          localPosition: renderBox.globalToLocal(details.globalPosition),
          velocity: details.velocity,
          primaryVelocity: details.primaryVelocity,
        ),
        pointer);
  }

  @override
  void cancel() {
    super.cancel();
    _handler.onDragCancel?.call(_lastDetails, pointer);
  }
}

class _DragHandler {
  final void Function(DragUpdateDetails details, int pointer)? onDragDown;

  final void Function(DragUpdateDetails details, int pointer)? onDragMove;

  final void Function(DragEndDetails details, int pointer)? onDragEnd;

  final void Function(DragUpdateDetails lastUpdate, int pointer)? onDragCancel;

  int pointer = 0;

  _DragHandler({
    this.onDragDown,
    this.onDragMove,
    this.onDragEnd,
    this.onDragCancel,
  });

  _Drag onDragGestureStart(Offset offset, RenderBox renderBox) {
    return _Drag(handler: this, pointer: ++pointer, renderBox: renderBox);
  }
}
