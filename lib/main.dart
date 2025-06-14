import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'pages/empresas_page.dart';
import 'pages/trabajadores_page.dart';
import 'pages/fichaje_page.dart';
import 'pages/registros_fichaje_page.dart';
import 'pages/register_worker_page.dart';
import 'models/empresa.dart';
import 'models/trabajador.dart';
import 'services/logger_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    LoggerService().info('Iniciando Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    LoggerService().info('Firebase inicializado correctamente');
    
    // Verificar conexión con Firestore
    try {
      await FirebaseFirestore.instance.collection('empresas').get();
      LoggerService().info('Conexión con Firestore establecida correctamente');
    } catch (e) {
      LoggerService().error('Error al conectar con Firestore', e);
    }
  } catch (e) {
    LoggerService().error('Error al inicializar Firebase', e);
    if (e.toString().contains('duplicate-app')) {
      LoggerService().info('Firebase ya está inicializado');
    } else {
      rethrow;
    }
  }
  
  runApp(
    MultiProvider(
      providers: [
        Provider.value(value: FirebaseFirestore.instance),
        StreamProvider<User?>.value(
          value: FirebaseAuth.instance.authStateChanges(),
          initialData: null,
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dpclock',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        textTheme: const TextTheme(
          titleLarge: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 28,
            fontWeight: FontWeight.w300,
            letterSpacing: 1.2,
          ),
        ),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final CollectionReference _empresasCollection = FirebaseFirestore.instance.collection('empresas');
  final List<Empresa> _empresas = [];
  final List<Trabajador> _trabajadores = [];
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargarEmpresas();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Dpclock',
          style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 24,
            fontWeight: FontWeight.w300,
            letterSpacing: 1.2,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildMenuCard(
              icon: Icons.business,
              title: 'Empresas',
              color: Colors.blue,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EmpresasPage(
                      empresas: _empresas,
                      onEmpresaAgregada: _agregarEmpresa,
                      onEmpresaEliminada: _eliminarEmpresa,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildMenuCard(
              icon: Icons.people,
              title: 'Trabajadores',
              color: Colors.green,
              onTap: () async {
                if (_empresas.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Primero debe registrar una empresa'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                
                try {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RegisterWorkerPage(
                        companyId: _empresas.first.id,
                        trabajadorId: '',
                      ),
                    ),
                  );
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error al abrir el formulario: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
            ),
            const SizedBox(height: 16),
            _buildMenuCard(
              icon: Icons.login,
              title: 'Acceso',
              color: Colors.orange,
              onTap: _mostrarDialogoAcceso,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _cargarEmpresas() async {
    try {
      LoggerService().info('Cargando empresas de Firestore');
      final snapshot = await _empresasCollection
          .orderBy('nombre', descending: false)
          .orderBy('fechaCreacion', descending: true)
          .orderBy('__name__', descending: true)
          .get();
      
      LoggerService().info('Documentos encontrados: ${snapshot.docs.length}');
      
      if (!mounted) return;
      
      setState(() {
        _empresas.clear();
        _empresas.addAll(
          snapshot.docs.map((doc) {
            LoggerService().info('Procesando documento: ${doc.id}');
            return Empresa.fromFirestore(doc);
          }).toList(),
        );
      });
    } catch (e) {
      LoggerService().error('Error al cargar empresas', e);
      rethrow;
    }
  }

  Future<void> _agregarEmpresa(Empresa empresa) async {
    try {
      LoggerService().info('Iniciando proceso de guardado de empresa...');
      
      // Verificar si ya existe una empresa con el mismo email
      final querySnapshot = await _empresasCollection
          .where('email', isEqualTo: empresa.email)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        LoggerService().info('Ya existe una empresa con este email');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ya existe una empresa con este email'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      // Crear nueva empresa en Firestore
      final docRef = _empresasCollection.doc();
      LoggerService().info('ID de documento generado: ${docRef.id}');
      
      final nuevaEmpresa = Empresa(
        id: docRef.id,
        nombre: empresa.nombre,
        direccion: empresa.direccion,
        telefono: empresa.telefono,
        email: empresa.email,
        userId: 'default',
        fechaCreacion: Timestamp.now(),
      );

      LoggerService().info('Datos de la empresa a guardar: ${nuevaEmpresa.toMap()}');
      
      try {
        LoggerService().info('Intentando guardar en Firestore...');
        await docRef.set(nuevaEmpresa.toMap());
        LoggerService().info('Empresa guardada exitosamente en Firestore');
        
        if (!mounted) return;
        
        setState(() {
          _empresas.add(nuevaEmpresa);
        });
        LoggerService().info('Estado actualizado con la nueva empresa');
      } catch (firestoreError) {
        LoggerService().error('Error específico de Firestore', firestoreError);
        rethrow;
      }
    } catch (e) {
      LoggerService().error('Error al agregar empresa', e);
      rethrow;
    }
  }

  Future<void> _eliminarEmpresa(Empresa empresa) async {
    try {
      LoggerService().info('Eliminando empresa: ${empresa.id}');
      await _empresasCollection.doc(empresa.id).delete();
      LoggerService().info('Empresa eliminada exitosamente');
      
      if (!mounted) return;
      
      setState(() {
        _empresas.removeWhere((e) => e.id == empresa.id);
      });
    } catch (e) {
      LoggerService().error('Error al eliminar empresa', e);
      rethrow;
    }
  }

  Future<void> _agregarTrabajador(Trabajador trabajador) async {
    try {
      LoggerService().info('Iniciando proceso de guardado de trabajador...');
      
      // Verificar que la empresa existe
      final empresaDoc = await _empresasCollection.doc(trabajador.empresaId).get();
      if (!empresaDoc.exists) {
        throw Exception('La empresa no existe');
      }

      // Crear referencia al documento del trabajador
      final trabajadorRef = _empresasCollection
          .doc(trabajador.empresaId)
          .collection('trabajadores')
          .doc();

      // Crear el trabajador con el ID generado
      final trabajadorData = trabajador.toMap();
      trabajadorData['id'] = trabajadorRef.id;
      trabajadorData['fechaContratacion'] = Timestamp.now();
      
      final nuevoTrabajador = Trabajador.fromMap(trabajadorData);

      LoggerService().info('Guardando trabajador en Firestore: ${nuevoTrabajador.toMap()}');
      
      // Guardar en Firestore
      await trabajadorRef.set(nuevoTrabajador.toMap());
      LoggerService().info('Trabajador guardado exitosamente con ID: ${trabajadorRef.id}');

      // Crear usuario correspondiente con email y contraseña específica
      LoggerService().info('Creando usuario para el trabajador...');
      final usuarioData = {
        'email': trabajadorData['email'],
        'password': trabajadorData['password'] ?? '123456',
        'isActive': true,
        'tipo': 'trabajador',
        'trabajadorId': trabajadorRef.id,
        'empresaId': trabajadorData['empresaId'],
        'fechaCreacion': Timestamp.now()
      };
      
      await FirebaseFirestore.instance.collection('usuarios').add(usuarioData);
      LoggerService().info('Usuario creado exitosamente');

      if (!mounted) return;

      // Actualizar el estado local
      setState(() {
        _trabajadores.add(nuevoTrabajador);
      });

      // Mostrar mensaje de éxito con las credenciales
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Trabajador registrado exitosamente\nEmail: ${trabajadorData['email']}\nContraseña: ${trabajadorData['password'] ?? '123456'}'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      LoggerService().error('Error al agregar trabajador', e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al registrar trabajador: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      rethrow;
    }
  }

  Future<void> _eliminarTrabajador(Trabajador trabajador) async {
    try {
      LoggerService().info('Eliminando trabajador: ${trabajador.id}');
      await _empresasCollection
          .doc(trabajador.empresaId)
          .collection('trabajadores')
          .doc(trabajador.id)
          .delete();
      LoggerService().info('Trabajador eliminado exitosamente');
    } catch (e) {
      LoggerService().error('Error al eliminar trabajador', e);
      rethrow;
    }
  }

  Future<void> _verificarAcceso() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor complete todos los campos'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('usuarios')
          .where('email', isEqualTo: _emailController.text.trim())
          .get();

      if (querySnapshot.docs.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email no encontrado'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final userData = querySnapshot.docs.first.data();
      if (userData['password'] != _passwordController.text) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Contraseña incorrecta'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (!mounted) return;
      Navigator.of(context).pop(); // Cerrar el diálogo

      // Esperar un momento para que el diálogo se cierre completamente
      await Future.delayed(const Duration(milliseconds: 100));

      if (!mounted) return;

      // Navegar según el tipo de usuario
      if (userData['tipo'] == 'admin') {
        // Navegar al panel de control para administradores
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => Scaffold(
              appBar: AppBar(
                leading: IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) => const HomePage(),
                      ),
                      (route) => false,
                    );
                  },
                ),
                title: const Text('Panel de Control'),
                backgroundColor: Theme.of(context).colorScheme.inversePrimary,
              ),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Bienvenido al Panel de Control',
                      style: TextStyle(fontSize: 24),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TrabajadoresPage(
                              empresas: _empresas.where((e) => e.id == userData['empresaId']).toList(),
                              onTrabajadorAgregado: _agregarTrabajador,
                              onTrabajadorEliminado: _eliminarTrabajador,
                              empresaId: userData['empresaId'],
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.people),
                      label: const Text('Ver Trabajadores'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          (route) => false,
        );
      } else if (userData['tipo'] == 'trabajador') {
        // Navegar a la página de fichaje para trabajadores
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => FichajePage(
              trabajadorId: userData['trabajadorId'],
              email: userData['email'],
            ),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 32),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(width: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarDialogoAcceso() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Acceso'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Contraseña',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _emailController.clear();
              _passwordController.clear();
              Navigator.pop(context);
            },
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _verificarAcceso();
            },
            child: const Text('Acceder'),
          ),
        ],
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
