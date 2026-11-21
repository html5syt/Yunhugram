import 'package:flutter_test/flutter_test.dart';
import 'package:yunhugram/core/bindings.dart';

void main() {
  test('Dart 能载入随应用生成的 Rust 核心库', () {
    expect(yhAbiVersion(), 1);
  });
}
