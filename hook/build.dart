import 'dart:convert';
import 'dart:io';
import 'package:hooks/hooks.dart';
import 'package:native_toolchain_rust/native_toolchain_rust.dart';

/// 构建并打包 yhlib；本机非默认 Rust 目录由忽略的设置文件提供。
Future<void> main(List<String> args) async {
  await build(args, (input, output) async {
    final settings = File.fromUri(
      input.packageRoot.resolve('.dart_tool/yhlib_environment.json'),
    );
    final environment = <String, String>{};
    if (settings.existsSync()) {
      final data =
          jsonDecode(settings.readAsStringSync()) as Map<String, dynamic>;
      for (final key in ['CARGO_HOME', 'RUSTUP_HOME']) {
        if (data[key] is String) environment[key] = data[key] as String;
      }
      output.dependencies.add(settings.uri);
    }
    await RustBuilder(
      assetName: 'core/bindings.dart',
      extraCargoBuildArgs: const ['--locked', '--jobs', '4'],
      extraCargoEnvironmentVariables: environment,
    ).run(input: input, output: output);
  });
}
