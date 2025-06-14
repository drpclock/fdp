import 'package:cloud_firestore/cloud_firestore.dart';

class Trabajador {
  final String id;
  final String nombre;
  final String apellidos;
  final String dni;
  final String telefono;
  final String email;
  final String password;
  final String empresaId;
  final DateTime fechaContratacion;
  final String? centroTrabajo;
  final String? responsable;
  final String? contrato;
  final String? columna1;
  final String? columna2;
  final String? columna3;

  Trabajador({
    required this.id,
    required this.nombre,
    required this.apellidos,
    required this.dni,
    required this.telefono,
    required this.email,
    required this.password,
    required this.empresaId,
    required this.fechaContratacion,
    this.centroTrabajo,
    this.responsable,
    this.contrato,
    this.columna1,
    this.columna2,
    this.columna3,
  });

  factory Trabajador.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Trabajador(
      id: doc.id,
      nombre: data['nombre'] ?? '',
      apellidos: data['apellidos'] ?? '',
      dni: data['dni'] ?? '',
      telefono: data['telefono'] ?? '',
      email: data['email'] ?? '',
      password: data['password'] ?? '',
      empresaId: data['empresaId'] ?? '',
      fechaContratacion: (data['fechaContratacion'] as Timestamp).toDate(),
      centroTrabajo: data['centroTrabajo'],
      responsable: data['responsable'],
      contrato: data['contrato'],
      columna1: data['columna1'],
      columna2: data['columna2'],
      columna3: data['columna3'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'apellidos': apellidos,
      'dni': dni,
      'telefono': telefono,
      'email': email,
      'password': password,
      'empresaId': empresaId,
      'fechaContratacion': Timestamp.fromDate(fechaContratacion),
      'centroTrabajo': centroTrabajo,
      'responsable': responsable,
      'contrato': contrato,
      'columna1': columna1,
      'columna2': columna2,
      'columna3': columna3,
    };
  }

  factory Trabajador.fromMap(Map<String, dynamic> map) {
    return Trabajador(
      id: map['id'] ?? '',
      nombre: map['nombre'] ?? '',
      apellidos: map['apellidos'] ?? '',
      dni: map['dni'] ?? '',
      telefono: map['telefono'] ?? '',
      email: map['email'] ?? '',
      password: map['password'] ?? '',
      empresaId: map['empresaId'] ?? '',
      fechaContratacion: (map['fechaContratacion'] as Timestamp).toDate(),
      centroTrabajo: map['centroTrabajo'],
      responsable: map['responsable'],
      contrato: map['contrato'],
      columna1: map['columna1'],
      columna2: map['columna2'],
      columna3: map['columna3'],
    );
  }
} 