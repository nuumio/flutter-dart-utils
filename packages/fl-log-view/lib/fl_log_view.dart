// Copyright (c) 2024 Jari Hämäläinen
// SPDX-License-Identifier: MIT

library fl_log_view;

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'src/widgets/selection_transformer.dart';

abstract class LogLineProvider extends ChangeNotifier {
  int get length;
  Iterable<String> getLines(int first, int count);
}

class LogViewController extends ChangeNotifier {
  bool _follow = true;

  LogViewController({follow = true}) : _follow = follow;

  bool get follow => _follow;
  set follow(bool value) {
    if (_follow != value) {
      _follow = value;
      notifyListeners();
    }
  }
}

LogViewController useLogViewController({
  List<Object?>? keys,
  bool follow = true,
}) {
  return use(
    _LogViewControllerHook(
      keys: keys,
      follow: follow,
    ),
  );
}

class _LogViewControllerHook extends Hook<LogViewController> {
  const _LogViewControllerHook({
    super.keys,
    this.follow = true,
  });

  final bool follow;

  @override
  HookState<LogViewController, Hook<LogViewController>> createState() =>
      _LogViewControllerHookState();
}

class _LogViewControllerHookState
    extends HookState<LogViewController, _LogViewControllerHook> {
  late final controller = LogViewController(
    follow: hook.follow,
  );

  @override
  LogViewController build(BuildContext context) => controller;

  @override
  void dispose() => controller.dispose();

  @override
  String get debugLabel => 'useLogViewController';
}

class LogView extends StatefulWidget {
  final LogLineProvider lineProvider;
  final TextStyle style;
  final LogViewController controller;

  const LogView({
    super.key,
    required this.lineProvider,
    required this.style,
    required this.controller,
  });

  @override
  State<LogView> createState() => LogViewState();
}

class LogViewState extends State<LogView> {
  bool _mounted = false;
  bool _following = true;
  late Size _textSize;
  double _viewHeight = 0;

  int _linesBefore = 0;
  Iterable<String> _lines = [];
  int _linesAfter = 0;
  int _lineCount = 0;

  final ScrollController _scrollControllerVertical = ScrollController();
  final ScrollController _scrollControllerHorizontal = ScrollController();

  void _handleLogChange() {
    final count = widget.lineProvider.length;
    final inView =
        (_viewHeight > 0 ? (_viewHeight / _textSize.height).floor() + 2 : 0)
            .clamp(0, count);
    final extentBefore =
        _mounted ? _scrollControllerVertical.position.extentBefore : 0;
    final before =
        (extentBefore / _textSize.height).floor().clamp(0, count - inView);
    final after = max(count - inView - before, 0);

    setState(() {
      _lines = widget.lineProvider.getLines(before, inView);
      _linesBefore = before;
      _linesAfter = after;

      if ((_lineCount != count || _following != widget.controller.follow) &&
          widget.controller.follow) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          _scrollControllerVertical
              .jumpTo(_scrollControllerVertical.position.maxScrollExtent);
        });
      }

      _lineCount = count;
      _following = widget.controller.follow;
    });
  }

  void _handleScroll() {
    final after = _scrollControllerVertical.position.extentAfter;
    if (after < _textSize.height / 2 && !widget.controller.follow) {
      widget.controller.follow = true;
    } else if (after >= _textSize.height / 2 && widget.controller.follow) {
      widget.controller.follow = false;
    }
    _handleLogChange();
  }

  @override
  void initState() {
    super.initState();
    // Any text goes as we only need the height.
    _textSize = _measureText(' ', widget.style);
    _following = widget.controller.follow;

    widget.lineProvider.addListener(_handleLogChange);
    _scrollControllerVertical.addListener(_handleScroll);
    widget.controller.addListener(_handleLogChange);
    _handleLogChange();
  }

  @override
  void dispose() {
    widget.lineProvider.removeListener(_handleLogChange);
    _scrollControllerVertical.removeListener(_handleScroll);
    widget.controller.removeListener(_handleLogChange);
    _mounted = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.maxWidth - 32;
        _mounted = true;
        if (constraints.maxHeight != _viewHeight) {
          SchedulerBinding.instance.addPostFrameCallback((_) {
            _viewHeight = constraints.maxHeight;
            _handleLogChange();
          });
        }
        return Scrollbar(
          controller: _scrollControllerHorizontal,
          thumbVisibility: true,
          // We need to replace the `defaultScrollNotificationPredicate`
          // (`return notification.depth == 0`) and check that depth is
          // 1, meaning that the notification did bubble through 1
          // intervening scrolling widget to get "through to" latter
          // SingleChildScrollView.
          notificationPredicate: (notification) {
            return notification.depth == 1;
          },
          child: Scrollbar(
            controller: _scrollControllerVertical,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _scrollControllerVertical,
              scrollDirection: Axis.vertical,
              child: Padding(
                // This padding prevents the horizontal scroll bar from
                // overlapping the vertical one.
                padding: const EdgeInsets.only(right: 16),
                child: SingleChildScrollView(
                  controller: _scrollControllerHorizontal,
                  scrollDirection: Axis.horizontal,
                  child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
                      child: SelectionArea(
                        child: SelectionTransformer.separated(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // This SizedBox forces content to take full
                              // width and so it pushes that vertical scroll
                              // bar to the right.
                              SizedBox(
                                width: boxWidth,
                                height: _textSize.height * _linesBefore,
                              ),
                              ..._lines.map((line) => Text(
                                    line,
                                    maxLines: 1,
                                    style: widget.style,
                                  )),
                              SizedBox(
                                width: boxWidth,
                                height: _textSize.height * _linesAfter,
                              ),
                            ],
                          ),
                        ),
                      )),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Size _measureText(String text, TextStyle style) {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    return textPainter.size;
  }
}
