// lib/models/order.dart
import 'package:flutter/material.dart';

// --- NOUVEAU MODÈLE : Représente un article dans une commande ---
class OrderItem {
  final String name;
  final double price; // Prix total de l'article (plat + suppléments)
  final int quantity;
  final List<String> supplements; // Liste des suppléments sous forme de chaînes

  OrderItem({
    required this.name,
    required this.price,
    required this.quantity,
    required this.supplements,
  });

  // Constructeur pour créer un OrderItem à partir d'un objet JSON
  factory OrderItem.fromJson(Map<String, dynamic> json) {
    // Gérer le prix de manière sécurisée
    double parsedPrice = 0.0;
    final rawPrice = json['price'];
    if (rawPrice is int) {
      parsedPrice = rawPrice.toDouble();
    } else if (rawPrice is double) {
      parsedPrice = rawPrice;
    } else if (rawPrice is String) {
      parsedPrice = double.tryParse(rawPrice) ?? 0.0;
    }

    // Lire les suppléments, en gérant le cas où le champ est null
    final supplementsJson = json['supplements'] as List<dynamic>?;
    final List<String> parsedSupplements = supplementsJson
        ?.map((s) => s as String)
        .toList() ?? [];

    return OrderItem(
      name: json['food_name'] as String,
      price: parsedPrice,
      quantity: json['quantity'] as int,
      supplements: parsedSupplements,
    );
  }
}

// --- MODÈLE PRINCIPAL : Représente une commande complète ---
class Order {
  final String id;
  final String clientName;
  final int tableNumber;
  final double totalPrice;
  final String notes;
  final String status; // pending, in_progress, done
  final DateTime createdAt;
  final List<OrderItem> items; // <--- CHAMP AJOUTÉ : Liste des articles

  Order({
    required this.id,
    required this.clientName,
    required this.tableNumber,
    required this.totalPrice,
    required this.notes,
    required this.status,
    required this.createdAt,
    required this.items, // <--- CHAMP AJOUTÉ
  });

  // Constructeur pour créer une Order à partir d'un objet JSON
  factory Order.fromJson(Map<String, dynamic> json) {
    // --- Gestion du prix total ---
    double parsedTotalPrice = 0.0;
    final rawTotalPrice = json['total_price'];
    if (rawTotalPrice is int) {
      parsedTotalPrice = rawTotalPrice.toDouble();
    } else if (rawTotalPrice is double) {
      parsedTotalPrice = rawTotalPrice;
    } else if (rawTotalPrice is String) {
      parsedTotalPrice = double.tryParse(rawTotalPrice) ?? 0.0;
    }

    // --- Gestion de la date ---
    DateTime parsedCreatedAt = DateTime.now();
    try {
      parsedCreatedAt = DateTime.parse(json['created_at'] as String);
    } catch (e) {
      // Si la date est invalide, utilise la date actuelle (ou une valeur par défaut)
      print('Erreur lors du parsing de la date: $e');
    }

    // --- Gestion des articles (items) ---
    // Supposons que la route GET /commandes_with_items renvoie les articles dans un champ 'items'
    final itemsJson = json['items'] as List<dynamic>? ?? [];
    final List<OrderItem> parsedItems = itemsJson
        .map((itemJson) => OrderItem.fromJson(itemJson))
        .toList();

    return Order(
      id: json['id'] as String,
      clientName: json['client_name'] as String,
      tableNumber: json['table_number'] as int,
      totalPrice: parsedTotalPrice,
      notes: json['notes'] as String,
      status: json['status'] as String,
      createdAt: parsedCreatedAt,
      items: parsedItems, // <--- CHAMP REMPLI
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