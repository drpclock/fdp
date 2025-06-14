import 'package:cloud_firestore/cloud_firestore.dart';

class RegistroFichaje {
  final String id;
  final String trabajadorId;
  final String tipo;
  final DateTime fecha;
  final String direccionCompleta;
  final Map<String, dynamic>? ubicacion;
  final String empresaId;

  RegistroFichaje({
    required this.id,
    required this.trabajadorId,
    required this.tipo,
    required this.fecha,
    required this.empresaId,
    this.direccionCompleta = '',
    this.ubicacion,
  });

  factory RegistroFichaje.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RegistroFichaje(
      id: doc.id,
      trabajadorId: data['trabajadorId'] ?? '',
      tipo: data['tipo'] ?? '',
      fecha: (data['fecha'] as Timestamp).toDate(),
      empresaId: data['empresaId'] ?? '',
      direccionCompleta: data['direccionCompleta'] ?? '',
      ubicacion: data['ubicacion'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'trabajadorId': trabajadorId,
      'tipo': tipo,
      'fecha': Timestamp.fromDate(fecha),
      'empresaId': empresaId,
      'direccionCompleta': direccionCompleta,
      'ubicacion': ubicacion,
    };
  }

  RegistroFichaje copyWith({
    String? id,
    String? trabajadorId,
    String? tipo,
    DateTime? fecha,
    String? empresaId,
    String? direccionCompleta,
    Map<String, dynamic>? ubicacion,
  }) {
    return RegistroFichaje(
      id: id ?? this.id,
      trabajadorId: trabajadorId ?? this.trabajadorId,
      tipo: tipo ?? this.tipo,
      fecha: fecha ?? this.fecha,
      empresaId: empresaId ?? this.empresaId,
      direccionCompleta: direccionCompleta ?? this.direccionCompleta,
      ubicacion: ubicacion ?? this.ubicacion,
    );
  }
} 