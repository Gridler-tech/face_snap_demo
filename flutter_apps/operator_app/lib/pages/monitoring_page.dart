// Monitoring page — port of the MAUI MonitoringPage: hardware status (the
// server checks board + every camera), kiosk info and live system usage.
import 'dart:async';

import 'package:face_snap_grpc/face_snap_grpc.dart';
import 'package:flutter/material.dart';

import '../services/settings_state.dart';
import '../ui/dev_info.dart';
import '../ui/ui.dart';

class MonitoringPage extends StatefulWidget {
  const MonitoringPage({super.key});

  @override
  State<MonitoringPage> createState() => _MonitoringPageState();
}

class _MonitoringPageState extends State<MonitoringPage> {
  final List<(String, String)> _statusLines = [];
  bool _statusRunning = false;
  KioskInfoResponse? _kioskInfo;
  final Map<UsageType, String> _usage = {};
  StreamSubscription<UsageResponse>? _usageSubscription;
  String? _message;
  LightMeasurementResponse? _light;
  bool _lightRunning = false;

  MonitoringClient get _monitoring =>
      MonitoringClient(GrpcChannelProvider.channel);

  @override
  void initState() {
    super.initState();
    _loadKioskInfo();
    _measureLight();
    // Retry the loads when the server comes up after app start.
    SettingsState.revision.addListener(_onSettingsChanged);
  }

  @override
  void dispose() {
    SettingsState.revision.removeListener(_onSettingsChanged);
    _usageSubscription?.cancel();
    super.dispose();
  }

  void _onSettingsChanged() {
    if (mounted && _kioskInfo == null) {
      _loadKioskInfo();
      _measureLight();
    }
  }

  Future<void> _loadKioskInfo() async {
    try {
      final info = await KioskClient(GrpcChannelProvider.channel)
          .getKioskInfo(Empty());
      setState(() => _kioskInfo = info);
    } catch (e) {
      setState(() => _message = 'Could not load kiosk info: ${operatorMessage(e)}');
    }
  }

  Future<void> _getKioskStatus() async {
    setState(() {
      _statusRunning = true;
      _statusLines.clear();
      _message = null;
    });
    try {
      await for (final line in _monitoring.getKioskStatus(Empty())) {
        setState(() => _statusLines.add((line.description, line.status)));
      }
    } catch (e) {
      setState(() => _message = 'Kiosk status failed: ${operatorMessage(e)}');
    } finally {
      setState(() => _statusRunning = false);
    }
  }

  Future<void> _measureLight() async {
    setState(() => _lightRunning = true);
    try {
      final light = await _monitoring.getLightMeasurement(Empty());
      if (mounted) setState(() => _light = light);
    } catch (e) {
      if (mounted) {
        setState(() => _light = LightMeasurementResponse(
            available: false, error: 'RPC failed: $e'));
      }
    } finally {
      if (mounted) setState(() => _lightRunning = false);
    }
  }

  void _toggleUsage() {
    if (_usageSubscription != null) {
      _usageSubscription!.cancel();
      setState(() => _usageSubscription = null);
      return;
    }
    final subscription = _monitoring.odroidUsage(Empty()).listen(
      (u) => setState(() => _usage[u.usageType] = u.usage),
      onError: (Object e) => setState(() {
        _message = 'Usage stream failed: ${operatorMessage(e)}';
        _usageSubscription = null;
      }),
      onDone: () => setState(() => _usageSubscription = null),
    );
    setState(() => _usageSubscription = subscription);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(children: [
        SectionCard(
          title: 'Hardware status',
          titleLeading: const DevInfoBadge('monitoring-status'),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(
              width: 220,
              child: GoButton(
                text: _statusRunning ? 'Checking…' : 'Get kiosk status',
                onPressed: _statusRunning ? null : _getKioskStatus,
              ),
            ),
            const SizedBox(height: 12),
            if (_statusLines.isNotEmpty)
              Container(
                constraints: const BoxConstraints(maxHeight: 280),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _statusLines.length,
                  itemBuilder: (_, i) {
                    final (description, status) = _statusLines[i];
                    final ok = status.toUpperCase() == 'OK';
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(children: [
                        Container(
                          width: 20,
                          height: 20,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                              color: ok ? T.pass : T.fail,
                              shape: BoxShape.circle),
                          child: Text(ok ? '✓' : '✕',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 11)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: RowLabel(description)),
                      ]),
                    );
                  },
                ),
              ),
          ]),
        ),
        const SizedBox(height: 14),
        SectionCard(
          title: 'Kiosk info',
          titleLeading: const DevInfoBadge('kiosk-info'),
          child: _kioskInfo == null
              ? const Text('Loading…',
                  style: TextStyle(color: T.muted, fontSize: 13))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RowLabel(
                        'Server: ${_kioskInfo!.kioskInfo.serverIpAddress}:${_kioskInfo!.kioskInfo.port}'),
                    const SizedBox(height: 4),
                    RowLabel(
                        'Cameras: ${_kioskInfo!.kioskInfo.numberOfCameras} '
                        '(${_kioskInfo!.cameraInfo.map((c) => c.index).join(', ')})'),
                  ],
                ),
        ),
        const SizedBox(height: 14),
        SectionCard(
          title: 'Lighting',
          titleLeading: const DevInfoBadge('light-measurement'),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(
              width: 220,
              child: QuietButton(
                text: _lightRunning ? 'Measuring…' : 'Measure light',
                onPressed: _lightRunning ? null : _measureLight,
              ),
            ),
            const SizedBox(height: 10),
            if (_light != null)
              _light!.available
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RowLabel(
                            'Illuminance: ${_light!.lux.toStringAsFixed(1)} lux'),
                        const SizedBox(height: 4),
                        RowLabel(
                            'Colour temperature: ${_light!.cct.round()} K'),
                        const SizedBox(height: 4),
                        RowLabel('CIE xy: ${_light!.cieX.toStringAsFixed(4)}, '
                            '${_light!.cieY.toStringAsFixed(4)}'),
                      ],
                    )
                  : Text('Light sensor unavailable: ${_light!.error}',
                      style: const TextStyle(color: T.muted, fontSize: 13)),
          ]),
        ),
        const SizedBox(height: 14),
        SectionCard(
          title: 'System usage',
          titleLeading: const DevInfoBadge('usage-stream'),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(
              width: 220,
              child: QuietButton(
                text: _usageSubscription == null
                    ? 'Start monitoring'
                    : 'Stop monitoring',
                onPressed: _toggleUsage,
              ),
            ),
            const SizedBox(height: 10),
            if (_usage.isNotEmpty) ...[
              RowLabel('CPU: ${_usage[UsageType.CPU] ?? '—'} %'),
              const SizedBox(height: 4),
              RowLabel('Memory: ${_usage[UsageType.MEMORY] ?? '—'} %'),
              const SizedBox(height: 4),
              RowLabel('CPU cores: ${_usage[UsageType.CPU_COUNT] ?? '—'}'),
              const SizedBox(height: 4),
              RowLabel('Boot time: ${_usage[UsageType.BOOT_TIME] ?? '—'}'),
            ],
          ]),
        ),
        ErrorLine(_message),
      ]),
    );
  }
}
