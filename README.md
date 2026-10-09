# Mi Alacena – Práctica 2 (Flutter + SQLite local)

Diseño oscuro (azul marino, degradados magenta/violeta, acentos cyan) en `lib/theme/app_theme.dart`.

Inventario doméstico con control de lotes (FEFO), alertas de caducidad/agotado,
calendario, carrito de compras, trazabilidad por tienda y alarmas locales.

## Cómo correrlo

1. Instala Flutter (3.27 o superior) y verifica con `flutter doctor`.
2. Descomprime el zip, entra a la carpeta y genera las carpetas de plataforma:
   ```
   cd alacena_app
   flutter create --org com.example --project-name alacena_app .
   flutter pub get
   ```
3. **Configura Android** (necesario para las notificaciones locales):

   a) `android/app/src/main/AndroidManifest.xml`
   - Dentro de `<manifest>` (antes de `<application>`):
     ```xml
     <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
     <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
     <uses-permission android:name="android.permission.VIBRATE"/>
     ```
   - Dentro de `<application>` (después de `</activity>`):
     ```xml
     <receiver android:exported="false"
         android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver"/>
     <receiver android:exported="false"
         android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
       <intent-filter>
         <action android:name="android.intent.action.BOOT_COMPLETED"/>
         <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
         <action android:name="android.intent.action.QUICKBOOT_POWERON"/>
         <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
       </intent-filter>
     </receiver>
     ```

   b) `android/app/build.gradle.kts` (o `build.gradle` si usa Groovy):
   - En `android { compileOptions { ... } }` agrega `isCoreLibraryDesugaringEnabled = true`
     (Groovy: `coreLibraryDesugaringEnabled true`).
   - Al final del archivo agrega:
     ```kotlin
     dependencies {
         coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
     }
     ```
     (Groovy: `coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.1.4'`)

   c) (Solo iOS) en `ios/Runner/Info.plist` agrega `NSCameraUsageDescription`
   y `NSPhotoLibraryUsageDescription`.

4. Conecta un celular (depuración USB) o abre un emulador y ejecuta:
   ```
   flutter run
   ```
   Si tienes errores raros después de configurar: `flutter clean && flutter pub get`.

## Qué cumple de la práctica

| Requisito | Dónde |
|---|---|
| Listado principal con próximos a caducar / por agotarse con imagen | `alertas_page.dart` (SliverList) |
| Calendario con `table_calendar` y un punto por alerta del día | `calendario_page.dart` |
| Modal pantalla completa al tocar un día | `day_detail_screen.dart` (`fullscreenDialog`) |
| Identificar estatus (caducado, agotado, por caducar, por agotarse) | `StatusChip` (color + ícono) |
| Alta de artículo con categoría + botón "agregar al carrito" | `product_form_screen.dart`, `producto_tile.dart` |
| Ícono de carrito arriba a la derecha con contador (`badges`) | `CartAction` en `widgets/common.dart` |
| FEFO al consumir | `DatabaseHelper.consumir` |
| Stock = suma de lotes con cantidad > 0; agotado si 0 | `Producto.stockTotal` / `estado` |
| Histórico de tiendas por producto | detalle del artículo → "Tiendas donde se compró" |
| `ultima_tienda_id` se actualiza al comprar | trigger `trg_ultima_tienda` en SQLite |
| Integridad de dominio (CHECK/UNIQUE/NOT NULL) y referencial (FK, RESTRICT/CASCADE/SET NULL) | `database_helper.dart` |
| CRUDs | Categorías, Tiendas, Artículos, Lotes (editar/eliminar) |
| Campo para alarmas locales | `Producto.alarma_activa` + `dias_alerta`; la notificación abre la pantalla de lo que caduca ese día |
| Slivers | `SliverList`, `SliverGrid`, `SliverAppBar.large` |
| Widgets nuevos | `NavigationBar`, `SegmentedButton`, `ChoiceChip`, `Dismissible`, `Hero`, `ExpansionTile`, `AnimatedSwitcher` |
| **Funcionalidad extra nueva: Tendencias** | `tendencias_screen.dart`: ventana con gráfica de línea (CustomPainter) de gasto o unidades compradas por 6 meses u 8 semanas, con total, promedio, pico y % vs periodo anterior |
| Funcionalidad extra | Auto-agregar al carrito cuando un artículo se agota, "Ya lo compré" desde el carrito (crea lote + historial), búsqueda y filtro por categoría, gasto por tienda, modo oscuro |

## Para la presentación
- *Más → Probar alarma* lanza una notificación y al tocarla abre los productos que caducan hoy.
- Para demostrar FEFO: registra 2 compras del mismo artículo con distinta caducidad y usa **Consumir**.
