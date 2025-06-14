import 'package:logging/logging.dart';

class LoggerService {
  static final LoggerService _instance = LoggerService._internal();
  final Logger _logger = Logger('DpClock');

  factory LoggerService() {
    return _instance;
  }

  LoggerService._internal() {
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) {
      // En producción, podrías enviar los logs a un servicio externo
      // o filtrar según el nivel
      if (record.level >= Level.WARNING) {
        // Aquí podrías implementar el envío a un servicio de monitoreo
        // como Firebase Crashlytics o Sentry
      }
    });
  }

  void error(String message, [Object? error, StackTrace? stackTrace]) {
    _logger.severe(message, error, stackTrace);
  }

  void warning(String message, [Object? error, StackTrace? stackTrace]) {
    _logger.warning(message, error, stackTrace);
  }

  void info(String message) {
    _logger.info(message);
  }

  void debug(String message) {
    _logger.fine(message);
  }
} 