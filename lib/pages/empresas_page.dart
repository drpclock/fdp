import 'package:flutter/material.dart';
import '../models/empresa.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EmpresasPage extends StatefulWidget {
  final List<Empresa> empresas;
  final Function(Empresa) onEmpresaAgregada;
  final Function(Empresa) onEmpresaEliminada;

  const EmpresasPage({
    super.key,
    required this.empresas,
    required this.onEmpresaAgregada,
    required this.onEmpresaEliminada,
  });

  @override
  State<EmpresasPage> createState() => _EmpresasPageState();
}

class _EmpresasPageState extends State<EmpresasPage> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _direccionController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _mostrarPassword = false;

  Future<void> _guardarEmpresa() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Verificar si ya existe una empresa con el mismo email
        final querySnapshot = await FirebaseFirestore.instance
            .collection('empresas')
            .where('email', isEqualTo: _emailController.text.trim())
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ya existe una empresa con este email'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        // Crear el documento de la empresa en la colección empresas
        final empresaRef = FirebaseFirestore.instance.collection('empresas').doc();
        
        // Crear la empresa con todos sus datos
        final empresaData = {
          'nombre': _nombreController.text.trim(),
          'direccion': _direccionController.text.trim(),
          'telefono': _telefonoController.text.trim(),
          'email': _emailController.text.trim(),
          'fechaCreacion': FieldValue.serverTimestamp(),
        };

        // Crear la subcolección trabajadores con un documento inicial
        final trabajadorData = {
          'nombre': 'Admin',
          'apellidos': 'Sistema',
          'dni': '00000000',
          'telefono': _telefonoController.text.trim(),
          'email': _emailController.text.trim(),
          'empresaId': empresaRef.id,
          'fechaContratacion': FieldValue.serverTimestamp(),
        };

        // Usar una transacción para asegurar que todo se cree correctamente
        await FirebaseFirestore.instance.runTransaction((transaction) async {
          // Crear la empresa
          transaction.set(empresaRef, empresaData);
          
          // Crear la subcolección trabajadores
          final trabajadorRef = empresaRef.collection('trabajadores').doc();
          transaction.set(trabajadorRef, trabajadorData);
          
          // Crear el usuario admin
          final usuarioRef = FirebaseFirestore.instance.collection('usuarios').doc();
          transaction.set(usuarioRef, {
            'nombre': _nombreController.text.trim(),
            'direccion': _direccionController.text.trim(),
            'telefono': _telefonoController.text.trim(),
            'email': _emailController.text.trim(),
            'tipo': 'admin',
            'isActive': true,
            'password': _passwordController.text,
            'empresaId': empresaRef.id,
            'fechaCreacion': FieldValue.serverTimestamp(),
          });
        });

        // Crear una nueva empresa para la lista local
        final nuevaEmpresa = Empresa(
          id: empresaRef.id,
          nombre: _nombreController.text.trim(),
          direccion: _direccionController.text.trim(),
          telefono: _telefonoController.text.trim(),
          email: _emailController.text.trim(),
          userId: empresaRef.id,
          fechaCreacion: null,
        );

        // Actualizar la lista local
        widget.onEmpresaAgregada(nuevaEmpresa);

        // Limpiar los campos
        _nombreController.clear();
        _direccionController.clear();
        _telefonoController.clear();
        _emailController.clear();
        _passwordController.clear();

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Empresa creada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al crear la empresa: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva Empresa'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.business,
                size: 100,
                color: Colors.blue,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre de la Empresa',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.business),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese el nombre de la empresa';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _direccionController,
                decoration: const InputDecoration(
                  labelText: 'Dirección',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese la dirección';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _telefonoController,
                decoration: const InputDecoration(
                  labelText: 'Teléfono',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese el teléfono';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese el email';
                  }
                  if (!value.contains('@')) {
                    return 'Por favor ingrese un email válido';
                  }
                  return null;
                },
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
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese la contraseña';
                  }
                  if (value.length < 6) {
                    return 'La contraseña debe tener al menos 6 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _guardarEmpresa,
                icon: const Icon(Icons.save),
                label: const Text('Guardar Empresa'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _direccionController.dispose();
    _telefonoController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
} 