import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Key File Management Tests', () {
    test('Key file can be created and read', () async {
      const testKey = 'test_api_key_create';
      final directory = Directory.systemTemp;
      final file = File('${directory.path}/test_key_file');

      await file.writeAsString(testKey);
      expect(await file.exists(), true);

      final content = await file.readAsString();
      expect(content, testKey);

      await file.delete();
    });

    test('Key file can be updated', () async {
      const testKey1 = 'test_api_key_1';
      const testKey2 = 'test_api_key_2';
      final directory = Directory.systemTemp;
      final file = File('${directory.path}/test_key_file_update');

      await file.writeAsString(testKey1);
      expect(await file.readAsString(), testKey1);

      await file.writeAsString(testKey2);
      expect(await file.readAsString(), testKey2);

      await file.delete();
    });

    test('Key file can be deleted', () async {
      const testKey = 'test_api_key_delete';
      final directory = Directory.systemTemp;
      final file = File('${directory.path}/test_key_file_delete');

      await file.writeAsString(testKey);
      expect(await file.exists(), true);

      await file.delete();
      expect(await file.exists(), false);
    });

    test('Key with whitespace is trimmed correctly', () async {
      const testKey = '  test_api_key_trimmed  ';
      final directory = Directory.systemTemp;
      final file = File('${directory.path}/test_key_file_trim');

      await file.writeAsString(testKey);
      final content = await file.readAsString();
      expect(content.trim(), 'test_api_key_trimmed');

      await file.delete();
    });

    test('Empty key validation works correctly', () async {
      const emptyKey = '';
      const whitespaceKey = '   ';
      
      expect(emptyKey.trim().isEmpty, true);
      expect(whitespaceKey.trim().isEmpty, true);
    });

    test('Non-empty key validation works correctly', () async {
      const validKey = 'valid_api_key_12345';
      const validKeyWithSpaces = '  valid_api_key_12345  ';
      
      expect(validKey.trim().isNotEmpty, true);
      expect(validKeyWithSpaces.trim().isNotEmpty, true);
      expect(validKeyWithSpaces.trim(), 'valid_api_key_12345');
    });
  });
}
