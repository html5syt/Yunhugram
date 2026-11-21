import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:yunhugram/core/credentials.dart';

void main() {
  test('旧会话清除完成后才保存新会话，写入顺序不能反转', () async {
    final serial = SerialWrites();
    final gate = Completer<void>();
    final order = <String>[];
    final first = serial.run(() async {
      order.add('clear-start');
      await gate.future;
      order.add('clear-end');
    });
    final second = serial.run(() async {
      order.add('save-new');
    });
    await Future<void>.delayed(Duration.zero);
    expect(order, ['clear-start']);
    gate.complete();
    await Future.wait([first, second]);
    expect(order, ['clear-start', 'clear-end', 'save-new']);
  });
  test('一次安全存储错误不会永久阻塞后续重试', () async {
    final serial = SerialWrites();
    await expectLater(
      serial.run(() async {
        throw StateError('storage');
      }),
      throwsStateError,
    );
    var retried = false;
    await serial.run(() async {
      retried = true;
    });
    expect(retried, isTrue);
  });
}
