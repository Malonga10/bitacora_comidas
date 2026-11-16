# Bitácora de Comidas

App móvil en Flutter para llevar un diario de lo que comes: guardas una foto del platillo, el tipo de comida, tus notas (escritas o dictadas por voz) y el lugar donde estabas. Proyecto individual del Parcial 2 de Desarrollo de Dispositivos Móviles (Universidad Anáhuac Mayab).

## Problema que resuelve
Es fácil olvidar qué comiste, dónde y qué te pareció. La app permite registrar cada comida en segundos, con foto, ubicación y una nota hablada, y consultar después el historial filtrado por tipo de comida.

## Funcionalidades
- **Lista, detalle y formulario** con `Scaffold`, `AppBar`, `Drawer` y rutas nombradas (`Navigator.pushNamed`).
- **Transición Hero** de la foto entre la lista y el detalle.
- **Filtro por tipo de comida** (Desayuno, Comida, Cena, Snack) desde el Drawer.
- **Persistencia local en SQLite** (`sqflite`) con guardado de rutas de imagen y coordenadas.
- **Carga asíncrona con `FutureBuilder`**, indicador de carga y manejo de errores con `try-catch`.
- **Cámara y galería** para ilustrar cada entrada.
- **Dictado por voz** en las notas (`speech_to_text`).
- **GPS** al guardar la entrada (`geolocator`).
- **Botón "Ver en Google Maps"** en el detalle, con las coordenadas guardadas (`url_launcher`).
- **Permisos denegados** (cámara, ubicación, micrófono): la app avisa y sigue funcionando.

## Estructura (por capas)
```
lib/
├── main.dart              # Configuración de la app y rutas
├── app_routes.dart        # Nombres de las rutas
├── models/                # MealEntry
├── data/                  # DatabaseHelper (SQLite, Singleton)
├── services/              # Una responsabilidad cada uno
│   ├── media_service.dart     # Cámara y galería
│   ├── location_service.dart  # GPS
│   ├── speech_service.dart    # Voz a texto
│   └── map_service.dart       # Abrir Google Maps
├── screens/               # Lista, detalle y formulario
└── widgets/               # Drawer y miniatura con Hero
```

## Cómo correrla
1. Instala Flutter y un emulador o conecta un teléfono Android.
2. Clona el repositorio y entra a la carpeta.
3. Ejecuta:
   ```
   flutter pub get
   flutter run
   ```

## Notas para probar en el emulador
- **GPS:** el emulador usa una ubicación falsa. Cámbiala en `⋯ → Location → Set location`.
- **Dictado:** requiere una imagen con Google Play, internet y el micrófono virtual activado (`⋯ → Microphone`).

## Autor
Irving — Ing. TI y Negocios Digitales, Universidad Anáhuac Mayab.
