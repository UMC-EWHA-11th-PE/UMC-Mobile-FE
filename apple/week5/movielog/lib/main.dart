import 'package:flutter/material.dart';

import 'app/movie_log_app.dart';
import 'data/local/secure_storage_cleanup.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await clearStaleSecureStorageOnFirstInstall();
  runApp(const MovieLogApp());
}
