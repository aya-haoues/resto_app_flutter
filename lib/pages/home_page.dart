import 'package:flutter/material.dart';
import 'menu_page.dart'; // Importation de la nouvelle page Menu
import 'commandes_page.dart'; // Importation de la nouvelle page Menu

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final Color _accentColor = const Color(0xFFFF6B35);
  final Color _backgroundColor = Colors.white;
  final Color _textPrimary = const Color(0xFF1E293B);
  final Color _textSecondary = const Color(0xFF64748B);

  // Mise à jour : Données pour Cuisines et Catégories
  final List<Category> _categories = [
    Category('Tunisienne', '🇹🇳', Colors.red.shade100),
    Category('Américaine', '🍔', Colors.blue.shade100),
    Category('Italienne', '🍕', Colors.green.shade100),
    Category('Asiatique', '🍜', Colors.purple.shade100),
    Category('Végétarien', '🥦', Colors.lightGreen.shade100),
    Category('Boissons', '🥤', Colors.teal.shade100),
    Category('Desserts', '🍰', Colors.orange.shade100),
  ];

  // Données fictives pour le Plat du Jour
  final DailySpecial _dailySpecialItem = DailySpecial(
    name: 'Lablabi Spécial',
    imagePath: 'assets/images/lablabi.jpg', // Chemin d'image fictif
    originalPrice: 7.50,
    discountedPrice: 5.99, // Prix en Dinar Tunisien (DT)
    description: 'Soupe de pois chiches épicée avec pain rassis, thon et œuf.',
  );

  // Données fictives pour les Plats en Promotion
  final List<PromotionalItem> _promotionalItems = [
    PromotionalItem(
      'Poulet roti',
      'assets/images/poulet.jpg', // Chemin d'image fictif
      9.00,
      6.99, // Prix en Dinar Tunisien (DT)
    ),
    PromotionalItem(
      'Salade Méchouia',
      'assets/images/mechouia.jpg', // Chemin d'image fictif
      5.50,
      4.25, // Prix en Dinar Tunisien (DT)
    ),
    PromotionalItem(
      'Sandwich Kafteji',
      'assets/images/kafteji.jpg', // Chemin d'image fictif
      8.00,
      6.50, // Prix en Dinar Tunisien (DT)
    ),
  ];


  // Données fictives pour les plats populaires
  final List<FoodItem> _popularItems = [
    FoodItem(
      'Couscous Royal', // Changé pour une cuisine locale
      'assets/images/couscous.jpg', // Chemin d'image fictif
      12.99, // Prix en Dinar Tunisien (DT)
      4.8,
      'Semoule fine, agneau, légumes de saison',
    ),
    FoodItem(
      'Pizza Royale',
      'assets/images/pizza.jpg',
      16.50, // Prix en Dinar Tunisien (DT)
      4.9,
      'Sauce tomate, mozzarella, jambon, champignons',
    ),
    FoodItem(
      'Sushi Mix',
      'assets/images/sushi.jpg',
      18.75, // Prix en Dinar Tunisien (DT)
      4.7,
      'Assortiment de 12 pièces de sushi frais',
    ),
    FoodItem(
      'Pâtes Carbonara',
      'assets/images/pasta.jpg',
      14.25, // Prix en Dinar Tunisien (DT)
      4.6,
      'Pâtes fraîches avec sauce carbonara crémeuse',
    ),
  ];

  // Données fictives pour les recommandations
  final List<FoodItem> _recommendedItems = [
    FoodItem(
      'Salade César',
      'assets/images/salad.jpg',
      10.99, // Prix en Dinar Tunisien (DT)
      4.5,
      'Laitue romaine, croûtons, parmesan, sauce césar',
    ),
    FoodItem(
      'Tiramisu',
      'assets/images/tiramisu.jpg',
      8.50, // Prix en Dinar Tunisien (DT)
      4.8,
      'Dessert italien au café et mascarpone',
    ),
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  // Fonction pour gérer la navigation du BottomNavigationBar
  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });

    if (index == 1) { // 1 correspond à l'index de l'onglet 'Menu'
      _navigateToMenu();
    }
    // Pour les autres onglets, on reste sur la page Home pour l'instant
    // ou on pourrait implémenter d'autres navigations
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: _buildAppBar(),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tawa Order',
            style: TextStyle(
              color: _textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          Text(
            'Livraison rapide • 20-30 min',
            style: TextStyle(
              color: _textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
      backgroundColor: _backgroundColor,
      elevation: 0,
      actions: [
        IconButton(
          icon: Badge(
            backgroundColor: _accentColor,
            label: const Text('3', style: TextStyle(color: Colors.white, fontSize: 10)),
            child: const Icon(Icons.shopping_cart_outlined),
          ),
          onPressed: () => _navigateToCart(),
          color: _textPrimary,
        ),
      ],
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Barre de recherche
          _buildSearchBar(),
          const SizedBox(height: 24),

          // Section Cuisines et Catégories
          _buildCategoriesSection(),
          const SizedBox(height: 32),

          // NOUVELLE SECTION : Plat du Jour
          _buildDailySpecialSection(),
          const SizedBox(height: 32),

          // NOUVELLE SECTION : Plats en Promotion
          _buildPromotionalSection(),
          const SizedBox(height: 32),

          // Section Plats Populaires - LISTE HORIZONTALE
          _buildPopularHorizontalListSection(),
          const SizedBox(height: 32),

          // Section Recommandations
          _buildRecommendedSection(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Rechercher un plat, un restaurant...',
          hintStyle: TextStyle(color: _textSecondary),
          prefixIcon: Icon(Icons.search, color: _textSecondary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onChanged: (value) {
          // Implémenter la recherche
        },
      ),
    );
  }

  Widget _buildCategoriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cuisines & Catégories', // Texte mis à jour
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: _textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              return _buildCategoryItem(_categories[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryItem(Category category) {
    return GestureDetector(
      onTap: () => _navigateToCategory(category.name),
      child: Container(
        width: 80,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: category.color,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Center(
                child: Text(
                  category.emoji,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              category.name,
              style: TextStyle(
                color: _textPrimary,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  // NOUVELLE SECTION : Plat du Jour
  Widget _buildDailySpecialSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          ' Plat du Jour',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: _textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: _backgroundColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.red.shade100,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            image: DecorationImage(
              image: AssetImage(_dailySpecialItem.imagePath),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.3), BlendMode.darken),
            ),
          ),
          child: Stack(
            children: [
              // Informations textuelles
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      _dailySpecialItem.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                    Text(
                      _dailySpecialItem.description,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          '${_dailySpecialItem.discountedPrice} DT',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 28,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${_dailySpecialItem.originalPrice} DT',
                          style: const TextStyle(
                            color: Colors.white54,
                            decoration: TextDecoration.lineThrough,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Badge "Plat du Jour"
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _accentColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'JOUR',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // NOUVELLE SECTION : Plats en Promotion
  Widget _buildPromotionalSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          ' Plats en Promotion',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: _textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 140, // Hauteur ajustée pour la liste horizontale
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _promotionalItems.length,
            itemBuilder: (context, index) {
              return _buildPromotionalItem(_promotionalItems[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPromotionalItem(PromotionalItem item) {
    return Container(
      width: 250,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.yellow.shade50,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Row(
        children: [
          // Image
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              image: DecorationImage(
                image: AssetImage(item.imagePath),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Texte et prix
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item.name,
                  style: TextStyle(
                    color: _textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${item.originalPrice} DT',
                      style: TextStyle(
                        color: _textSecondary,
                        decoration: TextDecoration.lineThrough,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${item.discountedPrice} DT',
                      style: TextStyle(
                        color: _accentColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPopularHorizontalListSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Plats Populaires',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: _textPrimary,
              ),
            ),
            TextButton(
              onPressed: () => _navigateToMenu(), // Navigue vers la page Menu
              child: Text(
                'Voir tout',
                style: TextStyle(
                  color: _accentColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        SizedBox(
          height: 280,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _popularItems.length,
            itemBuilder: (context, index) {
              return _buildPopularListItem(_popularItems[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPopularListItem(FoodItem item) {
    return Container(
      width: 200, // Largeur fixe pour la carte dans la liste horizontale
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image du plat
          Container(
            height: 140,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              image: DecorationImage(
                image: AssetImage(item.imagePath),
                fit: BoxFit.cover,
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _accentColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, color: Colors.white, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          item.rating.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Informations du plat
          Padding(
            padding: const EdgeInsets.all(12),
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  item.description,
                  style: TextStyle(
                    color: _textSecondary,
                    fontSize: 11,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${item.price} DT',
                      style: TextStyle(
                        color: _accentColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),

                    // Bouton d'ajout au panier
                    GestureDetector(
                      onTap: () => _addToCart(item),
                      child: Container(
                        height: 36, // Taille ajustée
                        width: 36,  // Taille ajustée
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
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildRecommendedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recommandé pour vous',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: _textPrimary,
              ),
            ),
            TextButton(
              onPressed: () => _navigateToMenu(), // Navigue vers la page Menu
              child: Text(
                'Voir tout',
                style: TextStyle(
                  color: _accentColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Column(
          children: _recommendedItems.map((item) => _buildFoodRow(item)).toList(),
        ),
      ],
    );
  }

  Widget _buildFoodRow(FoodItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Image
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
              image: DecorationImage(
                image: AssetImage(item.imagePath),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Informations
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: TextStyle(
                      color: _textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.description,
                    style: TextStyle(
                      color: _textSecondary,
                      fontSize: 11,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${item.price} DT',
                        style: TextStyle(
                          color: _accentColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber, size: 14),
                          const SizedBox(width: 2),
                          Text(
                            item.rating.toString(),
                            style: TextStyle(
                              color: _textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Bouton d'ajout
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => _addToCart(item),
              child: Container(
                height: 40, // Taille ajustée
                width: 40,  // Taille ajustée
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

  BottomNavigationBar _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: _onItemTapped, // Utilise la nouvelle fonction
      type: BottomNavigationBarType.fixed,
      selectedItemColor: _accentColor,
      unselectedItemColor: _textSecondary,
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
      backgroundColor: _backgroundColor,
      elevation: 8,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Accueil',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.restaurant_menu_outlined),
          activeIcon: Icon(Icons.restaurant_menu),
          label: 'Menu',
        ),
        BottomNavigationBarItem(
          icon: Badge(
            label: Text('3', style: TextStyle(color: Colors.white, fontSize: 10)),
            child: Icon(Icons.receipt_long_outlined),
          ),
          activeIcon: Badge(
            label: Text('3', style: TextStyle(color: Colors.white, fontSize: 10)),
            child: Icon(Icons.receipt_long),
          ),
          label: 'Commande',
        ),
      ],
    );
  }

  // Méthodes de navigation
  void _navigateToCart() {
    // Navigator.push(...)
    print('Navigation vers le panier');
  }

  void _navigateToProfile() {
    // Navigator.push(...)
    print('Navigation vers le profil');
  }

  void _navigateToCategory(String category) {
    // Navigator.push(...)
    print('Navigation vers la catégorie: $category');
  }

  void _navigateToMenu() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MenuPage()),
    );

  }

  void _addToCart(FoodItem item) {
    // Logique d'ajout au panier
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

// Classes modèles
class Category {
  final String name;
  final String emoji;
  final Color color;

  Category(this.name, this.emoji, this.color);
}

class FoodItem {
  final String name;
  final String imagePath;
  final double price;
  final double rating;
  final String description;

  FoodItem(this.name, this.imagePath, this.price, this.rating, this.description);
}

// NOUVELLES CLASSES POUR LES SECTIONS SPÉCIALES
class DailySpecial {
  final String name;
  final String imagePath;
  final double originalPrice;
  final double discountedPrice;
  final String description;

  DailySpecial({
    required this.name,
    required this.imagePath,
    required this.originalPrice,
    required this.discountedPrice,
    required this.description,
  });
}

class PromotionalItem {
  final String name;
  final String imagePath;
  final double originalPrice;
  final double discountedPrice;

  PromotionalItem(this.name, this.imagePath, this.originalPrice, this.discountedPrice);
}
