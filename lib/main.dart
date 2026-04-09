import 'package:flutter/material.dart';

import 'app.dart';
import 'services/firebase_core_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseCoreService.ensureInitialized(); 
  runApp(const SmartLifeApp());
}
