import 'package:flutter/material.dart';

class FoodItem {
  final String name;
  final String imagePath;
  final double price;
  final double rating;
  final String description;

  const FoodItem(this.name, this.imagePath, this.price, this.rating, this.description);
}

class Category {
  final String name;
  final String emoji;
  final Color color;

  const Category(this.name, this.emoji, this.color);
}
