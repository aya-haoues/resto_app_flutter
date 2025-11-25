// lib/pages/specials_management_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/food_item.dart';

// Couleurs (ajustez selon votre thème)
const Color _primaryBlue = Color(0xFF0D3B66);
const Color _goldAccent = Color(0xFFD4AF37);
const Color _ivoryWhite = Color(0xFFFFFFFF);
const Color _textSecondary = Color(0xFF64748B);
const Color _oliveGreen = Color(0xFF6B8E23);
const Color _pimentRed = Color(0xFFE63946);

class SpecialsManagementScreen extends StatefulWidget {
  const SpecialsManagementScreen({super.key});

  @override
  State<SpecialsManagementScreen> createState() => _SpecialsManagementScreenState();
}

class _SpecialsManagementScreenState extends State<SpecialsManagementScreen> {
  bool _isLoading = true;
  FoodItem? _dailySpecial;
  List<FoodItem> _promotionalItems = [];
  List<FoodItem> _allMenuItems = [];

  final String _specialsUrl = 'http://10.187.253.200:8082/specials';
  final String _menuUrl = 'http://10.187.253.200:8082/menu';

  @override
  void initState() {
    super.initState();
    _loadSpecials();
  }

  Future<void> _loadSpecials() async {
    setState(() => _isLoading = true);
    try {
      // Charger tous les plats pour la sélection
      final menuResponse = await http.get(Uri.parse(_menuUrl));
      if (menuResponse.statusCode == 200) {
        final List<dynamic> menuData = json.decode(menuResponse.body);
        _allMenuItems = menuData.map((json) => FoodItem.fromJson(json)).toList();
      }

      // Charger les spéciaux actuels
      final specialsResponse = await http.get(Uri.parse(_specialsUrl));
      if (specialsResponse.statusCode == 200) {
        final specialsData = json.decode(specialsResponse.body);

        // Gérer le plat du jour
        if (specialsData['daily_special'] != null) {
          _dailySpecial = FoodItem.fromJson(specialsData['daily_special']);
        } else {
          _dailySpecial = null;
        }

        // Gérer les promotions
        if (specialsData['promotional_items'] is List) {
          _promotionalItems = (specialsData['promotional_items'] as List)
              .map((item) => FoodItem.fromJson(item))
              .toList();
        } else {
          _promotionalItems = [];
        }
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de chargement: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _setDailySpecial(FoodItem foodItem, double discountedPrice) async {
    try {
      final response = await http.put(
        Uri.parse('$_specialsUrl/daily'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'food_item_id': foodItem.id,
          'discounted_price': discountedPrice,
        }),
      );

      if (response.statusCode == 200) {
        await _loadSpecials();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Plat du jour mis à jour !'), backgroundColor: _ivoryWhite),
          );
        }
      } else {
        final errorBody = jsonDecode(response.body);
        final errorMsg = errorBody['error'] ?? 'Erreur inconnue';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $errorMsg'), backgroundColor: _pimentRed),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur réseau: $e'), backgroundColor: _pimentRed),
        );
      }
    }
  }

  Future<void> _removeDailySpecial() async {
    try {
      final response = await http.delete(Uri.parse('$_specialsUrl/daily'));
      if (response.statusCode == 200) {
        await _loadSpecials();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Plat du jour supprimé !'), backgroundColor: _ivoryWhite),
          );
        }
      } else {
        final errorBody = jsonDecode(response.body);
        final errorMsg = errorBody['error'] ?? 'Erreur inconnue';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $errorMsg'), backgroundColor: _pimentRed),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur réseau: $e'), backgroundColor: _pimentRed),
        );
      }
    }
  }

  Future<void> _addPromotion(FoodItem foodItem, double originalPrice, double discountedPrice) async {
    try {
      final response = await http.put(
        Uri.parse('$_specialsUrl/promotional'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'food_item_id': foodItem.id,
          'original_price': originalPrice,
          'discounted_price': discountedPrice,
        }),
      );

      if (response.statusCode == 200) {
        await _loadSpecials();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Promotion ajoutée !'), backgroundColor: _ivoryWhite),
          );
        }
      } else {
        final errorBody = jsonDecode(response.body);
        final errorMsg = errorBody['error'] ?? 'Erreur inconnue';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $errorMsg'), backgroundColor: _pimentRed),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur réseau: $e'), backgroundColor: _pimentRed),
        );
      }
    }
  }

  Future<void> _removePromotion(String foodItemId) async {
    try {
      final response = await http.delete(Uri.parse('$_specialsUrl/promotional/$foodItemId'));
      if (response.statusCode == 200) {
        await _loadSpecials();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Promotion supprimée !'), backgroundColor: _ivoryWhite),
          );
        }
      } else {
        final errorBody = jsonDecode(response.body);
        final errorMsg = errorBody['error'] ?? 'Erreur inconnue';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $errorMsg'), backgroundColor: _pimentRed),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur réseau: $e'), backgroundColor: _pimentRed),
        );
      }
    }
  }

  Future<double?> _getDiscountedPrice(BuildContext context, double originalPrice) async {
    final priceController = TextEditingController(text: (originalPrice * 0.8).toStringAsFixed(2));
    double? newPrice;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Prix réduit'),
          content: TextField(
            controller: priceController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Nouveau prix (TND)'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                final parsedPrice = double.tryParse(priceController.text);
                if (parsedPrice != null && parsedPrice >= 0 && parsedPrice < originalPrice) {
                  newPrice = parsedPrice;
                  Navigator.pop(context);
                } else if (parsedPrice != null) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Le prix réduit doit être inférieur au prix original.'), backgroundColor: _pimentRed),
                    );
                  }
                }
              },
              child: const Text('Valider'),
            ),
          ],
        );
      },
    );

    return newPrice;
  }

  Future<FoodItem?> _selectFoodItem(String title, List<FoodItem> excludedItems) async {
    final selectableItems = _allMenuItems.where((item) => !excludedItems.any((ex) => ex.id == item.id)).toList();

    return await showDialog<FoodItem>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: selectableItems.isEmpty
                ? const Center(child: Text('Aucun plat disponible.'))
                : ListView.builder(
              itemCount: selectableItems.length,
              itemBuilder: (context, index) {
                final item = selectableItems[index];
                return ListTile(
                  leading: Image.asset(item.imagePath, width: 40, height: 40, fit: BoxFit.cover),
                  title: Text(item.name),
                  subtitle: Text('${item.price.toStringAsFixed(2)} DT'),
                  onTap: () => Navigator.pop(context, item),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
          ],
        );
      },
    );
  }

  void _selectDailySpecial() async {
    final excluded = _dailySpecial != null ? [_dailySpecial!] : <FoodItem>[];
    final selectedFoodItem = await _selectFoodItem('Sélectionnez le plat du jour', excluded);
    if (selectedFoodItem != null) {
      final discountedPrice = await _getDiscountedPrice(context, selectedFoodItem.price);
      if (discountedPrice != null) {
        _setDailySpecial(selectedFoodItem, discountedPrice);
      }
    }
  }

  void _selectPromotion() async {
    final excluded = [..._promotionalItems];
    if (_dailySpecial != null) excluded.add(_dailySpecial!);

    final selectedFoodItem = await _selectFoodItem('Sélectionnez un plat en promotion', excluded);
    if (selectedFoodItem != null) {
      final discountedPrice = await _getDiscountedPrice(context, selectedFoodItem.price);
      if (discountedPrice != null && discountedPrice < selectedFoodItem.price) {
        _addPromotion(selectedFoodItem, selectedFoodItem.price, discountedPrice);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _ivoryWhite,
      appBar: AppBar(
        title: Text(
          'Gestion des Spéciaux',
          style: const TextStyle(
            color: _primaryBlue,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        backgroundColor: _ivoryWhite,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadSpecials,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDailySpecialSection(),
              const SizedBox(height: 32),
              _buildPromotionalItemsSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDailySpecialSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Plat du Jour',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: _textSecondary,
              ),
            ),
            if (_dailySpecial == null)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: _goldAccent),
                onPressed: _selectDailySpecial,
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text('Définir', style: TextStyle(color: Colors.white)),
              )
            else
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: _pimentRed),
                onPressed: _removeDailySpecial,
                icon: const Icon(Icons.delete, color: Colors.white),
                label: const Text('Supprimer', style: TextStyle(color: Colors.white)),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (_dailySpecial != null)
          Card(
            color: Colors.white,
            elevation: 4,
            child: ListTile(
              leading: Image.asset(_dailySpecial!.imagePath, width: 50, height: 50, fit: BoxFit.cover),
              title: Text(_dailySpecial!.name),
              subtitle: Text(
                '${_dailySpecial!.description}\n'
                    'Prix Original: ${_dailySpecial!.price.toStringAsFixed(2)} DT\n'
                    'Prix Réduit: ${(_dailySpecial!.discountPrice ?? 0.0).toStringAsFixed(2)} DT',
              ),
            ),
          )
        else
          const Center(child: Text('Aucun plat du jour défini.')),
      ],
    );
  }

  Widget _buildPromotionalItemsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Promotions',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: _textSecondary,
              ),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: _goldAccent),
              onPressed: _selectPromotion,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Ajouter', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_promotionalItems.isEmpty)
          const Center(child: Text('Aucune promotion active.'))
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _promotionalItems.length,
            itemBuilder: (context, index) {
              final promo = _promotionalItems[index];
              return Card(
                color: Colors.white,
                elevation: 4,
                child: ListTile(
                  leading: Image.asset(promo.imagePath, width: 50, height: 50, fit: BoxFit.cover),
                  title: Text(promo.name),
                  subtitle: Text(
                    '${promo.description}\n'
                        'Prix Original: ${promo.originalPrice?.toStringAsFixed(2) ?? 'N/A'} DT\n'
                        'Prix Réduit: ${promo.discountedPrice?.toStringAsFixed(2) ?? 'N/A'} DT',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: _pimentRed),
                    onPressed: () => _removePromotion(promo.id),
                    tooltip: 'Supprimer la promotion',
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}