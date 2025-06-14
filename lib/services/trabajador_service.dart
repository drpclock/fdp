import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/trabajador.dart';

class TrabajadorService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'empresas';

  // Obtener todos los trabajadores de una empresa
  Future<List<Trabajador>> getTrabajadoresPorEmpresa(String empresaId, String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .doc(empresaId)
          .collection('trabajadores')
          .where('userId', isEqualTo: userId)
          .orderBy('fechaContratacion', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => Trabajador.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error al obtener trabajadores: $e');
      return [];
    }
  }

  // Obtener un trabajador por ID
  Future<Trabajador?> getTrabajadorById(String empresaId, String trabajadorId) async {
    try {
      final doc = await _firestore
          .collection(_collection)
          .doc(empresaId)
          .collection('trabajadores')
          .doc(trabajadorId)
          .get();
      
      if (doc.exists) {
        return Trabajador.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error al obtener trabajador: $e');
      return null;
    }
  }

  // Buscar trabajador por DNI
  Future<Trabajador?> buscarTrabajadorPorDNI(String dni, String userId) async {
    try {
      final snapshot = await _firestore
          .collectionGroup('trabajadores')
          .where('dni', isEqualTo: dni)
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();
      
      if (snapshot.docs.isNotEmpty) {
        return Trabajador.fromFirestore(snapshot.docs.first);
      }
      return null;
    } catch (e) {
      print('Error al buscar trabajador: $e');
      return null;
    }
  }

  // Crear un nuevo trabajador
  Future<String?> crearTrabajador(String empresaId, Trabajador trabajador) async {
    try {
      final docRef = await _firestore
          .collection(_collection)
          .doc(empresaId)
          .collection('trabajadores')
          .add({
            ...trabajador.toMap(),
            'empresaId': empresaId,
            'fechaContratacion': FieldValue.serverTimestamp(),
          });
      return docRef.id;
    } catch (e) {
      print('Error al crear trabajador: $e');
      return null;
    }
  }

  // Actualizar un trabajador
  Future<bool> actualizarTrabajador(String empresaId, String trabajadorId, Trabajador trabajador) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(empresaId)
          .collection('trabajadores')
          .doc(trabajadorId)
          .update(trabajador.toMap());
      return true;
    } catch (e) {
      print('Error al actualizar trabajador: $e');
      return false;
    }
  }

  // Eliminar un trabajador
  Future<bool> eliminarTrabajador(String empresaId, String trabajadorId) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(empresaId)
          .collection('trabajadores')
          .doc(trabajadorId)
          .delete();
      return true;
    } catch (e) {
      print('Error al eliminar trabajador: $e');
      return false;
    }
  }
} 