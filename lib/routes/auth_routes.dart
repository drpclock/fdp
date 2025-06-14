import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/logger_service.dart';

class AuthRoutes {
  static const String callback = '/auth/callback';
  static const String setup = '/setup';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case callback:
        return MaterialPageRoute(
          builder: (_) => const AuthCallbackPage(),
        );
      case setup:
        return MaterialPageRoute(
          builder: (_) => const SetupPage(),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}

class AuthCallbackPage extends StatefulWidget {
  const AuthCallbackPage({Key? key}) : super(key: key);

  @override
  State<AuthCallbackPage> createState() => _AuthCallbackPageState();
}

class _AuthCallbackPageState extends State<AuthCallbackPage> {
  @override
  void initState() {
    super.initState();
    _handleCallback();
  }

  Future<void> _handleCallback() async {
    try {
      // Aquí manejaremos la lógica de callback de GitHub OAuth
      LoggerService().info('Procesando callback de GitHub OAuth');
      
      // Redirigir al usuario a la página principal después del procesamiento
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/');
      }
    } catch (e) {
      LoggerService().error('Error en el callback de GitHub OAuth', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error en la autenticación: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class SetupPage extends StatefulWidget {
  const SetupPage({Key? key}) : super(key: key);

  @override
  State<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends State<SetupPage> {
  @override
  void initState() {
    super.initState();
    _handleSetup();
  }

  Future<void> _handleSetup() async {
    try {
      // Aquí manejaremos la lógica de configuración post-instalación
      LoggerService().info('Procesando configuración post-instalación');
      
      // Redirigir al usuario a la página principal después del procesamiento
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/');
      }
    } catch (e) {
      LoggerService().error('Error en la configuración post-instalación', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error en la configuración: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
} 