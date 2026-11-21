import 'package:hooks/hooks.dart';
import 'package:native_toolchain_rust/native_toolchain_rust.dart';

/// 由 Flutter 的原生资源流程按目标平台生成并打包 yhlib。
Future<void> main(List<String> args) async {
  await build(args, (input, output) async {
    await RustBuilder(
      assetName: 'core/bindings.dart',
    ).run(input: input, output: output);
  });
}
