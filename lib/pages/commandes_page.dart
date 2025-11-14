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

  const CommandesPage({
    super.key,
    required this.panier,
    required this.clientName,
    required this.tableNumber,
    required this.notes,
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

  late List<FoodItem> _localPanier;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _localPanier = List<FoodItem>.from(widget.panier);
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
    return _localPanier.fold(0, (sum, item) => sum + item.price);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: _buildAppBar(),
      body: _localPanier.isEmpty
          ? _buildEmptyState()
          : Column(
        children: [
          _buildHeaderInfo(),
          Expanded(child: _buildCartItems()),
          _buildBottomPanel(),
        ],
      ),
    );
  }

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
      child: Row(
        children: [
          Container(
            width: 80,
            height: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
              image: DecorationImage(
                image: AssetImage(item.imagePath),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(12),
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
                  SizedBox(height: 4),
                  Text(
                    item.description,
                    style: TextStyle(
                      color: _textSecondary,
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "${item.price.toStringAsFixed(2)} DT",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _primaryColor,
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: _errorColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          icon: Icon(Icons.delete_outline,
                              color: _errorColor, size: 20),
                          onPressed: () => _removeItem(item),
                          padding: EdgeInsets.all(4),
                          constraints: BoxConstraints(),
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
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
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Continuer mes achats",
              style: TextStyle(
                color: _textSecondary,
                fontWeight: FontWeight.w500,
              ),
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

  void _confirmOrder() async {
    if (_localPanier.isEmpty) {
      _showErrorDialog("Votre panier est vide.");
      return;
    }

    setState(() => _isSubmitting = true);

    final String backendUrl = dotenv.env['BACKEND_URL'] ?? 'http://192.168.56.1:8082/commandes';
    final Uri url = Uri.parse(backendUrl);

    final body = {
      "client_name": widget.clientName,
      "total_price": _total,
      "table_number": widget.tableNumber,
      "notes": widget.notes,
      "items": _localPanier.map((item) => {
        "name": item.name,
        "price": item.price,
        "quantity": item.quantity ?? 1,
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
        _showSuccessDialog(data['order_id']);
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

  void _showSuccessDialog(String? orderId) {
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
                "Total: ${_total.toStringAsFixed(2)} DT",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
              },
              child: Text("OK"),
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
}