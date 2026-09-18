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
// SKIPPED, and the mechanism is measured rather than suspected. The committed
// bridges ARE what `d4rtgen` produces; this check disagrees with the tool
// because of the path form it passes, not because anything is stale.
//
// `checkBridgeFreshness` opens with `p.normalize(p.absolute(projectPath))`,
// while `d4rtgen` passes `-p .` through as given. `generateBridges` is not
// invariant under that difference: its barrel export-clause filter looks up
// `exportInfo[c.sourceFile]`, and `sourceFile` is written in mixed forms
// (filesystem path in one place, package URI in another), so a relative path
// misses the lookup and falls open while an absolute path hits the wrong entry
// and drops symbols the barrel explicitly shows.
//
// Measured here on 2026-09-18: the check reports this package's module bridge
// as differing by exactly one GEN-107 re-export tuple
// (`HeartbeatResult`), and regenerating with a RELATIVE project path
// reproduces the committed file with that tuple present. So the report is a
// false positive.
//
// This is NOT "two generator implementations" — SCE28 unified those, and both
// entry points now call one `generateBridges` with one config. That earlier
// diagnosis is retracted; see SCF1.
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
        'SCF1: `generateBridges` is not invariant under the project-path form, '
        'so this check (absolute) disagrees with `d4rtgen` (relative). The '
        'committed bridges ARE what `d4rtgen` produces — verified 2026-09-18.',
  );
}
