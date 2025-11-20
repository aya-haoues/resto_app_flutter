// lib/models/table.dart
import 'package:flutter/material.dart';

class TableInfo {
  final String id;
  final int number;
  final String? notes;
  String status; // Mutable for local updates
  final String? orderSummary;
  final String? timeOccupied;

  TableInfo({
    required this.id,
    required this.number,
    required this.status,
    this.orderSummary,
    this.timeOccupied,
    this.notes,
  });

  factory TableInfo.fromJson(Map<String, dynamic> json) {
    return TableInfo(
      id: json['id'] as String,
      number: json['number'] as int,
      status: json['status'] as String,
      notes: json['notes'] as String?,
      orderSummary: json['order_summary'] as String?,
      timeOccupied: json['time_occupied'] as String?,
    );
  }

  TableInfo copyWith({
    String? status,
    String? orderSummary,
    String? timeOccupied,
  }) {
    return TableInfo(
      id: this.id,
      number: this.number,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      orderSummary: orderSummary ?? this.orderSummary,
      timeOccupied: timeOccupied ?? this.timeOccupied,
    );
  }

  // Helper to get icon based on status
  IconData getStatusIcon() {
    switch (status.toLowerCase()) {
      case 'available':
      case 'libre':
        return Icons.circle_outlined;
      case 'occupied':
      case 'occupée':
        return Icons.circle;
      default:
        return Icons.help_outline;
    }
  }
}