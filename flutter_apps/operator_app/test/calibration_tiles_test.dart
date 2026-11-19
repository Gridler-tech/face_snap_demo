// The Calibration page's overview tiles (design 2026-10-16, proposal A): the four
// status functions behind the tiles, one test per row of the status table, as pure
// functions (no server), and the default selection.
import 'package:face_snap_grpc/face_snap_grpc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:operator_app/ui/calibration_tiles.dart';
import 'package:operator_app/ui/ui.dart';

ColourCorrectionState _own(String light) =>
    ColourCorrectionState(light: light, source: 'kiosk');
ColourCorrectionState _shipped(String light) =>
    ColourCorrectionState(light: light, source: 'shipped');

void main() {
  group('Camera order', () {
    test('the mode and "N of M placed"; Done when every camera has a position', () {
      expect(cameraOrderTile(mode: 'manual', positions: [1, 2, 3, 4, 5], notSaved: false),
          (value: 'Manual · 5 of 5 placed', status: TileStatus.done));
    });

    test('every mode is named as the selector names it', () {
      expect(cameraOrderTile(mode: 'automatic', positions: [1], notSaved: false).value,
          'Automatic (USB sockets) · 1 of 1 placed');
      expect(cameraOrderTile(mode: 'person', positions: [1], notSaved: false).value,
          'By a person · 1 of 1 placed');
      expect(cameraOrderTile(mode: 'surroundings', positions: [1], notSaved: false).value,
          'From the surroundings · 1 of 1 placed');
    });

    test('To do when one camera is still unset', () {
      expect(cameraOrderTile(mode: 'manual', positions: [1, 0, 3], notSaved: false),
          (value: 'Manual · 2 of 3 placed', status: TileStatus.toDo));
    });

    test('To do when the server lists no camera at all', () {
      expect(cameraOrderTile(mode: 'manual', positions: const [], notSaved: false),
          (value: 'Manual · 0 of 0 placed', status: TileStatus.toDo));
    });

    test('Not saved wins over Done and To do', () {
      expect(cameraOrderTile(mode: 'manual', positions: [1, 2], notSaved: true).status,
          TileStatus.notSaved);
      expect(cameraOrderTile(mode: 'manual', positions: [0, 2], notSaved: true).status,
          TileStatus.notSaved);
    });

    test('still loading: the mode, no status', () {
      expect(cameraOrderTile(mode: 'manual', positions: null, notSaved: false),
          (value: 'Manual', status: null));
    });
  });

  group('Expected cameras', () {
    test('automatic: "Automatic (N found)", Done', () {
      expect(expectedCamerasTile(expected: 0, found: 5, notSaved: false),
          (value: 'Automatic (5 found)', status: TileStatus.done));
    });

    test('a set number that matches what was found: the number, Done', () {
      expect(expectedCamerasTile(expected: 6, found: 6, notSaved: false),
          (value: '6', status: TileStatus.done));
    });

    test('a set number that differs from what was found: Check, with the count found', () {
      expect(expectedCamerasTile(expected: 6, found: 5, notSaved: false),
          (value: '6 · 5 found', status: TileStatus.check));
    });

    test('automatic never asks for a check', () {
      expect(expectedCamerasTile(expected: 0, found: 0, notSaved: false).status,
          TileStatus.done);
    });

    test('Not saved wins over Done and Check', () {
      expect(expectedCamerasTile(expected: 6, found: 6, notSaved: true).status,
          TileStatus.notSaved);
      expect(expectedCamerasTile(expected: 6, found: 5, notSaved: true).status,
          TileStatus.notSaved);
    });

    test('still loading: no status', () {
      expect(expectedCamerasTile(expected: 0, found: null, notSaved: false),
          (value: 'Automatic', status: null));
    });
  });

  group('Focus', () {
    // Ruling A (fix round 2): the server has no reliable "focus was calibrated" signal
    // (an adopted column's standard holds the default 40; "Restore factory (all)"
    // deletes the standard), so the tile shows the value in force and never judges.
    test('the value in force with the neutral "Set": never Done or To do', () {
      expect(focusTile(focus: 62, notSaved: false),
          (value: 'Focus 62', status: TileStatus.set));
      expect(focusTile(focus: 40, notSaved: false),
          (value: 'Focus 40', status: TileStatus.set));
      expect(focusTile(focus: -1, notSaved: false),
          (value: 'Focus unknown', status: TileStatus.set));
    });

    test('Not saved wins, showing the value in force', () {
      expect(focusTile(focus: 64, notSaved: true),
          (value: 'Focus 64', status: TileStatus.notSaved));
    });

    test('still loading: no status', () {
      expect(focusTile(focus: null, notSaved: false), (value: 'Focus', status: null));
    });

    test('"Set" never drives the default selection', () {
      expect(TileStatus.set.needsAttention, isFalse);
      TileState done() => (value: '', status: TileStatus.done);
      expect(
          defaultSection({
            CalibrationSection.cameraOrder: done(),
            CalibrationSection.expectedCameras: done(),
            CalibrationSection.focus: focusTile(focus: 40, notSaved: false),
            CalibrationSection.photoColour: done(),
          }),
          CalibrationSection.cameraOrder);
    });
  });

  group('Photo colour', () {
    test('mixed: which lights are own and which shipped, by their card labels; Shipped', () {
      expect(
          photoColourTile([_own('all'), _shipped('neighbours'), _shipped('glare_free')],
              notSaved: false),
          (
            value: 'Own: Standard light (all LEDs) · shipped: Standard light (neighbours), '
                'Glare-free light',
            status: TileStatus.shipped,
          ));
    });

    test('Own colours when all three lights have this kiosk\'s own matrix', () {
      expect(
          photoColourTile([_own('all'), _own('neighbours'), _own('glare_free')],
              notSaved: false),
          (
            value: 'Own: Standard light (all LEDs), Standard light (neighbours), '
                'Glare-free light',
            status: TileStatus.ownColours,
          ));
    });

    test('all shipped: Shipped', () {
      expect(
          photoColourTile(
              [_shipped('all'), _shipped('neighbours'), _shipped('glare_free')],
              notSaved: false),
          (
            value: 'Shipped: Standard light (all LEDs), Standard light (neighbours), '
                'Glare-free light',
            status: TileStatus.shipped,
          ));
    });

    test('a light the server does not list counts as shipped (as colourStatusText says)', () {
      expect(photoColourTile([_own('all'), _own('neighbours')], notSaved: false).status,
          TileStatus.shipped);
    });

    test('a server without the feature: not available', () {
      expect(photoColourTile(const [], notSaved: false),
          (value: 'Not available on this server', status: TileStatus.notAvailable));
      expect(photoColourTile(null, notSaved: false).status, TileStatus.notAvailable);
    });

    test('Not saved wins over Own colours and Shipped', () {
      expect(
          photoColourTile([_own('all'), _own('neighbours'), _own('glare_free')],
                  notSaved: true)
              .status,
          TileStatus.notSaved);
      expect(photoColourTile([_shipped('all')], notSaved: true).status, TileStatus.notSaved);
    });
  });

  group('Pills', () {
    test('labels', () {
      expect([for (final s in TileStatus.values) s.label], [
        'Done',
        'To do',
        'Check',
        'Not saved',
        'Own colours',
        'Shipped',
        'Not available',
        'Set',
      ]);
    });

    test('Done and Own colours are success; To do, Check and Not saved a warning; '
        'Shipped neutral, not a warning', () {
      expect(TileStatus.done.color, T.pass);
      expect(TileStatus.ownColours.color, T.pass);
      expect(TileStatus.toDo.color, T.warn);
      expect(TileStatus.check.color, T.warn);
      expect(TileStatus.notSaved.color, T.warn);
      expect(TileStatus.shipped.color, T.muted);
      expect(TileStatus.notAvailable.color, T.muted);
      expect(TileStatus.set.color, T.muted);
    });

    test('which statuses ask for the operator is an explicit flag, not the colour', () {
      expect([for (final s in TileStatus.values) if (s.needsAttention) s],
          [TileStatus.toDo, TileStatus.check, TileStatus.notSaved]);
    });
  });

  group('Default selection', () {
    TileState done() => (value: '', status: TileStatus.done);
    TileState toDo() => (value: '', status: TileStatus.toDo);

    test('the first tile that is not done', () {
      expect(
          defaultSection({
            CalibrationSection.cameraOrder: done(),
            CalibrationSection.expectedCameras: done(),
            CalibrationSection.focus: toDo(),
            CalibrationSection.photoColour: (value: '', status: TileStatus.notSaved),
          }),
          CalibrationSection.focus);
      expect(
          defaultSection({
            CalibrationSection.cameraOrder: done(),
            CalibrationSection.expectedCameras: (value: '', status: TileStatus.check),
            CalibrationSection.focus: toDo(),
            CalibrationSection.photoColour: done(),
          }),
          CalibrationSection.expectedCameras);
    });

    test('Shipped colours are not "to do": all done -> Camera order', () {
      expect(
          defaultSection({
            CalibrationSection.cameraOrder: done(),
            CalibrationSection.expectedCameras: done(),
            CalibrationSection.focus: done(),
            CalibrationSection.photoColour: (value: '', status: TileStatus.shipped),
          }),
          CalibrationSection.cameraOrder);
    });

    test('a not-saved photo colour is picked when everything else is done', () {
      expect(
          defaultSection({
            CalibrationSection.cameraOrder: done(),
            CalibrationSection.expectedCameras: done(),
            CalibrationSection.focus: done(),
            CalibrationSection.photoColour: (value: '', status: TileStatus.notSaved),
          }),
          CalibrationSection.photoColour);
    });

    test('the tiles in their order, with their names', () {
      expect([for (final s in CalibrationSection.values) s.label],
          ['Camera order', 'Expected cameras', 'Focus', 'Photo colour']);
    });
  });
}
