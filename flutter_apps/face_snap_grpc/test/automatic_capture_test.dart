// The automatic capture's events from its response stream: the head turn's
// Instruction messages become CaptureInstruction events in stream order, next to
// the status lines, the check results and the photo (spec 2026-10-08 section
// 3.3), and the settings used (per-capture settings, spec 2026-10-11) become the first
// event. No server: the messages are fed to automaticCaptureEvents /
// manualCaptureEvents directly.
import 'package:face_snap_grpc/face_snap_grpc.dart';
import 'package:test/test.dart';

ProcessAutomaticResponse _status(String text) => ProcessAutomaticResponse(
    processStatus: ProcessStepStatus(
        index: 4, description: text, status: StatusType.OK));

ProcessAutomaticResponse _instruction(InstructionKind kind,
        {double progress = 0, bool repeat = false, double secondsLeft = 4, String text = ''}) =>
    ProcessAutomaticResponse(
        instruction: Instruction(
            index: 4,
            kind: kind,
            progress: progress,
            repeat: repeat,
            secondsLeft: secondsLeft,
            text: text));

void main() {
  test('instructions become CaptureInstruction events, in stream order',
      () async {
    final events = await automaticCaptureEvents(Stream.fromIterable([
      _status('Turn your head to the left'),
      _instruction(InstructionKind.TURN_LEFT,
          progress: 0.25, secondsLeft: 3.5, text: 'Turn your head to the left'),
      _status('Once more: turn your head to the right'),
      _instruction(InstructionKind.TURN_RIGHT,
          repeat: true, text: 'Once more: turn your head to the right'),
      _instruction(InstructionKind.DONE, secondsLeft: 0),
      ProcessAutomaticResponse(
          imageData: ProcessImageData(
              index: 4, width: 2, height: 3, format: 'JPG', chunkData: [1, 2])),
    ])).toList();

    expect(events.map((e) => e.runtimeType.toString()), [
      'CaptureStatus',
      'CaptureInstruction',
      'CaptureStatus',
      'CaptureInstruction',
      'CaptureInstruction',
      'CapturePhoto',
    ]);
    final left = events[1] as CaptureInstruction;
    expect(left.kind, InstructionKind.TURN_LEFT);
    expect(left.progress, closeTo(0.25, 1e-6));
    expect(left.secondsLeft, closeTo(3.5, 1e-6));
    expect(left.repeat, isFalse);
    expect(left.text, 'Turn your head to the left');
    final again = events[3] as CaptureInstruction;
    expect((again.kind, again.repeat), (InstructionKind.TURN_RIGHT, true));
    expect((events[4] as CaptureInstruction).kind, InstructionKind.DONE);
    expect((events[5] as CapturePhoto).bytes, [1, 2]);
  });

  test('an instruction after the photo chunks flushes the photo first',
      () async {
    final events = await automaticCaptureEvents(Stream.fromIterable([
      ProcessAutomaticResponse(
          imageData: ProcessImageData(
              index: 4, width: 2, height: 3, format: 'JPG', chunkData: [9])),
      _instruction(InstructionKind.DONE, secondsLeft: 0),
    ])).toList();

    expect(events.map((e) => e.runtimeType.toString()),
        ['CapturePhoto', 'CaptureInstruction']);
  });

  test('settings used becomes the first event', () async {
    final events = await automaticCaptureEvents(Stream.fromIterable([
      ProcessAutomaticResponse(
          settingsUsed: CaptureSettingsUsed(
              values: CaptureSettings(photoFormat: 'us_2x2', jpegQuality: 95),
              overridden: ['photo_format'])),
      _status('Loading OFIQ (first use, about 8 s)'),
      ProcessAutomaticResponse(
          imageData: ProcessImageData(
              index: 4, width: 2, height: 3, format: 'JPG', chunkData: [7])),
    ])).toList();

    expect(events.map((e) => e.runtimeType.toString()),
        ['CaptureSettingsReport', 'CaptureStatus', 'CapturePhoto']);
    final report = events.first as CaptureSettingsReport;
    expect(report.values.photoFormat, 'us_2x2');
    expect(report.values.jpegQuality, 95);
    expect(report.overridden, ['photo_format']);
    expect(() => report.overridden.add('crop'), throwsUnsupportedError);
    // The first-use row is an ordinary status row.
    expect((events[1] as CaptureStatus).description, 'Loading OFIQ (first use, about 8 s)');
  });

  test('manual: settings used becomes the first event', () async {
    final events = await manualCaptureEvents(Stream.fromIterable([
      ProcessManualResponse(
          settingsUsed: CaptureSettingsUsed(
              values: CaptureSettings(jpegQuality: 80), overridden: ['jpeg_quality'])),
      ProcessManualResponse(
          imageData: ProcessImageData(index: 1, width: 2, height: 3, chunkData: [1])),
      ProcessManualResponse(
          imageData: ProcessImageData(index: 2, width: 2, height: 3, chunkData: [2])),
    ])).toList();

    expect(events.map((e) => e.runtimeType.toString()),
        ['CaptureSettingsReport', 'CameraPhoto', 'CameraPhoto']);
    final report = events.first as CaptureSettingsReport;
    expect(report.values.jpegQuality, 80);
    expect(report.overridden, ['jpeg_quality']);
    expect((events[2] as CameraPhoto).bytes, [2]);
  });
}
