import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/empresa.dart';
import '../models/trabajador.dart';
import '../models/fichaje.dart';
import 'logger_service.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _logger = LoggerService();

  // Empresas
  Future<List<Empresa>> getEmpresas() async {
    try {
      final snapshot = await _firestore.collection('empresas').get();
      return snapshot.docs.map((doc) => Empresa.fromFirestore(doc)).toList();
    } catch (e) {
      _logger.error('Error al obtener empresas', e);
      return [];
    }
  }

  // Trabajadores por empresa
  Future<List<Trabajador>> getTrabajadoresPorEmpresa(String empresaId) async {
    try {
      final snapshot = await _firestore
          .collection('empresas')
          .doc(empresaId)
          .collection('trabajadores')
          .orderBy('fechaContratacion', descending: true)
          .get();
      return snapshot.docs.map((doc) => Trabajador.fromFirestore(doc)).toList();
    } catch (e) {
      _logger.error('Error al obtener trabajadores', e);
      return [];
    }
  }

  // Fichajes por trabajador y fecha
  Future<List<Fichaje>> getFichajesPorTrabajador(
    String empresaId,
    String trabajadorId, {
    DateTime? fechaInicio,
    DateTime? fechaFin,
  }) async {
    try {
      Query query = _firestore
          .collection('empresas')
          .doc(empresaId)
          .collection('trabajadores')
          .doc(trabajadorId)
          .collection('fichajes')
          .orderBy('fechaHora', descending: true);

      if (fechaInicio != null) {
        query = query.where('fechaHora',
            isGreaterThanOrEqualTo: Timestamp.fromDate(fechaInicio));
      }
      if (fechaFin != null) {
        query = query.where('fechaHora',
            isLessThanOrEqualTo: Timestamp.fromDate(fechaFin));
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => Fichaje.fromFirestore(doc)).toList();
    } catch (e) {
      _logger.error('Error al obtener fichajes', e);
      return [];
    }
  }

  // Crear nuevo fichaje
  Future<void> crearFichaje(Fichaje fichaje) async {
    try {
      await _firestore
          .collection('empresas')
          .doc(fichaje.empresaId)
          .collection('trabajadores')
          .doc(fichaje.trabajadorId)
          .collection('fichajes')
          .doc(fichaje.id)
          .set(fichaje.toMap());
    } catch (e) {
      _logger.error('Error al crear fichaje', e);
      rethrow;
    }
  }

  // Obtener último fichaje de un trabajador
  Future<Fichaje?> getUltimoFichaje(String empresaId, String trabajadorId) async {
    try {
      final snapshot = await _firestore
          .collection('empresas')
          .doc(empresaId)
          .collection('trabajadores')
          .doc(trabajadorId)
          .collection('fichajes')
          .orderBy('fechaHora', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;
      return Fichaje.fromFirestore(snapshot.docs.first);
    } catch (e) {
      _logger.error('Error al obtener último fichaje', e);
      return null;
    }
  }
} 