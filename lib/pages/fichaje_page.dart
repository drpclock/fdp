import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:geocoding/geocoding.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/logger_service.dart';
import 'registros_fichaje_page.dart';
import '../main.dart';

class FichajePage extends StatefulWidget {
  final String trabajadorId;
  final String email;

  const FichajePage({
    super.key,
    required this.trabajadorId,
    required this.email,
  });

  @override
  State<FichajePage> createState() => _FichajePageState();
}

class _FichajePageState extends State<FichajePage> {
  String? _empresaId;
  bool _isLoading = true;
  String? _trabajadorId;

  @override
  void initState() {
    super.initState();
    _trabajadorId = widget.trabajadorId;
    _cargarDatosTrabajador();
    if (kIsWeb) {
      _solicitarPermisosWeb();
    }
  }

  Future<void> _cargarDatosTrabajador() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('usuarios')
          .where('email', isEqualTo: widget.email)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final userData = querySnapshot.docs.first.data();
        setState(() {
          _empresaId = userData['empresaId'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar datos: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _solicitarPermisosWeb() async {
    try {
      // Solicitar permisos de ubicación en web
      await geo.Geolocator.requestPermission();
      
      // Verificar si los servicios de ubicación están habilitados
      bool serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor, habilita los servicios de ubicación en tu navegador'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      print('Error al solicitar permisos en web: $e');
    }
  }

  Future<geo.Position> _obtenerUbicacion() async {
    if (kIsWeb) {
      try {
        // En web, intentar obtener la ubicación con la máxima precisión posible
        return await geo.Geolocator.getCurrentPosition(
          desiredAccuracy: geo.LocationAccuracy.bestForNavigation,
          timeLimit: const Duration(seconds: 10),
        );
      } catch (e) {
        print('Error al obtener ubicación de alta precisión en web: $e');
        // Si falla, intentar con precisión alta
        try {
          return await geo.Geolocator.getCurrentPosition(
            desiredAccuracy: geo.LocationAccuracy.high,
            timeLimit: const Duration(seconds: 10),
          );
        } catch (e) {
          print('Error al obtener ubicación de precisión alta en web: $e');
          // Último intento con precisión media
          return await geo.Geolocator.getCurrentPosition(
            desiredAccuracy: geo.LocationAccuracy.medium,
            timeLimit: const Duration(seconds: 10),
          );
        }
      }
    } else {
      bool serviceEnabled;
      geo.LocationPermission permission;

      // Verificar si el servicio de ubicación está habilitado
      serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Los servicios de ubicación están deshabilitados.');
      }

      // Verificar permisos de ubicación
      permission = await geo.Geolocator.checkPermission();
      if (permission == geo.LocationPermission.denied) {
        permission = await geo.Geolocator.requestPermission();
        if (permission == geo.LocationPermission.denied) {
          throw Exception('Los permisos de ubicación fueron denegados.');
        }
      }

      if (permission == geo.LocationPermission.deniedForever) {
        throw Exception('Los permisos de ubicación están permanentemente denegados.');
      }

      try {
        // Intentar obtener la ubicación con la máxima precisión posible
        return await geo.Geolocator.getCurrentPosition(
          desiredAccuracy: geo.LocationAccuracy.bestForNavigation,
          timeLimit: const Duration(seconds: 10),
        );
      } catch (e) {
        print('Error al obtener ubicación de alta precisión: $e');
        // Si falla, intentar con precisión alta
        try {
          return await geo.Geolocator.getCurrentPosition(
            desiredAccuracy: geo.LocationAccuracy.high,
            timeLimit: const Duration(seconds: 10),
          );
        } catch (e) {
          print('Error al obtener ubicación de precisión alta: $e');
          // Último intento con precisión media
          return await geo.Geolocator.getCurrentPosition(
            desiredAccuracy: geo.LocationAccuracy.medium,
            timeLimit: const Duration(seconds: 10),
          );
        }
      }
    }
  }

  Future<String> _obtenerDireccion(double latitud, double longitud) async {
    try {
      print('Obteniendo dirección para: $latitud, $longitud');
      final url = 'https://nominatim.openstreetmap.org/reverse?format=json&lat=$latitud&lon=$longitud&zoom=18&addressdetails=1&namedetails=1&accept-language=es';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'DPClock/1.0',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Respuesta de Nominatim: $data');
        
        if (data['address'] != null) {
          final address = data['address'];
          String street = '';
          String houseNumber = '';
          String locality = '';
          String postcode = '';
          String state = '';
          String country = '';
          
          // Obtener el número de la casa
          if (address['house_number'] != null) {
            houseNumber = address['house_number'];
          }
          
          // Obtener la calle
          if (address['road'] != null) {
            street = address['road'];
          } else if (address['pedestrian'] != null) {
            street = address['pedestrian'];
          } else if (address['footway'] != null) {
            street = address['footway'];
          } else if (address['residential'] != null) {
            street = address['residential'];
          } else if (address['path'] != null) {
            street = address['path'];
          } else if (address['track'] != null) {
            street = address['track'];
          }
          
          // Obtener la localidad
          if (address['city'] != null) {
            locality = address['city'];
          } else if (address['town'] != null) {
            locality = address['town'];
          } else if (address['village'] != null) {
            locality = address['village'];
          } else if (address['suburb'] != null) {
            locality = address['suburb'];
          }
          
          // Obtener el código postal
          if (address['postcode'] != null) {
            postcode = address['postcode'];
          }

          // Obtener el estado/provincia
          if (address['state'] != null) {
            state = address['state'];
          }

          // Obtener el país
          if (address['country'] != null) {
            country = address['country'];
          }
          
          // Construir la dirección
          List<String> partes = [];
          
          if (street.isNotEmpty) {
            if (houseNumber.isNotEmpty) {
              partes.add('$street $houseNumber');
            } else {
              partes.add(street);
            }
          }
          
          if (locality.isNotEmpty) {
            partes.add(locality);
          }
          
          if (postcode.isNotEmpty) {
            partes.add('($postcode)');
          }
          
          if (state.isNotEmpty) {
            partes.add(state);
          }
          
          if (country.isNotEmpty) {
            partes.add(country);
          }
          
          String direccion = partes.join(', ');
          print('Dirección encontrada: $direccion');
          return direccion;
        }
      }
      
      print('No se pudo obtener una dirección válida de Nominatim');
      return 'Ubicación: ${latitud.toStringAsFixed(6)}, ${longitud.toStringAsFixed(6)}';
    } catch (e, stackTrace) {
      print('Error al obtener dirección: $e');
      print('Stack trace: $stackTrace');
      return 'Ubicación: ${latitud.toStringAsFixed(6)}, ${longitud.toStringAsFixed(6)}';
    }
  }

  Future<void> _registrarFichaje(String tipo) async {
    if (_empresaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: No se pudo obtener el ID de la empresa'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Obtener la ubicación actual
      final position = await _obtenerUbicacion();
      print('Ubicación obtenida: ${position.latitude}, ${position.longitude}');
      
      // Obtener la dirección
      final direccion = await _obtenerDireccion(position.latitude, position.longitude);
      print('Dirección obtenida: $direccion');
      
      // Crear el mapa de ubicación
      final ubicacion = {
        'latitud': position.latitude,
        'longitud': position.longitude,
        'precision': position.accuracy,
        'altitud': position.altitude,
        'velocidad': position.speed,
        'velocidadPrecision': position.speedAccuracy,
        'direccion': position.heading,
        'direccionCompleta': direccion,
        'timestamp': Timestamp.now(),
      };

      print('Datos de ubicación a guardar: $ubicacion');

      // Crear el documento de fichaje
      final fichajeData = {
        'tipo': tipo,
        'fecha': Timestamp.now(),
        'trabajadorId': widget.trabajadorId,
        'empresaId': _empresaId!,
        'ubicacion': ubicacion,
        'direccionCompleta': direccion,
      };

      print('Datos completos del fichaje: $fichajeData');

      // Guardar en Firestore
      final docRef = await FirebaseFirestore.instance
          .collection('empresas')
          .doc(_empresaId!)
          .collection('trabajadores')
          .doc(widget.trabajadorId)
          .collection('fichajes')
          .add(fichajeData);

      print('Fichaje guardado con ID: ${docRef.id}');

      if (!mounted) return;

      // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fichaje de $tipo registrado correctamente\nUbicación: $direccion'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 5),
        ),
      );

      // Navegar a la página de registros después de un fichaje exitoso
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RegistrosFichajePage(
            trabajadorId: widget.trabajadorId,
            empresaId: _empresaId!,
          ),
        ),
      );
    } catch (e) {
      print('Error al registrar fichaje: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al registrar fichaje: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _navegarARegistros() {
    if (_empresaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: No se ha seleccionado una empresa'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RegistrosFichajePage(
          trabajadorId: _trabajadorId!,
          empresaId: _empresaId!,
        ),
      ),
    );
  }

  void _mostrarRegistros() {
    if (_empresaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: No se ha seleccionado una empresa'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RegistrosFichajePage(
          trabajadorId: _trabajadorId!,
          empresaId: _empresaId!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fichaje'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
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
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: _mostrarRegistros,
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _registrarFichaje('entrada'),
                  icon: const Icon(Icons.login),
                  label: const Text('Entrada'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                ElevatedButton.icon(
                  onPressed: () => _registrarFichaje('pausa'),
                  icon: const Icon(Icons.pause),
                  label: const Text('Pausa'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _registrarFichaje('reanudar'),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Reanudar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                ElevatedButton.icon(
                  onPressed: () => _registrarFichaje('salida'),
                  icon: const Icon(Icons.logout),
                  label: const Text('Salida'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 