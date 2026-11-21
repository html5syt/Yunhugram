import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:yunhugram/core/bindings.dart';
import 'package:yunhugram/core/client.dart';
import 'package:yunhugram/features/auth/challenge.dart';

void main() {
  test('Dart 能载入随应用生成的 Rust 核心库', () {
    expect(yhAbiVersion(), 1);
  });
  test('异步 FFI 能返回错误并正确关闭，而非阻塞界面线程', () async {
    final client = YhClient({
      'device_id': 'ffi-test',
      'platform': 'windows',
      'cache_dir': Directory.current.uri
          .resolve('.dart_tool/ffi-tests')
          .toFilePath(),
    });
    await expectLater(
      client.request('getConversations'),
      throwsA(
        isA<ClientError>().having((e) => e.kind, 'kind', 'sessionExpired'),
      ),
    );
    client.dispose();
    client.dispose();
  });
  if (Platform.environment['YH_NETWORK_CHECK'] == '1') {
    test('真实验证码接口经过 Rust 与 Dart FFI 可读取，不发送短信', () async {
      final client = YhClient({
        'device_id': 'ffi-read-only-check',
        'platform': 'windows',
        'cache_dir': Directory.current.uri
            .resolve('.dart_tool/ffi-tests')
            .toFilePath(),
      });
      try {
        final data = await client.request('getCaptcha', {'mode': 'slide'});
        final c = Challenge(data, false);
        expect(c.width, greaterThan(0));
        expect(c.tileWidth, lessThan(c.width));
        expect(c.background, isNotEmpty);
      } finally {
        client.dispose();
      }
    });
  }
}
