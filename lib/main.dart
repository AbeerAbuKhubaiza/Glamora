import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:glamora_project/core/routing/app_router.dart';
import 'package:google_fonts/google_fonts.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const GlamoraApp());
}

class GlamoraApp extends StatelessWidget {
  const GlamoraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      theme: ThemeData(textTheme: GoogleFonts.plusJakartaSansTextTheme()),

      routerConfig: AppRouter.router,
      debugShowCheckedModeBanner: false,
    );
  }
}
