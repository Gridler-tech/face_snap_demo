// About page: Gridler, the FaceSnap solution, and the open-source libraries
// the product is built on.
import 'package:flutter/material.dart';

import '../ui/ui.dart';

class _Library {
  const _Library(this.name, this.purpose, this.license);

  final String name;
  final String purpose;
  final String license;
}

const _serverLibraries = [
  _Library('OpenCV', 'camera capture and image processing', 'Apache-2.0'),
  _Library('MediaPipe', 'face landmarks and segmentation', 'Apache-2.0'),
  _Library('TensorFlow / tf-keras', 'deep-learning runtime', 'Apache-2.0'),
  _Library('DeepFace', 'face recognition framework', 'MIT'),
  _Library('Face recognition weights: Dlib / Facenet512 / SFace',
      'model files', 'CC0 (public domain) / MIT / Apache-2.0'),
  _Library('dlib', 'face recognition runtime', 'Boost'),
  _Library('ONNX Runtime', 'neural-network inference', 'MIT'),
  _Library('rembg / MODNet / U2-Net', 'background removal', 'MIT / Apache-2.0'),
  _Library('PyMatting, scikit-image, Numba', 'matting and image toolkits',
      'MIT / BSD'),
  _Library('gRPC (grpcio) & Protocol Buffers', 'client-server communication',
      'Apache-2.0 / BSD-3'),
  _Library('NumPy', 'numeric computing', 'BSD-3'),
  _Library('cv2-enumerate-cameras & pygrabber', 'Windows camera discovery',
      'MIT'),
  _Library('mpremote & pyserial', 'LED-board (MicroPython) link', 'MIT / BSD-3'),
  _Library('psutil', 'system monitoring', 'BSD-3'),
  _Library('Python', 'server runtime', 'PSF'),
];

const _qualityLibraries = [
  _Library('OFIQ', 'ISO/IEC 29794-5 reference face image quality assessment '
      '(BSI / eu-LISA)', 'MIT'),
];

const _appLibraries = [
  _Library('Flutter & Dart', 'operator and kiosk applications', 'BSD-3'),
  _Library('grpc & protobuf (Dart)', 'server communication', 'Apache-2.0 / BSD-3'),
  _Library('photo_view', 'photo zoom viewer', 'MIT'),
  _Library('file_selector', 'native save dialogs', 'BSD-3'),
  _Library('flutter_colorpicker', 'focus-light colour picker', 'MIT'),
  _Library('dartssh2', 'kiosk board server control (SSH)', 'MIT'),
];

const _boardLibraries = [
  _Library('MicroPython', 'LED controller firmware runtime', 'MIT'),
  _Library('Pimoroni Plasma libraries', 'LED strip control', 'MIT'),
];

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(children: [
        SectionCard(
          title: 'About FaceSnap',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'FaceSnap is a self-service photo kiosk by Gridler for '
                'ICAO-compliant identity photos. A column of six cameras at '
                'different heights automatically selects the camera at the '
                'customer’s eye level, calibrated LED lighting provides a '
                'measured, neutral white light, and every capture is checked '
                'automatically — from eyes, expression and head pose to '
                'sharpness and lighting — with optional scoring against '
                'the ISO/IEC 29794-5 international quality standard. '
                'A multi-camera liveness check confirms a real person is in '
                'front of the kiosk, and the background is replaced digitally '
                'so no backdrop is needed.',
                style: TextStyle(color: T.ink, fontSize: 13.5, height: 1.5),
              ),
              SizedBox(height: 12),
              Text(
                'Gridler · www.gridler.com · info@gridler.com',
                style: TextStyle(color: T.muted, fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SectionCard(
          title: 'Open source libraries',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'FaceSnap is built on the work of many open-source projects. '
                'The principal components and their licenses:',
                style: TextStyle(color: T.muted, fontSize: 12.5),
              ),
              const SizedBox(height: 10),
              _group('Server', _serverLibraries),
              _group('Quality assessment', _qualityLibraries),
              _group('Applications', _appLibraries),
              _group('LED board', _boardLibraries),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const SectionCard(
          title: 'Data protection & disclaimer',
          child: Text(
            'FaceSnap processes facial images and, when the face recognition '
            'feature is used, biometric data. The organisation operating this '
            'kiosk acts as the data controller and is solely responsible for '
            'compliance with applicable law — including the GDPR and the EU '
            'AI Act — such as establishing a lawful basis for processing, '
            'informing the persons photographed, and the storage, retention '
            'and deletion of captured images.\n\n'
            'The software is provided “as is”. To the maximum extent '
            'permitted by applicable law, Gridler accepts no liability for '
            'unlawful use or misuse of the system or for damages arising '
            'from it. The applicable license or purchase agreement governs; '
            'this notice is informational and does not constitute legal '
            'advice.',
            style: TextStyle(color: T.muted, fontSize: 12.5, height: 1.5),
          ),
        ),
      ]),
    );
  }

  static Widget _group(String title, List<_Library> libraries) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: T.titleBlue,
                  fontSize: 13,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          for (final library in libraries)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 280,
                    child: Text(library.name,
                        style:
                            const TextStyle(color: T.ink, fontSize: 13)),
                  ),
                  Expanded(
                    child: Text('${library.purpose}  —  ${library.license}',
                        style:
                            const TextStyle(color: T.muted, fontSize: 12.5)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
