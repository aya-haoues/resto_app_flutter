// lib/pages/menu_page.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/food_item.dart';

// ✅ OFFICIAL TAWA ORDER COLORS (from Compte rendu 1)
const Color _primaryBlue = Color(0xFF0D3B66);    // Bleu Nuit
const Color _goldAccent = Color(0xFFD4AF37);     // Or Vif
const Color _ivoryWhite = Color(0xFFFFF0F0);     // Blanc Ivoire
const Color _textSecondary = Color(0xFF64748B);  // Gris secondaire

class MenuPage extends StatelessWidget {
  final Function(FoodItem) onAddToOrder;
  const MenuPage({Key? key, required this.onAddToOrder}) : super(key: key);

  // 🔹 URL de l'API Hono (même que le responsable)
  final String _baseUrl = 'http://192.168.43.8:8082/menu';

  Future<List<FoodItem>> _fetchMenu() async {
    final response = await http.get(Uri.parse(_baseUrl));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      // Utilise le factory `fromJson` de votre modèle mis à jour
      return data.map((json) => FoodItem.fromJson(json)).toList();
    } else {
      throw Exception('Échec du chargement du menu');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<FoodItem>>(
      future: _fetchMenu(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: _ivoryWhite,
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: _ivoryWhite,
            body: Center(child: Text('Erreur: ${snapshot.error}')),
          );
        }

        final items = snapshot.data!;
        // Groupe les plats par catégorie (Tunisienne, Italienne, etc.)
        final grouped = <String, List<FoodItem>>{};
        for (var item in items) {
          grouped.putIfAbsent(item.category, () => []).add(item);
        }

        return DefaultTabController(
          length: grouped.length,
          child: Scaffold(
            backgroundColor: _ivoryWhite,
            appBar: AppBar(
              backgroundColor: _ivoryWhite,
              elevation: 0,
              title: Text(
                'Le Menu Complet',
                style: const TextStyle(
                  color: _primaryBlue,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: _primaryBlue),
                onPressed: () => Navigator.pop(context),
              ),
              bottom: TabBar(
                isScrollable: true,
                labelColor: _goldAccent,
                unselectedLabelColor: _textSecondary,
                indicatorColor: _goldAccent,
                labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                tabs: grouped.keys.map((cat) => Tab(text: cat)).toList(),
              ),
            ),
            body: TabBarView(
              children: grouped.entries.map((entry) {
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: entry.value.length,
                  itemBuilder: (context, index) => _buildFoodRow(
                    entry.value[index],
                    context,
                    onAddToOrder,
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFoodRow(
      FoodItem item,
      BuildContext context,
      Function(FoodItem) onAddToOrder,
      ) {
    return GestureDetector(
      onTap: () => _showFoodDetail(context, item, onAddToOrder),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _ivoryWhite,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image du plat
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(
                  image: AssetImage(item.imagePath),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Détails du plat
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      color: _primaryBlue,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.description,
                    style: const TextStyle(
                      color: _textSecondary,
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${item.price.toStringAsFixed(2)} DT',
                        style: const TextStyle(
                          color: _goldAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Row(
                        children: const [
                          Icon(Icons.star, color: Colors.amber, size: 16),
                          SizedBox(width: 4),
                          Text(
                            '4.5',
                            style: TextStyle(
                              color: _textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Bouton "Ajouter"
            Container(
              height: 40,
              width: 40,
              margin: const EdgeInsets.only(left: 10, top: 25),
              child: GestureDetector(
                onTap: () => onAddToOrder(item),
                child: Container(
                  decoration: BoxDecoration(
                    color: _goldAccent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFoodDetail(
      BuildContext context,
      FoodItem item,
      Function(FoodItem) onAddToOrder,
      ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _ivoryWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Grande image
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  image: DecorationImage(
                    image: AssetImage(item.imagePath),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Nom
              Text(
                item.name,
                style: const TextStyle(
                  color: _primaryBlue,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 8),
              // Description
              Text(
                item.description,
                style: const TextStyle(
                  color: _textSecondary,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              // Prix
              Text(
                '${item.price.toStringAsFixed(2)} DT',
                style: const TextStyle(
                  color: _goldAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
              const SizedBox(height: 20),
              // Bouton Ajouter
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _goldAccent,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    onAddToOrder(item);
                  },
                  child: const Text(
                    'Ajouter à la commande',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}