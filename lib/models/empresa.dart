import 'package:cloud_firestore/cloud_firestore.dart';

class Empresa {
  final String id;
  final String nombre;
  final String direccion;
  final String telefono;
  final String email;
  final String userId;
  final Timestamp? fechaCreacion;

  Empresa({
    required this.id,
    required this.nombre,
    required this.direccion,
    required this.telefono,
    required this.email,
    required this.userId,
    this.fechaCreacion,
  });

  factory Empresa.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Empresa(
      id: doc.id,
      nombre: data['nombre'] ?? '',
      direccion: data['direccion'] ?? '',
      telefono: data['telefono'] ?? '',
      email: data['email'] ?? '',
      userId: data['userId'] ?? '',
      fechaCreacion: data['fechaCreacion'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'direccion': direccion,
      'telefono': telefono,
      'email': email,
      'userId': userId,
      'fechaCreacion': fechaCreacion ?? FieldValue.serverTimestamp(),
    };
  }
} 