// The generation boundary the update pipeline converts across: detection of
// the first-generation ("legacy") layout on both sides, and the two compose
// templates. The legacy sample is the real file from a face_snap:1.4.0 board.
import 'package:flutter_test/flutter_test.dart';
import 'package:operator_app/updater/kiosk.dart';

const _realLegacyCompose = '''
services:
  face_snap:
    image: "c603c95cda96"
    command: >
      bash -c "cd /root/face_snap/server && watchmedo auto-restart --recursive --pattern='*.py' -- python3.8 server.py"
    restart: always
    ports:
      - "50051:50051"
    volumes:
      # Camera settings, kiosk settings, light settings etc.
      - type: bind
        source: ./camera_settings.json
        target: /root/face_snap/server/camera_settings.json
      - /dev:/dev
      - /run/udev:/run/udev:ro
    privileged: true
''';

void main() {
  group('isLegacyCompose', () {
    test('the real 1.4.0 compose file is legacy', () {
      expect(isLegacyCompose(_realLegacyCompose), isTrue);
    });

    test('both templates classify as their own generation', () {
      expect(isLegacyCompose(composeTemplate('facesnap2:2.0.10-arm64')), isFalse);
      expect(isLegacyCompose(legacyComposeTemplate('face_snap:1.4.0')), isTrue);
    });

    test('a comment mentioning the data mount does not count', () {
      expect(isLegacyCompose('$_realLegacyCompose\n# was: - ./data:/data'),
          isTrue);
    });
  });

  group('imageUsesDataDir', () {
    test('data/ generations set FACE_SNAP_DATA_DIR in the image', () {
      expect(
          imageUsesDataDir('["PATH=/usr/bin","FACE_SNAP_DATA_DIR=/data"]'),
          isTrue);
    });

    test('a first-generation image does not', () {
      expect(imageUsesDataDir('["PATH=/usr/bin","LANG=C.UTF-8"]'), isFalse);
      expect(imageUsesDataDir('null'), isFalse);
    });
  });

  group('legacyComposeTemplate', () {
    final text = legacyComposeTemplate('face_snap:1.4.0');

    test('mounts every settings file into the server folder', () {
      for (final name in kSettingsFiles) {
        expect(text, contains('source: ./$name'));
        expect(text, contains('target: /root/face_snap/server/$name'));
      }
    });

    test('carries the image and the Python 3.8 start command', () {
      expect(text, contains('image: face_snap:1.4.0'));
      expect(text, contains('python3.8 server.py'));
    });
  });

  test('legacy settings seeds are valid empty JSON of the right shape', () {
    expect(legacySettingsSeed('light_settings.json'), '[]');
    expect(legacySettingsSeed('kiosk_settings.json'), '{}');
    expect(legacySettingsSeed('camera_settings.json'), '{}');
  });

  group('hasCalibratedPositions', () {
    test('the real migrated 1.4 calibration has none', () {
      expect(
          hasCalibratedPositions('[{"ID_MODEL_ID": "0057", '
              '"linux_camera_index": 0, "calibrated_camera_index": null}]'),
          isFalse);
    });

    test('a saved calibration has them; a missing file does not', () {
      expect(
          hasCalibratedPositions('[{"linux_camera_index":5,'
              '"calibrated_camera_index":1,"port_path":"4.4"}]'),
          isTrue);
      expect(hasCalibratedPositions(''), isFalse);
    });
  });

  test('the LED marker knows the first-generation wording too', () {
    expect(
        kLedBoardConnectedMarker.hasMatch(
            '[DEBUG] mpremote.py:133 - Successfully communicated with plasma, cmd: …'),
        isTrue);
    expect(kLedBoardConnectedMarker.hasMatch('Plasma LED board connected on COM3'),
        isTrue);
    expect(kLedBoardConnectedMarker.hasMatch('Waiting for the Plasma LED board'),
        isFalse);
  });

  test('the ready marker knows all three server generations', () {
    expect(kServerReadyMarker.hasMatch('gRPC server started'), isTrue);
    expect(kServerReadyMarker.hasMatch('gRPC server bound to [::]:50051'),
        isTrue);
    expect(kServerReadyMarker.hasMatch('FaceSnap Server 2.0 bound to port 50051'),
        isTrue);
    expect(kServerReadyMarker.hasMatch('gRPC server starting'), isFalse);
  });
}
