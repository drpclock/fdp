import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/empresa.dart';
import '../services/logger_service.dart';
import '../services/auth_service.dart';
import 'empresas_page.dart';
import 'fichaje_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  bool _mostrarPassword = false;

  Future<void> _iniciarSesion() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Por favor, complete todos los campos';
        _successMessage = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      // Iniciar sesión con Firebase Auth
      final userCredential = await _authService.signIn(
        email: _emailController.text,
        password: _passwordController.text,
      );

      // Obtener datos del usuario desde Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(userCredential.user!.uid)
          .get();

      if (!userDoc.exists) {
        throw Exception('Usuario no encontrado en la base de datos');
      }

      final userData = userDoc.data()!;

      if (!userData['isActive']) {
        throw Exception('Usuario inactivo');
      }

      if (!mounted) return;

      // Redirigir según el tipo de usuario
      if (userData['tipo'] == 'admin') {
        // Obtener la empresa del administrador
        final empresaDoc = await FirebaseFirestore.instance
            .collection('empresas')
            .doc(userData['empresaId'])
            .get();

        if (!empresaDoc.exists) {
          throw Exception('Empresa no encontrada');
        }

        final empresa = Empresa.fromFirestore(empresaDoc);

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => EmpresasPage(
              empresas: [empresa],
              onEmpresaAgregada: (empresa) {},
              onEmpresaEliminada: (empresa) {},
            ),
          ),
        );
      } else if (userData['tipo'] == 'trabajador') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => FichajePage(
              trabajadorId: userData['trabajadorId'],
              email: userData['email'],
            ),
          ),
        );
      } else {
        throw Exception('Tipo de usuario no válido');
      }

      setState(() {
        _successMessage = 'Inicio de sesión exitoso';
        _emailController.clear();
        _passwordController.clear();
      });
    } catch (e) {
      LoggerService().error('Error al iniciar sesión', e);
      setState(() {
        _errorMessage = 'Error al iniciar sesión: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Iniciar Sesión'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.business,
              size: 100,
              color: Colors.blue,
            ),
            const SizedBox(height: 24),
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red.shade900),
                ),
              ),
            if (_successMessage != null)
              Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _successMessage!,
                  style: TextStyle(color: Colors.green.shade900),
                ),
              ),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
              enabled: !_isLoading,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Contraseña',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                    _mostrarPassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _mostrarPassword = !_mostrarPassword;
                    });
                  },
                ),
              ),
              obscureText: !_mostrarPassword,
              enabled: !_isLoading,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _iniciarSesion,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.login),
                label: Text(_isLoading ? 'Iniciando sesión...' : 'Iniciar Sesión'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
} 