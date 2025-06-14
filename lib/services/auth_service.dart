import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Registrar un nuevo trabajador
  Future<void> registerWorker({
    required String email,
    required String password,
    required String name,
    required String companyId,
    required String trabajadorId,
  }) async {
    try {
      // Crear el documento del usuario en Firestore
      await _firestore.collection('usuarios').add({
        'email': email,
        'password': password,
        'tipo': 'trabajador',
        'isActive': true,
        'empresaId': companyId,
        'trabajadorId': trabajadorId,
        'fechaCreacion': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error al registrar trabajador: $e');
    }
  }

  // Iniciar sesión
  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection('usuarios')
          .where('email', isEqualTo: email)
          .get();

      if (querySnapshot.docs.isEmpty) {
        throw Exception('Email no encontrado');
      }

      final userData = querySnapshot.docs.first.data();
      if (userData['password'] != password) {
        throw Exception('Contraseña incorrecta');
      }

      return userData;
    } catch (e) {
      throw Exception('Error al iniciar sesión: $e');
    }
  }

  // Cerrar sesión
  Future<void> signOut() async {
    // No es necesario implementar nada aquí ya que no usamos Firebase Auth
  }

  // Obtener datos del usuario actual desde Firestore
  Future<Map<String, dynamic>?> getCurrentUserData(String email) async {
    try {
      final querySnapshot = await _firestore
          .collection('usuarios')
          .where('email', isEqualTo: email)
          .get();

      if (querySnapshot.docs.isEmpty) return null;

      return querySnapshot.docs.first.data();
    } catch (e) {
      throw Exception('Error al obtener datos del usuario: $e');
    }
  }

  // Verificar si el usuario es administrador
  Future<bool> isAdmin(String email) async {
    try {
      final userData = await getCurrentUserData(email);
      return userData?['tipo'] == 'admin';
    } catch (e) {
      return false;
    }
  }

  // Verificar si el usuario es trabajador
  Future<bool> isWorker(String email) async {
    try {
      final userData = await getCurrentUserData(email);
      return userData?['tipo'] == 'trabajador';
    } catch (e) {
      return false;
    }
  }

  // Obtener el ID de la empresa del usuario actual
  Future<String?> getCurrentUserCompanyId(String email) async {
    try {
      final userData = await getCurrentUserData(email);
      return userData?['empresaId'];
    } catch (e) {
      return null;
    }
  }
} 