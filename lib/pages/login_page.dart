import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  // Supabase est initialisé dans main.dart
  final supabase = Supabase.instance.client;
  bool _isLoading = false;

  // --- PALETTE HARMONISÉE AVEC WELCOMEPAGE ---
  static const Color primaryDarkText = Color(0xFF1F487E); // Bleu pétrole pour texte sur fond blanc
  static const Color accentOrange = Color(0xFFD4AF37); // Jaune/Or Vif (Couleur d'action)
  static const Color errorRed = Color(0xFFE63946); // Rouge Piment
  // ------------------------------------------

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInManager() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs.')),
      );
      return;
    }

    // Vibration haptique au début de la connexion
    HapticFeedback.lightImpact();
    setState(() => _isLoading = true);

    try {
      await supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // CONNEXION RÉUSSIE
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        // Le Responsable est connecté, naviguer vers le tableau de bord
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/dashboard',
              (route) => false,
        );
      }
    } on AuthException catch (error) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur: Email ou Mot de passe incorrect.'),
          backgroundColor: errorRed,
        ),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur inattendue: $error')),
      );
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Accès Responsable', style: TextStyle(color: primaryDarkText, fontWeight: FontWeight.bold)), // NOUVEAU: Texte Sombre
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: primaryDarkText),
        elevation: 0,
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Icône de Connexion
              Icon(Icons.lock_person, size: 100, color: accentOrange),
              const SizedBox(height: 10),

              // Texte Principal
              Text(
                'Connexion Sécurisée',
                textAlign: TextAlign.center,
                style: TextStyle(color: primaryDarkText, fontSize: 24, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 50),

              // --- CHAMP EMAIL ---
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: primaryDarkText),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  labelText: 'Email',
                  labelStyle: TextStyle(color: primaryDarkText.withOpacity(0.7)),
                  prefixIcon: const Icon(Icons.email, color: primaryDarkText),
                  // Style de bordure unifié
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: primaryDarkText.withOpacity(0.3))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: primaryDarkText.withOpacity(0.3))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: accentOrange, width: 2)),
                ),
              ),
              const SizedBox(height: 20),

              // CHAMP MOT DE PASSE
              TextField(
                controller: _passwordController,
                obscureText: true,
                style: const TextStyle(color: primaryDarkText),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  labelText: 'Mot de Passe',
                  labelStyle: TextStyle(color: primaryDarkText.withOpacity(0.7)),
                  prefixIcon: const Icon(Icons.lock, color: primaryDarkText),
                  // Style de bordure unifié
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: primaryDarkText.withOpacity(0.3))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: primaryDarkText.withOpacity(0.3))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: accentOrange, width: 2)),
                ),
              ),
              const SizedBox(height: 50),

              // --- BOUTON DE CONNEXION ---
              ElevatedButton(
                onPressed: _isLoading ? null : _signInManager,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentOrange,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 60),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 10,
                  shadowColor: accentOrange.withOpacity(0.5),
                ),
                child: _isLoading
                    ? const SizedBox(
                    height: 25,
                    width: 25,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                    : const Text(
                  'Se Connecter',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}