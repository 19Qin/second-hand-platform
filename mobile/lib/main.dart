import 'package:flutter/material.dart';
import 'app.dart';
import 'injection.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize dependency injection
  await ServiceLocator().init();
  
  runApp(const MyApp());
}
