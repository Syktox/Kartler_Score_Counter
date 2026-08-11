import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/app.dart';

export 'app/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  unawaited(
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    ),
  );
  runApp(const KartlerApp());
}
