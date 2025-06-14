import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:io';
import 'dart:html' as html;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/logger_service.dart';
import '../models/registro_fichaje.dart';
import '../models/trabajador.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Formateador para el campo de hora
class TimeInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    final text = newValue.text.replaceAll(':', '');
    if (text.length > 4) {
      return oldValue;
    }

    if (text.length >= 2) {
      final hours = int.parse(text.substring(0, 2));
      if (hours > 23) {
        return oldValue;
      }
    }

    if (text.length >= 4) {
      final minutes = int.parse(text.substring(2, 4));
      if (minutes > 59) {
        return oldValue;
      }
    }

    String formatted = text;
    if (text.length >= 2) {
      formatted = '${text.substring(0, 2)}:${text.substring(2)}';
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class RegistrosFichajePage extends StatefulWidget {
  final String trabajadorId;
  final String empresaId;

  const RegistrosFichajePage({
    super.key,
    required this.trabajadorId,
    required this.empresaId,
  });

  @override
  State<RegistrosFichajePage> createState() => _RegistrosFichajePageState();
}

class _RegistrosFichajePageState extends State<RegistrosFichajePage> {
  final List<RegistroFichaje> _registros = [];
  Trabajador? _trabajador;
  DateTime _fechaInicio = DateTime.now().subtract(const Duration(days: 30));
  DateTime _fechaFin = DateTime.now();
  bool _isLoading = true;
  bool _isAdmin = false;
  String? _nombreEmpresa;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
    _verificarAdmin();
    _cargarNombreEmpresa();
  }

  Future<void> _cargarNombreEmpresa() async {
    try {
      final empresaDoc = await FirebaseFirestore.instance
          .collection('empresas')
          .doc(widget.empresaId)
          .get();

      if (empresaDoc.exists) {
        setState(() {
          _nombreEmpresa = empresaDoc.data()?['nombre'] ?? 'Empresa';
        });
      }
    } catch (e) {
      print('Error al cargar nombre de empresa: $e');
    }
  }

  Future<void> _cargarDatos() async {
    try {
      print('Cargando datos para trabajador: ${widget.trabajadorId} en empresa: ${widget.empresaId}');
      print('Período: ${_fechaInicio} - ${_fechaFin}');

      // Cargar datos del trabajador
      final trabajadorDoc = await FirebaseFirestore.instance
          .collection('empresas')
          .doc(widget.empresaId)
          .collection('trabajadores')
          .doc(widget.trabajadorId)
          .get();

      if (trabajadorDoc.exists) {
        _trabajador = Trabajador.fromFirestore(trabajadorDoc);
        print('Trabajador encontrado: ${_trabajador?.nombre} ${_trabajador?.apellidos}');
      } else {
        print('No se encontró el trabajador');
      }

      // Cargar registros de fichaje
      final snapshot = await FirebaseFirestore.instance
          .collection('empresas')
          .doc(widget.empresaId)
          .collection('trabajadores')
          .doc(widget.trabajadorId)
          .collection('fichajes')
          .where('fecha', isGreaterThanOrEqualTo: Timestamp.fromDate(_fechaInicio))
          .where('fecha', isLessThanOrEqualTo: Timestamp.fromDate(_fechaFin))
          .orderBy('fecha', descending: true)
          .get();

      print('Número de registros encontrados: ${snapshot.docs.length}');

      setState(() {
        _registros.clear();
        _registros.addAll(
          snapshot.docs.map((doc) {
            print('Procesando registro: ${doc.id}');
            return RegistroFichaje.fromFirestore(doc);
          }).toList(),
        );
        _isLoading = false;
      });

      if (_registros.isEmpty) {
        print('No se encontraron registros en el período seleccionado');
      }
    } catch (e, stackTrace) {
      print('Error al cargar datos: $e');
      print('Stack trace: $stackTrace');
      setState(() {
        _isLoading = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar datos: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _seleccionarFechas() async {
    final DateTimeRange? fechas = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _fechaInicio, end: _fechaFin),
    );

    if (fechas != null) {
      setState(() {
        _fechaInicio = DateTime(fechas.start.year, fechas.start.month, fechas.start.day);
        _fechaFin = DateTime(fechas.end.year, fechas.end.month, fechas.end.day, 23, 59, 59);
        _isLoading = true;
      });
      await _cargarDatos();
    }
  }

  Future<void> _exportarPDF() async {
    try {
      final pdf = pw.Document();
      final registrosAgrupados = _agruparRegistrosPorDia();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Encabezado
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  color: PdfColors.blue,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Registros de Fichaje',
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                      pw.SizedBox(height: 10),
                      if (_trabajador != null) ...[
                        pw.Text(
                          'Nombre: ${_trabajador!.nombre} ${_trabajador!.apellidos}',
                          style: const pw.TextStyle(
                            fontSize: 12,
                            color: PdfColors.white,
                          ),
                        ),
                        pw.SizedBox(height: 5),
                        pw.Text(
                          'DNI: ${_trabajador!.dni}',
                          style: const pw.TextStyle(
                            fontSize: 12,
                            color: PdfColors.white,
                          ),
                        ),
                      ],
                      pw.SizedBox(height: 10),
                      pw.Text(
                        'Período: ${DateFormat('dd/MM/yyyy').format(_fechaInicio)} - ${DateFormat('dd/MM/yyyy').format(_fechaFin)}',
                        style: const pw.TextStyle(
                          fontSize: 12,
                          color: PdfColors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),

                // Tabla de registros
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.black),
                  columnWidths: {
                    0: const pw.FixedColumnWidth(50),
                    1: const pw.FixedColumnWidth(45),
                    2: const pw.FixedColumnWidth(45),
                    3: const pw.FixedColumnWidth(45),
                    4: const pw.FixedColumnWidth(45),
                    5: const pw.FixedColumnWidth(60),
                  },
                  children: [
                    // Encabezado
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.blue,
                      ),
                      children: [
                        _buildHeaderCell('Fecha'),
                        _buildHeaderCell('Entrada'),
                        _buildHeaderCell('Pausa'),
                        _buildHeaderCell('Reanudar'),
                        _buildHeaderCell('Salida'),
                        _buildHeaderCell('Horas'),
                      ],
                    ),
                    // Datos
                    ...registrosAgrupados.entries.map((entry) {
                      final fecha = entry.key;
                      final registros = entry.value;
                      
                      final entrada = registros.where((r) => r.tipo == 'entrada').firstOrNull;
                      final pausa = registros.where((r) => r.tipo == 'pausa').firstOrNull;
                      final reanudar = registros.where((r) => r.tipo == 'reanudar').firstOrNull;
                      final salida = registros.where((r) => r.tipo == 'salida').firstOrNull;

                      return pw.TableRow(
                        children: [
                          _buildCell(fecha),
                          _buildCell(entrada != null ? DateFormat('HH:mm').format(entrada.fecha) : null),
                          _buildCell(pausa != null ? DateFormat('HH:mm').format(pausa.fecha) : null),
                          _buildCell(reanudar != null ? DateFormat('HH:mm').format(reanudar.fecha) : null),
                          _buildCell(salida != null ? DateFormat('HH:mm').format(salida.fecha) : null),
                          _buildCell(_calcularHorasTrabajadas(registros)),
                        ],
                      );
                    }).toList(),
                    // Fila de total
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.grey200,
                      ),
                      children: [
                        _buildCell('TOTAL', isBold: true),
                        _buildCell(''),
                        _buildCell(''),
                        _buildCell(''),
                        _buildCell(''),
                        _buildCell(_calcularTotalHorasTrabajadas(registrosAgrupados), isBold: true),
                      ],
                    ),
                  ],
                ),

                // Espacio flexible para empujar las firmas al final
                pw.Spacer(),

                // Espacio para firmas
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    // Firma de la empresa
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Container(
                          width: 200,
                          height: 1,
                          color: PdfColors.black,
                        ),
                        pw.SizedBox(height: 5),
                        pw.Text(
                          'Firma de la Empresa',
                          style: const pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 5),
                        pw.Text(
                          'Fecha: _________________',
                          style: const pw.TextStyle(
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    // Firma del trabajador
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Container(
                          width: 200,
                          height: 1,
                          color: PdfColors.black,
                        ),
                        pw.SizedBox(height: 5),
                        pw.Text(
                          'Firma del Trabajador',
                          style: const pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 5),
                        pw.Text(
                          'Fecha: _________________',
                          style: const pw.TextStyle(
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Texto legal al pie de página
                pw.SizedBox(height: 30),
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.symmetric(vertical: 10),
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      top: pw.BorderSide(color: PdfColors.grey),
                    ),
                  ),
                  child: pw.Text(
                    'Registro realizado en cumplimiento del apartado 9 del artículo 34 del R.D.-Ley 2/2015 de 23 de Octubre',
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey700,
                      fontStyle: pw.FontStyle.italic,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
              ],
            );
          },
        ),
      );

      // Convertir PDF a bytes
      final pdfBytes = await pdf.save();

      if (kIsWeb) {
        // Para web, crear un blob y descargar directamente
        final blob = html.Blob([pdfBytes], 'application/pdf');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', 'registros_fichaje.pdf')
          ..click();
        html.Url.revokeObjectUrl(url);
      } else {
        // Para móvil, guardar en el dispositivo
        final output = await getTemporaryDirectory();
        final file = File('${output.path}/registros_fichaje.pdf');
        await file.writeAsBytes(pdfBytes);
        _mostrarOpcionesCompartir(file);
      }
    } catch (e) {
      print('Error al generar PDF: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al generar PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _mostrarOpcionesCompartir(File file) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.email),
              title: const Text('Enviar por correo'),
              onTap: () {
                Navigator.pop(context);
                Share.shareXFiles(
                  [XFile(file.path)],
                  subject: 'Registros de Fichaje',
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.save),
              title: const Text('Guardar en dispositivo'),
              onTap: () async {
                Navigator.pop(context);
                final directory = await getExternalStorageDirectory();
                if (directory != null) {
                  final savedFile = await file.copy('${directory.path}/registros_fichaje.pdf');
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Archivo guardado en: ${savedFile.path}'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Compartir'),
              onTap: () {
                Navigator.pop(context);
                Share.shareXFiles(
                  [XFile(file.path)],
                  text: 'Registros de Fichaje',
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Color _getColorForTipo(String tipo) {
    switch (tipo) {
      case 'entrada':
        return Colors.green;
      case 'pausa':
        return Colors.orange;
      case 'reanudar':
        return Colors.blue;
      case 'salida':
        return Colors.red;
      default:
        return Colors.black;
    }
  }

  String _getIconForTipo(String tipo) {
    switch (tipo) {
      case 'entrada':
        return 'Entrada';
      case 'pausa':
        return 'Pausa';
      case 'reanudar':
        return 'Reanudar';
      case 'salida':
        return 'Salida';
      default:
        return tipo;
    }
  }

  Map<String, List<RegistroFichaje>> _agruparRegistrosPorDia() {
    final registrosAgrupados = <String, List<RegistroFichaje>>{};
    
    for (var registro in _registros) {
      final fechaStr = DateFormat('dd/MM/yyyy').format(registro.fecha);
      if (!registrosAgrupados.containsKey(fechaStr)) {
        registrosAgrupados[fechaStr] = [];
      }
      registrosAgrupados[fechaStr]!.add(registro);
    }
    
    // Ordenar los registros dentro de cada día por hora
    for (var registros in registrosAgrupados.values) {
      registros.sort((a, b) => a.fecha.compareTo(b.fecha));
    }
    
    return registrosAgrupados;
  }

  void _mostrarUbicacion(RegistroFichaje registro) {
    // Obtener todos los registros del mismo día
    final registrosDelDia = _registros.where((r) => 
      DateFormat('dd/MM/yyyy').format(r.fecha) == DateFormat('dd/MM/yyyy').format(registro.fecha)
    ).toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Registros del día ${DateFormat('dd/MM/yyyy').format(registro.fecha)}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...registrosDelDia.map((r) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getColorForTipo(r.tipo).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              color: _getColorForTipo(r.tipo),
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${_getIconForTipo(r.tipo)} - ${DateFormat('HH:mm').format(r.fecha)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _getColorForTipo(r.tipo),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Ubicación:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          r.direccionCompleta ?? 'No disponible',
                          style: const TextStyle(fontSize: 14),
                        ),
                        if (r.ubicacion != null) ...[
                          const SizedBox(height: 8),
                          const Text(
                            'Detalles:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text('Latitud: ${r.ubicacion!['latitud']?.toStringAsFixed(6) ?? 'No disponible'}'),
                          Text('Longitud: ${r.ubicacion!['longitud']?.toStringAsFixed(6) ?? 'No disponible'}'),
                          Text('Precisión: ${r.ubicacion!['precision']?.toStringAsFixed(2) ?? 'No disponible'} metros'),
                          if (r.ubicacion!['altitud'] != null)
                            Text('Altitud: ${r.ubicacion!['altitud'].toStringAsFixed(2)} metros'),
                          if (r.ubicacion!['velocidad'] != null)
                            Text('Velocidad: ${r.ubicacion!['velocidad'].toStringAsFixed(2)} m/s'),
                          if (r.ubicacion!['direccion'] != null)
                            Text('Dirección: ${r.ubicacion!['direccion'].toStringAsFixed(2)}°'),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              )).toList(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  String _calcularHorasTrabajadas(List<RegistroFichaje> registros) {
    final entrada = registros.where((r) => r.tipo == 'entrada').firstOrNull;
    final salida = registros.where((r) => r.tipo == 'salida').firstOrNull;
    
    if (entrada == null || salida == null) {
      return '-';
    }

    // Calcular tiempo total entre entrada y salida
    final tiempoTotal = salida.fecha.difference(entrada.fecha);
    
    // Calcular tiempo de pausas
    Duration tiempoPausas = Duration.zero;
    var pausaActual = registros.where((r) => r.tipo == 'pausa').firstOrNull;
    var reanudacionActual = registros.where((r) => r.tipo == 'reanudar').firstOrNull;
    
    while (pausaActual != null && reanudacionActual != null) {
      tiempoPausas += reanudacionActual.fecha.difference(pausaActual.fecha);
      
      // Buscar siguiente pausa y reanudación
      pausaActual = registros
          .where((r) => r.tipo == 'pausa' && r.fecha.isAfter(reanudacionActual!.fecha))
          .firstOrNull;
      reanudacionActual = registros
          .where((r) => r.tipo == 'reanudar' && r.fecha.isAfter(pausaActual?.fecha ?? DateTime.now()))
          .firstOrNull;
    }

    // Restar tiempo de pausas del tiempo total
    final tiempoTrabajado = tiempoTotal - tiempoPausas;
    
    // Convertir a horas y minutos
    final horas = tiempoTrabajado.inHours;
    final minutos = tiempoTrabajado.inMinutes % 60;
    
    return '$horas:${minutos.toString().padLeft(2, '0')}';
  }

  String _calcularTotalHorasTrabajadas(Map<String, List<RegistroFichaje>> registrosAgrupados) {
    Duration tiempoTotal = Duration.zero;
    
    for (var registros in registrosAgrupados.values) {
      final entrada = registros.where((r) => r.tipo == 'entrada').firstOrNull;
      final salida = registros.where((r) => r.tipo == 'salida').firstOrNull;
      
      if (entrada != null && salida != null) {
        // Calcular tiempo total entre entrada y salida
        final tiempoDia = salida.fecha.difference(entrada.fecha);
        
        // Calcular tiempo de pausas
        Duration tiempoPausas = Duration.zero;
        var pausaActual = registros.where((r) => r.tipo == 'pausa').firstOrNull;
        var reanudacionActual = registros.where((r) => r.tipo == 'reanudar').firstOrNull;
        
        while (pausaActual != null && reanudacionActual != null) {
          tiempoPausas += reanudacionActual.fecha.difference(pausaActual.fecha);
          
          pausaActual = registros
              .where((r) => r.tipo == 'pausa' && r.fecha.isAfter(reanudacionActual!.fecha))
              .firstOrNull;
          reanudacionActual = registros
              .where((r) => r.tipo == 'reanudar' && r.fecha.isAfter(pausaActual?.fecha ?? DateTime.now()))
              .firstOrNull;
        }

        // Restar tiempo de pausas del tiempo total del día
        tiempoTotal += tiempoDia - tiempoPausas;
      }
    }
    
    // Convertir a horas y minutos
    final horas = tiempoTotal.inHours;
    final minutos = tiempoTotal.inMinutes % 60;
    
    return '$horas:${minutos.toString().padLeft(2, '0')}';
  }

  pw.Widget _buildHeaderCell(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(5),
      width: 100,
      child: pw.Text(
        text,
        style: const pw.TextStyle(
          color: PdfColors.white,
          fontWeight: pw.FontWeight.bold,
          fontSize: 10,
        ),
        textAlign: pw.TextAlign.center,
        maxLines: 2,
      ),
    );
  }

  pw.Widget _buildCell(String? text, {bool isBold = false}) {
    String displayText = text ?? '-';
    // Si el texto es muy largo, lo dividimos en múltiples líneas
    if (displayText.length > 30) {
      final words = displayText.split(' ');
      final lines = <String>[];
      String currentLine = '';
      
      for (var word in words) {
        if ((currentLine + ' ' + word).length <= 30) {
          currentLine += (currentLine.isEmpty ? '' : ' ') + word;
        } else {
          if (currentLine.isNotEmpty) {
            lines.add(currentLine);
          }
          currentLine = word;
        }
      }
      if (currentLine.isNotEmpty) {
        lines.add(currentLine);
      }
      displayText = lines.join('\n');
    }

    return pw.Container(
      padding: const pw.EdgeInsets.all(5),
      width: 100,
      child: pw.Text(
        displayText,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textAlign: pw.TextAlign.center,
        maxLines: 3,
      ),
    );
  }

  Future<void> _verificarAdmin() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('No hay usuario autenticado');
        setState(() {
          _isAdmin = false;
        });
        return;
      }

      // Primero verificar si es el creador de la empresa
      final empresaDoc = await FirebaseFirestore.instance
          .collection('empresas')
          .doc(widget.empresaId)
          .get();

      if (empresaDoc.exists) {
        final creadorId = empresaDoc.data()?['creadorId'];
        if (creadorId == user.uid) {
          print('Usuario es el creador de la empresa');
          setState(() {
            _isAdmin = true;
          });
          return;
        }
      }

      // Si no es el creador, verificar si es admin en la colección de usuarios
      final userDoc = await FirebaseFirestore.instance
          .collection('empresas')
          .doc(widget.empresaId)
          .collection('usuarios')
          .doc(user.uid)
          .get();

      print('Verificando rol de usuario: ${userDoc.data()?['rol']}');
      setState(() {
        _isAdmin = userDoc.exists && (userDoc.data()?['rol'] == 'admin');
      });
      print('Estado final de admin: $_isAdmin');
    } catch (e) {
      print('Error al verificar admin: $e');
      setState(() {
        _isAdmin = false;
      });
    }
  }

  Widget _buildEditableCell(RegistroFichaje? registro, String campo, String fecha, String tipo) {
    if (registro == null) {
      return const Text('-');
    }

    final hora = DateFormat('HH:mm').format(registro.fecha);
    return Text(
      hora,
      style: const TextStyle(
        color: Colors.black,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final registrosAgrupados = _agruparRegistrosPorDia();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registros de Fichaje'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _seleccionarFechas,
            tooltip: 'Seleccionar fechas',
          ),
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: _exportarPDF,
            tooltip: 'Exportar registros',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _registros.isEmpty
              ? const Center(
                  child: Text(
                    'No hay registros en el período seleccionado',
                    style: TextStyle(fontSize: 18),
                  ),
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    child: DataTable(
                      headingRowColor: MaterialStateProperty.all(Colors.blue.shade100),
                      columns: const [
                        DataColumn(label: Text('Entrada')),
                        DataColumn(label: Text('Pausa')),
                        DataColumn(label: Text('Reanudar')),
                        DataColumn(label: Text('Salida')),
                        DataColumn(label: Text('Horas Trabajadas')),
                        DataColumn(label: Text('Ubicación')),
                      ],
                      rows: registrosAgrupados.entries.map((entry) {
                        final fecha = entry.key;
                        final registros = entry.value;
                        
                        final entrada = registros.where((r) => r.tipo == 'entrada').firstOrNull;
                        final pausa = registros.where((r) => r.tipo == 'pausa').firstOrNull;
                        final reanudar = registros.where((r) => r.tipo == 'reanudar').firstOrNull;
                        final salida = registros.where((r) => r.tipo == 'salida').firstOrNull;
                    
                        return DataRow(
                          cells: [
                            DataCell(
                              _buildEditableCell(
                                entrada,
                                'fecha',
                                fecha,
                                'entrada',
                              ),
                            ),
                            DataCell(
                              _buildEditableCell(
                                pausa,
                                'fecha',
                                fecha,
                                'pausa',
                              ),
                            ),
                            DataCell(
                              _buildEditableCell(
                                reanudar,
                                'fecha',
                                fecha,
                                'reanudar',
                              ),
                            ),
                            DataCell(
                              _buildEditableCell(
                                salida,
                                'fecha',
                                fecha,
                                'salida',
                              ),
                            ),
                            DataCell(
                              Text(
                                _calcularHorasTrabajadas(registros),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.purple,
                                ),
                              ),
                            ),
                            DataCell(
                              IconButton(
                                icon: const Icon(Icons.location_on),
                                color: Colors.blue,
                                onPressed: () {
                                  _mostrarUbicacion(registros.first);
                                },
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
    );
  }
} 