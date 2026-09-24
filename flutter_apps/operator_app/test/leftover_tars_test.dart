// Removal hunts down image .tar files a failed or hand-run install can leave on
// the eMMC. The parser turns `find ... -printf '%s\t%p\n'` output into
// (bytes, path) records, and the command builders must only ever match
// FaceSnap image tars — never an unrelated archive.
import 'package:flutter_test/flutter_test.dart';
import 'package:operator_app/updater/kiosk.dart';

void main() {
  group('parseLeftoverTars', () {
    test('parses size and path from each line', () {
      const out = '1048576\t/root/face_snap-2.0.10-arm64.tar\n'
          '2097152\t/tmp/facesnap2-2.0.11-arm64.tar\n';
      final r = parseLeftoverTars(out);
      expect(r, hasLength(2));
      expect(r[0].bytes, 1048576);
      expect(r[0].path, '/root/face_snap-2.0.10-arm64.tar');
      expect(r[1].bytes, 2097152);
      expect(r[1].path, '/tmp/facesnap2-2.0.11-arm64.tar');
    });

    test('empty output yields no leftovers', () {
      expect(parseLeftoverTars(''), isEmpty);
      expect(parseLeftoverTars('\n\n'), isEmpty);
    });

    test('skips blank and malformed lines', () {
      const out = '\n'
          'garbage-without-a-tab\n'
          '\t/root/no-size.tar\n' // empty size field
          'notanumber\t/root/bad.tar\n'
          '4096\t/root/face_snap-1.4.0.tar\n';
      final r = parseLeftoverTars(out);
      expect(r, hasLength(1));
      expect(r.single.bytes, 4096);
      expect(r.single.path, '/root/face_snap-1.4.0.tar');
    });

    test('preserves spaces inside a path', () {
      final r = parseLeftoverTars('512\t/root/old builds/face_snap-2.0.9.tar\n');
      expect(r.single.path, '/root/old builds/face_snap-2.0.9.tar');
    });

    test('total reclaimed size is a simple fold', () {
      const out = '100\t/root/face_snap-a.tar\n200\t/tmp/facesnap-b.tar\n';
      final freed =
          parseLeftoverTars(out).fold<int>(0, (s, f) => s + f.bytes);
      expect(freed, 300);
    });
  });

  group('leftover tar commands', () {
    test('scan and delete cover the same bounded roots and predicate', () {
      final scan = leftoverTarScanCmd();
      final del = leftoverTarDeleteCmd();
      expect(scan, contains(kLeftoverTarRoots));
      expect(del, contains(kLeftoverTarRoots));
      expect(scan, contains(kLeftoverTarPredicate));
      expect(del, contains(kLeftoverTarPredicate));
    });

    test('scan emits size-tab-path and tolerates missing roots', () {
      final scan = leftoverTarScanCmd();
      expect(scan, contains(r"-printf '%s\t%p\n'"));
      expect(scan, contains('2>/dev/null'));
    });

    test('delete uses find -delete, not rm -rf', () {
      final del = leftoverTarDeleteCmd();
      expect(del, contains('-delete'));
      expect(del, isNot(contains('rm -rf')));
    });

    test('predicate matches only FaceSnap image tars, not arbitrary archives',
        () {
      // Both server generations are covered; the prefixes match kImageRefFilters
      // so an unrelated backup.tar is never in scope.
      expect(kLeftoverTarPredicate, contains("-name 'face_snap*.tar'"));
      expect(kLeftoverTarPredicate, contains("-name 'facesnap*.tar'"));
      expect(kLeftoverTarPredicate, contains('-type f'));
    });
  });
}
