// lib/pages/home_page.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // Import pour http
import 'dart:convert'; // Import pour jsonDecode
import 'menu_page.dart';
import 'commandes_page.dart';
import '../models/food_item.dart'; // Assurez-vous que FoodItem contient isDailySpecial, etc.
import 'order_info_page.dart';
import 'package:uuid/uuid.dart';
import 'package:collection/collection.dart';

class HomePage extends StatefulWidget {
  final String? initialClientName;
  final int? initialTableNumber;
  final String? initialNotes;
  final String? initialOrderId;
  final String? initialOrderStatus;

  const HomePage({
    super.key,
    this.initialClientName,
    this.initialTableNumber,
    this.initialNotes,
    this.initialOrderId,
    this.initialOrderStatus,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  List<FoodItem> _panier = [];

  // ✅ Nouvelles variables d'état pour les infos client
  String? _clientName;
  int? _tableNumber;
  String? _notes;
  String? _orderId;
  String? _orderStatus;

  // Palette de couleurs
  final Color _accentColor = const Color(0xFFFF6B35);
  final Color _backgroundColor = Color(0xFFF8FAFC);
  final Color _textPrimary = const Color(0xFF1E293B);
  final Color _textSecondary = const Color(0xFF64748B);

  // --- ÉTAT POUR LES CATÉGORIES DYNAMIQUES ---
  List<Category> _dynamicCategories = [];
  bool _categoriesLoading = true;
  String? _categoriesError;

  // --- ÉTAT POUR LES SPÉCIAUX (PLAT DU JOUR & PROMOTIONS) ---
  FoodItem? _dailySpecial;
  List<FoodItem> _promotionalItems = [];
  bool _specialsLoading = true;
  String? _specialsError;

  // --- NOUVELLE FONCTION : Charger les spéciaux depuis l'API ---
  Future<void> _loadSpecials() async {
    if (!mounted) return;
    setState(() {
      _specialsLoading = true;
      _specialsError = null;
    });

    try {
      final response = await http.get(Uri.parse('http://192.168.56.1:8082/menu'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final allItems = data.map((json) => FoodItem.fromJson(json)).toList();

        // ✅ CORRIGÉ : Utiliser firstWhereOrNull
        final dailySpecial = allItems.firstWhereOrNull((item) => item.isDailySpecial);
        final promotionalItems = allItems.where((item) => item.isFeaturedPromotion).toList();

        if (mounted) {
          setState(() {
            _dailySpecial = dailySpecial; // Peut être null
            _promotionalItems = promotionalItems;
            _specialsLoading = false;
          });
        }
      } else {
        throw Exception('Erreur ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _specialsError = 'Erreur: $e';
          _specialsLoading = false;
        });
      }
    }
  }


  // --- NOUVELLE FONCTION : Charger les catégories depuis l'API ---
  Future<void> _loadDynamicCategories() async {
    if (!mounted) return;
    setState(() {
      _categoriesLoading = true;
      _categoriesError = null;
    });

    try {
      final response = await http.get(Uri.parse('http://192.168.56.1:8082/categories'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final List<Category> loadedCategories = data
            .map((json) => Category(
          json['name'] as String,
          _getEmojiForCategory(json['name'] as String),
          _getColorForCategory(json['name'] as String),
          'assets/images/placeholder.jpg',
        ))
            .toList();

        if (mounted) {
          setState(() {
            _dynamicCategories = loadedCategories;
            _categoriesLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _categoriesError = 'Erreur ${response.statusCode} lors du chargement des catégories';
            _categoriesLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _categoriesError = 'Erreur réseau: $e';
          _categoriesLoading = false;
        });
      }
    }
  }

  Future<void> _checkForExistingOrder(String clientName, int tableNumber) async {
    final url = Uri.parse('http://192.168.56.1:8082/client-order?client_name=$clientName&table_number=$tableNumber');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => CommandesPage(
              panier: _panier,
              clientName: clientName,
              tableNumber: tableNumber,
              notes: _notes ?? "",
            ),
          ),
        );
      } else if (response.statusCode == 404) {
        // No existing order, proceed as normal
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur de recherche d\'ordre')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur réseau: $e')));
    }
  }

  // --- FONCTIONS AIDE POUR LES CATÉGORIES DYNAMIQUES ---
  String _getEmojiForCategory(String name) {
    switch (name.toLowerCase()) {
      case 'tunisienne':
        return '🇹🇳';
      case 'américaine':
        return '🇺🇸';
      case 'italienne':
        return '🇮🇹';
      case 'desserts':
        return '🍰';
      case 'boissons':
        return '🥤';
      case 'plats principaux':
        return '🍽️';
      default:
        return '🍽️';
    }
  }

  Color _getColorForCategory(String name) {
    switch (name.toLowerCase()) {
      case 'tunisienne':
        return Colors.red;
      case 'américaine':
        return Colors.blue;
      case 'italienne':
        return Colors.green;
      case 'desserts':
        return Colors.orange;
      case 'boissons':
        return Colors.cyan;
      case 'plats principaux':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  void _addToCart(FoodItem item) {
    setState(() {
      _panier.add(item);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item.name} ajouté au panier !'),
        duration: const Duration(seconds: 1),
        backgroundColor: Colors.teal,
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _navigateToMenu() {
    _onItemTapped(1);
  }

  @override
  void initState() {
    super.initState();
    _clientName = widget.initialClientName;
    _tableNumber = widget.initialTableNumber;
    _notes = widget.initialNotes;
    _orderId = widget.initialOrderId;
    _orderStatus = widget.initialOrderStatus;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDynamicCategories();
      _loadSpecials(); // <--- Charger les spéciaux au démarrage
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildHomeContent(),
      MenuPage(onAddToOrder: _addToCart),
      if (_clientName != null && _tableNumber != null && _notes != null)
        CommandesPage(
          panier: _panier,
          clientName: _clientName!,
          tableNumber: _tableNumber!,
          notes: _notes!,
          orderId: _orderId,
          orderStatus: _orderStatus,
        )
      else
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Veuillez d'abord saisir vos informations."),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => OrderInfoPage(panier: _panier),
                    ),
                  );
                },
                child: Text("Saisir les informations"),
              ),
            ],
          ),
        ),
    ];

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: _buildAppBar(),
      body: pages[_currentIndex],
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
        ],
      ),
      backgroundColor: _backgroundColor,
      elevation: 0,
      actions: [
        IconButton(
          icon: Icon(Icons.logout, color: _accentColor),
          tooltip: 'Retour à l\'accueil',
          onPressed: () {
            Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
          },
        ),
      ],
    );
  }

  BottomNavigationBar _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: _onItemTapped,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: _accentColor,
      unselectedItemColor: _textSecondary,
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
      backgroundColor: _backgroundColor,
      elevation: 8,
      items: [
        const BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Accueil',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.restaurant_menu_outlined),
          activeIcon: Icon(Icons.restaurant_menu),
          label: 'Menu',
        ),
        BottomNavigationBarItem(
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.receipt_long_outlined),
              if (_panier.isNotEmpty)
                Positioned(
                  top: -5,
                  right: -5,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: _accentColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _backgroundColor, width: 1),
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      _panier.length.toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          activeIcon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.receipt_long),
              if (_panier.isNotEmpty)
                Positioned(
                  top: -5,
                  right: -5,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: _accentColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _backgroundColor, width: 1),
                    ),
                    constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                    child: Text(
                      _panier.length.toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          label: 'Commande',
        ),
      ],
    );
  }

  Widget _buildHomeContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSearchBar(),
          const SizedBox(height: 24),
          _buildCategoriesSection(),
          const SizedBox(height: 32),
          _buildDailySpecialSection(), // <--- Section mise à jour
          const SizedBox(height: 32),
          _buildPromotionalSection(), // <--- Section mise à jour
          const SizedBox(height: 32),
          _buildPopularHorizontalListSection(),
          const SizedBox(height: 32),
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
      ),
    );
  }

  Widget _buildCategoriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cuisines & Catégories',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _textPrimary),
        ),
        const SizedBox(height: 16),
        if (_categoriesLoading)
          const Center(child: CircularProgressIndicator())
        else if (_categoriesError != null)
          Center(child: Text('Erreur: $_categoriesError'))
        else if (_dynamicCategories.isEmpty)
            const Center(child: Text('Aucune catégorie disponible.'))
          else
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _dynamicCategories.length,
                itemBuilder: (context, index) {
                  return _buildCategoryItem(_dynamicCategories[index]);
                },
              ),
            ),
      ],
    );
  }

  Widget _buildCategoryItem(Category category) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MenuPage(
              onAddToOrder: (item) {},
              initialCategory: category.name,
            ),
          ),
        );
      },
      child: Container(
        width: 80,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: category.color.withOpacity(0.2),
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
              style: TextStyle(color: _textPrimary, fontWeight: FontWeight.w500, fontSize: 12),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  // --- SECTION PLAT DU JOUR MISE À JOUR ---
  Widget _buildDailySpecialSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          ' Plat du Jour',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _textPrimary),
        ),
        const SizedBox(height: 16),
        if (_specialsLoading)
          const Center(child: CircularProgressIndicator())
        else if (_specialsError != null)
          Center(child: Text('Erreur: $_specialsError'))
        else if (_dailySpecial != null)
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
                  image: AssetImage(_dailySpecial!.imagePath),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.3), BlendMode.darken),
                ),
              ),
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          _dailySpecial!.name,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24),
                        ),
                        Text(
                          _dailySpecial!.description,
                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              '${(_dailySpecial!.discountPrice ?? _dailySpecial!.price).toStringAsFixed(2)} DT',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 28),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${_dailySpecial!.price.toStringAsFixed(2)} DT',
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
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            const Center(child: Text('Aucun plat du jour.')),
      ],
    );
  }

  // --- SECTION PROMOTIONS MISE À JOUR ---
  Widget _buildPromotionalSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          ' Plats en Promotion',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _textPrimary),
        ),
        const SizedBox(height: 16),
        if (_specialsLoading)
          const Center(child: CircularProgressIndicator())
        else if (_specialsError != null)
          Center(child: Text('Erreur: $_specialsError'))
        else if (_promotionalItems.isNotEmpty)
            SizedBox(
              height: 140,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _promotionalItems.length,
                itemBuilder: (context, index) {
                  return _buildPromotionalItem(_promotionalItems[index]);
                },
              ),
            )
          else
            const Center(child: Text('Aucune promotion.')),
      ],
    );
  }

  Widget _buildPromotionalItem(FoodItem item) {
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
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              image: DecorationImage(image: AssetImage(item.imagePath), fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item.name,
                  style: TextStyle(color: _textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${item.price.toStringAsFixed(2)} DT',
                      style: TextStyle(color: _textSecondary, decoration: TextDecoration.lineThrough, fontSize: 12),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${(item.discountedPrice ?? item.price).toStringAsFixed(2)} DT',
                      style: TextStyle(color: _accentColor, fontWeight: FontWeight.bold, fontSize: 18),
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
              onPressed: _navigateToMenu,
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
            //itemCount: _popularItems.length,
            itemBuilder: (context, index) {
              //return _buildPopularListItem(_popularItems[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPopularListItem(FoodItem item) {
    return Container(
      width: 200,
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
                      '${item.price.toStringAsFixed(2)} DT',
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
                        height: 36,
                        width: 36,
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
              onPressed: _navigateToMenu,
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
          //children: _recommendedItems.map((item) => _buildFoodRow(item)).toList(),
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
                        '${item.price.toStringAsFixed(2)} DT',
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
                height: 40,
                width: 40,
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
}

// Modèles simplifiés pour les besoins de la HomePage
// La classe Category est maintenant utilisée pour les données dynamiques
class Category {
  final String name;
  final String emoji;
  final Color color;
  final String imagePath;
  const Category(this.name, this.emoji, this.color, this.imagePath);
}

class DailySpecial {
  final String name;
  final String imagePath;
  final double originalPrice;
  final double discountedPrice;
  final String description;
  const DailySpecial({
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
  const PromotionalItem(this.name, this.imagePath, this.originalPrice, this.discountedPrice);
}