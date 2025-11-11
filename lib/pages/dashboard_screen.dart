import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'menu_management_screen.dart';
import '../models/food_item.dart';



class DashboardColors {
  static const Color primaryText = Color(0xFF4A3F35);       // Brun doux
  static const Color background = Color(0xFFF9F9F9);         // Gris très clair
  static const Color cardBackground = Colors.white;
  static const Color accentPink = Color(0xFFFF6B9D);         // Rose poudré
  static const Color accentCoral = Color(0xFFFF9E80);        // Coral doux
  static const Color statusAvailable = Color(0xFFA8E6CF);    // Menthe pastel
  static const Color statusOccupied = Color(0xFFD6496D);     // Framboise
  static const Color statusReserved = Color(0xFFD4C1EC);     // Lavande douce
  static const Color searchBackground = Color(0xFFF0F0F0);   // Gris très clair pour la barre de recherche
}


//  ENUM & MODEL


enum TableStatus {
  available,
  occupied,
  reserved;
}

class TableData {
  final int id;
  TableStatus status;
  final String orderSummary;
  final DateTime? timeOccupied;

  TableData({
    required this.id,
    required this.status,
    required this.orderSummary,
    this.timeOccupied,
  });
}

//  DASHBOARD SCREEN


class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<TableData> tables = [
    TableData(id: 1, status: TableStatus.occupied, orderSummary: '1x Chawarma, 2x Boisson', timeOccupied: DateTime.now().subtract(const Duration(minutes: 15))),
    TableData(id: 2, status: TableStatus.available, orderSummary: 'Aucune commande'),
    TableData(id: 3, status: TableStatus.reserved, orderSummary: 'Réservée pour John Doe', timeOccupied: DateTime.now().subtract(const Duration(hours: 1))),
    TableData(id: 4, status: TableStatus.occupied, orderSummary: '2x Salades, 1x Café', timeOccupied: DateTime.now().subtract(const Duration(minutes: 5))),
    TableData(id: 5, status: TableStatus.available, orderSummary: 'Aucune commande'),
    TableData(id: 6, status: TableStatus.reserved, orderSummary: 'Réservée pour Famille Smith'),
    TableData(id: 7, status: TableStatus.occupied, orderSummary: '1x Dessert, 1x Thé', timeOccupied: DateTime.now().subtract(const Duration(minutes: 45))),
    TableData(id: 8, status: TableStatus.available, orderSummary: 'Aucune commande'),
    TableData(id: 9, status: TableStatus.available, orderSummary: 'Aucune commande'),
  ];


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

  Map<TableStatus, int> _calculateStatusCounts() {
    final counts = <TableStatus, int>{
      TableStatus.available: 0,
      TableStatus.occupied: 0,
      TableStatus.reserved: 0,
    };
    for (final table in tables) {
      counts[table.status] = (counts[table.status] ?? 0) + 1;
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
    final counts = _calculateStatusCounts();
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0, bottom: 12.0),
      child: Row(
        children: [
          _buildSummaryCard('Libres', counts[TableStatus.available] ?? 0, DashboardColors.statusAvailable),
          const SizedBox(width: 12),
          _buildSummaryCard('Occupées', counts[TableStatus.occupied] ?? 0, DashboardColors.statusOccupied),
          const SizedBox(width: 12),
          _buildSummaryCard('Réservées', counts[TableStatus.reserved] ?? 0, DashboardColors.statusReserved),
        ],
      ),
    );
  }


  //  ORDER DETAILS


  void _showOrderDetails(BuildContext context, TableData table) {
    Color statusColor;
    String statusText;
    switch (table.status) {
      case TableStatus.available:
        statusColor = DashboardColors.statusAvailable;
        statusText = 'Disponible';
        break;
      case TableStatus.occupied:
        statusColor = DashboardColors.statusOccupied;
        statusText = 'Occupée';
        break;
      case TableStatus.reserved:
        statusColor = DashboardColors.statusReserved;
        statusText = 'Réservée';
        break;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          title: Text(
            'Table ${table.id}',
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
              if (table.status == TableStatus.occupied)
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        'Temps : ${_timeElapsed(table.timeOccupied)}',
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
                table.orderSummary,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  color: DashboardColors.primaryText,
                ),
              ),
              if (table.status == TableStatus.occupied) ...[
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        table.status = TableStatus.available;
                      });
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: DashboardColors.statusAvailable,
                          content: Text(
                            'Table ${table.id} libérée avec succès !',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
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


  Widget _buildTablesLayoutView(BuildContext context) {
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
            itemCount: tables.length,
            itemBuilder: (context, index) {
              final table = tables[index];
              Color color;
              IconData icon;
              String statusText;

              switch (table.status) {
                case TableStatus.available:
                  color = DashboardColors.statusAvailable;
                  icon = Icons.circle;
                  statusText = 'Libre';
                  break;
                case TableStatus.occupied:
                  color = DashboardColors.statusOccupied;
                  icon = Icons.circle;
                  statusText = 'Occupée';
                  break;
                case TableStatus.reserved:
                  color = DashboardColors.statusReserved;
                  icon = Icons.circle;
                  statusText = 'Réservée';
                  break;
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
                          'Table ${table.id}',
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
                          statusText,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (table.status == TableStatus.occupied)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              _timeElapsed(table.timeOccupied),
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
            _buildTablesLayoutView(context),
            _buildRealtimeOrdersView(context),
            _buildStatisticsView(context),
            MenuManagementScreen(),
          ],
        ),
      ),
    );
  }
}