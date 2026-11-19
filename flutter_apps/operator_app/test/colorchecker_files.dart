// The colour-card data these tests share with tools/colorchecker (cc_probe and its fixture
// generator): three folders up in the FaceSnap repository (client/flutter/operator_app), two
// in the public demo repository (flutter_apps/operator_app), which mirrors those files.
import 'dart:io';

final String colorcheckerDir = const ['../../../tools/colorchecker', '../../tools/colorchecker']
    .firstWhere((dir) => Directory(dir).existsSync(), orElse: () => '../../../tools/colorchecker');
