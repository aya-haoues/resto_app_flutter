// lib/models/commande.dart
import 'package:flutter/material.dart';

class Commande {
  final String id;
  final String orderId;
  final String clientName;
  final int tableNumber;
  final double totalPrice;
  final String notes;
  final String status;
  final DateTime createdAt;
  final List<Map<String, dynamic>> items;// 👈 Ajoutez ce champ

  Commande({
    required this.id,
    required this.orderId,
    required this.clientName,
    required this.tableNumber,
    required this.totalPrice,
    required this.notes,
    required this.status,
    required this.createdAt,
    required this.items, // 👈 Ajoutez ce champ
  });

  factory Commande.fromJson(Map<String, dynamic> json) {
    return Commande(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      clientName: json['client_name'] as String,
      tableNumber: json['table_number'] as int,
      totalPrice: (json['total_price'] as num).toDouble(),
      notes: json['notes'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      // ✅ ICI : Utiliser 'items' si disponible, sinon une liste vide
      items: (json['items'] as List?)?.map((e) => e as Map<String, dynamic>).toList() ?? [],
    );
  }
  // Helper to get status color
  Color getStatusColor() {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange.shade300;
      case 'in_progress':
        return Colors.blue.shade300;
      case 'done':
        return Colors.green.shade300;
      default:
        return Colors.grey.shade300;
    }
  }

  // Helper to get status icon
  IconData getStatusIcon() {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.hourglass_bottom;
      case 'in_progress':
        return Icons.access_time;
      case 'done':
        return Icons.check_circle;
      default:
        return Icons.help_outline;
    }
  }

  // Helper to get status text
  String getStatusText() {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'En Attente';
      case 'in_progress':
        return 'En Cours';
      case 'done':
        return 'Terminée';
      default:
        return 'Inconnu';
    }
  }
}