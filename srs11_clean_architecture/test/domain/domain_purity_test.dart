import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Domain Layer не должен зависеть от Flutter и библиотек работы с данными.
/// Тест проверяет все import'ы в lib/src/domain.
void main() {
  const forbidden = [
    'package:flutter/',
    'package:flutter_bloc/',
    'package:dio/',
    'package:http/',
    'package:retrofit/',
    'package:shared_preferences/',
    'package:json_annotation/',
    'package:firebase',
    'package:cloud_firestore/',
    'dart:io',
    'dart:ui',
    '/data/',
    '/presentation/',
    '/models/',
    '/core/',
  ];

  test('lib/src/domain не импортирует Flutter, Dio, http, Firebase и Data Layer',
      () {
    final files = Directory('lib/src/domain')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .toList();
    expect(files, isNotEmpty);

    final violations = <String>[];
    for (final file in files) {
      final imports = file
          .readAsLinesSync()
          .where((l) => l.startsWith('import ') || l.startsWith('export '));
      for (final line in imports) {
        if (forbidden.any(line.contains)) {
          violations.add('${file.path}: $line');
        }
      }
    }
    expect(violations, isEmpty, reason: violations.join('\n'));
  });
}
