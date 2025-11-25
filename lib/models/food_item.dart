// lib/models/food_item.dart

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



  // --- CHAMPS AJOUTÉS POUR LA GESTION DES SPÉCIAUX ---
  final bool isDailySpecial; // Champ pour le plat du jour
  final bool isFeaturedPromotion; // Champ pour les promotions
  final double? discountPrice; // Prix réduit optionnel (pour plat du jour)
  final double? originalPrice; // Prix original optionnel (pour promotions)
  final double? discountedPrice; // Prix réduit optionnel (pour promotions)

  // --- CHAMP AJOUTÉ POUR LES SUPPLÉMENTS ---
  final List<String> supplements; // Liste de suppléments sélectionnés/écrits par le client

  const FoodItem({
    required this.name,
    required this.imagePath,
    required this.price,
    required this.rating,
    required this.description,
    this.id = '',
    this.category = 'Autre',
    // --- VALEURS PAR DÉFAUT POUR LES NOUVEAUX CHAMPS ---
    this.isDailySpecial = false,
    this.isFeaturedPromotion = false,
    this.discountPrice,
    this.originalPrice,
    this.discountedPrice,
    this.supplements = const [], // Valeur par défaut : liste vide
  });

  double _extractSupplementPrice(String supplement) {
    final match = RegExp(r'\+([\d,]+(?:\.\d+)?)\s*DT').firstMatch(supplement);
    if (match != null) {
      final priceString = match.group(1)!.replaceAll(',', '');
      return double.tryParse(priceString) ?? 0.0;
    }
    return 0.0;
  }

  double get totalPriceWithSupplements {
    final supplementsTotal = supplements.fold(0.0, (sum, sup) => sum + _extractSupplementPrice(sup));
    return price + supplementsTotal;
  }


  // --- MÉTHODE toJson MISE À JOUR ---
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'price': price,
      'rating': rating,
      'description': description,
      'image_path': imagePath.split('/').last, // Envoie seulement le nom du fichier
      // --- CHAMPS POUR LES SPÉCIAUX ---
      'is_daily_special': isDailySpecial,
      'is_featured_promotion': isFeaturedPromotion,
      'discount_price': discountPrice,
      'original_price': originalPrice,
      'discounted_price': discountedPrice,
      // --- CHAMP POUR LES SUPPLÉMENTS ---
      'supplements': supplements,
    };
  }

  // --- MÉTHODE copyWith MISE À JOUR ---
  FoodItem copyWith({
    String? name,
    String? imagePath,
    double? price,
    double? rating,
    String? description,
    String? id,
    String? category,
    // --- ARGUMENTS POUR LES NOUVEAUX CHAMPS ---
    bool? isDailySpecial,
    bool? isFeaturedPromotion,
    double? discountPrice,
    double? originalPrice,
    double? discountedPrice,
    List<String>? supplements,
  }) {
    return FoodItem(
      name: name ?? this.name,
      imagePath: imagePath ?? this.imagePath,
      price: price ?? this.price,
      rating: rating ?? this.rating,
      description: description ?? this.description,
      id: id ?? this.id,
      category: category ?? this.category,
      // --- MISE À JOUR DES NOUVEAUX CHAMPS ---
      isDailySpecial: isDailySpecial ?? this.isDailySpecial,
      isFeaturedPromotion: isFeaturedPromotion ?? this.isFeaturedPromotion,
      discountPrice: discountPrice ?? this.discountPrice,
      originalPrice: originalPrice ?? this.originalPrice,
      discountedPrice: discountedPrice ?? this.discountedPrice,
      supplements: supplements ?? this.supplements,
    );
  }



  // 🔸 Factory constructor pour Supabase (recommandé)
  factory FoodItem.fromJson(Map<String, dynamic> json) {
    // Ensure we get a double, even if the JSON provides an int.
    final priceValue = json['price'];
    final double price = (priceValue is int) ? priceValue.toDouble() : (priceValue as double? ?? 0.0);

    // --- LECTURE DES SUPPLÉMENTS DU JSON ---
    final List<dynamic>? supplementsJson = json['supplements'] as List<dynamic>?;
    final List<String> supplements = supplementsJson
        ?.map((s) => s as String)
        .toList() ?? [];

    return FoodItem(
      name: json['name'] as String,
      imagePath: 'assets/images/${json['image_path'] ?? 'placeholder.jpg'}',
      price: price,
      rating: (json['rating'] as num?)?.toDouble() ?? 4.5,
      description: json['description'] as String? ?? '',
      id: json['id'].toString(),
      category: json['category'] as String? ?? 'Autre',
      // --- LECTURE DES CHAMPS DE SPÉCIAUX DU JSON ---
      isDailySpecial: json['is_daily_special'] as bool? ?? false,
      isFeaturedPromotion: json['is_featured_promotion'] as bool? ?? false,
      discountPrice: (json['discount_price'] as num?)?.toDouble(),
      originalPrice: (json['original_price'] as num?)?.toDouble(),
      discountedPrice: (json['discounted_price'] as num?)?.toDouble(),
      // --- ASSIGNATION DES SUPPLÉMENTS ---
      supplements: supplements,
    );
  }

  get quantity => null;
}

// Classe pour les catégories de cuisine
class Category {
  final String id; // <--- AJOUTÉ : Champ ID
  final String name;
  final String emoji;
  final MaterialColor color; // CHANGEMENT : De Color à MaterialColor
  final String imagePath; // Ajouté pour une éventuelle utilisation visuelle

  // --- CONSTRUCTEUR MISE À JOUR ---
  const Category({
    required this.id, // <--- AJOUTÉ
    required this.name,
    required this.emoji,
    required this.color,
    required this.imagePath,
  });

  // --- FACTORY CONSTRUCTOR POUR SUPABASE ---
  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      name: json['name'] as String,
      emoji: json['emoji'] as String? ?? _getEmojiForCategory(json['name'] as String),
      color: _getColorForCategory(json['name'] as String),
      imagePath: 'assets/images/${json['image_path'] as String? ?? 'placeholder.jpg'}',
    );
  }

  // --- FONCTIONS D'AIDE POUR LES CATÉGORIES ---
  static String _getEmojiForCategory(String name) {
    switch (name.toLowerCase()) {
      case 'tunisienne':
        return '🇹🇳';
      case 'américaine':
        return '🇺🇸';
      case 'italienne':
        return '🇮🇹';
      case 'desserts':
        return '🍰';
      case 'boissons':
        return '🥤';
      case 'plats principaux':
        return '🍽️';
      default:
        return '🍽️';
    }
  }

  static MaterialColor _getColorForCategory(String name) {
    switch (name.toLowerCase()) {
      case 'tunisienne':
        return Colors.red;
      case 'américaine':
        return Colors.blue;
      case 'italienne':
        return Colors.green;
      case 'desserts':
        return Colors.orange;
      case 'boissons':
        return Colors.cyan;
      case 'plats principaux':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}

// Classe pour les plats du jour (peut être redondant, mais utile pour la clarté)
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

  factory DailySpecial.fromJson(Map<String, dynamic> json) {
    return DailySpecial(
      name: json['name'] as String,
      imagePath: 'assets/images/${json['image_path'] as String? ?? 'placeholder.jpg'}',
      originalPrice: (json['original_price'] as num?)?.toDouble() ?? (json['price'] as num?)?.toDouble() ?? 0.0,
      discountedPrice: (json['discounted_price'] as num?)?.toDouble() ?? (json['discount_price'] as num?)?.toDouble() ?? 0.0,
      description: json['description'] as String? ?? '',
    );
  }
}

// Classe pour les plats en promotion (peut être redondant, mais utile pour la clarté)
class PromotionalItem {
  final String name;
  final String imagePath;
  final double originalPrice;
  final double discountedPrice;

  const PromotionalItem({
    required this.name,
    required this.imagePath,
    required this.originalPrice,
    required this.discountedPrice,
  });

  factory PromotionalItem.fromJson(Map<String, dynamic> json) {
    return PromotionalItem(
      name: json['name'] as String,
      imagePath: 'assets/images/${json['image_path'] as String? ?? 'placeholder.jpg'}',
      originalPrice: (json['original_price'] as num?)?.toDouble() ?? (json['price'] as num?)?.toDouble() ?? 0.0,
      discountedPrice: (json['discounted_price'] as num?)?.toDouble() ?? (json['discount_price'] as num?)?.toDouble() ?? 0.0,
    );
  }
}