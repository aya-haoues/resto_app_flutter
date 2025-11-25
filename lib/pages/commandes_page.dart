// lib/pages/commandes_page.dart
import 'package:flutter/material.dart';
import '../models/food_item.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CommandesPage extends StatefulWidget {
  final List<FoodItem> panier;
  final String clientName;
  final int tableNumber;
  final String notes;
  final String? orderId; // Accepte un orderId optionnel
  final String? orderStatus;

  const CommandesPage({
    super.key,
    required this.panier,
    required this.clientName,
    required this.tableNumber,
    required this.notes,
    this.orderId,
    this.orderStatus,
  });

  @override
  State<CommandesPage> createState() => _CommandesPageState();
}

class _CommandesPageState extends State<CommandesPage> {
  // Couleurs
  final Color _primaryColor = Color(0xFFFF6B35);
  final Color _backgroundColor = Color(0xFFF8FAFC);
  final Color _cardColor = Colors.white;
  final Color _textPrimary = Color(0xFF1E293B);
  final Color _textSecondary = Color(0xFF64748B);
  final Color _successColor = Color(0xFF10B981);
  final Color _errorColor = Color(0xFFEF4444);

  // État pour gérer une commande existante
  bool _isDisplayingExistingOrder = false;
  Map<String, dynamic>? _existingOrderData;
  bool _isLoading = true; // Ajouté pour afficher un indicateur de chargement

  late List<FoodItem> _localPanier;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _localPanier = List<FoodItem>.from(widget.panier);

    // Si un orderId est fourni, on est en mode "client existant"
    if (widget.orderId != null) {
      _isDisplayingExistingOrder = true;
      _fetchExistingOrder(widget.orderId!);
    }
  }

  // Fonction pour charger la commande existante
  Future<void> _fetchExistingOrder(String orderId) async {
    setState(() { _isLoading = true; }); // Commencer le chargement
    try {
      // UTILISER LA BONNE ROUTE: /commandes_with_items
      final response = await http.get(
        Uri.parse('http://192.168.43.8:8082/commandes_with_items'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> allOrders = jsonDecode(response.body);
        // Trouver LA commande par son ID
        final order = allOrders.firstWhere(
              (o) => o['id'] == orderId,
          orElse: () => null,
        );

        if (order != null) {
          setState(() {
            _existingOrderData = order;
            _isLoading = false; // Arrêter le chargement
          });
        } else {
          // Gérer le cas où la commande n'est pas trouvée
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Commande non trouvée.'), backgroundColor: Colors.red),
          );
          setState(() { _isLoading = false; }); // Arrêter le chargement
        }
      } else {
        print('Failed to fetch orders: ${response.statusCode}');
        setState(() { _isLoading = false; }); // Arrêter le chargement
      }
    } catch (e) {
      print('Error fetching order: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur de chargement.'), backgroundColor: Colors.red),
      );
      setState(() { _isLoading = false; }); // Arrêter le chargement
    }
  }

  void _removeItem(FoodItem item) {
    setState(() {
      _localPanier.remove(item);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Expanded(child: Text("${item.name} supprimé du panier")),
          ],
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: _successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _clearCart() {
    setState(() {
      _localPanier.clear();
    });
  }

  double get _total {
    return _localPanier.fold(0, (sum, item) => sum + item.totalPriceWithSupplements);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: _buildAppBar(),
      body: _isDisplayingExistingOrder
          ? _buildExistingOrderView()
          : _localPanier.isEmpty
          ? _buildEmptyState()
          : Column(
        children: [
          _buildHeaderInfo(),
          Expanded(child: _buildCartItems()),
          _buildBottomPanel(),
          // --- BOUTON POUR LE CLIENT : LIBÉRER LA TABLE ---
          if (widget.orderId != null && widget.tableNumber != null && _isDisplayingExistingOrder && (widget.orderStatus?.toLowerCase() == 'done'))
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                onPressed: _markTableAsFree,
                icon: const Icon(Icons.check_circle, color: Colors.white),
                label: const Text('Marquer la table comme libre', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // --- VUE POUR UNE COMMANDE EXISTANTE ---
  Widget _buildExistingOrderView() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: _primaryColor),
      );
    }

    if (_existingOrderData == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: _errorColor, size: 48),
            const SizedBox(height: 16),
            Text(
              'Impossible de charger votre commande.',
              style: TextStyle(color: _textSecondary, fontSize: 16),
            ),
          ],
        ),
      );
    }

    final items = _existingOrderData!['items'] as List<dynamic>;
    final total = (_existingOrderData!['total_price'] as num).toDouble();
    final status = _existingOrderData!['status'] as String;
    final clientName = _existingOrderData!['client_name'] as String;
    final tableNumber = _existingOrderData!['table_number'] as int;
    final notes = _existingOrderData!['notes'] as String;

    return Column(
      children: [
        _buildHeaderInfoForExistingOrder(status),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              // ✅ Use image_path from the backend
              final imagePath = item['image_path'] as String?;
              final imageUrl = imagePath != null
                  ? 'assets/images/$imagePath'
                  : 'assets/images/placeholder.jpg';

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: _cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Image du plat
                    Container(
                      width: 80,
                      height: 100,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          bottomLeft: Radius.circular(16),
                        ),
                        image: DecorationImage(
                          image: AssetImage(imageUrl), // ✅ Use AssetImage for local assets
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['food_name'] as String,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: _textPrimary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Quantité: ${item['quantity']}',
                              style: TextStyle(
                                color: _textSecondary,
                                fontSize: 12,
                              ),
                            ),
                            // Show supplements if they exist
                            if ((item['supplements'] as List<dynamic>?)?.isNotEmpty == true) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Suppléments: ${item['supplements'].join(', ')}',
                                style: TextStyle(
                                  color: _primaryColor,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "${(item['price'] as num).toStringAsFixed(2)} DT",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: _primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        _buildBottomPanelForExistingOrder(total, status),
      ],
    );
  }

  Widget _buildHeaderInfoForExistingOrder(String status) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _primaryColor.withOpacity(0.05),
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Icon(Icons.restaurant, color: _primaryColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Votre commande",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _textPrimary,
                    fontSize: 14,
                  ),
                ),
                Text(
                  "Statut: ${_getStatusText(status)}",
                  style: TextStyle(
                    color: _getStatusColor(status),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getStatusColor(status).withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _getStatusText(status).toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomPanelForExistingOrder(double total, String status) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildPriceRow("Total à payer", total, isTotal: true),
          const SizedBox(height: 20),
          Text(
            "Votre commande ${status == 'done' ? 'est terminée' : 'est en cours de préparation'}.",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _primaryColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // --- WIDGETS POUR LE PANIER NORMAL ---
  AppBar _buildAppBar() {
    return AppBar(
      title: Text(
        "Mon Panier",
        style: TextStyle(
          color: _textPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 24,
        ),
      ),
      centerTitle: true,
      backgroundColor: _cardColor,
      elevation: 1,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: _textPrimary),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        if (_localPanier.isNotEmpty)
          IconButton(
            icon: Icon(Icons.delete_outline, color: _errorColor),
            onPressed: _showClearCartDialog,
            tooltip: 'Vider le panier',
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: _primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.shopping_basket_outlined,
                size: 60,
                color: _primaryColor,
              ),
            ),
            SizedBox(height: 24),
            Text(
              "Panier Vide",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _textPrimary,
              ),
            ),
            SizedBox(height: 12),
            Text(
              "Ajoutez des plats délicieux à votre panier pour commencer votre commande",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: _textSecondary,
                height: 1.5,
              ),
            ),
            SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                "Explorer le Menu",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderInfo() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _primaryColor.withOpacity(0.05),
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Icon(Icons.restaurant, color: _primaryColor, size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Commande sur place",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _textPrimary,
                    fontSize: 14,
                  ),
                ),
                Text(
                  "Préparation: 15-20 min",
                  style: TextStyle(
                    color: _textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "${_localPanier.length} article${_localPanier.length > 1 ? 's' : ''}",
              style: TextStyle(
                color: _primaryColor,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItems() {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _localPanier.length,
      itemBuilder: (context, index) {
        final item = _localPanier[index];
        return _buildCartItem(item);
      },
    );
  }

  // --- FONCTION AJOUTÉE : Afficher les suppléments pour un article ---
  Widget _buildSupplementsSection(FoodItem item) {
    if (item.supplements.isEmpty) {
      return Text(
        "Aucun supplément",
        style: TextStyle(color: _textSecondary, fontSize: 12),
      );
    }
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: item.supplements.map((supplement) {
        return Chip(
          label: Text(
            supplement,
            style: TextStyle(fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          backgroundColor: _primaryColor.withOpacity(0.1),
          labelStyle: TextStyle(color: _primaryColor),
          deleteIcon: Icon(Icons.cancel, size: 14, color: _primaryColor),
          onDeleted: () {
            _removeSupplement(item, supplement);
          },
        );
      }).toList(),
    );
  }

  // --- FONCTION AJOUTÉE : Supprimer un supplément ---
  void _removeSupplement(FoodItem item, String supplement) {
    final updatedSupplements = List<String>.from(item.supplements)..remove(supplement);
    final updatedItem = item.copyWith(supplements: updatedSupplements);
    setState(() {
      final index = _localPanier.indexOf(item);
      if (index != -1) {
        _localPanier[index] = updatedItem;
      }
    });
  }

  // --- FONCTION AJOUTÉE : Modifier les suppléments ---
  void _modifySupplements(FoodItem item) async {
    final controller = TextEditingController();
    List<Map<String, dynamic>> availableSupplements = [];

    // Charger la liste des suppléments depuis l'API
    try {
      final response = await http.get(Uri.parse('http://192.168.43.8:8082/supplements'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        availableSupplements = data.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de chargement des suppléments'), backgroundColor: Colors.red),
        );
      }
    }

    final selectedSupplements = List<String>.from(item.supplements);

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Suppléments pour ${item.name}'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Afficher le prix de base du plat
                    Text(
                      'Prix de base: ${item.price.toStringAsFixed(2)} DT',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Liste déroulante pour les suppléments prédéfinis
                    DropdownButtonFormField<Map<String, dynamic>>(
                      decoration: InputDecoration(
                        labelText: 'Choisir un supplément',
                        border: OutlineInputBorder(),
                      ),
                      value: null,
                      items: availableSupplements.map((supplement) {
                        final displayText = '${supplement['name']} (+${(supplement['price'] as num).toStringAsFixed(3)} DT)';
                        return DropdownMenuItem(
                          value: supplement,
                          child: Text(displayText),
                        );
                      }).toList(),
                      onChanged: (Map<String, dynamic>? newValue) {
                        if (newValue != null) {
                          final formattedSupplement = '${newValue['name']} (+${(newValue['price'] as num).toStringAsFixed(3)} DT)';
                          if (!selectedSupplements.contains(formattedSupplement)) {
                            setState(() {
                              selectedSupplements.add(formattedSupplement);
                            });
                          }
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    // Champ de texte pour un supplément personnalisé
                    TextField(
                      controller: controller,
                      decoration: const InputDecoration(
                        labelText: 'Supplément personnalisé',
                        hintText: 'Ex: Double portion de frites',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (value) {
                        if (value.isNotEmpty && !selectedSupplements.contains(value)) {
                          setState(() {
                            selectedSupplements.add(value);
                            controller.clear();
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    // Liste des suppléments sélectionnés
                    if (selectedSupplements.isNotEmpty) ...[
                      const Text('Suppléments sélectionnés:'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: selectedSupplements.map((supplement) {
                          return Chip(
                            label: Text(supplement),
                            backgroundColor: Colors.grey.shade200,
                            onDeleted: () {
                              setState(() {
                                selectedSupplements.remove(supplement);
                              });
                            },
                            deleteIcon: const Icon(Icons.cancel, size: 14),
                          );
                        }).toList(),
                      ),
                      // Prix total des suppléments sélectionnés
                      Text(
                        'Total suppléments: ${selectedSupplements.fold(0.0, (sum, sup) {
                          final match = RegExp(r'\+([\d,]+(?:\.\d+)?)\s*DT').firstMatch(sup);
                          if (match != null) {
                            final priceString = match.group(1)!.replaceAll(',', '');
                            return sum + (double.tryParse(priceString) ?? 0.0);
                          }
                          return sum;
                        }).toStringAsFixed(2)} DT',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final updatedItem = item.copyWith(supplements: selectedSupplements);
                    setState(() {
                      final index = _localPanier.indexOf(item);
                      if (index != -1) {
                        _localPanier[index] = updatedItem;
                      }
                    });

                    // Enregistrer les modifications dans la base de données
                    try {
                      final response = await http.put(
                        Uri.parse('http://192.168.43.8:8082/menu/${item.id}'),
                        headers: {'Content-Type': 'application/json'},
                        body: jsonEncode({
                          'supplements': selectedSupplements,
                        }),
                      );

                      if (response.statusCode == 200) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Suppléments sauvegardés'), backgroundColor: Colors.green),
                        );
                      } else {
                        final errorBody = jsonDecode(response.body);
                        final errorMsg = errorBody['error'] ?? 'Erreur inconnue';
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Erreur lors de la sauvegarde: $errorMsg'), backgroundColor: Colors.red),
                        );
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Erreur réseau: $e'), backgroundColor: Colors.red),
                      );
                    }

                    Navigator.of(ctx).pop();
                  },
                  child: const Text('Sauvegarder'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildCartItem(FoodItem item) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Image du plat
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                      image: AssetImage(item.imagePath),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: _textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.description,
                        style: TextStyle(
                          color: _textSecondary,
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "${item.totalPriceWithSupplements.toStringAsFixed(2)} DT",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                // Bouton de suppression
                Container(
                  decoration: BoxDecoration(
                    color: _errorColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.delete_outline, color: _errorColor, size: 20),
                    onPressed: () => _removeItem(item),
                    padding: EdgeInsets.all(4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Section des suppléments
            Row(
              children: [
                Text(
                  "Suppléments:",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: _textPrimary),
                ),
                const SizedBox(width: 8),
                Expanded(child: _buildSupplementsSection(item)),
                IconButton(
                  icon: Icon(Icons.edit, color: _primaryColor, size: 20),
                  onPressed: () => _modifySupplements(item),
                  tooltip: 'Modifier les suppléments',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomPanel() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildPriceRow("Sous-total", _total),
          Divider(height: 20),
          _buildPriceRow("Total à payer", _total, isTotal: true),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: _isSubmitting ? null : _confirmOrder,
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
            ),
            child: _isSubmitting
                ? CircularProgressIndicator(color: Colors.white)
                : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shopping_bag_outlined, size: 20),
                SizedBox(width: 8),
                Text(
                  "Confirmer la commande",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Continuer mes achats",
              style: TextStyle(color: _textSecondary, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount, {bool isTotal = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: _textSecondary,
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          Text(
            "${amount.toStringAsFixed(2)} DT",
            style: TextStyle(
              color: isTotal ? _primaryColor : _textPrimary,
              fontSize: isTotal ? 18 : 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // --- FONCTION POUR CONFIRMER UNE NOUVELLE COMMANDE ---
  void _confirmOrder() async {
    if (_localPanier.isEmpty) {
      _showErrorDialog("Votre panier est vide.");
      return;
    }
    setState(() => _isSubmitting = true);
    final String backendUrl = dotenv.env['BACKEND_URL'] ?? 'http://192.168.43.8:8082/commandes';
    final Uri url = Uri.parse(backendUrl);
    final body = {
      "client_name": widget.clientName,
      "total_price": _total,
      "table_number": widget.tableNumber,
      "notes": widget.notes,
      "client_id": widget.clientName,
      "items": _localPanier.map((item) => {
        "name": item.name,
        "price": item.totalPriceWithSupplements, // Prix total avec suppléments
        "quantity": item.quantity ?? 1,
        "image_path": item.imagePath.split('/').last,
        "supplements": item.supplements,
      }).toList(),
    };

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _showSuccessDialog(data['order_id'], data['status']);
      } else {
        final errorBody = jsonDecode(response.body);
        final msg = errorBody['message'] ?? 'Erreur inconnue du serveur';
        _showErrorDialog("Erreur ($response.statusCode): $msg");
      }
    } catch (e) {
      _showErrorDialog("Impossible d’envoyer la commande. Vérifiez la connexion au backend.");
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  // --- BOUTON POUR LE CLIENT : LIBÉRER LA TABLE ---
  Future<void> _markTableAsFree() async {
    try {
      final response = await http.put(
        Uri.parse('http://192.168.43.8:8082/tables/${widget.tableNumber}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'status': 'free',
          'notes': null,
          'time_occupied': null,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Table libérée avec succès !'), backgroundColor: Colors.green),
        );
        Navigator.pushReplacementNamed(context, '/');
      } else {
        final errorMsg = jsonDecode(response.body)['error'] ?? 'Erreur inconnue';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $errorMsg'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur réseau: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // --- DIALOGUES ---
  void _showSuccessDialog(String? orderId, String? initialStatus) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text("Commande confirmée"),
            ],
          ),
          content: Text(
            "Votre commande a été envoyée avec succès !\n\n"
                "Numéro: ${orderId ?? 'N/A'}\n"
                "Statut: ${initialStatus?.toUpperCase() ?? 'PENDING'}\n"
                "Total: ${_total.toStringAsFixed(2)} DT",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
              },
              child: Text("Retour à l'accueil"),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 8),
            Text("Erreur"),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Fermer"),
          ),
        ],
      ),
    );
  }

  void _showClearCartDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: _errorColor),
            SizedBox(width: 8),
            Text("Vider le panier"),
          ],
        ),
        content: Text("Êtes-vous sûr de vouloir supprimer tous les articles ?"),
        actions: [
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: Text("Annuler", style: TextStyle(color: _textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _clearCart();
            },
            child: Text("Vider", style: TextStyle(color: _errorColor)),
          ),
        ],
      ),
    );
  }

  // --- HELPERS POUR LE STATUT ---
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'in_progress':
        return Colors.blue;
      case 'done':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'En Attente';
      case 'in_progress':
        return 'En Cours';
      case 'done':
        return 'Terminée';
      default:
        return 'Inconnu';
    }
  }
}