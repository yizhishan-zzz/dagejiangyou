import 'dart:async';

import 'package:flutter/widgets.dart';

import 'app/app.dart';
import 'core/config/app_settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appSettings = AppSettings();
  runApp(MicroLogisticsApp(appSettings: appSettings));
  // Render the auth surface immediately; restoring a previous session must
  // never hold the first frame hostage to a platform storage plugin.
  unawaited(appSettings.load());
}
