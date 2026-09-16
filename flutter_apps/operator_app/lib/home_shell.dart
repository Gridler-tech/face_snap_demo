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
import 'ui/ui.dart';

/// Navigation shell: rail on the left (desktop idiom replacing the MAUI tab
/// bar), one entry per operator page.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _pages = [
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Scrollable so the rail never overflows a short window.
          LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: NavigationRail(
                    selectedIndex: _index,
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
                      for (final (label, icon, _) in _pages)
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
              index: _index,
              children: [for (final (_, _, page) in _pages) page],
            ),
          ),
        ],
      ),
    );
  }
}
