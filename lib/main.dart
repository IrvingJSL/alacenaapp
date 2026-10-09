import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app_state.dart';
import 'screens/day_detail_screen.dart';
import 'screens/home_screen.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  await initializeDateFormatting('es_MX');
  await NotificationService.instance.init();
  NotificationService.instance.onAbrirDia = (dia) {
    navigatorKey.currentState?.push(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => DayDetailScreen(dia: dia),
    ));
  };
  runApp(const AlacenaApp());
}

class AlacenaApp extends StatefulWidget {
  const AlacenaApp({super.key});

  @override
  State<AlacenaApp> createState() => _AlacenaAppState();
}

class _AlacenaAppState extends State<AlacenaApp> {
  @override
  void initState() {
    super.initState();
    AppState.instance.cargar().then((_) async {
      final payload = await NotificationService.instance.payloadDeLanzamiento();
      if (payload != null) {
        WidgetsBinding.instance.addPostFrameCallback(
            (_) => NotificationService.instance.abrirPayload(payload));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mi Alacena',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: buildTheme(),
      locale: const Locale('es', 'MX'),
      supportedLocales: const [Locale('es', 'MX'), Locale('es')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const HomeScreen(),
    );
  }
}
