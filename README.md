# DPClock - Sistema de Control de Asistencia

Sistema de control de asistencia desarrollado con Flutter y Firebase.

## Características

- Control de asistencia mediante geolocalización
- Gestión de empresas y trabajadores
- Registro de fichajes con ubicación
- Generación de informes
- Soporte para múltiples plataformas (Web, Android, iOS)

## Requisitos Previos

- Flutter SDK (versión 3.0.0 o superior)
- Dart SDK (versión 2.17.0 o superior)
- Cuenta de Firebase
- Cuenta de GitHub

## Configuración

1. Clona el repositorio:
```bash
git clone https://github.com/dpclock/dpclock.git
cd dpclock
```

2. Instala las dependencias:
```bash
flutter pub get
```

3. Configura Firebase:
   - Crea un proyecto en Firebase Console
   - Descarga el archivo de configuración `google-services.json` para Android
   - Descarga el archivo de configuración `GoogleService-Info.plist` para iOS
   - Coloca los archivos en las carpetas correspondientes:
     - Android: `android/app/google-services.json`
     - iOS: `ios/Runner/GoogleService-Info.plist`

4. Configura las variables de entorno:
   - Crea un archivo `.env` en la raíz del proyecto
   - Añade las siguientes variables:
     ```
     FIREBASE_API_KEY=tu_api_key
     FIREBASE_AUTH_DOMAIN=tu_auth_domain
     FIREBASE_PROJECT_ID=tu_project_id
     FIREBASE_STORAGE_BUCKET=tu_storage_bucket
     FIREBASE_MESSAGING_SENDER_ID=tu_messaging_sender_id
     FIREBASE_APP_ID=tu_app_id
     ```

## Despliegue Web

1. Construye la aplicación web:
```bash
flutter build web --release
```

2. Los archivos generados estarán en la carpeta `build/web`

3. Configura GitHub Pages:
   - Ve a la configuración del repositorio en GitHub
   - En la sección "GitHub Pages", selecciona la rama `gh-pages`
   - La aplicación estará disponible en `https://dpclock.github.io/dpclock`

## Desarrollo

Para ejecutar la aplicación en modo desarrollo:

```bash
flutter run -d chrome
```

## Estructura del Proyecto

```
lib/
  ├── models/         # Modelos de datos
  ├── pages/          # Páginas de la aplicación
  ├── services/       # Servicios (Firebase, Auth, etc.)
  ├── widgets/        # Widgets reutilizables
  └── main.dart       # Punto de entrada de la aplicación
```

## Licencia

Este proyecto está bajo la Licencia MIT. Ver el archivo `LICENSE` para más detalles.
