import 'package:flutter/material.dart';

// Classe de base pour un plat
class FoodItem {
  final String id;
  final String name;
  final String imagePath;
  final double price;
  final double rating;
  final String description;
  final String category;

  const FoodItem(
      this.name,
      this.imagePath,
      this.price,
      this.rating,
      this.description, {
        this.id = '',
        this.category = 'Autre',
      });
  // 🔸 Factory constructor pour Supabase (recommandé)
  // Factory pour Supabase
  factory FoodItem.fromJson(Map<String, dynamic> json) {
    return FoodItem(
      json['name'] as String,
      'assets/images/${json['image_path'] ?? 'placeholder.jpg'}',
      (json['price'] as num?)?.toDouble() ?? 0.0,
      4.5,
      json['description'] ?? '',
      id: json['id'].toString(),
      category: json['category'] ?? 'Autre',
    );
  }

  get quantity => null;
}



// Classe pour les catégories de cuisine
class Category {
  final String name;
  final String emoji;
  final MaterialColor color; // CHANGEMENT : De Color à MaterialColor
  final String imagePath; // Ajouté pour une éventuelle utilisation visuelle

  const Category(
      this.name,
      this.emoji,
      this.color,
      this.imagePath,
      );
}

// Classe pour les plats du jour (avec prix original et prix réduit)
class DailySpecial {
  final String name;
  final String imagePath;
  final double originalPrice;
  final double discountedPrice;
  final String description;

  const DailySpecial({
    required this.name,
    required this.imagePath,
    required this.originalPrice,
    required this.discountedPrice,
    required this.description,
  });
}

// Classe pour les plats en promotion (similaire à DailySpecial)
class PromotionalItem {
  final String name;
  final String imagePath;
  final double originalPrice;
  final double discountedPrice;

  const PromotionalItem(
      this.name,
      this.imagePath,
      this.originalPrice,
      this.discountedPrice,
      );
}