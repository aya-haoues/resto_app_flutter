// lib/pages/order_info_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // <--- AJOUTER CETTE LIGNE POUR FilteringTextInputFormatter
import 'package:http/http.dart' as http; // <--- AJOUTER CETTE LIGNE POUR http
import 'dart:convert'; // <--- AJOUTER CETTE LIGNE POUR jsonEncode
import '../models/food_item.dart'; // Ajustez le chemin si nécessaire
import 'home_page.dart';
// ... autres imports ...

// ... vos constantes de couleurs (primaryBackground, textPrimary, etc.) ...
// Exemple (remplacez par vos véritables constantes) :
const Color primaryBackground = Color(0xFFFFF0F0);
const Color textPrimary = Color(0xFF1E293B);
const Color textSecondary = Color(0xFF64748B);
const Color accentOrange = Color(0xFFFF6B35);
const Color shadowColor = Color(0x0F1E293B);

class OrderInfoPage extends StatefulWidget {
  final List<FoodItem> panier; // ✅ Nouveau paramètre pour le panier
  const OrderInfoPage({super.key, required this.panier}); // ✅ Requis

  @override
  State<OrderInfoPage> createState() => _OrderInfoPageState(); // <--- Renommé en _OrderInfoPageState
}

// --- CHANGÉ : Renommé la classe d'état ---
class _OrderInfoPageState extends State<OrderInfoPage> // <--- Renommé en _OrderInfoPageState
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _tableController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _scaleAnimation;
  final FocusNode _nameFocusNode = FocusNode();
  bool _isLoading = false;
  String? _errorMessage;

  // Variable pour stocker temporairement le numéro de table sélectionné
  int? _selectedTableNumber;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );
    _slideAnimation = Tween<double>(begin: 0.3, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic),
      ),
    );
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 1.0, curve: Curves.elasticOut),
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _nameFocusNode.requestFocus();
      _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _nameController.dispose();
    _tableController.dispose();
    _notesController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  // --- NOUVELLE FONCTION : Mettre à jour le statut de la table dans la base de données ---
  // lib/pages/order_info_page.dart
  Future<void> _markTableAsOccupied(int tableNumber, String? notes) async {
    // <--- Remettre 'notes' en paramètre
    try {
      final response = await http.put(
        Uri.parse('http://192.168.56.1:8082/tables/$tableNumber'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'status': 'occupied',
          'notes': notes ?? 'Aucune note spéciale', // <--- REMETTRE L'ENVOI DES NOTES
        }),
      );

      if (response.statusCode == 200) {
        print(
            '✅ Statut de la table $tableNumber mis à jour à "occupied" et notes enregistrées dans la base de données.');
      } else {
        final errorBody = jsonDecode(response.body);
        final errorMsg = errorBody['error'] ?? 'Erreur inconnue';
        print(
            '❌ Erreur lors de la mise à jour de la table $tableNumber: ${response
                .statusCode} - $errorMsg');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur mise à jour table: $errorMsg'),
                backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      print(
          '❌ Erreur réseau lors de la mise à jour de la table $tableNumber: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Erreur réseau: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _submitOrderInfo() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    HapticFeedback.lightImpact();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      // ✅ Récupérer les valeurs du formulaire
      final String clientName = _nameController.text.trim();
      final int tableNumber = int.parse(_tableController.text);
      final String? notes = _notesController.text
          .trim()
          .isEmpty ? null : _notesController.text
          .trim(); // <--- Récupérer les notes

      // ✅ Stocker le numéro de table dans la variable d'instance
      _selectedTableNumber = tableNumber;

      // ✅ Appeler la fonction pour marquer la table comme occupée ET enregistrer les notes
      await _markTableAsOccupied(tableNumber, notes);
      // ✅ Afficher la notification de succès
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Informations envoyées!'),
            backgroundColor: Colors.green,
            duration: const Duration(milliseconds: 1500),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
        );
      }

      // ✅ Réinitialiser les champs du formulaire après succès
      _nameController.clear();
      _tableController.clear();
      _notesController.clear();
      _formKey.currentState?.reset();

      // ✅ Naviguer vers HomePage avec les données client
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) =>
                HomePage(
                  initialClientName: clientName,
                  initialTableNumber: tableNumber,
                  initialNotes: notes ??
                      "", // <--- Passer les notes à HomePage (optionnel, pour affichage client)
                ),
          ),
        );
      }
    } on FormatException {
      setState(() {
        _errorMessage = 'Numéro de table invalide.';
      });
    } catch (e) {
      print('General Error: $e');
      setState(() {
        _errorMessage = 'Une erreur inattendue est survenue: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // --- WIDGETS PRIVÉS (déplacés hors de build) ---

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Préparez votre commande',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: textPrimary,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Renseignez vos informations pour commencer',
          style: TextStyle(
            fontSize: 16,
            color: textSecondary,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool isOptional = false,
    FocusNode? focusNode,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: shadowColor.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: keyboardType,
        validator: isOptional ? null : validator,
        maxLines: maxLines,
        inputFormatters: keyboardType == TextInputType.number
            ? [FilteringTextInputFormatter.digitsOnly]
            : null, // <--- CORRECTION : Utiliser FilteringTextInputFormatter
        style: const TextStyle(
          color: textPrimary,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: isOptional ? '$labelText (Facultatif)' : labelText,
          labelStyle: const TextStyle(color: textSecondary),
          prefixIcon: Icon(icon, color: textSecondary),
          filled: true,
          fillColor: primaryBackground,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: accentOrange, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.redAccent, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.redAccent, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: Colors.red.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(
                color: Colors.red.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient( // <--- RENDU CONST ICI
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              // Utilisez vos couleurs DashboardColors ou une autre constante si elles sont définies
              // DashboardColors.buttonGradientStart,
              // DashboardColors.buttonGradientEnd,
              // Pour l'exemple, on utilise des couleurs arbitraires
              Color(0xFFFF9E80), // Exemple : DashboardColors.accentCoral
              Color(0xFFFF6B9D), // Exemple : DashboardColors.accentPink
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: accentOrange.withOpacity(_isLoading ? 0.2 : 0.3),
              blurRadius: 15,
              spreadRadius: 2,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _submitOrderInfo,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 0,
          ),
          child: _isLoading
              ? const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
          )
              : const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'CONFIRMER',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(width: 12),
              Icon(Icons.arrow_forward_rounded, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  // --- MÉTHODE BUILD ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryBackground,
      appBar: AppBar(
        title: const Text(
          'Informations de Commande',
          style: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        backgroundColor: primaryBackground,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return FadeTransition(
            opacity: _opacityAnimation,
            child: Transform.translate(
              offset: Offset(0, _slideAnimation.value * 100),
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        // En-tête
                        _buildHeader(),
                        const SizedBox(height: 32),
                        // Formulaire
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              _buildTextField(
                                controller: _nameController,
                                focusNode: _nameFocusNode,
                                labelText: 'Votre Nom',
                                icon: Icons.person_outline_rounded,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Veuillez entrer votre nom';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),
                              _buildTextField(
                                controller: _tableController,
                                labelText: 'Numéro de Table',
                                icon: Icons.table_restaurant_rounded,
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Veuillez entrer le numéro de table';
                                  }
                                  if (int.tryParse(value) == null) {
                                    return 'Doit être un nombre valide';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),
                              _buildTextField(
                                controller: _notesController,
                                labelText: 'Notes Spéciales',
                                icon: Icons.note_alt_rounded,
                                maxLines: 3,
                                isOptional: true,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Message d'erreur
                        if (_errorMessage != null)
                          _buildErrorCard(),
                        const SizedBox(height: 24),
                        // Bouton de soumission, enveloppé dans Center
                        Center(
                          child: _buildSubmitButton(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}