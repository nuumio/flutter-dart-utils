// Copyright (c) 2024 Jari Hämäläinen
// SPDX-License-Identifier: MIT

import 'dart:async';
import 'dart:io';

import 'package:fl_log_view/fl_log_view.dart';
import 'package:fl_log_view_example/log_utils.dart';
import 'package:logging/logging.dart';

// ignore: constant_identifier_names
const Level NOTICE = Level('NOTICE', 850);

extension CustomLevels on Logger {
  void notice(Object? message, [Object? error, StackTrace? stackTrace]) =>
      this.log(NOTICE, message, error, stackTrace);
}

late final Logger mainLogger;
late final Logger userLogger;
late final Log log;
late final RandomAccessFile? logFile;
bool _logClosing = false;
Future<void>? _logFlushing;
final List<LogRecord> _logBuffer = [];

String recordToString(LogRecord record) => record.error != null &&
        (record.error is Exception || record.error is Error)
    ? '${record.time.toIsoLogTimestamp()} ${record.loggerName.padRight(5)} ${record.level.name.padLeft(7)} ${record.message}: ${record.error}'
    : '${record.time.toIsoLogTimestamp()} ${record.loggerName.padRight(5)} ${record.level.name.padLeft(7)} ${record.message}';

Future<void> initLogging({String? logFilePath}) async {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen(writeLogRecord);

  if (logFilePath != null) {
    try {
      final file = File(logFilePath);
      logFile = await file.open(mode: FileMode.write);
    } catch (e) {
      logFile = null;
    }
  } else {
    logFile = null;
  }

  mainLogger = Logger('main');
  userLogger = Logger('user');
  log = Log();
}

Future<void> closeLogFile() async {
  _logClosing = true;
  if (_logFlushing != null) await _logFlushing;
  await logFile?.close();
}

void writeLogRecord(LogRecord record) {
  if (_logClosing) return;
  log.append(record);
  _logBuffer.add(record);
  _flushLogBuffer();
}

void _flushLogBuffer() async {
  if (_logFlushing != null) return;
  final completer = Completer<void>();
  _logFlushing = completer.future;
  while (_logBuffer.isNotEmpty) {
    final record = _logBuffer.removeAt(0);
    try {
      await logFile?.writeString('${recordToString(record)}\n');
    } catch (e) {
      // Ignore
    }
  }
  completer.complete();
  _logFlushing = null;
}

class Log extends LogLineProvider {
  bool _notifying = false;
  final List<LogRecord> _log = [];

  List<LogRecord> get log => _log;
  @override
  int get length => _log.length;

  void append(LogRecord record) {
    _log.add(record);
    _notify();
  }

  void clearLogs() {
    _log.clear();
    _notify();
  }

  void _notify() {
    if (!_notifying) {
      _notifying = true;
      Future(() {
        _notifying = false;
        if (hasListeners) notifyListeners();
      });
    }
  }

  @override
  Iterable<String> getLines(int first, int count) {
    return _log.getRange(first, first + count).map((e) => recordToString(e));
  }
}
