import 'package:flutter/material.dart';

import 'app.dart';
// import 'services/firebase_core_service.dart'; // Tạm thời tắt Firebase

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await FirebaseCoreService.ensureInitialized(); // Tạm thời tắt Firebase
  runApp(const SmartLifeApp());
}
