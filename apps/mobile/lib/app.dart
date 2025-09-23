import 'package:flutter/material.dart';
import 'package:mobile/root_shell.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Second-Hand',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF32C286)),
        useMaterial3: true,
      ),
      home: const RootShell(),
    );
  }
}
