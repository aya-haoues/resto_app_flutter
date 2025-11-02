import 'package:flutter/material.dart';
import 'home_page.dart';

class CommandesPage extends StatefulWidget {
  final List<FoodItem> panier;

  const CommandesPage({super.key, required this.panier});

  @override
  State<CommandesPage> createState() => _CommandesPageState();
}

class _CommandesPageState extends State<CommandesPage> {
  late List<FoodItem> _panierLocal;

  @override
  void initState() {
    super.initState();
    _panierLocal = List.from(widget.panier);
  }

  @override
  Widget build(BuildContext context) {
    double total = _panierLocal.fold(0, (sum, item) => sum + item.price);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Votre Commande'),
        backgroundColor: Colors.orangeAccent,
      ),
      body: _panierLocal.isEmpty
          ? const Center(child: Text('Votre panier est vide !'))
          : Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _panierLocal.length,
              itemBuilder: (context, index) {
                final item = _panierLocal[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: Image.asset(item.imagePath, width: 60, height: 60, fit: BoxFit.cover),
                    title: Text(item.name),
                    subtitle: Text('${item.price.toStringAsFixed(2)} DT'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          _panierLocal.removeAt(index);
                        });
                      },
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('${total.toStringAsFixed(2)} DT',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orangeAccent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    onPressed: _panierLocal.isEmpty ? null : _passerCommande,
                    child: const Text('Passer la commande',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _passerCommande() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Commande passée'),
        content: const Text('Merci pour votre commande !'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _panierLocal.clear();
              });
              Navigator.of(context).pop(); // Retour à l'accueil
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
