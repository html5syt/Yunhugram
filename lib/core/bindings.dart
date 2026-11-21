import 'dart:ffi';

/// 从原生资源载入接口；不依赖手写平台路径或系统动态库搜索。
@Native<Uint32 Function()>(
  assetId: 'package:yunhugram/core/bindings.dart',
  symbol: 'yh_abi_version',
)
external int yhAbiVersion();
