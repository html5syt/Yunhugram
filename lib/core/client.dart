import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'bindings.dart';

/// 业务层只依赖异步接口；模拟实现仅允许在测试中使用。
abstract interface class CoreClient {
  Stream<Map<String, dynamic>> get updates;
  Future<Map<String, dynamic>> request(
    String type, [
    Map<String, dynamic> args = const {},
  ]);
  void dispose();
}

class ClientError implements Exception {
  const ClientError(this.kind, this.message);
  final String kind;
  final String message;
  @override
  String toString() => message;
}

/// 请求编号对应 Future，服务端更新单独广播；轮询不等待网络。
class YhClient implements CoreClient {
  YhClient(Map<String, dynamic> config) {
    if (yhAbiVersion() != 1) {
      throw const ClientError('configuration', '应用文件版本不一致，请重新安装');
    }
    final input = jsonEncode(config).toNativeUtf8();
    try {
      _handle = yhCreate(input.cast());
    } finally {
      calloc.free(input);
    }
    if (_handle == nullptr) {
      throw const ClientError('configuration', '无法启动应用，请检查安装文件后重试');
    }
    _timer = Timer.periodic(const Duration(milliseconds: 40), (_) => _drain());
  }
  late Pointer<Void> _handle;
  late final Timer _timer;
  final _pending = <int, Completer<Map<String, dynamic>>>{};
  final _events = StreamController<Map<String, dynamic>>.broadcast();
  int _sequence = 0;
  bool _closed = false;
  @override
  Stream<Map<String, dynamic>> get updates => _events.stream;

  @override
  Future<Map<String, dynamic>> request(
    String type, [
    Map<String, dynamic> args = const {},
  ]) async {
    if (_closed) throw const ClientError('closed', '客户端已关闭');
    final id = ++_sequence;
    final completion = Completer<Map<String, dynamic>>();
    _pending[id] = completion;
    final input = jsonEncode({
      ...args,
      '@type': type,
      '@extra': id,
    }).toNativeUtf8();
    try {
      if (yhSend(_handle, input.cast()) != 0) {
        _pending.remove(id);
        throw const ClientError('busy', '正在处理其他操作，请稍后重试');
      }
    } finally {
      calloc.free(input);
    }
    try {
      return await completion.future.timeout(
        const Duration(seconds: 40),
        onTimeout: () => throw const ClientError('network', '请求超时，请重试'),
      );
    } finally {
      _pending.remove(id);
    }
  }

  void _drain() {
    // 每轮限制处理数量，推送密集时也不会长时间占用界面线程。
    for (var i = 0; i < 32 && !_closed; i++) {
      final value = yhReceive(_handle);
      if (value == nullptr) return;
      late Map<String, dynamic> event;
      try {
        event =
            jsonDecode(value.cast<Utf8>().toDartString())
                as Map<String, dynamic>;
      } finally {
        yhFree(value);
      }
      final completion = _pending.remove(event['@extra']);
      if (completion != null) {
        if (event['@type'] == 'error') {
          final error = event['error'] as Map<String, dynamic>;
          completion.completeError(
            ClientError(error['kind'] as String, error['message'] as String),
          );
        } else {
          completion.complete(event['data'] as Map<String, dynamic>);
        }
      } else if (event['@type'] != 'response' && event['@type'] != 'error') {
        _events.add(event);
      }
    }
  }

  @override
  void dispose() {
    if (_closed) return;
    _closed = true;
    _timer.cancel();
    for (final completion in _pending.values) {
      completion.completeError(const ClientError('closed', '客户端已关闭'));
    }
    _pending.clear();
    yhDestroy(_handle);
    _events.close();
  }
}
