import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:nest_craft/LandingPage.dart';

import 'package:nest_craft/firebase_options.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
void main() async{
  await Supabase.initialize(
    url:'https://ctazizhqefswgmlhedkg.supabase.co',
    publishableKey: 'sb_publishable_dqNyTjWjkp7oKP_C46aUpg_ZlhGG-ux');
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: LandingPage()
    );
  }
}
