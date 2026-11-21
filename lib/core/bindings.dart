import 'dart:ffi';

const _asset = 'package:yunhugram/core/bindings.dart';

/// 由原生资源打包系统解析，不硬编码各个平台的动态库文件名。
@Native<Uint32 Function()>(assetId: _asset, symbol: 'yh_abi_version')
external int yhAbiVersion();
@Native<Pointer<Void> Function(Pointer<Char>)>(
  assetId: _asset,
  symbol: 'yh_create',
)
external Pointer<Void> yhCreate(Pointer<Char> config);
@Native<Int32 Function(Pointer<Void>, Pointer<Char>)>(
  assetId: _asset,
  symbol: 'yh_send',
)
external int yhSend(Pointer<Void> client, Pointer<Char> command);
@Native<Pointer<Char> Function(Pointer<Void>)>(
  assetId: _asset,
  symbol: 'yh_receive',
)
external Pointer<Char> yhReceive(Pointer<Void> client);
@Native<Void Function(Pointer<Char>)>(assetId: _asset, symbol: 'yh_free')
external void yhFree(Pointer<Char> value);
@Native<Void Function(Pointer<Void>)>(assetId: _asset, symbol: 'yh_destroy')
external void yhDestroy(Pointer<Void> client);
