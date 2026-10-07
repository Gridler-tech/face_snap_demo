import 'package:flutter/material.dart';

import 'pages/about_page.dart';
import 'pages/calibration_page.dart';
import 'pages/camera_page.dart';
import 'pages/capture_page.dart';
import 'pages/face_recognition_page.dart';
import 'pages/kiosk_page.dart';
import 'pages/lighting_page.dart';
import 'pages/monitoring_page.dart';
import 'pages/photo_page.dart';
import 'pages/updater_page.dart';
import 'ui/dev_info.dart';
import 'ui/rpc_console.dart';
import 'ui/ui.dart';

/// Navigation shell: rail on the left (desktop idiom replacing the MAUI tab
/// bar), one entry per operator page. In developer mode the rail's top holds
/// the RPC console button; the console docks along the bottom of the window
/// and stays open across page switches.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    DevMode.enabled.addListener(_onDevModeChanged);
  }

  @override
  void dispose() {
    DevMode.enabled.removeListener(_onDevModeChanged);
    super.dispose();
  }

  /// Leaving developer mode closes the console (and stops recording).
  void _onDevModeChanged() {
    if (!DevMode.enabled.value) RpcConsoleController.instance.setOpen(false);
  }

  static const _operatorPages = [
    ('Kiosk', Icons.sensors, KioskPage()),
    ('Capture', Icons.center_focus_strong, CapturePage()),
    ('Face recognition', Icons.badge_outlined, FaceRecognitionPage()),
    ('Photo', Icons.photo_outlined, PhotoPage()),
    ('Lighting', Icons.lightbulb_outline, LightingPage()),
    ('Camera', Icons.photo_camera_outlined, CameraPage()),
    ('Calibration', Icons.straighten, CalibrationPage()),
    ('Monitoring', Icons.monitor_heart_outlined, MonitoringPage()),
    ('About', Icons.info_outline, AboutPage()),
  ];

  /// The Updater (install / update / remove / batch — fleet-destructive)
  /// only appears in dev mode, so an operator's everyday rail never shows it.
  static const _updaterPage =
      ('Updater', Icons.system_update_alt, UpdaterPage());

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: DevMode.enabled,
      builder: (context, dev, _) {
        final pages = [..._operatorPages, if (dev) _updaterPage];
        // Leaving dev mode while on the Updater page: fall back to Kiosk.
        final index = _index < pages.length ? _index : 0;
        return _shell(pages, index, dev);
      },
    );
  }

  Widget _shell(List<(String, IconData, Widget)> pages, int index, bool dev) {
    return Scaffold(
      body: Column(children: [
        Expanded(child: _pagesRow(pages, index, dev)),
        // The RPC console, docked full width under the rail and the page.
        ValueListenableBuilder<bool>(
          valueListenable: RpcConsoleController.instance.open,
          builder: (context, open, _) => open && dev
              ? const RpcConsoleDock()
              : const SizedBox.shrink(),
        ),
      ]),
    );
  }

  Widget _pagesRow(
      List<(String, IconData, Widget)> pages, int index, bool dev) {
    return Row(
        children: [
          // Scrollable so the rail never overflows a short window.
          LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: NavigationRail(
                    selectedIndex: index,
                    leading: dev
                        ? const Padding(
                            padding: EdgeInsets.only(top: 6, bottom: 4),
                            child: RpcConsoleButton(),
                          )
                        : null,
                    onDestinationSelected: (i) => setState(() => _index = i),
                    labelType: NavigationRailLabelType.all,
                    backgroundColor: Colors.white,
                    indicatorColor: const Color(0xFFDCE9F6),
                    selectedIconTheme:
                        const IconThemeData(color: T.titleBlue),
                    selectedLabelTextStyle: const TextStyle(
                        color: T.titleBlue,
                        fontWeight: FontWeight.w700,
                        fontSize: 12),
                    unselectedLabelTextStyle:
                        const TextStyle(color: T.muted, fontSize: 12),
                    destinations: [
                      for (final (label, icon, _) in pages)
                        NavigationRailDestination(
                            icon: Icon(icon), label: Text(label)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const VerticalDivider(width: 1, color: T.cardStroke),
          Expanded(
            child: IndexedStack(
              index: index,
              children: [for (final (_, _, page) in pages) page],
            ),
          ),
        ],
    );
  }
}
