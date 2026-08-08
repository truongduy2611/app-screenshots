import 'dart:convert';
import 'dart:io';

import 'package:app_screenshots_cli/src/upload_payload.dart';
import 'package:test/test.dart';

void main() {
  test('encodes sorted screenshots from selected locale folders', () async {
    final root = await Directory.systemTemp.createTemp('appshots_payload_');
    addTearDown(() => root.delete(recursive: true));
    final english = await Directory('${root.path}/en-US').create();
    final japanese = await Directory('${root.path}/ja').create();
    await File('${english.path}/02.jpg').writeAsBytes([2]);
    await File('${english.path}/01.png').writeAsBytes([1]);
    await File('${english.path}/ignore.txt').writeAsString('ignored');
    await File('${japanese.path}/01.png').writeAsBytes([3]);

    final payload = await encodeLocaleScreenshots(
      root.path,
      selectedLocales: ['en-US'],
    );

    expect(payload.keys, ['en-US']);
    expect(payload['en-US']!.map((item) => item['name']), ['01.png', '02.jpg']);
    expect(base64Decode(payload['en-US']!.first['data']!), [1]);
  });
}
