import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:glamora_project/core/utils/app_router.dart';

void main() async{
    WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(const GlamoraApp());
}

class GlamoraApp extends StatelessWidget {
  const GlamoraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: AppRouter.router,
      debugShowCheckedModeBanner: false,
    );
  }
}
