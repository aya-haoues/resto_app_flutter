// lib/screens/menu_management_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/food_item.dart';

// ✅ OFFICIAL TAWA ORDER COLORS
const Color _primaryBlue = Color(0xFF0D3B66);
const Color _goldAccent = Color(0xFFD4AF37);
const Color _ivoryWhite = Color(0xFFFFF0F0);
const Color _textSecondary = Color(0xFF64748B);
const Color _oliveGreen = Color(0xFF6B8E23);
const Color _pimentRed = Color(0xFFE63946);

class MenuManagementScreen extends StatefulWidget {
  const MenuManagementScreen({super.key});

  @override
  State<MenuManagementScreen> createState() => _MenuManagementScreenState();
}

class _MenuManagementScreenState extends State<MenuManagementScreen> {
  List<FoodItem> _items = [];
  bool _isLoading = true;
  final String _baseUrl = 'http://192.168.43.8:8082/menu';

  @override
  void initState() {
    super.initState();
    _loadMenu();
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

  Future<void> _deleteItem(String id) async {
    await http.delete(Uri.parse('$_baseUrl/$id'));
    if (!mounted) return;
    await _loadMenu();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: const Text('Plat supprimé'), backgroundColor: _ivoryWhite),
    );
  }

  Future<void> _addItem() async {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final imgCtrl = TextEditingController(text: 'placeholder.jpg');
    String category = 'Tunisienne';

    await showDialog(
      context: context,
      builder: (ctx) {
        return Theme(
          data: Theme.of(context).copyWith(dialogBackgroundColor: _ivoryWhite),
          child: AlertDialog(
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
                    DropdownButtonFormField<String>(
                      value: category,
                      items: const ['Tunisienne', 'Italienne', 'Américaine', 'Desserts', 'Boissons']
                          .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (v) => setState(() => category = v!),
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
                  _createItem(nameCtrl.text, category, priceCtrl.text, descCtrl.text, imgCtrl.text);
                  Navigator.pop(ctx);
                },
                child: const Text('Ajouter', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      },
    );
    if (mounted) await _loadMenu();
  }

  Future<void> _createItem(String name, String category, String priceStr, String desc, String img) async {
    final price = double.tryParse(priceStr) ?? 0.0;
    await http.post(
      Uri.parse(_baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'category': category,
        'price': price,
        'description': desc,
        'image_path': img,
      }),
    );
  }

  Future<void> _editItem(FoodItem item) async {
    final nameCtrl = TextEditingController(text: item.name);
    final priceCtrl = TextEditingController(text: item.price.toString());
    final descCtrl = TextEditingController(text: item.description);
    final imgCtrl = TextEditingController(text: item.imagePath.split('/').last);
    String category = item.category;

    final validCategories = ['Tunisienne', 'Italienne', 'Américaine', 'Desserts', 'Boissons'];
    if (!validCategories.contains(category)) {
      category = 'Tunisienne';
    }

    await showDialog(
      context: context,
      builder: (ctx) {
        return Theme(
          data: Theme.of(context).copyWith(dialogBackgroundColor: _ivoryWhite),
          child: AlertDialog(
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
                    DropdownButtonFormField<String>(
                      value: category,
                      items: validCategories.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (v) => setState(() => category = v!),
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
                  _updateItem(item.id, nameCtrl.text, category, priceCtrl.text, descCtrl.text, imgCtrl.text);
                  Navigator.pop(ctx);
                },
                child: const Text('Sauvegarder', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      },
    );
    if (mounted) await _loadMenu();
  }

  Future<void> _updateItem(String id, String name, String category, String priceStr, String desc, String img) async {
    final price = double.tryParse(priceStr) ?? 0.0;
    await http.put(
      Uri.parse('$_baseUrl/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'category': category,
        'price': price,
        'description': desc,
        'image_path': img,
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(backgroundColor: _ivoryWhite, body: const Center(child: CircularProgressIndicator()));
    }

    final grouped = <String, List<FoodItem>>{};
    for (var item in _items) {
      grouped.putIfAbsent(item.category, () => []).add(item);
    }

    return DefaultTabController(
      length: grouped.length,
      child: Scaffold(
        backgroundColor: _ivoryWhite,
        appBar: AppBar(
          backgroundColor: _ivoryWhite,
          title: Text('Gestion du Menu', style: const TextStyle(color: _primaryBlue, fontWeight: FontWeight.bold, fontSize: 24)),
          actions: [IconButton(icon: Icon(Icons.add, color: _goldAccent), onPressed: _addItem)],
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
              tabs: grouped.keys.map((cat) => Tab(text: cat)).toList(),
            ),
            Expanded(
              child: TabBarView(
                children: grouped.entries.map((entry) {
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: entry.value.length,
                    itemBuilder: (context, index) => _buildFoodCard(entry.value[index]),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFoodCard(FoodItem item) {
    return GestureDetector(
      onTap: () => _showFoodDetail(item),
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
                      Text('${item.price.toStringAsFixed(2)} DT', style: const TextStyle(color: _goldAccent, fontWeight: FontWeight.bold, fontSize: 18)),
                      Row(children: const [Icon(Icons.star, color: Colors.amber, size: 16), SizedBox(width: 4), Text('4.5', style: TextStyle(color: _textSecondary, fontSize: 14))]),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () => _editItem(item),
                  child: Container(
                    height: 36,
                    width: 36,
                    decoration: BoxDecoration(color: _oliveGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.edit, color: _oliveGreen, size: 20),
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => _showDeleteConfirm(item),
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

  void _showFoodDetail(FoodItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _ivoryWhite,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
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
                      _editItem(item);
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Modifier'),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: _pimentRed, foregroundColor: Colors.white),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showDeleteConfirm(item);
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

  void _showDeleteConfirm(FoodItem item) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Theme(
          data: Theme.of(context).copyWith(dialogBackgroundColor: _ivoryWhite),
          child: AlertDialog(
            title: const Text('Supprimer ?'),
            content: Text('Supprimer "${item.name}" ?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
              TextButton(
                onPressed: () {
                  _deleteItem(item.id);
                  Navigator.pop(ctx);
                },
                child: const Text('Supprimer', style: TextStyle(color: _pimentRed)),
              ),
            ],
          ),
        );
      },
    );
  }
}