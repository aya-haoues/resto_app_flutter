import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pages/order_info_page.dart';
import 'pages/welcome_page.dart';
import 'pages/home_page.dart'; // Importation de la HomePage

// Constantes de couleurs (réutilisées)
const Color primaryBlue = Color(0xFF003366);
const Color lightGold = Color(0xFFf1c40f);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // IMPORTANT : REMPLACEZ CES VALEURS PAR VOS CLÉS SUPABASE
  await Supabase.initialize(
    url: 'https://wsqqggubsdhepayqeitv.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndzcXFnZ3Vic2RoZXBheXFlaXR2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjAxNjk5NDYsImV4cCI6MjA3NTc0NTk0Nn0.hMgS2bdA9VRzfgGXY9dThgAkyp1mU41r6a6iLjqOAJs',
    debug: true, // Activez le déboguage pour voir les logs Supabase
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App de Commande',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: primaryBlue),
        appBarTheme: const AppBarTheme(
          color: primaryBlue,
          titleTextStyle: TextStyle(color: lightGold, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        // Route initiale: La page d'accueil avec le bouton "Nouvelle Commande"
        '/': (context) => const WelcomePage(),

        // Route de saisie des informations client
        '/order_info': (context) => const OrderInfoPage(),

        // Route de la page du menu après soumission réussie
        '/pages/home_page.dart': (context) => const HomePage(),
      },
    );
  }
}
