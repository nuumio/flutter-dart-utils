import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:my_flutter_notes/src/widgets/tab_drag_brake.dart';
import 'package:nudgets/nudgets.dart';

final ballColors = [
  Colors.grey,
  Colors.yellow,
  Colors.cyan,
  Colors.brown,
  Colors.purple,
  Colors.pink,
  Colors.orange,
  Colors.blue,
  Colors.green,
  Colors.red,
];

const _ballCount = 20;
const _ballRadius = 40.0;
// Give some leeway for dragging the balls and tab drag brake on Android.
// A smarter thing to do would be to check what kind of pointer was used
// (mouse, touch, ...).
const _ballDragRadiusLinux = 40.0;
const _ballDragRadiusAndroid = 60.0;
const _ballDragBrakeRadiusLinux = 40.0;
const _ballDragBrakeRadiusAndroid = 100.0;

class MultiTouchTab extends StatefulWidget {
  const MultiTouchTab({super.key});

  @override
  State<MultiTouchTab> createState() => _MultiTouchTabState();
}

class _MultiTouchTabState extends State<MultiTouchTab> {
  _DragController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller ??= _DragController(
      ballCount: _ballCount,
      style: Theme.of(context).textTheme.bodySmall!,
      textBackground: Theme.of(context).colorScheme.surface.withOpacity(0.45),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _controller!.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: LayoutBuilder(builder: (context, constraints) {
        // Origin is at center
        final pointerOffset =
            Offset(constraints.maxWidth / 2, constraints.maxHeight / 2);
        // Rect in which balls must reside. Size if the whole area minus 0.5 for
        // each edge.
        final area = Rect.fromLTWH(
          0.5 - pointerOffset.dx,
          0.5 - pointerOffset.dy,
          constraints.maxWidth - 1,
          constraints.maxHeight - 1,
        );
        _controller!.area = area;

        // Wrap things in a ImmediateMultiDragListener to get the drag events.
        // NOTE: If "the brake" is off tab drags will win over ball drags.
        //       Because of this ImmediateMultiDragListener doesn't get events
        //       until brakes are on (thus the pointer counter doesn't increase
        //       when hitting far outside the balls).
        return ImmediateMultiDragListener(
          onDragDown: (details, pointer) => _controller!
              .startDrag(details.localPosition - pointerOffset, pointer),
          onDragMove: (details, pointer) => _controller!
              .onDragged(details.localPosition - pointerOffset, pointer),
          onDragEnd: (details, pointer) => _controller!.endDrag(pointer),
          onDragCancel: (details, pointer) => _controller!.endDrag(pointer),
          // "Extra" Listener wrap takes care on braking and unbraking the
          // tab dragging so that tab doesn't accidentally change when trying to
          // drag a ball.
          child: Listener(
            onPointerDown: (event) {
              if (_controller!
                  .brake(event.localPosition - pointerOffset, event.pointer)) {
                TabDragBrake.of(context).brake();
              }
            },
            onPointerUp: (event) {
              if (_controller!.unbrake(event.pointer)) {
                TabDragBrake.of(context).unbrake();
              }
            },
            child: CustomPaint(
              painter: _DragPainter(
                  repaint: _controller,
                  controller: _controller!,
                  colorScheme: Theme.of(context).colorScheme),
              // Container stretches the CustomPaint to the whole area. Could
              // also get the size from constraints and pass it to CustomPaint.
              child: Container(),
            ),
          ),
        );
      }),
    );
  }
}

class _DragBall {
  final double radius;
  final double dragRadius;
  final double dragBrakeRadius;
  final Paint outerPaint;
  final Paint paintInner;
  int sortOrder;
  Offset _position;
  Offset _dragOffset = Offset.zero;
  TextPainter? pointerNumber;

  _DragBall({
    required this.radius,
    required this.dragRadius,
    required this.dragBrakeRadius,
    required this.outerPaint,
    required this.paintInner,
    required this.sortOrder,
    Offset position = Offset.zero,
  }) : _position = position;

  bool hitsDragRadius(Offset position) {
    return (position - _position).distance < dragRadius;
  }

  bool hitsDragBrakeRadius(Offset position) {
    return (position - _position).distance < dragBrakeRadius;
  }

  void dispose() {
    pointerNumber?.dispose();
  }

  void onStartDrag({
    required Offset dragPosition,
    required int sortOrder,
    required int pointer,
    required TextStyle style,
  }) {
    _dragOffset = _position - dragPosition;
    sortOrder = sortOrder;
    pointerNumber?.dispose();
    pointerNumber = TextPainter(
      text: TextSpan(
        text: '$pointer',
        style: style,
      ),
      textDirection: TextDirection.ltr,
    )..layout();
  }

  void onDragged(Offset dragPosition, Rect area) {
    _position = dragPosition + _dragOffset;
    _position = Offset(
      _position.dx.clamp(area.left + radius, area.right - radius),
      _position.dy.clamp(area.top + radius, area.bottom - radius),
    );
  }

  void paint(Canvas canvas, TextPainter pointerText, Color textBackground) {
    canvas.drawCircle(_position, radius, outerPaint);
    canvas.drawCircle(_position, radius * 0.9, paintInner);

    final pn = pointerNumber;
    if (pn != null) {
      final totalHeight = pointerText.height + pn.height;
      final totalWidth = max(pointerText.width, pn.width);

      canvas.drawRRect(
        RRect.fromLTRBR(
          _position.dx - totalWidth / 2 - 4,
          _position.dy - totalHeight / 2 - 4,
          _position.dx + totalWidth / 2 + 4,
          _position.dy + totalHeight / 2 + 4,
          const Radius.circular(4),
        ),
        Paint()
          ..color = textBackground
          ..style = PaintingStyle.fill,
      );

      pointerText.paint(
        canvas,
        _position + Offset(-pointerText.width / 2, -totalHeight / 2),
      );
      pn.paint(
        canvas,
        _position +
            Offset(
              -pn.width / 2,
              -totalHeight / 2 + pointerText.height,
            ),
      );
    }
  }
}

class _DragController extends ChangeNotifier {
  final List<_DragBall> _balls;
  final TextStyle style;
  final Color textBackground;
  final _pointerToBall = <int, _DragBall>{};
  Rect _area = Rect.zero;
  late int _sortOrder;
  late final TextPainter _pointerText = TextPainter(
    text: TextSpan(
      text: 'Pointer',
      style: style,
    ),
    textDirection: TextDirection.ltr,
  )..layout();

  final Set<int> _brakePointers = {};

  _DragController({
    required int ballCount,
    required this.style,
    required this.textBackground,
  }) : _balls = List.generate(
          ballCount,
          (i) => _DragBall(
            sortOrder: i,
            radius: _ballRadius,
            dragRadius: Platform.isLinux
                ? _ballDragRadiusLinux
                : _ballDragRadiusAndroid,
            dragBrakeRadius: Platform.isLinux
                ? _ballDragBrakeRadiusLinux
                : _ballDragBrakeRadiusAndroid,
            outerPaint: Paint()
              ..color = ballColors[
                  ((i / ballColors.length).round() + 1 + i) % ballColors.length]
              ..style = PaintingStyle.fill,
            paintInner: Paint()
              ..color = ballColors[i % ballColors.length]
              ..style = PaintingStyle.fill,
          ),
        ) {
    _sortOrder = ballCount;
  }

  set area(Rect area) {
    _area = area;
  }

  @override
  void dispose() {
    super.dispose();
    for (final ball in _balls) {
      ball.dispose();
    }
  }

  bool brake(Offset position, int pointer) {
    for (final ball in _balls) {
      if (ball.hitsDragBrakeRadius(position)) {
        _brakePointers.add(pointer);
        return true;
      }
    }
    return false;
  }

  bool unbrake(int pointer) {
    return _brakePointers.remove(pointer);
  }

  void startDrag(Offset dragPosition, int pointer) {
    for (int i = _balls.length - 1; i >= 0; i--) {
      final ball = _balls[i];
      if (ball.hitsDragRadius(dragPosition)) {
        ball.onStartDrag(
          dragPosition: dragPosition,
          sortOrder: _sortOrder,
          pointer: pointer,
          style: style,
        );
        ball.sortOrder = _sortOrder++;
        _pointerToBall[pointer] = ball;
        _balls.sort((a, b) => a.sortOrder - b.sortOrder);
        notifyListeners();
        return;
      }
    }
  }

  void endDrag(int pointer) {
    _pointerToBall.remove(pointer);
  }

  void onDragged(Offset position, int pointer) {
    final ball = _pointerToBall[pointer];
    ball?.onDragged(position, _area);
    notifyListeners();
  }

  void paint(Canvas canvas, Size size) {
    // Canvas origin at center
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    for (final ball in _balls) {
      ball.paint(canvas, _pointerText, textBackground);
    }
    canvas.restore();
  }
}

class _DragPainter extends CustomPainter {
  final _DragController controller;
  final ColorScheme colorScheme;

  _DragPainter({
    super.repaint,
    required this.controller,
    required this.colorScheme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    controller.paint(canvas, size);
    canvas.drawRRect(
      RRect.fromLTRBR(
        0,
        0,
        size.width,
        size.height,
        const Radius.circular(4),
      ),
      Paint()
        ..color = colorScheme.outline
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _DragPainter oldDelegate) =>
      !listEquals(oldDelegate.controller._balls, controller._balls) ||
      oldDelegate.colorScheme != colorScheme;
}
