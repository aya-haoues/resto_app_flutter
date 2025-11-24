// lib/models/order.dart
import 'package:flutter/material.dart';

class Order {
  final String id;
  final String clientName;
  final int tableNumber;
  final double totalPrice;
  final String notes;
  final String status; // pending, in_progress, done
  final DateTime createdAt;

  Order({
    required this.id,
    required this.clientName,
    required this.tableNumber,
    required this.totalPrice,
    required this.notes,
    required this.status,
    required this.createdAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    // Extraire la valeur brute du prix
    dynamic rawPrice = json['total_price'];

    // Convertir en double en gérant les types possibles
    double parsedPrice = 0.0;

    if (rawPrice is int) {
      parsedPrice = rawPrice.toDouble();
    } else if (rawPrice is double) {
      parsedPrice = rawPrice;
    } else if (rawPrice is String) {
      parsedPrice = double.tryParse(rawPrice) ?? 0.0;
    }

    return Order(
      id: json['id'] as String,
      clientName: json['client_name'] as String,
      tableNumber: json['table_number'] as int,
      totalPrice: parsedPrice, // ✅ Utiliser la variable parsee
      notes: json['notes'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
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