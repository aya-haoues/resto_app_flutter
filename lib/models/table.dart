// lib/models/table.dart

// Renommez la classe
class TableInfo { // <--- CHANGÉ : Renommé de 'Table' à 'TableInfo'
  final String id;
  final int number;
  final String? notes;
  String status; // Mutable pour permettre la mise à jour locale via copyWith
  final String? orderSummary;
  final String? timeOccupied;

  // Constructeur STANDARD (non 'const') car 'status' est mutable
  TableInfo({ // <--- CHANGÉ : Retirer 'const' ici
    required this.id,
    required this.number,
    required this.status, // <--- Mutable, donc constructeur standard
    this.orderSummary,
    this.timeOccupied,
    this.notes,
  });

  factory TableInfo.fromJson(Map<String, dynamic> json) {
    return TableInfo( // <--- Appel au constructeur standard
      id: json['id'] as String, // ou 'json['id'] as int' si c'est un entier dans votre base
      number: json['number'] as int,
      status: json['status'] as String,
      notes: json['notes'] as String?,
      orderSummary: json['order_summary'] as String?, // ou une valeur par défaut si null
      timeOccupied: json['time_occupied'] as String?, // ou DateTime.parse(...) si vous voulez le convertir
    );
  }

  // Méthode copyWith - NÉCESSAIRE pour la mise à jour locale
  TableInfo copyWith({String? status, String? orderSummary, String? timeOccupied}) {
    return TableInfo( // <--- Retourne une nouvelle instance avec les champs mis à jour
      id: this.id,
      number: this.number,
      status: status ?? this.status, // Utilise le nouveau statut si fourni, sinon garde l'ancien
      notes: notes ?? this.notes,
      orderSummary: orderSummary ?? this.orderSummary,
      timeOccupied: timeOccupied ?? this.timeOccupied,
    );
  }
}