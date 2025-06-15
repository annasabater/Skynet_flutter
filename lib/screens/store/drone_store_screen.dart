// lib/screens/store/drone_store_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../provider/drone_provider.dart';
import '../../provider/users_provider.dart';
import '../../provider/cart_provider.dart';
import 'all_tab.dart';
import 'favorites_tab.dart';
import 'my_drones_tab.dart';
import '../../widgets/balance_form.dart';
import '../../widgets/cart_modal.dart';
import '../history/history_screen.dart';
import '../../widgets/language_selector.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../provider/theme_provider.dart';

class DroneStoreScreen extends StatefulWidget {
  const DroneStoreScreen({Key? key}) : super(key: key);

  @override
  State<DroneStoreScreen> createState() => _DroneStoreScreenState();
}

class _DroneStoreScreenState extends State<DroneStoreScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final DroneProvider _droneProv;
  late final UserProvider _userProv;

  @override
  void initState() {
    super.initState();

    _droneProv = context.read<DroneProvider>();
    _userProv = context.read<UserProvider>();
    _tabController = TabController(length: 3, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = _userProv.currentUser?.id;
      _droneProv.setUserIdForReload(uid);
      _droneProv.loadDrones();
      _loadExtras();
    });
  }

  Future<void> _loadExtras() async {
    final uid = _userProv.currentUser?.id;
    if (uid != null && uid.isNotEmpty) {
      await Future.wait([
        _droneProv.loadFavorites(uid),
        _droneProv.loadMyDrones(uid),
      ]);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).maybePop(),
              )
            : null,
        title: Text(AppLocalizations.of(context)!.store),
        actions: [
          const LanguageSelector(),
          Consumer<ThemeProvider>(
            builder: (_, t, __) => IconButton(
              icon: Icon(t.isDarkMode ? Icons.dark_mode : Icons.light_mode),
              tooltip: t.isDarkMode ? AppLocalizations.of(context)!.lightMode : AppLocalizations.of(context)!.darkMode,
              onPressed: () => t.toggleTheme(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Historial de compras/ventas',
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const HistoryScreen()));
            },
          ),
          // Cambio de moneda
          Consumer<DroneProvider>(
            builder: (context, droneProv, _) {
              return PopupMenuButton<String>(
                icon: Row(
                  children: [
                    const Icon(Icons.currency_exchange),
                    const SizedBox(width: 4),
                    Text(
                      droneProv.currency,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                tooltip: 'Cambiar divisa',
                onSelected: (value) {
                  droneProv.currency = value;
                },
                itemBuilder:
                    (context) =>
                        [
                              'EUR',
                              'USD',
                              'GBP',
                              'JPY',
                              'CHF',
                              'CAD',
                              'AUD',
                              'CNY',
                              'HKD',
                              'NZD',
                            ]
                            .map(
                              (currency) => PopupMenuItem(
                                value: currency,
                                child: Text(currency),
                              ),
                            )
                            .toList(),
              );
            },
          ),
          // Icono de carrito
          Consumer<CartProvider>(
            builder: (context, cart, _) {
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart),
                    tooltip: 'Carrito',
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => const CartModal(),
                      );
                    },
                  ),
                  if (cart.items.isNotEmpty)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          '${cart.items.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          // Icono de moneda para ingresar saldo
          Builder(
            builder:
                (context) => IconButton(
                  icon: const Icon(Icons.account_balance_wallet),
                  tooltip: 'Ingresar saldo',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const BalanceForm()),
                    );
                  },
                ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: scheme.onPrimary,
          unselectedLabelColor: scheme.onPrimary.withOpacity(0.7),
          indicatorColor: scheme.secondary,
          indicatorWeight: 4,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
          tabs: [
            Tab(text: AppLocalizations.of(context)!.allTab),
            Tab(text: AppLocalizations.of(context)!.favoritesTab),
            Tab(text: AppLocalizations.of(context)!.myDronesTab),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [AllTab(), FavoritesTab(), MyDronesTab()],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/store/add'),
        tooltip: 'Nou anunci',
        child: const Icon(Icons.add),
      ),
    );
  }
}
