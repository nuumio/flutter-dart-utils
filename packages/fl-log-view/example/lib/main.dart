// Copyright (c) 2024 Jari Hämäläinen
// SPDX-License-Identifier: MIT

import 'dart:async';
import 'dart:ui';

import 'package:fl_log_view/fl_log_view.dart';
import 'package:fl_log_view_example/logging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class MyWidgetsBindingObserver with WidgetsBindingObserver {
  @override
  Future<AppExitResponse> didRequestAppExit() async {
    mainLogger.info('App exit requested');
    await closeLogFile();
    return AppExitResponse.exit;
  }
}

void main() async {
  await initLogging();
  runApp(const MyApp());
}

class MyApp extends HookWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium!.copyWith(
          fontFamily: 'monospace',
          fontSize: 19,
        );
    final follow = useState(true);
    final systemEntryNumber = useState(1);
    final userEntryNumber = useState(1);
    final logViewController = useLogViewController(follow: follow.value);
    useEffect(() {
      updateFollow() => follow.value = logViewController.follow;
      logViewController.addListener(updateFollow);
      final t = Timer.periodic(const Duration(seconds: 1), (_) {
        mainLogger.info('System log entry ${systemEntryNumber.value++}');
      });
      return () {
        logViewController.removeListener(updateFollow);
        t.cancel();
      };
    }, []);

    return MaterialApp(
      title: 'FL Log View Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: Scaffold(
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      log.clearLogs();
                    },
                    child: const Text('Clear'),
                  ),
                  const SizedBox(width: 16),
                  Checkbox(
                    value: follow.value,
                    onChanged: (v) => logViewController.follow = v!,
                  ),
                  const SizedBox(width: 8),
                  const Text('Follow'),
                  const Expanded(child: SizedBox()),
                  ElevatedButton(
                    onPressed: () {
                      userLogger
                          .notice('User log entry ${userEntryNumber.value++}');
                    },
                    child: const Text('Insert user log entry'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: LogView(
                lineProvider: log,
                style: style,
                controller: logViewController,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
