// The committed `*.b.dart` files must match what the generator produces from
// this package's own `buildkit.yaml`.
//
// Nothing regenerates them during `dart test`: they change only when somebody
// runs `d4rtgen`. Without this check, a generator upgrade or a source change
// that was not followed by a regeneration leaves the rest of the suite green
// and testing stale generated code. The check regenerates into a scratch tree
// under `.dart_tool/` and never writes to the package.
//
// When it fails: run `dart run tom_d4rt_generator:d4rtgen` in this package and
// commit what it changes.
//
// SKIPPED, and the mechanism is known rather than suspected. SCE1 regenerated
// this package to a fixed point with `d4rtgen` 1.26.2 — running it again
// changes nothing but the `// Generated:` line — and this check still reports
// `tom_dist_ledger_bridges.b.dart` as differing. The cause is not staleness:
// `d4rtgen` runs `_generateBridges` (`src/v2/d4rtgen_executor.dart`) and
// `checkBridgeFreshness` runs `generateBridges` (`src/bridge_api.dart`), two
// hand-maintained implementations that have drifted apart. Measured elsewhere
// in the same sweep, on `tom_d4rt_generator/example/dart_overview`: the tool
// emits 5960 code lines, the check's path 5144, the missing 816 being every
// abstract, sealed, generic and mixin class.
//
// The file is here rather than absent because the gate is wanted the moment
// that is fixed: SCF1 owns it, and unskipping is deleting one line.

import 'dart:io';

import 'package:test/test.dart';
import 'package:tom_d4rt_generator/tom_d4rt_generator.dart';

void main() {
  test(
    'BRIDGE-FRESH-01: the committed bridges match the generator '
    '[2026-09-11] (PASS)',
    () async {
      final freshness = await checkBridgeFreshness(Directory.current.path);
      expect(freshness.errors, isEmpty, reason: 'generation failed');
      expect(
        freshness.checked,
        isNotEmpty,
        reason: 'the generator produced nothing, so nothing was compared',
      );
      expect(
        freshness.stale,
        isEmpty,
        reason:
            'regenerate with d4rtgen and commit:\n  '
            '${freshness.stale.join('\n  ')}',
      );
    },
    timeout: const Timeout(Duration(minutes: 10)),
    skip:
        'SCF1: the freshness check and d4rtgen run two different generator '
        'implementations, and this package is one of the five where they '
        'disagree. The committed bridges ARE what d4rtgen produces.',
  );
}
