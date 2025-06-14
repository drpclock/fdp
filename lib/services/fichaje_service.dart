import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/fichaje.dart';

class FichajeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'empresas';

  // Obtener todos los fichajes de un trabajador
  Future<List<Fichaje>> getFichajesPorTrabajador(
    String empresaId,
    String trabajadorId,
    String userId, {
    DateTime? fechaInicio,
    DateTime? fechaFin,
  }) async {
    try {
      Query query = _firestore
          .collection(_collection)
          .doc(empresaId)
          .collection('trabajadores')
          .doc(trabajadorId)
          .collection('fichajes')
          .where('userId', isEqualTo: userId)
          .orderBy('fechaHora', descending: true);

      if (fechaInicio != null) {
        query = query.where('fechaHora', isGreaterThanOrEqualTo: Timestamp.fromDate(fechaInicio));
      }
      if (fechaFin != null) {
        query = query.where('fechaHora', isLessThanOrEqualTo: Timestamp.fromDate(fechaFin));
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => Fichaje.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error al obtener fichajes: $e');
      return [];
    }
  }

  // Obtener el último fichaje de un trabajador
  Future<Fichaje?> getUltimoFichaje(String empresaId, String trabajadorId, String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .doc(empresaId)
          .collection('trabajadores')
          .doc(trabajadorId)
          .collection('fichajes')
          .where('userId', isEqualTo: userId)
          .orderBy('fechaHora', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return Fichaje.fromFirestore(snapshot.docs.first);
      }
      return null;
    } catch (e) {
      print('Error al obtener último fichaje: $e');
      return null;
    }
  }

  // Crear un nuevo fichaje
  Future<String?> crearFichaje(String empresaId, String trabajadorId, Fichaje fichaje) async {
    try {
      final docRef = await _firestore
          .collection(_collection)
          .doc(empresaId)
          .collection('trabajadores')
          .doc(trabajadorId)
          .collection('fichajes')
          .add(fichaje.toMap());
      return docRef.id;
    } catch (e) {
      print('Error al crear fichaje: $e');
      return null;
    }
  }

  // Eliminar un fichaje
  Future<bool> eliminarFichaje(String empresaId, String trabajadorId, String fichajeId) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(empresaId)
          .collection('trabajadores')
          .doc(trabajadorId)
          .collection('fichajes')
          .doc(fichajeId)
          .delete();
      return true;
    } catch (e) {
      print('Error al eliminar fichaje: $e');
      return false;
    }
  }
} 