import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';

/// Output formatting utilities for CLI results.
class Output {
  /// Print a JSON result in either raw JSON or human-friendly format.
  static void print(Map<String, dynamic> result, {bool json = false}) {
    if (json) {
      stdout.writeln(const JsonEncoder.withIndent('  ').convert(result));
      return;
    }

    final ok = result['ok'] as bool? ?? false;
    if (!ok) {
      stderr.writeln('❌ ${result['error'] ?? 'Unknown error'}');
      return;
    }

    final data = result['data'];
    if (data == null) {
      stdout.writeln('✅ Done');
      return;
    }

    if (data is List) {
      _printList(data);
    } else if (data is Map) {
      _printMap(data.cast<String, dynamic>());
    } else {
      stdout.writeln(data);
    }
  }

  static void _printList(List items) {
    if (items.isEmpty) {
      stdout.writeln('(empty)');
      return;
    }

    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      if (item is Map) {
        final name = item['name'] ?? item['id'] ?? '';
        final id = item['id'] ?? '';
        final extra = <String>[];
        if (item.containsKey('lastModified')) extra.add(item['lastModified']);
        if (item.containsKey('isMulti') && item['isMulti'] == true) extra.add('multi');
        if (item.containsKey('designCount')) extra.add('${item['designCount']} designs');

        stdout.writeln('  ${i + 1}. $name${extra.isNotEmpty ? ' (${extra.join(', ')})' : ''}');
        if (id.isNotEmpty && id != name) stdout.writeln('     ID: $id');
      } else {
        stdout.writeln('  ${i + 1}. $item');
      }
    }
  }

  static void _printMap(Map<String, dynamic> map) {
    for (final entry in map.entries) {
      final value = entry.value;
      if (value is Map || value is List) {
        stdout.writeln('${entry.key}:');
        stdout.writeln(const JsonEncoder.withIndent('  ').convert(value));
      } else {
        stdout.writeln('${entry.key}: $value');
      }
    }
  }

  /// Whether --json flag is set in the global args.
  static bool isJson(ArgResults? globalResults) {
    return globalResults?['json'] == true;
  }
}
