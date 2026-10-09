import 'package:flutter/material.dart';
import '../app_state.dart';
import '../theme/app_theme.dart';
import 'alertas_page.dart';
import 'calendario_page.dart';
import 'inventario_page.dart';
import 'mas_page.dart';
import 'product_form_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _i = 0;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.instance,
      builder: (context, _) {
        if (AppState.instance.cargando) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        final pages = <Widget>[
          const AlertasPage(),
          const CalendarioPage(),
          const InventarioPage(),
          const MasPage(),
        ];
        return Scaffold(
          body: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: KeyedSubtree(key: ValueKey(_i), child: pages[_i]),
          ),
          floatingActionButton: (_i == 0 || _i == 2)
              ? GradientFab(
                  label: 'Nuevo artículo',
                  icon: Icons.add,
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const ProductFormScreen())),
                )
              : null,
          bottomNavigationBar: NavigationBar(
            selectedIndex: _i,
            onDestinationSelected: (i) => setState(() => _i = i),
            destinations: const [
              NavigationDestination(
                  icon: Icon(Icons.notifications_active_outlined),
                  selectedIcon: Icon(Icons.notifications_active),
                  label: 'Alertas'),
              NavigationDestination(
                  icon: Icon(Icons.calendar_month_outlined),
                  selectedIcon: Icon(Icons.calendar_month),
                  label: 'Calendario'),
              NavigationDestination(
                  icon: Icon(Icons.inventory_2_outlined),
                  selectedIcon: Icon(Icons.inventory_2),
                  label: 'Inventario'),
              NavigationDestination(icon: Icon(Icons.more_horiz), label: 'Más'),
            ],
          ),
        );
      },
    );
  }
}
