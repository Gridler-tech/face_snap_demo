import 'package:face_snap_grpc/face_snap_grpc.dart';
import 'package:flutter/material.dart';

import 'home_shell.dart';
import 'services/app_config.dart';
import 'services/photo_store.dart';
import 'services/settings_state.dart';
import 'ui/dev_info.dart';
import 'ui/ui.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // No connect screen: load the last-used address and point the shared channel
  // at it, then enter straight into the app. The operator picks/searches a
  // server from the Kiosk page (Server card). Loading the settings snapshot is
  // best-effort — if that server is down or unset the app still opens, showing
  // "No server" until one is chosen.
  await AppConfig.load();
  DevMode.enabled.value = AppConfig.devMode;
  // Two independent startup jobs, in parallel: reading the persisted captures
  // (Face recognition compares them against stored reference photos, possibly
  // days later — up to 18 JPEGs of disk I/O) and the first settings snapshot
  // over the network.
  await Future.wait([
    PhotoStore.load(),
    () async {
      await GrpcChannelProvider.setAddress(AppConfig.host, AppConfig.port);
      try {
        await SettingsState.refresh();
      } catch (_) {
        // Not reachable yet — the Kiosk page's Server card handles connecting.
      }
    }(),
  ]);

  // ExcludeSemantics: the Flutter Windows accessibility bridge corrupts its
  // AXTree on every page switch in this app ("Failed to update ui::AXTree,
  // error: Nodes left pending by the update" in stderr) and then intermittently
  // dies with 0xc0000005 in flutter_windows.dll when a UIA client queries the
  // corrupted tree — a UIA client is active by default on Windows 11, so this
  // crashed the app in normal use (Event Log 2026-07-23, twice, same fault
  // offset). Known upstream engine bug class (flutter#119125, #103808).
  // Excluding the whole app from semantics keeps the bridge's tree empty so
  // there is nothing to corrupt. Trade-off: no screen-reader support — an
  // accepted cost for this internal operator tool. Revisit after a Flutter
  // upgrade by removing this wrapper and re-checking stderr for the AXTree
  // errors while switching pages.
  runApp(const ExcludeSemantics(child: OperatorApp()));
}

class OperatorApp extends StatelessWidget {
  const OperatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FaceSnap Operator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: T.titleBlue,
        scaffoldBackgroundColor: T.ground,
        useMaterial3: true,
      ),
      home: const HomeShell(),
    );
  }
}
