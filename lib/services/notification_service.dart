import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import '../models/models.dart';


class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _ok = false;

  void Function(DateTime dia)? onAbrirDia;

  static const NotificationDetails _detalles = NotificationDetails(
    android: AndroidNotificationDetails(
      'caducidad',
      'Alertas de caducidad',
      channelDescription: 'Avisos de productos por caducar',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
  );

  Future<void> init() async {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) return;
    try {
      tzdata.initializeTimeZones();
      const settings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      );
      await _plugin.initialize(
        settings,
        onDidReceiveNotificationResponse: (r) => abrirPayload(r.payload),
      );
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      _ok = true;
    } catch (e) {
      debugPrint('Notificaciones no disponibles: $e');
    }
  }

  Future<String?> payloadDeLanzamiento() async {
    if (!_ok) return null;
    final d = await _plugin.getNotificationAppLaunchDetails();
    if (d != null && d.didNotificationLaunchApp) {
      return d.notificationResponse?.payload;
    }
    return null;
  }

  void abrirPayload(String? payload) {
    if (payload == null || !payload.startsWith('dia:')) return;
    final dia = DateTime.tryParse(payload.substring(4));
    if (dia != null) onAbrirDia?.call(dia);
  }

  Future<void> reprogramar(List<Producto> productos) async {
    if (!_ok) return;
    try {
      await _plugin.cancelAll();
      for (final p in productos) {
        if (!p.alarmaActiva) continue;
        for (final l in p.lotesActivos) {
          if (l.id == null) continue;
          final c = l.fechaCaducidad;
          final payload = 'dia:${isoFecha(c)}';
          await _programar(
            id: l.id! * 2,
            fecha: DateTime(c.year, c.month, c.day, 9),
            titulo: 'Caduca hoy: ${p.nombre}',
            cuerpo: '${l.cantidad} ${p.unidad} caducan hoy. Toca para ver.',
            payload: payload,
          );
          if (p.diasAlerta > 0) {
            await _programar(
              id: l.id! * 2 + 1,
              fecha: DateTime(c.year, c.month, c.day - p.diasAlerta, 9),
              titulo: 'Por caducar: ${p.nombre}',
              cuerpo: 'Caduca en ${p.diasAlerta} día(s).',
              payload: payload,
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error al programar alarmas: $e');
    }
  }

  Future<void> _programar({
    required int id,
    required DateTime fecha,
    required String titulo,
    required String cuerpo,
    required String payload,
  }) async {
    if (!fecha.isAfter(DateTime.now())) return;
    await _plugin.zonedSchedule(
      id,
      titulo,
      cuerpo,
      tz.TZDateTime.from(fecha, tz.UTC),
      _detalles,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: payload,
    );
  }

  Future<bool> probar() async {
    if (!_ok) return false;
    await _plugin.show(
      0,
      'Alarma de prueba',
      'Toca para ver los productos que caducan hoy.',
      _detalles,
      payload: 'dia:${isoFecha(DateTime.now())}',
    );
    return true;
  }
}
