// lib/pages/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http; // Ajout de l'import pour http
import 'dart:convert'; // Ajout de l'import pour jsonDecode
// Ajustez le chemin si MenuManagementScreen est dans un autre dossier
import 'menu_management_screen.dart';
import '../models/food_item.dart'; // Ajustez le chemin si nécessaire
import '../models/table.dart'; // <--- IMPORTER LE BON FICHIER, ASSUME QUE LE NOM DE LA CLASSE EST CHANGÉ EN dedans

// lib/pages/dashboard_screen.dart

class DashboardColors {
  // ... vos autres constantes ...
  static const Color primaryText = Color(0xFF4A3F35);
  static const Color background = Color(0xFFF9F9F9);
  static const Color cardBackground = Colors.white;
  static const Color accentPink = Color(0xFFFF6B9D);
  static const Color accentCoral = Color(0xFFFF9E80);
  static const Color statusAvailable = Color(0xFFA8E6CF);
  static const Color statusOccupied = Color(0xFFD6496D);
  static const Color statusReserved = Color(0xFFD4C1EC);
  static const Color searchBackground = Color(0xFFF0F0F0);

  static const Color buttonGradientStart = accentCoral; // Exemple : Utiliser une couleur existante
  static const Color buttonGradientEnd = accentPink;   // Exemple : Utiliser une autre couleur existante
}

//  DASHBOARD SCREEN

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // CHANGÉ : Utiliser TableInfo au lieu de TableData ou Table
  Map<int, TableInfo> _tablesMap = {};
  List<TableInfo> _filteredTables = [];
  bool _tablesLoading = true;
  String? _tablesError;

  // Définir la plage de tables (1 à 20)
  static const int _minTableNumber = 1;
  static const int _maxTableNumber = 20;

  String _timeElapsed(DateTime? startTime) {
    if (startTime == null) return '';
    final duration = DateTime.now().difference(startTime);
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes} min';
    } else {
      return 'Nouvelle session';
    }
  }

  // Mise à jour de _calculateStatusCounts pour utiliser le nouveau modèle TableInfo
  Map<String, int> _calculateStatusCounts() {
    final counts = <String, int>{
      'available': 0, // Utiliser la chaîne 'available'
      'occupied': 0,  // Utiliser la chaîne 'occupied'
    };
    // Parcourir la Map complète
    for (final tableInfo in _tablesMap.values) {
      final lowerCaseStatus = tableInfo.status.toLowerCase();
      if (lowerCaseStatus == 'available' || lowerCaseStatus == 'libre') {
        counts['available'] = (counts['available'] ?? 0) + 1;
      } else if (lowerCaseStatus == 'occupied' || lowerCaseStatus == 'occupée') {
        counts['occupied'] = (counts['occupied'] ?? 0) + 1;
      }
      // Les statuts non gérés ici ne sont pas comptés (ex: 'reserved' si non supprimé du backend)
    }
    return counts;
  }

  // CARD
  Widget _buildSummaryCard(String title, int count, Color color) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                color: DashboardColors.primaryText.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // status tables
  Widget _buildStatusSummaryHeader() {
    final counts = _calculateStatusCounts(); // Utilise la fonction mise à jour
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0, bottom: 12.0),
      child: Row(
        children: [
          _buildSummaryCard('Libres', counts['available'] ?? 0, DashboardColors.statusAvailable), // Utiliser 'available'
          const SizedBox(width: 12),
          _buildSummaryCard('Occupées', counts['occupied'] ?? 0, DashboardColors.statusOccupied), // Utiliser 'occupied'
        ],
      ),
    );
  }

  // lib/pages/dashboard_screen.dart

// ... dans la fonction _showOrderDetails ...

  // lib/pages/dashboard_screen.dart

// ... dans la fonction _showOrderDetails ...

  void _showOrderDetails(BuildContext context, TableInfo table) {
    Color statusColor;
    String statusText;
    switch (table.status.toLowerCase()) {
      case 'available':
      case 'libre':
        statusColor = DashboardColors.statusAvailable;
        statusText = 'Disponible';
        break;
      case 'occupied':
      case 'occupée':
        statusColor = DashboardColors.statusOccupied;
        statusText = 'Occupée';
        break;
      default:
        statusColor = Colors.grey;
        statusText = table.status;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          title: Text(
            'Table ${table.number}',
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: DashboardColors.primaryText,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor, width: 1),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: statusColor,
                  ),
                ),
              ),
              // --- AJOUTER L'AFFICHAGE DES NOTES ICI ---
              if (table.status.toLowerCase() == 'occupied' || table.status.toLowerCase() == 'occupée')
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Notes du client :',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: DashboardColors.primaryText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: SelectableText( // Utilisez SelectableText pour permettre la copie
                          table.notes ?? 'Aucune note spéciale', // Affiche les notes ou un message par défaut
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            color: DashboardColors.primaryText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              // --- FIN DE L'AJOUT ---
              if (table.status.toLowerCase() == 'occupied' || table.status.toLowerCase() == 'occupée')
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        'Temps : ${_timeElapsed(DateTime.tryParse(table.timeOccupied ?? ''))}',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              const Text(
                'Détails de la commande :',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: DashboardColors.primaryText,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                table.orderSummary ?? 'Aucune commande',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  color: DashboardColors.primaryText,
                ),
              ),
              if (table.status.toLowerCase() == 'occupied' || table.status.toLowerCase() == 'occupée') ...[
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _markTableAsAvailable(table.number); // <--- Appel à la fonction API avec 'table.number'
                      Navigator.of(context).pop(); // Fermer la boîte de dialogue
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: DashboardColors.statusAvailable,
                          content: Text('Table ${table.number} libérée avec succès !'), // <--- Afficher 'table.number'
                        ),
                      );
                    },
                    icon: const Icon(Icons.check_circle, color: Colors.white),
                    label: const Text(
                      'Marquer comme Libre',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DashboardColors.statusAvailable,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 4,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Fermer',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: DashboardColors.accentPink,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  //  TABLES LAYOUT VIEW
  // --- MODIFIER _buildTablesLayoutView POUR UTILISER _filteredTables ---
  Widget _buildTablesLayoutView(BuildContext context) {
    if (_tablesLoading) {
      return const Center(child: CircularProgressIndicator()); // Afficher un indicateur de chargement
    }
    if (_tablesError != null) {
      return Center(child: Text('Erreur: $_tablesError')); // Afficher l'erreur
    }

    return Column(
      children: [
        _buildStatusSummaryHeader(),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.95,
            ),
            // CHANGEMENT : Utiliser la plage de numéros de table
            itemCount: _maxTableNumber - _minTableNumber + 1,
            itemBuilder: (context, index) {
              // Calculer le numéro de table réel à partir de l'index
              final tableNumber = _minTableNumber + index;
              // Récupérer les données de la table depuis la Map
              final table = _tablesMap[tableNumber]!; // On sait qu'elle existe grâce à _loadTables

              Color color;
              IconData icon;
              String statusText;

              final lowerCaseStatus = table.status.toLowerCase();
              if (lowerCaseStatus == 'available' || lowerCaseStatus == 'libre') {
                color = DashboardColors.statusAvailable;
                icon = Icons.circle;
                statusText = 'Libre';
              } else if (lowerCaseStatus == 'occupied' || lowerCaseStatus == 'occupée') {
                color = DashboardColors.statusOccupied;
                icon = Icons.circle;
                statusText = 'Occupée';
              } else {
                // Gérer un statut inconnu ou non affiché (théoriquement impossible ici grâce à _loadTables)
                color = Colors.grey;
                icon = Icons.help_outline;
                statusText = table.status; // Afficher le statut brut
              }

              return InkWell(
                onTap: () => _showOrderDetails(context, table),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    border: Border.all(color: color.withOpacity(0.5), width: 1.5),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon, size: 28, color: color),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Table $tableNumber', // <--- Utiliser le numéro calculé
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: DashboardColors.primaryText,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          statusText, // <--- Utiliser le texte calculé
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (lowerCaseStatus == 'occupied' || lowerCaseStatus == 'occupée')
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              _timeElapsed(DateTime.tryParse(table.timeOccupied ?? '')),
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // PLACEHOLDER WIDGET
  Widget _placeholderWidget(String title, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: DashboardColors.background,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 48,
              color: DashboardColors.primaryText.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Module: $title',
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: DashboardColors.primaryText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'À venir bientôt...',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  //  STATISTICS VIEW
  Widget _statCard(String title, String value, IconData icon) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: DashboardColors.accentCoral.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: DashboardColors.accentCoral, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: DashboardColors.primaryText,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                color: DashboardColors.primaryText.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsView(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Performance Aujourd\'hui',
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: DashboardColors.primaryText,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _statCard('Commandes', '42', Icons.receipt_long),
              const SizedBox(width: 12),
              _statCard('Revenu', '1250 TND', Icons.attach_money),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _statCard('Plat phare', 'Chawarma (12)', Icons.fastfood),
              const SizedBox(width: 12),
              _statCard('Temps moyen', '18 min', Icons.timer),
            ],
          ),
          const SizedBox(height: 28),
          Text(
            'Aperçu de la Semaine',
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: DashboardColors.primaryText,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 240,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
            ),
            child: _placeholderWidget('Graphique', Icons.bar_chart),
          ),
        ],
      ),
    );
  }

  //  REAL-TIME ORDERS VIEW
  Widget _buildRealtimeOrdersView(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildOrderTile('#0012', 'En Préparation', 'Table 1', '95 TND', DashboardColors.accentCoral, Icons.access_time_filled),
        const SizedBox(height: 12),
        _buildOrderTile('#0011', 'Prête', 'Table 4', '40 TND', DashboardColors.statusAvailable, Icons.check_circle_outline),
      ],
    );
  }

  Widget _buildOrderTile(String id, String status, String location, String price, Color color, IconData icon) {
    return Card(
      color: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          'Commande $id',
          style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statut: $status',
              style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 14),
            ),
            Text(location, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
        trailing: Text(
          price,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: DashboardColors.primaryText,
          ),
        ),
        onTap: () {},
      ),
    );
  }

  //  BUILD
  @override
  void initState() {
    super.initState();
    // Charger les tables dynamiquement au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTables();
    });
  }

  // FONCTION POUR CHARGER LES TABLES DEPUIS L'API
  // FONCTION POUR CHARGER LES DONNÉES DES TABLES DEPUIS L'API ET CRÉER UNE MAP COMPLÈTE
  Future<void> _loadTables() async {
    if (!mounted) return; // Vérifier si le widget est encore monté
    setState(() {
      _tablesLoading = true;
      _tablesError = null; // Réinitialiser l'erreur
    });

    try {
      final response = await http.get(
        Uri.parse('http://192.168.56.1:8082/tables'), // URL de votre API Hono pour les tables
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        // Convertir la réponse JSON en Map<numéro, TableInfo>
        final apiTableMap = <int, TableInfo>{};
        for (final json in data) {
          final tableInfo = TableInfo.fromJson(json);
          apiTableMap[tableInfo.number] = tableInfo;
        }

        // Fusionner : Utiliser les données de l'API si disponibles, sinon créer une entrée "Libre"
        final fullTableMap = <int, TableInfo>{};
        for (int i = _minTableNumber; i <= _maxTableNumber; i++) {
          if (apiTableMap.containsKey(i)) {
            // Utiliser les données de l'API
            fullTableMap[i] = apiTableMap[i]!;
          } else {
            // Créer une entrée par défaut "Libre"
            fullTableMap[i] = TableInfo(
              id: 'default_$i', // Valeur par défaut pour l'ID, peut être une chaîne arbitraire ou vide
              number: i,
              status: 'available', // ou 'Libre' selon votre backend/affichage
              orderSummary: 'Aucune commande',
              timeOccupied: null,
            );
          }
        }

        if (mounted) { // Vérifier à nouveau si le widget est encore monté avant setState
          setState(() {
            _tablesMap = fullTableMap; // Mettre à jour la Map d'état
            _tablesLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _tablesError = 'Erreur ${response.statusCode} lors du chargement des tables';
            _tablesLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _tablesError = 'Erreur réseau: $e';
          _tablesLoading = false;
        });
      }
    }
  }

  // FONCTION POUR MARQUER UNE TABLE COMME LIBRE VIA L'API
  Future<void> _markTableAsAvailable(int tableNumber) async { // Prend le numéro de la table
    try {
      final response = await http.put(
        Uri.parse('http://192.168.56.1:8082/tables/$tableNumber'), // URL avec le numéro de table
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'status': 'free'}), // ou 'Libre' selon votre backend
      );

      if (response.statusCode == 200) {
        // Mise à jour locale réussie dans le DashboardScreen
        if (mounted) {
          setState(() {
            // Mettre à jour l'objet TableInfo dans la Map
            if (_tablesMap.containsKey(tableNumber)) {
              _tablesMap[tableNumber] = _tablesMap[tableNumber]!.copyWith(status: 'free'); // <--- Mettre à jour le statut local à 'free'
            }
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: DashboardColors.statusAvailable,
              content: Text('Table $tableNumber libérée avec succès !'),
            ),
          );
        }
      } else {
        final errorBody = jsonDecode(response.body);
        final errorMsg = errorBody['error'] ?? 'Erreur inconnue';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $errorMsg'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur réseau: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ... (le reste de vos fonctions existantes) ...

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: DashboardColors.background,
        appBar: AppBar(
          title: Text(
            'Tawa Order',
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w800,
              fontSize: 20,
              color: DashboardColors.primaryText,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 4,
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: DashboardColors.statusOccupied),
              tooltip: 'Déconnexion',
              onPressed: () async {
                await supabase.auth.signOut();
                if (context.mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                }
              },
            ),
          ],
          bottom: TabBar(
            isScrollable: true,
            indicatorColor: DashboardColors.accentPink,
            labelColor: DashboardColors.primaryText,
            unselectedLabelColor: DashboardColors.primaryText.withOpacity(0.6),
            labelStyle: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
            ),
            tabs: [
              const Tab(icon: Icon(Icons.table_bar), text: 'Tables'),
              const Tab(icon: Icon(Icons.receipt_long), text: 'Commandes'),
              const Tab(icon: Icon(Icons.show_chart), text: 'Statistiques'),
              const Tab(icon: Icon(Icons.menu_book), text: 'Menu'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildTablesLayoutView(context), // Affiche les tables dynamiques
            _buildRealtimeOrdersView(context),
            _buildStatisticsView(context),
            const MenuManagementScreen(),
          ],
        ),
      ),
    );
  }
}