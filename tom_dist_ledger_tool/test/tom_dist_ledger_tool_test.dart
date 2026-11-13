import 'package:test/test.dart';
import 'package:tom_build_base/tom_build_base_v2.dart';
import 'package:tom_dist_ledger_tool/tom_dist_ledger_tool.dart';
import 'package:tom_dist_ledger_tool/src/version.versioner.dart';

/// ledger_server on tom_build_base's ToolRunner.
///
/// Test IDs: LDG-CLI-1..4.
void main() {
  CliArgs parse(List<String> args) =>
      CliArgParser(toolDefinition: ledgerServerTool).parse(args);

  test('LDG-CLI-1: a ProcessMonitor\'s start (--path <dir>) and the '
      'defaults', () {
    final s = ledgerServerSettings(parse(['--path', '/srv/ledger']))!;
    expect((s.port, s.basePath), (defaultLedgerPort, '/srv/ledger'));
    final d = ledgerServerSettings(parse([]))!;
    expect(d.port, 19880);
    expect(d.basePath, endsWith('/.tom/distributed_ledger'));
  });

  test('LDG-CLI-2: -p / --port and -d / --path in both forms', () {
    final a = ledgerServerSettings(parse(['-p', '8080', '-d', '/a']))!;
    final b = ledgerServerSettings(parse(['--port=9090', '--path=/b']))!;
    expect((a.port, a.basePath, b.port, b.basePath), (8080, '/a', 9090, '/b'));
  });

  test('LDG-CLI-3: a --port that is no port number is an error', () {
    final errors = <String>[];
    expect(
      ledgerServerSettings(parse(['--port', 'abc']), onError: errors.add),
      isNull,
    );
    expect(
      ledgerServerSettings(parse(['--port=70000']), onError: errors.add),
      isNull,
    );
    expect(errors, hasLength(2));
  });

  test('LDG-CLI-4: --version prints the versioner\'s version; --help the '
      'options; neither starts the server', () async {
    final out = StringBuffer();
    final version = await ToolRunner(
      tool: ledgerServerTool,
      executors: {'default': LedgerServerExecutor()},
      output: out,
    ).run(['--version']);
    expect(version.success, isTrue);
    expect(
      out.toString().split('\n').first,
      'ledger_server ${DistLedgerToolVersionInfo.versionLong}',
    );

    out.clear();
    final help = await ToolRunner(
      tool: ledgerServerTool,
      executors: {'default': LedgerServerExecutor()},
      output: out,
    ).run(['--help']);
    expect(help.success, isTrue);
    expect(out.toString(), allOf(contains('--port'), contains('--path')));
  });
}
