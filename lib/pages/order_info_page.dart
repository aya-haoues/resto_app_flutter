import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/food_item.dart';
import 'home_page.dart';

// Define color constants for the form
const Color primaryBackground = Color(0xFFF8FAFC);
const Color textPrimary = Color(0xFF1E293B);
const Color textSecondary = Color(0xFF64748B);
const Color accentOrange = Color(0xFFF17551);
const Color accentGreen = Color(0xFFD64E4E);
const Color shadowColor = Color(0x0F1E293B);

class OrderInfoPage extends StatefulWidget {
  final List<FoodItem> panier;
  const OrderInfoPage({super.key, required this.panier});

  @override
  State<OrderInfoPage> createState() => _OrderInfoPageState();
}

class _OrderInfoPageState extends State<OrderInfoPage>
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

  // Toggle between modes: creating a new order vs finding an existing one
  bool _isFindingOrder = false;

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

  // --- WIDGET: Show a dialog with available tables ---
  void _showAvailableTablesDialog(List<int> availableTables, String clientName, String? notes) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Table occupée !'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('La table que vous avez choisie est occupée.'),
                const SizedBox(height: 8),
                const Text('Veuillez choisir une table libre parmi les suivantes :'),
                const SizedBox(height: 12),
                // Afficher la liste des tables disponibles
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: availableTables.map((tableNum) {
                    return ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        // Mettre à jour le numéro de table dans le contrôleur
                        _tableController.text = tableNum.toString();
                        // Fermer la boîte de dialogue
                        Navigator.of(context).pop();
                      },
                      child: Text('Table $tableNum'),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
          ],
        );
      },
    );
  }

  // --- FUNCTION: Find Existing Order ---
  Future<void> _findExistingOrder(String clientName, int tableNumber) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _isFindingOrder = true;
    });

    try {
      final response = await http.get(
        Uri.parse(
            'http://10.187.253.200:8082/client-order?client_name=$clientName&table_number=$tableNumber'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Navigate to HomePage with the found order's details
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => HomePage(
              initialClientName: clientName,
              initialTableNumber: tableNumber,
              initialNotes: data['notes'] ?? "",
              initialOrderId: data['id'],
              initialOrderStatus: data['status'],
            ),
          ),
        );
      } else if (response.statusCode == 404) {
        setState(() {
          _errorMessage = 'Aucune commande active trouvée.';
        });
      } else {
        final errorBody = jsonDecode(response.body);
        final errorMsg = errorBody['error'] ?? 'Erreur inconnue';
        setState(() {
          _errorMessage = 'Erreur: $errorMsg';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur réseau: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
        _isFindingOrder = false;
      });
    }
  }

  // --- FUNCTION: Submit New Order Info ---
  // --- FUNCTION: Submit New Order Info (CORRIGÉE) ---
  Future<void> _submitNewOrderInfo() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    HapticFeedback.lightImpact();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final String clientName = _nameController.text.trim();
      final int tableNumber = int.parse(_tableController.text);
      final String? notes = _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim();

      // Check if the table is already occupied
      final tableStatus = await _checkTableStatus(tableNumber);
      if (tableStatus == 'occupied') {
        // La table est occupée, on propose les tables libres
        final availableTables = await _loadAvailableTables();
        if (availableTables.isEmpty) {
          setState(() {
            _errorMessage = 'Toutes les tables sont actuellement occupées. Veuillez réessayer plus tard.';
          });
        } else {
          // Afficher une boîte de dialogue avec les tables disponibles
          _showAvailableTablesDialog(availableTables, clientName, notes);
        }
        return; // Important: ne pas continuer le processus normal
      }

      // Si la table est libre, on continue normalement
      await _markTableAsOccupied(tableNumber, notes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Informations envoyées!'), backgroundColor: Colors.green),
        );
      }

      _nameController.clear();
      _tableController.clear();
      _notesController.clear();
      _formKey.currentState?.reset();

      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => HomePage(
              initialClientName: clientName,
              initialTableNumber: tableNumber,
              initialNotes: notes ?? "",
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

  // --- Helper: Load all tables to find available ones ---
  Future<List<int>> _loadAvailableTables() async {
    final availableTables = <int>[];
    try {
      final response = await http.get(
        Uri.parse('http://10.187.253.200:8082/tables'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> tablesData = jsonDecode(response.body);
        for (var table in tablesData) {
          if (table['status'] != 'occupied') {
            availableTables.add(table['number'] as int);
          }
        }
      }
    } catch (e) {
      print('Erreur lors du chargement des tables disponibles: $e');
    }
    return availableTables;
  }

  // --- Helper: Check Table Status ---
  Future<String?> _checkTableStatus(int tableNumber) async {
    try {
      final response = await http.get(
        Uri.parse('http://10.187.253.200:8082/check-table/$tableNumber'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['status'];
      }
    } catch (e) {
      print('Erreur vérification table: $e');
    }
    return null;
  }

  // --- Helper: Mark Table as Occupied ---
  Future<void> _markTableAsOccupied(int tableNumber, String? notes) async {
    try {
      final response = await http.put(
        Uri.parse('http://10.187.253.200:8082/tables/$tableNumber'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'status': 'occupied',
          'notes': notes ?? 'Aucune note spéciale',
        }),
      );
      if (response.statusCode != 200) {
        final errorBody = jsonDecode(response.body);
        final errorMsg = errorBody['error'] ?? 'Erreur inconnue';
        throw Exception('Erreur: $errorMsg');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
      rethrow;
    }
  }

  // --- WIDGETS ---
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isFindingOrder ? 'Retrouver ma commande' : 'Préparez votre commande',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: textPrimary,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _isFindingOrder
              ? 'Entrez vos informations pour retrouver votre commande.'
              : 'Renseignez vos informations pour commencer',
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
            : null,
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
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Color(0xFFFF9E80),
              Color(0xFFFF6B9D),
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
          onPressed: _isLoading
              ? null
              : _isFindingOrder
              ? () {
            final String clientName = _nameController.text.trim();
            final int tableNumber = int.tryParse(_tableController.text) ?? 0;
            if (clientName.isNotEmpty && tableNumber > 0) {
              _findExistingOrder(clientName, tableNumber);
            } else {
              setState(() {
                _errorMessage = 'Veuillez entrer un nom et un numéro de table valides.';
              });
            }
          }
              : _submitNewOrderInfo,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 0,
          ),
          child: _isLoading
              ? const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(color: Colors.white),
          )
              : Text(
            _isFindingOrder ? 'TROUVER MA COMMANDE' : 'CONFIRMER',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.5),
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchModeButton() {
    return TextButton(
      onPressed: () {
        setState(() {
          _isFindingOrder = !_isFindingOrder;
          _errorMessage = null;
          _nameController.clear();
          _tableController.clear();
          _notesController.clear();
          _formKey.currentState?.reset();
        });
      },
      child: Text(
        _isFindingOrder
            ? 'Je veux créer une nouvelle commande'
            : 'J\'ai déjà commandé, retrouver ma commande',
        style: TextStyle(color: accentOrange, fontWeight: FontWeight.bold),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryBackground,
      appBar: AppBar(
        title: const Text(
          'Informations de Commande',
          style: TextStyle(color: textPrimary, fontWeight: FontWeight.w700, fontSize: 20),
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
                        _buildHeader(),
                        const SizedBox(height: 32),
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
                              if (!_isFindingOrder) ...[
                                const SizedBox(height: 20),
                                _buildTextField(
                                  controller: _notesController,
                                  labelText: 'Notes Spéciales',
                                  icon: Icons.note_alt_rounded,
                                  maxLines: 3,
                                  isOptional: true,
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        if (_errorMessage != null) _buildErrorCard(),
                        const SizedBox(height: 24),
                        _buildSwitchModeButton(),
                        const SizedBox(height: 12),
                        Center(child: _buildSubmitButton()),
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