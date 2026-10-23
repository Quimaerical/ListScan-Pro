# ListScan PRO [![Flutter](https://img.shields.io/badge/SDK%203.27-Flutter?style=flat&logo=flutter&label=Flutter&labelColor=02569B&color=02569B)](https://flutter.dev)  [![Dart](https://img.shields.io/badge/SDK%203.x-Dart?style=flat&logo=dart&label=Dart&labelColor=%23057AEA&color=%23057AEA)]() [![ML kit](https://img.shields.io/badge/ML_kit_text_recognition-Google?style=flat&logo=google&logoColor=ffffff&label=Google&labelColor=%234285F4&color=%234285F4)](https://developers.google.com/ml-kit?hl=es-419) [![]()]()

Aplicación móvil inteligente para la gestión de listas de compras, extracción óptica de textos mediante OCR, importación automática de recetas desde enlaces web o APIs culinarias, control presupuestario y sincronización local primero (offline-first).

Desarrollada con Flutter siguiendo una arquitectura limpia y modular, orientada a ofrecer privacidad total, rapidez táctil y alta fidelidad visual bajo estándares de diseño glassmorphic y temas adaptativos.

---

## Tabla de Contenidos

1. [Descripción General](#descripción-general)
2. [Características Principales](#características-principales)
3. [Novedades de la Versión 1.0.4](#novedades-de-la-versión-104)
4. [Arquitectura y Estructura del Proyecto](#arquitectura-y-estructura-del-proyecto)
5. [Seguridad y Privacidad](#seguridad-y-privacidad)
6. [Instalación y Requisitos](#instalación-y-requisitos)
7. [Guía para Actualización Manual de APK](#guía-para-actualización-manual-de-apk)
8. [Comandos de Desarrollo y Pruebas](#comandos-de-desarrollo-y-pruebas)

---

## Descripción General

ListScan PRO resuelve de forma integral el proceso de compra doméstica: desde la digitalización de listas en papel usando la cámara del dispositivo, pasando por la extracción estructurada de ingredientes e instrucciones de recetas en blogs de cocina o plataformas gastronómicas (TheMealDB, Spoonacular), hasta la organización interactiva por categorías, precios y presupuestos en el supermercado.

Toda la persistencia de datos opera de manera local mediante SQLite (`sqflite`), garantizando que la información del usuario no dependa de servidores externos para su consulta o edición.

---

## Características Principales

### 1. Gestión Avanzada de Listas de Compras
- Creación, edición, duplicación y eliminación directa de listas con diálogos de confirmación.
- Soporte para vista de cuadrícula (grid) o lista vertical con persistencia en preferencias de usuario.
- Organización visual mediante separadores de sección personalizables (por ejemplo: pasillos del supermercado, categorías o etapas de la receta) eliminables directamente desde la interfaz.
- Filtros rápidos por estado (todos, pendientes, completados) y búsqueda instantánea.

### 2. Control de Precios y Presupuesto en Tiempo Real
- Cada producto admite un valor monetario opcional con soporte para separador decimal por punto o coma.
- Indicador en forma de etiqueta (chip) interactiva en cada tarjeta de producto que permite editar el precio de forma rápida.
- Cálculo automático y reactivo del importe total acumulado en el encabezado de la lista.
- Exportación del presupuesto estimado al compartir la lista.
- Total compatibilidad con listas creadas con anterioridad sin campos de precio.

### 3. Recetas Integradas y Notas Markdown
- Al importar recetas desde enlaces o desde el explorador culinario, las instrucciones completas de preparación quedan asociadas como notas de la lista.
- Sección dedicada y colapsable en la parte superior del detalle de la lista.
- Editor de texto plano y markdown con soporte para formatear ingredientes, pasos y notas adicionales.
- Opciones de exportación flexibles: compartir solo los elementos de la lista o la lista acompañada del texto completo de la receta.
- Visor con límite de altura y scroll independiente para prevenir desbordamientos visuales en recetas largas.

### 4. Barra Flotante de Entrada Rápida y Smart Link
- Barra de entrada de texto elevada con animación suave por encima del teclado.
- Detección inmediata de enlaces web (`http://` o `https://`): al ingresar o pegar un enlace, se abre automáticamente el asistente inteligente de importación de recetas.
- Sugerencias automáticas en tiempo real (autocompletado por chips) a medida que el usuario escribe.
- Soporte para pegar fragmentos multilínea o texto en formato markdown convirtiéndolos directamente en elementos de lista.

### 5. Escaneo de Listas por OCR
- Integración con Google ML Kit Text Recognition para procesar capturas fotográficas de tickets, listas manuscritas o notas impresas.
- Parser inteligente que clasifica líneas de texto en ingredientes, cantidades y unidades comunes (kg, g, l, ml, pza, etc.).

### 6. Explorador de Recetas Gastronómicas
- Motor de búsqueda integrado compatible con TheMealDB y Spoonacular API.
- Selección individual o grupal de ingredientes para sumarlos a listas existentes o crear una nueva lista de compra en un solo toque.

---

## Novedades de la Versión 1.0.4

La versión 1.0.4 incorpora un sistema integral de comprobación y notificación de actualizaciones:

- **Detección Automática de Actualizaciones en GitHub**:
  Al conectarse a internet, la aplicación consulta de forma no invasiva la API pública de GitHub Releases (`https://github.com/Quimaerical/ListScan-Pro/releases`). Si existe una versión más reciente que la instalada, se notifica inmediatamente.
- **Banner Informativo Descartable**:
  Se despliega en la parte superior del panel principal un banner informativo con diseño glassmorphic indicando la nueva versión disponible, las notas de la versión y un botón directo para descargar el instalador APK o visitar el repositorio oficial.
- **Cierre Rápido y Memoria de Sesión**:
  El banner incluye un botón de cierre inmediato que oculta el aviso durante el uso actual de la aplicación sin obstaculizar la navegación.
- **Guía Asistida para Instalación de APK**:
  Diálogo interactivo accesible desde el banner que orienta paso a paso al usuario sobre cómo autorizar e instalar el archivo APK descargado desde navegadores móviles (Chrome, Firefox, Brave).
- **Refinamiento de Interfaz y Eliminación de Desbordamientos (Overflows)**:
  Reorganización vertical de los controles de cantidad, precio y unidad en las tarjetas de productos para garantizar una lectura limpia y libre de advertencias RenderFlex en pantallas de cualquier tamaño.
- **Eliminación de Separadores Visuales**:
  Los separadores de lista cuentan ahora con un botón de borrado directo desde el propio elemento.
- **Mapeo Seguro de Recetas**:
  Las instrucciones de preparación de recetas importadas se trasladan automáticamente al campo de notas de las listas creadas desde el asistente culinario.

---

## Arquitectura y Estructura del Proyecto

El proyecto sigue una arquitectura limpia orientada por características (Feature-Driven Architecture):

```
lib/
├── core/
│   ├── config/              # Configuraciones de endpoints y ofuscacion de seguridad
│   ├── database/            # Inicializacion SQLite y migraciones de esquema
│   ├── network/             # Clientes HTTP, mapeo de excepciones y servicios API
│   ├── theme/               # Paletas de color, temas claro/oscuro y estilos tipograficos
│   └── utils/               # Funciones auxiliares, lanzadores nativos y formateadores
├── features/
│   ├── ocr/                 # Reconocimiento optico de caracteres (ML Kit)
│   ├── recipes/             # Busqueda culinaria, scraping web y detalles de recetas
│   ├── settings/            # Preferencias de usuario, temas y verificador de versiones
│   │   ├── data/            # Servicios de consulta contra GitHub Releases
│   │   ├── domain/          # Modelos de versionamiento semantico
│   │   └── presentation/    # Pantalla de ajustes y seleccion de proveedores
│   └── shopping_lists/      # Listas de compras, productos, separadores y precios
│       ├── data/            # Repositorios SQLite locales y serializadores
│       ├── domain/          # Modelos de negocio (ShoppingList, ShoppingItem, etc.)
│       └── presentation/    # Controladores, vistas (Dashboard, Detalle) y widgets
└── main.dart                # Punto de entrada de la aplicacion
```

---

## Seguridad y Privacidad

- **Ofuscación de Endpoints**:
  Las URLs base de APIs y repositorios no se almacenan como cadenas en texto plano dentro del código fuente compilado. Se encuentran cifradas mediante un esquema XOR con claves numéricas y se resuelven dinámicamente en tiempo de ejecución.
- **Almacenamiento Local de Datos**:
  Las listas, artículos, precios y notas se almacenan exclusivamente en la base de datos local SQLite del dispositivo. No se transmiten datos privados a servidores externos.
- **Sin Dependencias de Rastreo**:
  No se utilizan servicios de analítica invasiva, identificadores de publicidad ni rastreadores de terceros.

---

## Instalación y Requisitos

- **Plataformas Soportadas**: Android (SDK 21 o superior), Linux Desktop (modo desarrollo/pruebas).
- **Entorno de Compilación**:
  - Flutter SDK 3.27+ o compatible.
  - Dart SDK 3.6+ o compatible.
  - Android SDK y NDK configurados.

---

## Guía para Actualización Manual de APK

Para instalar una nueva versión descargada directamente desde el repositorio:

1. **Descarga**:
   Pulse sobre el botón 'Descargar' en el banner de actualización de la aplicación o acceda a la sección de Releases en GitHub y descargue el archivo `ListScanPro.apk`.
2. **Confirmación del Navegador**:
   Si el navegador muestra un mensaje de advertencia sobre la descarga de archivos APK, confirme la acción seleccionando 'Descargar de todos modos'.
3. **Permisos de Instalación**:
   Al abrir el archivo descargado, si el sistema Android lo solicita, ingrese a Ajustes y habilite la opción 'Permitir desde esta fuente' para el navegador utilizado.
4. **Instalación**:
   Seleccione 'Instalar' o 'Actualizar'. El instalador actualizará la aplicación preservando íntegramente todas sus listas y configuraciones almacenadas localmente.

---

## Comandos de Desarrollo y Pruebas

### Ejecutar Análisis Estático
```bash
flutter analyze
```

### Ejecutar Suite Completa de Pruebas Unitarias y de Widgets
```bash
flutter test
```

### Compilar APK de Producción
```bash
flutter build apk --release
```

### Ejecutar en Dispositivo Conectado
```bash
flutter run
```
