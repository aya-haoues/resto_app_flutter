import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:resto_app/models/food_item.dart'; // <-- ton modèle


class MenuPage extends StatelessWidget {
  const MenuPage({super.key});

  final Color _accentColor = const Color(0xFFFF6B35);
  final Color _backgroundColor = Colors.white;
  final Color _textPrimary = const Color(0xFF1E293B);
  final Color _textSecondary = const Color(0xFF64748B);

  // Données fictives complètes pour le menu
  final Map<String, List<FoodItem>> _menuData = const {
    'Tunisienne': [
      FoodItem('Couscous Poisson', 'assets/images/couscous.jpg', 22.50, 4.7, 'Poisson frais, légumes et bouillon épicé.'),
      FoodItem('Lablabi Classique', 'assets/images/lablabi.jpg', 6.00, 4.5, 'Soupe de pois chiches, huile d\'olive et cumin.'),
      FoodItem('Kamouniya', 'assets/images/kamouniya.jpg', 7.50, 4.6, 'Beignet salé farci au thon, harissa et œufs.'),
    ],
    'Italienne': [
      FoodItem('Lasagnes Bolognaise', 'assets/images/pasta.jpg', 18.00, 4.8, 'Pâtes en couches, viande hachée et sauce béchamel.'),
      FoodItem('Pizza Margherita', 'assets/images/pizza.jpg', 14.00, 4.4, 'Sauce tomate, mozzarella et basilic frais.'),
    ],
    'Américaine': [
      FoodItem('Classic Cheeseburger', 'assets/images/burger.jpg', 15.50, 4.3, 'Galette de bœuf, cheddar, laitue et sauce spéciale.'),
      FoodItem('Frites au Fromage', 'assets/images/fries.jpg', 8.50, 4.1, 'Frites croustillantes et sauce au fromage fondu.'),
    ],
    'Desserts': [
      FoodItem('Tiramisu Original', 'assets/images/tiramisu.jpg', 9.50, 4.9, 'Dessert crémeux au mascarpone et café.'),
      FoodItem('Salade de Fruits', 'assets/images/salad.jpg', 6.50, 4.5, 'Mélange de fruits frais de saison.'),
    ],
  };

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _menuData.keys.length,
      child: Scaffold(
        backgroundColor: _backgroundColor,
        appBar: AppBar(
          backgroundColor: _backgroundColor,
          elevation: 0,
          title: Text(
            'Le Menu Complet',
            style: TextStyle(
              color: _textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: _textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          bottom: TabBar(
            isScrollable: true,
            labelColor: _accentColor,
            unselectedLabelColor: _textSecondary,
            indicatorColor: _accentColor,
            indicatorSize: TabBarIndicatorSize.label,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            tabs: _menuData.keys.map((category) => Tab(text: category)).toList(),
          ),
        ),
        body: TabBarView(
          children: _menuData.keys.map((category) {
            return _buildCategoryList(_menuData[category]!);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildCategoryList(List<FoodItem> items) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return _buildFoodRow(items[index], context);
      },
    );
  }

  Widget _buildFoodRow(FoodItem item, BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _backgroundColor,
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
          // Image
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
          // Informations
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: TextStyle(
                    color: _textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${item.price.toStringAsFixed(2)} DT',
                      style: TextStyle(
                        color: _accentColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          item.rating.toString(),
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
          // Bouton d'ajout
          Container(
            height: 40,
            width: 40,
            margin: const EdgeInsets.only(left: 10, top: 25),
            child: GestureDetector(
              onTap: () => _addToCart(item, context),
              child: Container(
                decoration: BoxDecoration(
                  color: _accentColor,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: _accentColor.withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
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
    );
  }

  void _addToCart(FoodItem item, BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item.name} ajouté au panier'),
        backgroundColor: _accentColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
