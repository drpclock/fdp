import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/trabajador.dart';
import '../models/empresa.dart';
import '../pages/registros_fichaje_page.dart';
import '../pages/register_worker_page.dart';

class TrabajadoresPage extends StatefulWidget {
  final List<Empresa> empresas;
  final Function(Trabajador) onTrabajadorAgregado;
  final Function(Trabajador) onTrabajadorEliminado;
  final String? empresaId;

  const TrabajadoresPage({
    super.key,
    required this.empresas,
    required this.onTrabajadorAgregado,
    required this.onTrabajadorEliminado,
    this.empresaId,
  });

  @override
  State<TrabajadoresPage> createState() => _TrabajadoresPageState();
}

class _TrabajadoresPageState extends State<TrabajadoresPage> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _apellidosController = TextEditingController();
  final _dniController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _contratoController = TextEditingController();
  final List<Trabajador> _trabajadores = [];
  List<Trabajador> _trabajadoresFiltrados = [];
  Empresa? _empresaSeleccionada;
  bool _mostrarPassword = false;
  bool _mostrarFormulario = false;
  DateTime? _fechaContratacion;
  
  // Mapas para almacenar los FocusNodes y Controllers de cada celda
  final Map<String, FocusNode> _focusNodes = {};
  final Map<String, TextEditingController> _controllers = {};
  
  // Filtros activos
  final Map<String, String> _filtros = {};

  @override
  void initState() {
    super.initState();
    if (widget.empresaId != null) {
      _empresaSeleccionada = widget.empresas.firstWhere(
        (empresa) => empresa.id == widget.empresaId,
        orElse: () => widget.empresas.first,
      );
    } else if (widget.empresas.isNotEmpty) {
      _empresaSeleccionada = widget.empresas.first;
    }
    _cargarTrabajadores();
  }

  @override
  void didUpdateWidget(TrabajadoresPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.empresas != oldWidget.empresas) {
      if (widget.empresaId != null) {
        _empresaSeleccionada = widget.empresas.firstWhere(
          (empresa) => empresa.id == widget.empresaId,
          orElse: () => widget.empresas.first,
        );
      } else if (widget.empresas.isNotEmpty) {
        _empresaSeleccionada = widget.empresas.first;
      }
      _cargarTrabajadores();
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidosController.dispose();
    _dniController.dispose();
    _telefonoController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _contratoController.dispose();
    
    // Dispose de todos los controllers y focus nodes
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes.values) {
      focusNode.dispose();
    }
    
    super.dispose();
  }

  Future<void> _cargarTrabajadores() async {
    try {
      final empresaId = widget.empresaId ?? _empresaSeleccionada?.id;
      if (empresaId == null) {
        print('No hay empresa seleccionada');
        setState(() {
          _trabajadores.clear();
          _trabajadoresFiltrados.clear();
        });
        return;
      }

      print('Cargando trabajadores de la empresa: $empresaId');

      // Obtener todos los trabajadores de la empresa
      final snapshot = await FirebaseFirestore.instance
          .collection('empresas')
          .doc(empresaId)
          .collection('trabajadores')
          .get();

      print('Número de trabajadores encontrados: ${snapshot.docs.length}');
      print('Documentos encontrados:');
      for (var doc in snapshot.docs) {
        print('ID: ${doc.id}, Datos: ${doc.data()}');
      }

      if (!mounted) return;

      final trabajadores = snapshot.docs.map((doc) {
        final data = doc.data();
        print('Procesando trabajador: ${doc.id}');
        print('Datos del trabajador: $data');
        
        return Trabajador(
          id: doc.id,
          nombre: data['nombre'] ?? '',
          apellidos: data['apellidos'] ?? '',
          dni: data['dni'] ?? '',
          telefono: data['telefono'] ?? '',
          email: data['email'] ?? '',
          password: data['password'] ?? '',
          empresaId: data['empresaId'] ?? '',
          fechaContratacion: (data['fechaContratacion'] as Timestamp?)?.toDate() ?? DateTime.now(),
          contrato: data['contrato'] ?? '',
          centroTrabajo: data['centroTrabajo'] ?? '',
          responsable: data['responsable'] ?? '',
        );
      }).toList();

      print('Trabajadores procesados: ${trabajadores.length}');

      setState(() {
        _trabajadores.clear();
        _trabajadores.addAll(trabajadores);
        _trabajadoresFiltrados = List.from(_trabajadores);
      });

      print('Trabajadores cargados en la lista: ${_trabajadores.length}');
      for (var trabajador in _trabajadores) {
        print('Trabajador en lista: ${trabajador.id} - ${trabajador.nombre} ${trabajador.apellidos}');
      }
    } catch (e) {
      print('Error al cargar trabajadores: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar trabajadores: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _guardarTrabajador() async {
    if (_formKey.currentState!.validate()) {
      final empresaId = widget.empresaId ?? _empresaSeleccionada?.id;
      if (empresaId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se ha seleccionado una empresa'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      try {
        print('Guardando trabajador en empresa: $empresaId');

        // Verificar si ya existe un trabajador con el mismo DNI en la empresa seleccionada
        final querySnapshot = await FirebaseFirestore.instance
            .collection('empresas')
            .doc(empresaId)
            .collection('trabajadores')
            .where('dni', isEqualTo: _dniController.text.trim())
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ya existe un trabajador con este DNI en esta empresa'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        // Crear el documento del trabajador en la subcolección trabajadores de la empresa seleccionada
        final trabajadorRef = FirebaseFirestore.instance
            .collection('empresas')
            .doc(empresaId)
            .collection('trabajadores')
            .doc();

        print('Referencia del trabajador creada: ${trabajadorRef.path}');

        // Crear el trabajador con todos sus datos
        final trabajadorData = {
          'nombre': _nombreController.text.trim(),
          'apellidos': _apellidosController.text.trim(),
          'dni': _dniController.text.trim(),
          'telefono': _telefonoController.text.trim(),
          'email': _emailController.text.trim(),
          'empresaId': empresaId,
          'fechaContratacion': _fechaContratacion ?? FieldValue.serverTimestamp(),
          'contrato': _contratoController.text.trim(),
          'password': _passwordController.text.trim(),
          'centroTrabajo': '',
          'responsable': '',
        };

        print('Datos del trabajador a guardar: $trabajadorData');

        // Usar una transacción para asegurar que ambas operaciones se completen
        await FirebaseFirestore.instance.runTransaction((transaction) async {
          // Guardar en la subcolección trabajadores de la empresa
          transaction.set(trabajadorRef, trabajadorData);

          // Guardar en la colección usuarios
          final usuarioRef = FirebaseFirestore.instance.collection('usuarios').doc(trabajadorRef.id);
          transaction.set(usuarioRef, {
            ...trabajadorData,
            'rol': 'trabajador',
            'empresaId': empresaId,
          });
        });

        print('Trabajador guardado exitosamente en ambas colecciones');

        // Crear una nueva instancia de Trabajador
        final nuevoTrabajador = Trabajador(
          id: trabajadorRef.id,
          nombre: _nombreController.text.trim(),
          apellidos: _apellidosController.text.trim(),
          dni: _dniController.text.trim(),
          telefono: _telefonoController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          empresaId: empresaId,
          fechaContratacion: _fechaContratacion ?? DateTime.now(),
          contrato: _contratoController.text.trim(),
          centroTrabajo: '',
          responsable: '',
        );

        // Actualizar la lista local
        setState(() {
          _trabajadores.add(nuevoTrabajador);
          _trabajadoresFiltrados = List.from(_trabajadores);
        });

        // Limpiar los campos
      _nombreController.clear();
      _apellidosController.clear();
      _dniController.clear();
      _telefonoController.clear();
      _emailController.clear();
        _contratoController.clear();
      _passwordController.clear();
        _fechaContratacion = null;

        if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Trabajador guardado exitosamente'),
          backgroundColor: Colors.green,
        ),
      );

        // Recargar los trabajadores para asegurar que se muestren los datos actualizados
        await _cargarTrabajadores();
      } catch (e) {
        print('Error al guardar trabajador: $e');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar el trabajador: $e'),
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
        title: const Text('Trabajadores'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          if (!_mostrarFormulario) ...[
            Expanded(
              child: _trabajadoresFiltrados.isEmpty
                  ? const Center(
                      child: Text(
                        'No hay trabajadores registrados',
                        style: TextStyle(fontSize: 18),
                      ),
                    )
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        child: DataTable(
                          headingRowColor: MaterialStateProperty.all(Colors.blue.shade100),
                          columns: [
                            DataColumn(label: _buildColumnHeader('nombre', 'Nombre')),
                            DataColumn(label: _buildColumnHeader('apellidos', 'Apellidos')),
                            DataColumn(label: _buildColumnHeader('dni', 'DNI')),
                            DataColumn(label: _buildColumnHeader('telefono', 'Teléfono')),
                            DataColumn(label: _buildColumnHeader('email', 'Email')),
                            DataColumn(label: _buildColumnHeader('contrato', 'Contrato')),
                            DataColumn(label: _buildColumnHeader('centroTrabajo', 'Centro de Trabajo')),
                            DataColumn(label: _buildColumnHeader('responsable', 'Responsable')),
                            const DataColumn(label: Text('Acciones')),
                          ],
                          rows: _trabajadoresFiltrados.map((trabajador) {
                            _inicializarControllers(trabajador);
                            return DataRow(
                              cells: [
                                DataCell(
                                  EditableText(
                                    controller: _getController('${trabajador.id}_nombre'),
                                    focusNode: _getFocusNode('${trabajador.id}_nombre'),
                                    style: const TextStyle(color: Colors.black),
                                    backgroundCursorColor: Colors.blue,
                                    cursorColor: Colors.blue,
                                    onChanged: (value) => _actualizarColumna(trabajador, 'nombre', value),
                                  ),
                                ),
                                DataCell(
                                  EditableText(
                                    controller: _getController('${trabajador.id}_apellidos'),
                                    focusNode: _getFocusNode('${trabajador.id}_apellidos'),
                                    style: const TextStyle(color: Colors.black),
                                    backgroundCursorColor: Colors.blue,
                                    cursorColor: Colors.blue,
                                    onChanged: (value) => _actualizarColumna(trabajador, 'apellidos', value),
                                  ),
                                ),
                                DataCell(
                                  EditableText(
                                    controller: _getController('${trabajador.id}_dni'),
                                    focusNode: _getFocusNode('${trabajador.id}_dni'),
                                    style: const TextStyle(color: Colors.black),
                                    backgroundCursorColor: Colors.blue,
                                    cursorColor: Colors.blue,
                                    onChanged: (value) => _actualizarColumna(trabajador, 'dni', value),
                                  ),
                                ),
                                DataCell(
                                  EditableText(
                                    controller: _getController('${trabajador.id}_telefono'),
                                    focusNode: _getFocusNode('${trabajador.id}_telefono'),
                                    style: const TextStyle(color: Colors.black),
                                    backgroundCursorColor: Colors.blue,
                                    cursorColor: Colors.blue,
                                    onChanged: (value) => _actualizarColumna(trabajador, 'telefono', value),
                                  ),
                                ),
                                DataCell(
                                  EditableText(
                                    controller: _getController('${trabajador.id}_email'),
                                    focusNode: _getFocusNode('${trabajador.id}_email'),
                                    style: const TextStyle(color: Colors.black),
                                    backgroundCursorColor: Colors.blue,
                                    cursorColor: Colors.blue,
                                    onChanged: (value) => _actualizarColumna(trabajador, 'email', value),
                                  ),
                                ),
                                DataCell(
                                  EditableText(
                                    controller: _getController('${trabajador.id}_contrato'),
                                    focusNode: _getFocusNode('${trabajador.id}_contrato'),
                                    style: const TextStyle(color: Colors.black),
                                    backgroundCursorColor: Colors.blue,
                                    cursorColor: Colors.blue,
                                    onChanged: (value) => _actualizarColumna(trabajador, 'contrato', value),
                                  ),
                                ),
                                DataCell(
                                  EditableText(
                                    controller: _getController('${trabajador.id}_centroTrabajo'),
                                    focusNode: _getFocusNode('${trabajador.id}_centroTrabajo'),
                                    style: const TextStyle(color: Colors.black),
                                    backgroundCursorColor: Colors.blue,
                                    cursorColor: Colors.blue,
                                    onChanged: (value) => _actualizarColumna(trabajador, 'centroTrabajo', value),
                                  ),
                                ),
                                DataCell(
                                  EditableText(
                                    controller: _getController('${trabajador.id}_responsable'),
                                    focusNode: _getFocusNode('${trabajador.id}_responsable'),
                                    style: const TextStyle(color: Colors.black),
                                    backgroundCursorColor: Colors.blue,
                                    cursorColor: Colors.blue,
                                    onChanged: (value) => _actualizarColumna(trabajador, 'responsable', value),
                                  ),
                                ),
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.history, color: Colors.blue),
                                        tooltip: 'Ver registros de fichaje',
                                        onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => RegistrosFichajePage(
                                    trabajadorId: trabajador.id,
                                    empresaId: _empresaSeleccionada?.id ?? widget.empresaId ?? '',
                                  ),
                                ),
                              );
                            },
                                      ),
                                      IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                                        tooltip: 'Eliminar trabajador',
                                        onPressed: () => _confirmarEliminarTrabajador(trabajador),
                                      ),
                                    ],
                            ),
                          ),
                              ],
                        );
                          }).toList(),
                        ),
                      ),
                    ),
            ),
          ] else ...[
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(
                        Icons.person_add,
                        size: 100,
                        color: Colors.blue,
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _nombreController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingrese el nombre';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _apellidosController,
                        decoration: const InputDecoration(
                          labelText: 'Apellidos',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingrese los apellidos';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _dniController,
                        decoration: const InputDecoration(
                          labelText: 'DNI',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.badge),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingrese el DNI';
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
                          labelText: 'Email (Usuario)',
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
                        controller: _contratoController,
                        decoration: const InputDecoration(
                          labelText: 'Contrato',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.description),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingrese el contrato';
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
                      const SizedBox(height: 16),
                      ListTile(
                        title: Text(_fechaContratacion == null
                            ? 'Seleccionar fecha de contratación'
                            : 'Fecha de contratación: ${_fechaContratacion!.day}/${_fechaContratacion!.month}/${_fechaContratacion!.year}'),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: _fechaContratacion ?? DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null && picked != _fechaContratacion) {
                            setState(() {
                              _fechaContratacion = picked;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _guardarTrabajador,
                        icon: const Icon(Icons.save),
                        label: const Text('Guardar Trabajador'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _mostrarFormulario = false;
                          });
                        },
                        icon: const Icon(Icons.cancel),
                        label: const Text('Cancelar'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
      floatingActionButton: !_mostrarFormulario
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RegisterWorkerPage(
                      companyId: _empresaSeleccionada?.id ?? '',
                      trabajadorId: '',
                    ),
                  ),
                );
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  void _eliminarTrabajador(Trabajador trabajador) async {
    try {
      await widget.onTrabajadorEliminado(trabajador);
      _cargarTrabajadores();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar trabajador: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _confirmarEliminarTrabajador(Trabajador trabajador) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Estás seguro de que deseas eliminar al trabajador ${trabajador.nombre} ${trabajador.apellidos}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                // Eliminar el trabajador de Firestore
                await FirebaseFirestore.instance
                    .collection('empresas')
                    .doc(trabajador.empresaId)
                    .collection('trabajadores')
                    .doc(trabajador.id)
                    .delete();

                // Eliminar el usuario correspondiente
                final usuariosSnapshot = await FirebaseFirestore.instance
                    .collection('usuarios')
                    .where('trabajadorId', isEqualTo: trabajador.id)
                    .get();

                for (var doc in usuariosSnapshot.docs) {
                  await doc.reference.delete();
                }

                // Actualizar la lista local
                setState(() {
                  _trabajadores.removeWhere((t) => t.id == trabajador.id);
                  _trabajadoresFiltrados = List.from(_trabajadores);
                });

                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Trabajador eliminado exitosamente'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                print('Error al eliminar trabajador: $e');
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error al eliminar trabajador: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _actualizarColumna(Trabajador trabajador, String columna, String valor) async {
    try {
      Map<String, dynamic> updateData = {};
      
      if (columna == 'fechaContratacion') {
        try {
          final partes = valor.split('/');
          if (partes.length == 3) {
            final dia = int.parse(partes[0]);
            final mes = int.parse(partes[1]);
            final anio = int.parse(partes[2]);
            final fecha = DateTime(anio, mes, dia);
            updateData[columna] = Timestamp.fromDate(fecha);
          }
        } catch (e) {
          return;
        }
      } else {
        updateData[columna] = valor;
      }

      // Actualizar en Firestore
      await FirebaseFirestore.instance
          .collection('empresas')
          .doc(trabajador.empresaId)
          .collection('trabajadores')
          .doc(trabajador.id)
          .update(updateData);

      // Recargar los datos después de la actualización
      _cargarTrabajadores();
    } catch (e) {
      print('Error al actualizar $columna: $e');
    }
  }

  TextEditingController _getController(String key) {
    return _controllers[key] ?? TextEditingController();
  }

  FocusNode _getFocusNode(String key) {
    return _focusNodes[key] ?? FocusNode();
  }

  void _inicializarControllers(Trabajador trabajador) {
    final campos = ['nombre', 'apellidos', 'dni', 'telefono', 'email', 'contrato', 'centroTrabajo', 'responsable', 'fechaContratacion'];
    for (var campo in campos) {
      final key = '${trabajador.id}_$campo';
      if (!_controllers.containsKey(key)) {
        String valorInicial = '';
        if (campo == 'centroTrabajo') {
          valorInicial = trabajador.centroTrabajo ?? '';
        } else if (campo == 'responsable') {
          valorInicial = trabajador.responsable ?? '';
        } else if (campo == 'contrato') {
          valorInicial = trabajador.contrato ?? '';
        } else if (campo == 'fechaContratacion') {
          valorInicial = '${trabajador.fechaContratacion.day}/${trabajador.fechaContratacion.month}/${trabajador.fechaContratacion.year}';
        } else {
          valorInicial = trabajador.toMap()[campo] ?? '';
        }
        _controllers[key] = TextEditingController(text: valorInicial);
      }
      if (!_focusNodes.containsKey(key)) {
        _focusNodes[key] = FocusNode();
      }
    }
  }

  void _aplicarFiltros() {
    setState(() {
      _trabajadoresFiltrados = _trabajadores.where((trabajador) {
        return _filtros.entries.every((filtro) {
          final valor = filtro.value.toLowerCase();
          final campo = filtro.key;
          
          if (campo == 'fechaContratacion') {
            final fechaStr = '${trabajador.fechaContratacion.day}/${trabajador.fechaContratacion.month}/${trabajador.fechaContratacion.year}';
            return fechaStr.toLowerCase().contains(valor);
          } else if (campo == 'centroTrabajo') {
            return (trabajador.centroTrabajo ?? '').toLowerCase().contains(valor);
          } else if (campo == 'responsable') {
            return (trabajador.responsable ?? '').toLowerCase().contains(valor);
          } else {
            return trabajador.toMap()[campo].toString().toLowerCase().contains(valor);
          }
        });
      }).toList();
    });
  }

  void _mostrarDialogoFiltro(String columna, String titulo) {
    final controller = TextEditingController(text: _filtros[columna] ?? '');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Filtrar por $titulo'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Ingrese el texto para filtrar',
            suffixIcon: IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                controller.clear();
              },
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                if (controller.text.isEmpty) {
                  _filtros.remove(columna);
                } else {
                  _filtros[columna] = controller.text;
                }
              });
              _aplicarFiltros();
              Navigator.pop(context);
            },
            child: const Text('Aplicar'),
          ),
        ],
      ),
    );
  }

  Widget _buildColumnHeader(String columna, String titulo) {
    return InkWell(
      onTap: () => _mostrarDialogoFiltro(columna, titulo),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(titulo),
          if (_filtros.containsKey(columna))
            const Padding(
              padding: EdgeInsets.only(left: 4),
              child: Icon(Icons.filter_list, size: 16, color: Colors.blue),
            ),
        ],
      ),
    );
  }
} 