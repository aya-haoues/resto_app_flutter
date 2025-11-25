// lib/pages/menu_page.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/food_item.dart';

// ✅ OFFICIAL TAWA ORDER COLORS (from Compte rendu 1)
const Color _primaryBlue = Color(0xFF0D3B66);    // Bleu Nuit
const Color _goldAccent = Color(0xFFD4AF37);     // Or Vif
const Color _ivoryWhite = Color(0xFFF8FAFC);    // Blanc Ivoire
const Color _textSecondary = Color(0xFF64748B);  // Gris secondaire

class MenuPage extends StatefulWidget {
  final Function(FoodItem) onAddToOrder;
  final String? initialCategory; // <--- NOUVEAU PARAMÈTRE POUR LA CATÉGORIE INITIALE

  const MenuPage({
    Key? key,
    required this.onAddToOrder,
    this.initialCategory, // <--- NOUVEAU PARAMÈTRE
  }) : super(key: key);

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  // 🔹 URL de l'API Hono (même que le responsable)
  final String _baseUrl = 'http://192.168.56.1:8082/menu';
  final String _categoriesUrl = 'http://192.168.56.1:8082/categories';


  late TabController _tabController; // <--- CONTRÔLEUR POUR LES ONGLETS

  // --- MÉTHODES DE CHARGEMENT ---
  Future<List<FoodItem>> _fetchMenu() async {
    final response = await http.get(Uri.parse(_baseUrl));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => FoodItem.fromJson(json)).toList();
    } else {
      throw Exception('Échec du chargement du menu');
    }
  }

  Future<List<String>> _fetchCategories() async {
    final response = await http.get(Uri.parse(_categoriesUrl));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => json['name'] as String).toList();
    } else {
      throw Exception('Échec du chargement des catégories');
    }
  }

  Future<List<FoodItem>> _loadMenu() async {
    final response = await http.get(Uri.parse(_baseUrl));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => FoodItem.fromJson(json)).toList();
    } else {
      throw Exception('Échec du chargement du menu');
    }
  }


  @override
  void initState() {
    super.initState();
    // Pas besoin de TickerProvider ici
    _loadMenu(); // Chargez les données sans animation
  }


  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

        // Grouper les plats par catégorie
        final grouped = <String, List<FoodItem>>{};
        for (var item in items) {
          grouped.putIfAbsent(item.category, () => []).add(item);
        }

        return FutureBuilder<List<String>>(
          future: _fetchCategories(),
          builder: (context, categorySnapshot) {
            if (categorySnapshot.connectionState == ConnectionState.waiting) {
              return Scaffold(
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
                ),
                body: const Center(child: CircularProgressIndicator()),
              );
            }
            if (categorySnapshot.hasError) {
              return Scaffold(
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
                ),
                body: Center(child: Text('Erreur catégories: ${categorySnapshot.error}')),
              );
            }

            if (!context.mounted) return const SizedBox.shrink();

            final categories = categorySnapshot.data!;

            return DefaultTabController(
              length: categories.length,
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
                    tabs: categories.map((cat) => Tab(text: cat)).toList(),
                  ),
                ),
                body: TabBarView(
                  children: categories.map((categoryName) {
                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: grouped[categoryName]?.length ?? 0,
                      itemBuilder: (context, index) => _buildFoodRow(
                        grouped[categoryName]![index],
                        context,
                        widget.onAddToOrder,
                      ),
                    );
                  }).toList(),
                ),
              ),
            );
          },
        );
      },
    );
  }


  // --- WIDGETS DE SUPPORT ---
  Scaffold _buildLoadingScaffold() {
    return Scaffold(
      backgroundColor: _ivoryWhite,
      body: const Center(child: CircularProgressIndicator()),
    );
  }

  Scaffold _buildErrorScaffold(String message) {
    return Scaffold(
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
      ),
      body: Center(child: Text(message)),
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