import 'package:cloud_firestore/cloud_firestore.dart';

class Fichaje {
  final String id;
  final String trabajadorId;
  final String empresaId;
  final DateTime fechaHora;
  final String tipo; // 'entrada' o 'salida'

  Fichaje({
    required this.id,
    required this.trabajadorId,
    required this.empresaId,
    required this.fechaHora,
    required this.tipo,
  });

  factory Fichaje.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Fichaje(
      id: doc.id,
      trabajadorId: data['trabajadorId'] ?? '',
      empresaId: data['empresaId'] ?? '',
      fechaHora: (data['fechaHora'] as Timestamp).toDate(),
      tipo: data['tipo'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'trabajadorId': trabajadorId,
      'empresaId': empresaId,
      'fechaHora': Timestamp.fromDate(fechaHora),
      'tipo': tipo,
    };
  }
} 