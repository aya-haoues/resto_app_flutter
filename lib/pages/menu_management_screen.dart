// lib/pages/menu_management_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/food_item.dart';

class Category {
  final String id;
  final String name;

  Category({required this.id, required this.name});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }
}

class MenuManagementColors {
  // Réutilisez les couleurs de votre Dashboard si elles doivent être cohérentes
  // ou définissez-en de nouvelles spécifiques à ce module.
  // Exemple (remplacez par vos vraies couleurs) :
  static const Color buttonGradientStart = Color(0xFFFDFDFD); // Exemple : Coral doux
  static const Color buttonGradientEnd = Color(0xFFFF6B9D);   // Exemple : Rose poudré
  // Ajoutez d'autres couleurs spécifiques à MenuManagementScreen si nécessaire
  static const Color primaryBackground = Color(0xFFFFFFFF); // Exemple : _ivoryWhite
  static const Color textPrimary = Color(0xFF0D3B66);       // Exemple : _primaryBlue
// ... autres couleurs ...
}

// ... Vos constantes de couleurs ...
const Color _primaryBlue = Color(0xFF0D3B66);
const Color _goldAccent = Color(0xFFD4AF37);
const Color _ivoryWhite = Color(0xFFF8FAFC);
const Color _textSecondary = Color(0xFF64748B);
const Color _oliveGreen = Color(0xFF6B8E23);
const Color _pimentRed = Color(0xFFE63946);

// Constantes potentiellement utilisées dans d'autres parties du code
const Color primaryBackground = _ivoryWhite; // Exemple
const Color textPrimary = _primaryBlue; // Exemple
const Color textSecondary = _textSecondary; // Exemple
const Color shadowColor = Color(0xFF000000); // Exemple, ajustez selon votre thème
const Color accentOrange = _goldAccent; // Exemple
const Color primaryText = _primaryBlue; // Exemple
const Color accentPink = _pimentRed; // Exemple
const Color accentCoral = Color(0xFFFF9E80); // Exemple
const Color statusAvailable = Color(0xFFA8E6CF); // Exemple
const Color statusOccupied = _pimentRed; // Exemple
const Color statusReserved = Color(0xFFD4C1EC); // Exemple
const Color searchBackground = Color(0xFFF0F0F0); // Exemple
class MenuManagementScreen extends StatefulWidget {
  final VoidCallback? onCategoryChanged; // <--- AJOUTER CE PARAMÈTRE
  final VoidCallback? onTableStatusChanged;

  const MenuManagementScreen({super.key, this.onCategoryChanged, this.onTableStatusChanged}); // <--- AJOUTER CE PARAMÈTRE AU CONSTRUCTEUR

  @override
  State<MenuManagementScreen> createState() => _MenuManagementScreenState();
}

class _MenuManagementScreenState extends State<MenuManagementScreen> {
  List<FoodItem> _items = [];
  List<Category> _categories = []; // <--- CHANGÉ : Maintenant une liste d'objets Category
  bool _isLoading = true;
  bool _categoriesLoading = true; // <--- AJOUTER CETTE VARIABLE
  final String _baseUrl = 'http://192.168.56.1:8082/menu';
  final String _categoriesUrl = 'http://192.168.56.1:8082/categories'; // <--- AJOUTER CETTE URL

  // --- FONCTION : Charger les catégories ---
  Future<void> _loadCategories() async {
    print("Démarrage de _loadCategories");
    if (!mounted) return;
    setState(() => _categoriesLoading = true);
    try {
      final response = await http.get(Uri.parse(_categoriesUrl));
      print("Réponse de l'API: ${response.statusCode}");
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print("Données reçues: $data");
        print("Nombre de catégories: ${data.length}");
        if (mounted) {
          setState(() {
            // CHANGER ICI : Utilisez Category.fromJson pour créer les objets
            _categories = data.map((json) => Category.fromJson(json)).toList();
            print("_categories mis à jour avec: $_categories");
            _categoriesLoading = false;
          });
        }
      } else {
        throw Exception('Erreur ${response.statusCode} lors du chargement des catégories');
      }
    } catch (e) {
      print("Erreur dans _loadCategories: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: _ivoryWhite),
        );
        setState(() => _categoriesLoading = false);
      }
    }
  }

  Future<void> _loadMenu() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse(_baseUrl));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _items = data.map((json) => FoodItem.fromJson(json)).toList();
            _isLoading = false;
          });
        }
      } else {
        throw Exception('Erreur ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: _ivoryWhite),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  // --- FONCTION CORRIGÉE : Afficher la boîte de dialogue de gestion des catégories ---
  void _showCategoryManagementDialog() {
    print("Ouverture de la boîte de dialogue de gestion des catégories");
    print("État de _categories: $_categories");
    print("Est-ce vide ? ${_categories.isEmpty}");

    showDialog(
      context: context,
      builder: (ctx) {
        // Utilisation de StatefulBuilder pour forcer la reconstruction de la boîte de dialogue
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.category, color: _goldAccent),
                  SizedBox(width: 8),
                  Text('Gestion des Catégories'),
                ],
              ),
              // --- CHANGEMENT : Utilisation de SingleChildScrollView avec Column ---
              content: _categories.isEmpty
                  ? const Text('Aucune catégorie trouvée.')
                  : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min, // Important pour AlertDialog
                  children: _categories.map((category) { // <--- ICI : category est un objet Category
                    final categoryName = category.name; // <--- Accéder au nom
                    final categoryId = category.id;     // <--- Accéder à l'ID

                    return ListTile(
                      key: ValueKey(categoryId), // <--- AJOUTEZ CETTE LIGNE POUR AIDER FLUTTER À IDENTIFIER LES ÉLÉMENTS
                      title: Text(categoryName),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit, color: _oliveGreen),
                            onPressed: () async {
                              // Appeler la fonction d'édition qui recharge les catégories
                              await _editCategory(categoryId, categoryName, _loadCategories);
                              // Mettre à jour l'état local de la boîte de dialogue pour reconstruire la liste
                              setState(() {});
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, color: _pimentRed),
                            onPressed: () async {
                              // Appeler la fonction de suppression qui recharge les catégories
                              await _deleteCategory(categoryId, categoryName, _loadCategories);
                              // Mettre à jour l'état local de la boîte de dialogue pour reconstruire la liste
                              setState(() {});
                            },
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              // --- FIN DU CHANGEMENT ---
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx), // Ferme la boîte de dialogue
                  child: const Text('Fermer'),
                ),
                ElevatedButton( // <--- Le bouton qui appelle _addCategory
                  style: ElevatedButton.styleFrom(backgroundColor: _goldAccent),
                  onPressed: () async {
                    // Appeler la fonction d'ajout qui recharge les catégories
                    await _addCategory();
                    // Mettre à jour l'état local de la boîte de dialogue pour reconstruire la liste
                    setState(() {});
                  },
                  child: const Text('Ajouter Catégorie', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- FONCTION CORRIGÉE : Ajouter une catégorie ---
  Future<void> _addCategory() async {
    final nameCtrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) { // 'ctx' est le BuildContext de la boîte de dialogue
        // SUPPRESSION DU WIDGET THEME ICI
        return AlertDialog(
          title: const Text('Nouvelle Catégorie'),
          content: TextField(
            controller: nameCtrl,
            decoration: const InputDecoration(labelText: 'Nom de la catégorie'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx), // Ferme la boîte de dialogue sans ajouter
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _goldAccent),
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Le nom de la catégorie ne peut pas être vide.')),
                    );
                  }
                  return; // Ne fait rien si le nom est vide
                }
                try {
                  final response = await http.post(
                    Uri.parse(_categoriesUrl),
                    headers: {'Content-Type': 'application/json'},
                    body: jsonEncode({'name': nameCtrl.text.trim()}),
                  );
                  if (response.statusCode == 201) {
                    if (mounted) {
                      Navigator.pop(ctx); // Ferme la boîte de dialogue d'ajout
                      await _loadCategories(); // Recharge la liste des catégories dans l'application
                      // Le callback onCategoryChanged dans MenuManagementScreen appellera _switchToMenuTab
                      if (widget.onCategoryChanged != null) {
                        widget.onCategoryChanged!(); // <--- APPELER LE CALLBACK
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: const Text('Catégorie ajoutée'), backgroundColor: _ivoryWhite),
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
              },
              child: const Text('Ajouter', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  // --- FONCTION CORRIGÉE : Modifier une catégorie ---
  // Ajouter un paramètre pour la fonction de mise à jour
  Future<void> _editCategory(String categoryId, String currentName, Future<void> Function() updateFunction) async {
    final nameCtrl = TextEditingController(text: currentName);
    await showDialog(
      context: context,
      builder: (ctx) {
        // SUPPRESSION DU WIDGET THEME ICI
        return AlertDialog(
          title: const Text('Modifier Catégorie'),
          content: TextField(
            controller: nameCtrl,
            decoration: const InputDecoration(labelText: 'Nom de la catégorie'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _goldAccent),
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Le nom de la catégorie ne peut pas être vide.')),
                    );
                  }
                  return;
                }
                try {
                  final response = await http.put(
                    Uri.parse('$_categoriesUrl/$categoryId'), // URL avec l'ID de la catégorie
                    headers: {'Content-Type': 'application/json'},
                    body: jsonEncode({'name': nameCtrl.text.trim()}),
                  );
                  if (response.statusCode == 200) {
                    if (mounted) {
                      Navigator.pop(ctx);
                      await updateFunction(); // <--- APPELER LA FONCTION DE MISE À JOUR PASSÉE EN PARAMÈTRE (_loadCategories)
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: const Text('Catégorie modifiée'), backgroundColor: _ivoryWhite),
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
              },
              child: const Text('Sauvegarder', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  // --- FONCTION CORRIGÉE : Supprimer une catégorie ---
  // Ajouter un paramètre pour la fonction de mise à jour
  Future<void> _deleteCategory(String categoryId, String categoryName, Future<void> Function() updateFunction) async {
    await showDialog(
      context: context,
      builder: (ctx) {
        // SUPPRESSION DU WIDGET THEME ICI
        return AlertDialog(
          title: const Text('Supprimer Catégorie ?'),
          content: Text('Supprimer la catégorie "$categoryName" ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  final response = await http.delete(
                    Uri.parse('$_categoriesUrl/$categoryId'), // URL avec l'ID de la catégorie
                  );
                  if (response.statusCode == 200) {
                    if (mounted) {
                      Navigator.pop(ctx);
                      await updateFunction(); // <--- APPELER LA FONCTION DE MISE À JOUR PASSÉE EN PARAMÈTRE (_loadCategories)
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: const Text('Catégorie supprimée'), backgroundColor: _ivoryWhite),
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
                  if (mounted) Navigator.pop(ctx);
                }
              },
              child: const Text('Supprimer', style: TextStyle(color: _pimentRed)),
            ),
          ],
        );
      },
    );
  }

  // CREATE (Ajouter un plat)
  Future<void> _createItem(String name, String category, String priceStr, String desc, String img) async {
    final price = double.tryParse(priceStr) ?? 0.0;
    // Valider que la catégorie sélectionnée existe dans la liste chargée
    // CHANGEMENT : Utiliser les noms des catégories chargées
    final categoryNames = _categories.map((cat) => cat.name).toList();
    if (!categoryNames.contains(category)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: Catégorie invalide.'), backgroundColor: _pimentRed),
        );
      }
      return;
    }
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'category': category, // Utilisez la catégorie sélectionnée
          'price': price,
          'description': desc,
          'image_path': img,
        }),
      );
      if (response.statusCode == 201) {
        if (mounted) {
          await _loadMenu(); // Recharge la liste des plats
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: const Text('Plat ajouté'), backgroundColor: _ivoryWhite),
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

  // UPDATE (Modifier un plat)
  Future<void> _updateItem(String id, String name, String category, String priceStr, String desc, String img) async {
    final price = double.tryParse(priceStr) ?? 0.0;
    // Valider que la catégorie sélectionnée existe dans la liste chargée
    // CHANGEMENT : Utiliser les noms des catégories chargées
    final categoryNames = _categories.map((cat) => cat.name).toList();
    if (!categoryNames.contains(category)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: Catégorie invalide.'), backgroundColor: _pimentRed),
        );
      }
      return;
    }
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/$id'), // Utilise l'ID du plat à modifier
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'category': category, // Utilisez la catégorie sélectionnée
          'price': price,
          'description': desc,
          'image_path': img,
        }),
      );
      if (response.statusCode == 200) { // Supabase renvoie souvent 200 pour PUT réussi
        if (mounted) {
          await _loadMenu(); // Recharge la liste des plats
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: const Text('Plat modifié'), backgroundColor: _ivoryWhite),
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

  // DELETE (Supprimer un plat)
  Future<void> _deleteItem(String id) async { // <--- Le paramètre est l'ID du plat
    try {
      final response = await http.delete(Uri.parse('$_baseUrl/$id')); // Utilise l'ID du plat à supprimer
      if (response.statusCode == 200) { // Supabase renvoie souvent 200 pour DELETE réussi
        if (mounted) {
          await _loadMenu(); // Recharge la liste des plats
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: const Text('Plat supprimé'), backgroundColor: _ivoryWhite),
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

  @override
  void initState() {
    super.initState();
    // Charger à la fois les plats et les catégories
    Future.wait([_loadMenu(), _loadCategories()]); // <--- MODIFIER CETTE LIGNE
  }

  // --- FONCTION : Ajouter un plat ---
  Future<void> _addItem() async {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final imgCtrl = TextEditingController(text: 'placeholder.jpg');
    // Prendre la première catégorie par défaut, ou laisser vide
    String category = _categories.isNotEmpty ? _categories.first.name : ''; // <--- CHANGEMENT : Utiliser .name

    await showDialog(
      context: context,
      builder: (ctx) {
        // SUPPRESSION DU WIDGET THEME ICI
        return AlertDialog(
          title: const Text('Nouvel Article'),
          content: SizedBox(
            width: 300,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nom')),
                  TextField(controller: descCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Description')),
                  TextField(controller: priceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Prix (TND)')),
                  TextField(controller: imgCtrl, decoration: const InputDecoration(labelText: 'Image (ex: couscous.jpg)')),
                  // Remplacer la liste fixe par la liste dynamique _categories
                  DropdownButtonFormField<String>(
                    value: category,
                    items: _categories // Utiliser la liste chargée dynamiquement
                        .map((cat) => DropdownMenuItem(value: cat.name, child: Text(cat.name))) // <--- CHANGEMENT : Utiliser .name
                        .toList(),
                    onChanged: (v) => setState(() => category = v!),
                    decoration: const InputDecoration(labelText: 'Catégorie'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _goldAccent),
              onPressed: () {
                if (nameCtrl.text.isEmpty || priceCtrl.text.isEmpty) return;
                // Vérifier si la catégorie sélectionnée existe toujours dans la liste chargée
                final categoryNames = _categories.map((cat) => cat.name).toList(); // <--- CHANGEMENT : Utiliser .name
                if (!categoryNames.contains(category)) { // <--- CHANGEMENT : Utiliser .name
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Catégorie sélectionnée invalide.')),
                    );
                  }
                  return;
                }
                _createItem(nameCtrl.text, category, priceCtrl.text, descCtrl.text, imgCtrl.text);
                Navigator.pop(ctx);
              },
              child: const Text('Ajouter', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
    if (mounted) await _loadMenu();
  }

  // --- FONCTION : Modifier un plat ---
  Future<void> _editItem(FoodItem item) async {
    final nameCtrl = TextEditingController(text: item.name);
    final priceCtrl = TextEditingController(text: item.price.toString());
    final descCtrl = TextEditingController(text: item.description);
    final imgCtrl = TextEditingController(text: item.imagePath.split('/').last);
    String category = item.category; // La catégorie actuelle de l'item

    // Vérifier si la catégorie actuelle de l'item est dans la liste des catégories chargées
    // Si ce n'est pas le cas, on peut laisser la catégorie actuelle ou la changer
    // Pour l'instant, on la garde si elle n'est pas dans la liste (ou laisser l'utilisateur choisir)
    // ou forcer à sélectionner une catégorie valide.

    await showDialog(
      context: context,
      builder: (ctx) {
        // SUPPRESSION DU WIDGET THEME ICI
        return AlertDialog(
          title: const Text('Modifier Article'),
          content: SizedBox(
            width: 300,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nom')),
                  TextField(controller: descCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Description')),
                  TextField(controller: priceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Prix (TND)')),
                  TextField(controller: imgCtrl, decoration: const InputDecoration(labelText: 'Image (ex: couscous.jpg)')),
                  // Remplacer la liste fixe par la liste dynamique _categories
                  DropdownButtonFormField<String>(
                    value: category,
                    items: _categories // Utiliser la liste chargée dynamiquement
                        .map((cat) => DropdownMenuItem(value: cat.name, child: Text(cat.name))) // <--- CHANGEMENT : Utiliser .name
                        .toList(),
                    onChanged: (v) => setState(() => category = v!),
                    decoration: const InputDecoration(labelText: 'Catégorie'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _goldAccent),
              onPressed: () {
                if (nameCtrl.text.isEmpty || priceCtrl.text.isEmpty) return;
                // Vérifier si la catégorie sélectionnée existe toujours dans la liste chargée
                final categoryNames = _categories.map((cat) => cat.name).toList(); // <--- CHANGEMENT : Utiliser .name
                if (!categoryNames.contains(category)) { // <--- CHANGEMENT : Utiliser .name
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Catégorie sélectionnée invalide.')),
                    );
                  }
                  return;
                }
                _updateItem(item.id, nameCtrl.text, category, priceCtrl.text, descCtrl.text, imgCtrl.text);
                Navigator.pop(ctx);
              },
              child: const Text('Sauvegarder', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
    if (mounted) await _loadMenu();
  }

  // --- FONCTION : Confirmer la suppression d'un plat ---
  void _showDeleteConfirm(FoodItem item) {
    showDialog(
      context: context,
      builder: (ctx) {
        // SUPPRESSION DU WIDGET THEME ICI
        return AlertDialog(
          title: const Text('Supprimer ?'),
          content: Text('Supprimer "${item.name}" ?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
            TextButton(
              onPressed: () {
                _deleteItem(item.id); // <--- Appel à la fonction _deleteItem (que vous devez avoir)
                Navigator.pop(ctx);
              },
              child: const Text('Supprimer', style: TextStyle(color: _pimentRed)),
            ),
          ],
        );
      },
    );
  }

  // --- FONCTION : Afficher les détails d'un plat ---
  void _showFoodDetail(FoodItem item) {
    showModalBottomSheet(
      context: context,
      // SUPPRESSION DU WIDGET THEME ICI
      backgroundColor: _ivoryWhite, // Appliqué directement via le constructeur
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) { // 'ctx' est le BuildContext pour le bottom sheet
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  image: DecorationImage(image: AssetImage(item.imagePath), fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 16),
              Text(item.name, style: const TextStyle(color: _primaryBlue, fontWeight: FontWeight.bold, fontSize: 22)),
              const SizedBox(height: 8),
              Text(item.description, style: const TextStyle(color: _textSecondary, fontSize: 16), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Text('${item.price.toStringAsFixed(2)} DT', style: const TextStyle(color: _goldAccent, fontWeight: FontWeight.bold, fontSize: 24)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: _oliveGreen, foregroundColor: Colors.white),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _editItem(item); // <--- Appel à la fonction _editItem
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Modifier'),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: _pimentRed, foregroundColor: Colors.white),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showDeleteConfirm(item); // <--- Appel à la fonction _showDeleteConfirm
                    },
                    icon: const Icon(Icons.delete),
                    label: const Text('Supprimer'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // --- FONCTION : Construire la carte d'un plat ---
  Widget _buildFoodCard(FoodItem item) { // <--- Nom de la fonction
    // Trouver l'ID de la catégorie de l'item (nécessite une recherche dans _fullCategories)
    // Supposons que vous ayez une structure _fullCategories = [{'id': '...', 'name': '...'}, ...]
    // String? categoryId = _fullCategories.firstWhere((cat) => cat['name'] == item.category, orElse: () => {'id': ''})['id'];
    // Pour simplifier avec la structure actuelle (List<String> _categories), on ne peut pas facilement éditer la catégorie de l'item ici.
    // Il est préférable de gérer l'édition de la catégorie dans le dialogue d'édition de l'item lui-même.
    // Donc, les boutons d'édition/suppression de catégorie ne sont pas dans _buildFoodCard,
    // mais dans la boîte de dialogue de gestion des catégories.

    return GestureDetector(
      onTap: () => _showFoodDetail(item), // <--- Appel à la fonction _showFoodDetail
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _ivoryWhite,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(image: AssetImage(item.imagePath), fit: BoxFit.cover),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name, style: const TextStyle(color: _primaryBlue, fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(item.description, style: const TextStyle(color: _textSecondary, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                          '${item.price.toStringAsFixed(2)} DT',
                          style: const TextStyle(color: _goldAccent, fontWeight: FontWeight.bold, fontSize: 18)
                      ),
                      Row(children: const [
                        Icon(Icons.star, color: Colors.amber, size: 16),
                        SizedBox(width: 4),
                        Text('4.5', style: TextStyle(color: _textSecondary, fontSize: 14)) // Note fixe pour l'instant
                      ]),
                    ],
                  ),
                ],
              ),
            ),
            // Boutons d'édition/suppression de l'ITEM, pas de la catégorie
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () => _editItem(item), // <--- Appel à la fonction _editItem
                  child: Container(
                    height: 36,
                    width: 36,
                    decoration: BoxDecoration(color: _oliveGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.edit, color: _oliveGreen, size: 20),
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => _showDeleteConfirm(item), // <--- Appel à la fonction _showDeleteConfirm
                  child: Container(
                    height: 36,
                    width: 36,
                    decoration: BoxDecoration(color: _pimentRed.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.delete, color: _pimentRed, size: 20),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Afficher un indicateur de chargement si les catégories sont en cours de chargement
    // Vous pouvez aussi combiner l'état de chargement des plats et des catégories si nécessaire
    if (_isLoading || _categoriesLoading) {
      return Scaffold(
        backgroundColor: _ivoryWhite,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Grouper les plats en utilisant les catégories chargées
    final grouped = <String, List<FoodItem>>{};
    // CHANGEMENT : Utiliser les noms des catégories chargées pour le groupement
    final categoryNames = _categories.map((cat) => cat.name).toList();
    for (var item in _items) {
      // Vérifiez si la catégorie de l'item est dans la liste des catégories connues
      // Si non, vous pouvez soit ignorer l'item, soit l'ajouter à une catégorie par défaut
      if (categoryNames.contains(item.category)) { // <--- CHANGEMENT : Utiliser categoryNames
        grouped.putIfAbsent(item.category, () => []).add(item);
      } else {
        // Optionnel : Ajouter à une catégorie "Autres" ou ignorer
        // grouped.putIfAbsent('Autres', () => []).add(item);
        // Ou ignorer : continue;
      }
    }

    // Triez les onglets par ordre alphabétique des noms de catégories
    // CHANGEMENT : Trier la liste des objets Category en fonction de leur nom, puis extraire les noms
    final sortedCategoryNames = _categories.toList()..sort((a, b) => a.name.compareTo(b.name));
    final sortedNames = sortedCategoryNames.map((cat) => cat.name).toList(); // <--- Extraire les noms triés

    return DefaultTabController(
      length: sortedNames.length, // <--- UTILISER LA LONGUEUR DE LA LISTE TRIÉE DES NOMS
      child: Scaffold(
        backgroundColor: _ivoryWhite,
        appBar: AppBar(
          backgroundColor: _ivoryWhite,
          title: Text(
            'Gestion du Menu',
            style: const TextStyle(
              color: _primaryBlue,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          actions: [
            // Bouton pour gérer les catégories (affiche la liste, permet édition/suppression)
            IconButton(
              icon: Icon(Icons.category, color: _goldAccent),
              onPressed: _showCategoryManagementDialog, // <--- Appeler la fonction
              tooltip: 'Gérer les catégories',
            ),
            // Bouton pour ajouter UNE SEULE catégorie (ouvre directement le formulaire)
            IconButton(
              icon: Icon(Icons.add_circle, color: _goldAccent), // Choisissez une icône appropriée
              onPressed: _addCategory, // Appelle directement la fonction d'ajout
              tooltip: 'Ajouter une catégorie', // Info-bulle optionnelle
            ),
            // Bouton pour ajouter un plat
            IconButton(
              icon: Icon(Icons.add, color: _goldAccent),
              onPressed: _addItem,
            ),
          ],
          elevation: 0,
        ),
        body: Column(
          children: [
            TabBar(
              isScrollable: true,
              labelColor: _goldAccent,
              unselectedLabelColor: _textSecondary,
              indicatorColor: _goldAccent,
              labelStyle: const TextStyle(fontWeight: FontWeight.w600),
              tabs: sortedNames.map((cat) => Tab(text: cat)).toList(), // <--- UTILISER LA LISTE TRIÉE DES NOMS
            ),
            Expanded(
              child: TabBarView(
                children: sortedNames.map((categoryName) { // <--- UTILISER LA LISTE TRIÉE DES NOMS
                  final itemsForCategory = grouped[categoryName] ?? []; // <--- Récupérer la liste, peut être vide
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: itemsForCategory.length,
                    itemBuilder: (context, index) =>
                        _buildFoodCard(itemsForCategory[index]),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}