// lib/models/supplement.dart

class Supplement {
  final int id;
  final String name;
  final double price;

  const Supplement({
    required this.id,
    required this.name,
    required this.price,
  });

  factory Supplement.fromJson(Map<String, dynamic> json) {
    return Supplement(
      id: json['id'] as int,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'price': price,
    };
  }
}