import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:oculio_mobile/screens/reading_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  runApp(const OculioApp());
}

class OculioApp extends StatelessWidget {
  const OculioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Oculio Phase 0',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4F8EF7),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const ReadingScreen(),
    );
  }
}
