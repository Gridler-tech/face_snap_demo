import 'package:flutter/material.dart';

import 'pages/about_page.dart';
import 'pages/calibration_page.dart';
import 'pages/camera_page.dart';
import 'pages/capture_page.dart';
import 'pages/column_page.dart';
import 'pages/face_recognition_page.dart';
import 'pages/kiosk_page.dart';
import 'pages/lighting_page.dart';
import 'pages/monitoring_page.dart';
import 'pages/photo_page.dart';
import 'pages/updater_page.dart';
import 'services/column_state.dart';
import 'ui/dev_info.dart';
import 'ui/page_nav.dart';
import 'ui/rpc_console.dart';
import 'ui/ui.dart';

typedef _Page = (String, IconData, Widget);

/// Navigation shell: rail on the left (desktop idiom replacing the MAUI tab
/// bar), one entry per operator page. In developer mode the rail's top holds
/// the RPC console button; the console docks along the bottom of the window
/// and stays open across page switches. The Column page is on the rail only
/// while the server has the column profile (ColumnState.available, spec
/// 2026-10-10 section 5.5); a page asks for another one through PageNav (the
/// ● marks' "open the Column page").
/// The shell's page stack and rail for [dev] mode, [busy] (an Updater run is
/// going on, UpdaterRun.busy) and [column] (the server has the column
/// profile). The Updater stays in the stack while it runs, hidden once dev
/// mode is off (FL-2). The page stack keeps its order whatever the rail shows:
/// IndexedStack matches its children by position, so a page that came and
/// went in the middle would rebuild the pages after it (their state lost).
({List<_Page> stack, List<_Page> rail}) shellPages(
    {required bool dev, required bool busy, required bool column}) {
  const pages = _HomeShellState._operatorPages;
  const updater = _HomeShellState._updaterPage;
  final afterCalibration = pages.indexWhere((p) => p.$1 == 'Calibration') + 1;
  return (
    stack: [...pages, _HomeShellState._columnPage, if (dev || busy) updater],
    rail: [
      ...pages.sublist(0, afterCalibration),
      if (column) _HomeShellState._columnPage,
      ...pages.sublist(afterCalibration),
      if (dev) updater,
    ],
  );
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  // The selected page by its rail label: the rail's entries come and go (the
  // Column page with the server, the Updater with dev mode).
  String _selected = 'Kiosk';

  @override
  void initState() {
    super.initState();
    DevMode.enabled.addListener(_onDevModeChanged);
    PageNav.request.addListener(_onPageRequest);
    ColumnState.revision.addListener(_onColumnChanged);
  }

  @override
  void dispose() {
    DevMode.enabled.removeListener(_onDevModeChanged);
    PageNav.request.removeListener(_onPageRequest);
    ColumnState.revision.removeListener(_onColumnChanged);
    super.dispose();
  }

  /// Leaving developer mode closes the console (and stops recording).
  void _onDevModeChanged() {
    if (!DevMode.enabled.value) RpcConsoleController.instance.setOpen(false);
  }

  void _onPageRequest() {
    final label = PageNav.request.value;
    if (label != null && mounted) setState(() => _selected = label);
  }

  void _onColumnChanged() {
    if (mounted) setState(() {});
  }

  static const _operatorPages = <_Page>[
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

  /// The column profile (spec 2026-10-10 section 5.5): on the rail right after
  /// Calibration, while the server has it.
  static const _columnPage = (columnPageLabel, Icons.view_column_outlined, ColumnPage());

  /// The Updater (install / update / remove / batch — fleet-destructive)
  /// only appears in dev mode, so an operator's everyday rail never shows it.
  static const _updaterPage =
      ('Updater', Icons.system_update_alt, UpdaterPage());

  @override
  Widget build(BuildContext context) {
    // UpdaterRun.busy too: leaving dev mode mid-run keeps the Updater mounted.
    return ListenableBuilder(
      listenable: Listenable.merge([DevMode.enabled, UpdaterRun.busy]),
      builder: (context, _) {
        final dev = DevMode.enabled.value;
        final (:stack, :rail) = shellPages(
            dev: dev, busy: UpdaterRun.busy.value, column: ColumnState.available);
        // A page not on the rail (the Updater after leaving dev mode, the Column
        // page on an older server): the Kiosk page, which then stays selected, so
        // the page does not open by itself when it comes back.
        var railIndex = rail.indexWhere((p) => p.$1 == _selected);
        if (railIndex < 0) {
          railIndex = 0;
          _selected = rail[0].$1;
        }
        final stackIndex = stack.indexWhere((p) => p.$1 == rail[railIndex].$1);
        return _shell(rail, railIndex, stack, stackIndex, dev);
      },
    );
  }

  Widget _shell(List<_Page> rail, int railIndex, List<_Page> stack, int stackIndex, bool dev) {
    return Scaffold(
      body: Column(children: [
        Expanded(child: _pagesRow(rail, railIndex, stack, stackIndex, dev)),
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

  Widget _pagesRow(List<_Page> rail, int railIndex, List<_Page> stack, int stackIndex, bool dev) {
    return Row(
        children: [
          // Scrollable so the rail never overflows a short window.
          LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: NavigationRail(
                    selectedIndex: railIndex,
                    leading: dev
                        ? const Padding(
                            padding: EdgeInsets.only(top: 6, bottom: 4),
                            child: RpcConsoleButton(),
                          )
                        : null,
                    onDestinationSelected: (i) => setState(() => _selected = rail[i].$1),
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
                      for (final (label, icon, _) in rail)
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
              index: stackIndex,
              children: [for (final (_, _, page) in stack) page],
            ),
          ),
        ],
    );
  }
}
