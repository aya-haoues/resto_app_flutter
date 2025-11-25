// lib/pages/supplements_management_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/supplement.dart';

class SupplementsManagementScreen extends StatefulWidget {
  const SupplementsManagementScreen({super.key});

  @override
  State<SupplementsManagementScreen> createState() =>
      _SupplementsManagementScreenState();
}

class _SupplementsManagementScreenState
    extends State<SupplementsManagementScreen> {
  final String _supplementsUrl = 'http://10.187.253.200:8082/supplements';
  List<Supplement> _supplements = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSupplements();
  }

  Future<void> _loadSupplements() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse(_supplementsUrl));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _supplements = data.map((json) => Supplement.fromJson(json)).toList();
          _isLoading = false;
        });
      } else {
        throw Exception('Erreur ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _error = 'Erreur: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _createSupplement(String name, double price) async {
    try {
      final response = await http.post(
        Uri.parse(_supplementsUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'price': price}),
      );
      if (response.statusCode == 201) {
        await _loadSupplements();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Supplément ajouté !')),
          );
        }
      } else {
        final errorMsg = jsonDecode(response.body)['error'] ?? 'Erreur inconnue';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $errorMsg')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur réseau: $e')),
        );
      }
    }
  }

  Future<void> _updateSupplement(int id, String name, double price) async {
    try {
      final response = await http.put(
        Uri.parse('$_supplementsUrl/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'price': price}),
      );
      if (response.statusCode == 200) {
        await _loadSupplements();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Supplément mis à jour !')),
          );
        }
      } else {
        final errorMsg = jsonDecode(response.body)['error'] ?? 'Erreur inconnue';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $errorMsg')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur réseau: $e')),
        );
      }
    }
  }

  Future<void> _deleteSupplement(int id) async {
    try {
      final response = await http.delete(Uri.parse('$_supplementsUrl/$id'));
      if (response.statusCode == 200) {
        await _loadSupplements();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Supplément supprimé !')),
          );
        }
      } else {
        final errorMsg = jsonDecode(response.body)['error'] ?? 'Erreur inconnue';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $errorMsg')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur réseau: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestion des Suppléments')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _supplements.length,
        itemBuilder: (context, index) {
          final supplement = _supplements[index];
          return Card(
            child: ListTile(
              title: Text(
                supplement.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                '${supplement.price.toStringAsFixed(2)} DT',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _showEditDialog(supplement),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _showDeleteDialog(supplement.id),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showCreateDialog() {
    final nameController = TextEditingController();
    final priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Nouveau Supplément'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nom'),
                ),
                TextField(
                  controller: priceController,
                  decoration: const InputDecoration(labelText: 'Prix (DT)'),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: Navigator.of(context).pop,
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                final priceText = priceController.text.trim();
                if (name.isEmpty || priceText.isEmpty) return;
                final price = double.tryParse(priceText) ?? 0.0;
                if (name.isNotEmpty && price > 0) {
                  Navigator.of(context).pop();
                  _createSupplement(name, price);
                }
              },
              child: const Text('Créer'),
            ),
          ],
        );
      },
    );
  }

  void _showEditDialog(Supplement supplement) {
    final nameController = TextEditingController(text: supplement.name);
    final priceController = TextEditingController(
      text: supplement.price.toStringAsFixed(2),
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Modifier le Supplément'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nom'),
                ),
                TextField(
                  controller: priceController,
                  decoration: const InputDecoration(labelText: 'Prix (DT)'),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: Navigator.of(context).pop,
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                final priceText = priceController.text.trim();
                if (name.isEmpty || priceText.isEmpty) return;
                final price = double.tryParse(priceText) ?? 0.0;
                if (name.isNotEmpty && price >= 0) {
                  Navigator.of(context).pop();
                  _updateSupplement(supplement.id, name, price);
                }
              },
              child: const Text('Mettre à jour'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteDialog(int supplementId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Supprimer le Supplément ?'),
          content: const Text('Êtes-vous sûr de vouloir supprimer ce supplément ?'),
          actions: [
            TextButton(
              onPressed: Navigator.of(context).pop,
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteSupplement(supplementId);
              },
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );
  }
}