import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/empresa.dart';

class EmpresaService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'empresas';

  // Obtener todas las empresas de un usuario
  Future<List<Empresa>> getEmpresasPorUsuario(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .orderBy('nombre')
          .get();
      
      return snapshot.docs
          .map((doc) => Empresa.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error al obtener empresas: $e');
      return [];
    }
  }

  // Obtener una empresa por ID
  Future<Empresa?> getEmpresaById(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (doc.exists) {
        return Empresa.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error al obtener empresa: $e');
      return null;
    }
  }

  // Crear una nueva empresa
  Future<String?> crearEmpresa(Empresa empresa) async {
    try {
      final docRef = await _firestore.collection(_collection).add(empresa.toMap());
      return docRef.id;
    } catch (e) {
      print('Error al crear empresa: $e');
      return null;
    }
  }

  // Actualizar una empresa
  Future<bool> actualizarEmpresa(String id, Empresa empresa) async {
    try {
      await _firestore.collection(_collection).doc(id).update(empresa.toMap());
      return true;
    } catch (e) {
      print('Error al actualizar empresa: $e');
      return false;
    }
  }

  // Eliminar una empresa
  Future<bool> eliminarEmpresa(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
      return true;
    } catch (e) {
      print('Error al eliminar empresa: $e');
      return false;
    }
  }

  // Buscar empresa por nombre
  Future<List<Empresa>> buscarEmpresaPorNombre(String nombre) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('nombre', isGreaterThanOrEqualTo: nombre)
          .where('nombre', isLessThanOrEqualTo: nombre + '\uf8ff')
          .orderBy('nombre')
          .get();

      return snapshot.docs.map((doc) => Empresa.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error al buscar empresa: $e');
      return [];
    }
  }
} 