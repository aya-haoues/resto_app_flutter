import 'package:flutter/material.dart';
import '../models/food_item.dart';

class PanierItem {
  final FoodItem foodItem; // 🔑 Contient le nom, le prix et les détails du plat
  int quantity;            // 🔑 Contient la quantité commandée

  // Constructeur
  PanierItem({
    required this.foodItem,
    this.quantity = 1, // La quantité par défaut est 1
  });

  // Méthode pour incrémenter la quantité
  void incrementQuantity() {
    quantity++;
  }

  // Méthode pour décrémenter la quantité
  void decrementQuantity() {
    if (quantity > 1) {
      quantity--;
    }
  }

  // Obtenir le prix total pour cet article (Prix unitaire * Quantité)
  double get totalPrice => foodItem.price * quantity;
}