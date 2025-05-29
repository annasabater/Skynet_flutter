// lib/screens/store/all_tab.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../models/drone_query.dart';
import '../../provider/drone_provider.dart';
import '../../widgets/drone_card.dart';
import '../../widgets/store_sidebar.dart';

class AllTab extends StatefulWidget {
  const AllTab({super.key});
  @override
  State<AllTab> createState() => _AllTabState();
}

class _AllTabState extends State<AllTab> {
  final ScrollController _scrollCtrl = ScrollController();
  final TextEditingController _searchCtrl = TextEditingController();
  final String _selectedCat = 'all';
  int _dronesPerPage = 10;
  int _currentPage = 1;
  int _totalPages = 1;
  Map<String, dynamic> _lastFilters = {};
  final bool _showSidebar = false;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  void _onScroll() {
    final prov = context.read<DroneProvider>();
    if (!prov.isLoading &&
        _scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200) {
      prov.loadMore(
        filter: DroneQuery(category: _selectedCat != 'all' ? _selectedCat : null),
      );
    }
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch(String q) {
    final prov = context.read<DroneProvider>();
    if (q.trim().isEmpty) {
      prov.loadDronesFiltered(DroneQuery(category: _selectedCat != 'all' ? _selectedCat : null));
    } else {
      prov.loadDronesFiltered(DroneQuery(
        q: q.trim(),
        category: _selectedCat != 'all' ? _selectedCat : null,
      ));
    }
  }

  void _applyFilters(Map<String, dynamic> filters) {
    setState(() {
      _lastFilters = filters;
      _currentPage = 1;
    });
    final prov = context.read<DroneProvider>();
    prov.loadDronesFiltered(DroneQuery(
      q: filters['name'],
      category: filters['category'],
      condition: filters['condition'],
      minPrice: filters['minPrice'],
      maxPrice: filters['maxPrice'],
      // location: ...
      page: 1,
      limit: _dronesPerPage,
    ));
  }

  void _changePage(int page) {
    setState(() => _currentPage = page);
    final prov = context.read<DroneProvider>();
    prov.loadDronesFiltered(DroneQuery(
      q: _lastFilters['name'],
      category: _lastFilters['category'],
      condition: _lastFilters['condition'],
      minPrice: _lastFilters['minPrice'],
      maxPrice: _lastFilters['maxPrice'],
      // location: ...
      page: page,
      limit: _dronesPerPage,
    ));
  }

  void _changeDronesPerPage(int? value) {
    if (value == null) return;
    setState(() {
      _dronesPerPage = value;
      _currentPage = 1;
    });
    _applyFilters(_lastFilters);
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;
    return Scaffold(
      drawer: isDesktop ? null : Drawer(child: StoreSidebar(onApply: _applyFilters)),
      body: Row(
        children: [
          if (isDesktop)
            SizedBox(
              width: 320,
              child: StoreSidebar(onApply: _applyFilters),
            ),
          Expanded(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Text('Drones por página:'),
                      const SizedBox(width: 8),
                      DropdownButton<int>(
                        value: _dronesPerPage,
                        items: [5, 10, 20].map((int value) {
                          return DropdownMenuItem<int>(
                            value: value,
                            child: Text(value.toString()),
                          );
                        }).toList(),
                        onChanged: _changeDronesPerPage,
                      ),
                      const SizedBox(width: 16),
                      if (_currentPage > 1)
                        IconButton(
                          icon: const Icon(Icons.chevron_left),
                          onPressed: () => _changePage(_currentPage - 1),
                        ),
                      Text('Página $_currentPage'),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: () => _changePage(_currentPage + 1),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Consumer<DroneProvider>(
                    builder: (_, prov, __) {
                      if (prov.isLoading && prov.drones.isEmpty) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (prov.error != null) {
                        return Center(child: Text(prov.error!));
                      }
                      if (prov.drones.isEmpty) {
                        return const Center(child: Text('No hay anuncios'));
                      }
                      // Si el backend no devuelve el total de páginas, lo calculamos por la cantidad de resultados
                      final totalItems = prov.drones.length;
                      _totalPages = (totalItems / _dronesPerPage).ceil().clamp(1, 999);
                      return RefreshIndicator(
                        onRefresh: () async => prov.loadDrones(),
                        child: GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: MediaQuery.of(context).size.width < 600 ? 2 : 4,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childAspectRatio: 0.75,
                          ),
                          itemCount: prov.drones.length,
                          itemBuilder: (context, i) => DroneCard(
                            drone: prov.drones[i],
                            onTap: () => context.pushNamed(
                              'droneDetail',
                              pathParameters: {'id': prov.drones[i].id},
                              extra: prov.drones[i],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      appBar: isDesktop
          ? null
          : AppBar(
              title: const Text('Tienda de Drones'),
              leading: Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
            ),
    );
  }
}
