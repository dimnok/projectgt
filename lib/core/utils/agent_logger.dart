import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';

class AgentLogger {
  static const String logPath = '/Users/dmitrit./projectgt/.cursor/debug.log';

  static void log({
    required String hypothesisId,
    required String message,
    Map<String, dynamic>? data,
    required String location,
  }) {
    final entry = {
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'hypothesisId': hypothesisId,
      'message': message,
      'data': data,
      'location': location,
      'sessionId': 'debug-session',
    };

    final logLine = jsonEncode(entry);
    debugPrint('--- [AGENT_LOG] $logLine');

    try {
      if (!kIsWeb && (Platform.isMacOS || Platform.isLinux || Platform.isWindows)) {
        final file = File(logPath);
        file.writeAsStringSync(logLine + '\n', mode: FileMode.append, flush: true);
      }
    } catch (e) {
      // ignore
    }
  }
}
