// lib/screens/spectate_sessions_page.dart

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../services/socket_service.dart';
import '../data/game_texts.dart';

class SpectateSessionsPage extends StatefulWidget {
  final String sessionId;
  const SpectateSessionsPage({super.key, required this.sessionId});

  @override
  State<SpectateSessionsPage> createState() => _SpectateSessionsPageState();
}

class _SpectateSessionsPageState extends State<SpectateSessionsPage> {
  IO.Socket? _socket;
  final MapController _mapController = MapController();

  bool _mapLocked = true;
  double _currentZoom = 20;
  bool _gameFinished = false;
  bool _gameStarted = false;

  final Map<String, Marker> _droneMarkers = {};
  final Map<String, Marker> _bulletMarkers = {};
  final Map<String, Polygon> _fencePolygons = {};
  final Map<String, Polygon> _obstaclePolys = {};
  final Map<String, int> _scores = {};

  // estado & parpadeo de cada dron 
  final Map<String, String> _droneStates = {}; // 'active' | 'landed'
  bool _blinkVisible = true;
  Timer? _blinkTimer;

  static const Map<String, Color> _playerColor = {
    'dron_rojo1@upc.edu': Colors.red,
    'dron_azul1@upc.edu': Colors.blue,
    'dron_verde1@upc.edu': Colors.green,
    'dron_amarillo1@upc.edu': Colors.amber,
  };
  bool _isCompetitor(String email) => _playerColor.containsKey(email);

  @override
  void initState() {
    super.initState();
    _connectAsSpectator();
  }

void _connectAsSpectator() {
  _socket = IO.io(
    '${SocketService.baseUrl}/jocs',
    {
      'transports': ['websocket'],
      'query': {
        'sessionId': widget.sessionId,
        'spectator': 'true',
      },
      'autoConnect': false,
    },
  )..connect();

  _socket!
    ..on('connect', (_) {
      _socket!.emit('join', {'sessionId': widget.sessionId});
    })

    ..on('state_update', _handleStateUpdate)

    ..on('game_ended', (_) {
      if (!mounted || _gameFinished) return;
      _resetScenario();
      setState(() {
        _gameFinished = true;
        _gameStarted  = false;
      });
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) context.go('/');
      });
    })

    ..on('game_started', (_) {
      if (!mounted) return;
      _resetScenario();
      setState(() {
        _gameFinished = false;
        _gameStarted  = true;
      });
    })

    ..on('disconnect', (_) => debugPrint('Spectator disconnected'));
}

  void _handleStateUpdate(dynamic data) {
    if (!_gameStarted) {
      setState(() => _gameStarted = true);
    }
    
    if (_gameFinished) return;

    final action = data['action'] ?? '';
    final drone = data['drone'] ?? '';
    final payload = data['payload'] as Map<String, dynamic>? ?? {};

    switch (action) {
      case 'telemetry':
        _updateDrone(drone, payload);
        break;

      case 'state': 
        _droneStates[drone] = payload['state'] as String? ?? 'flying';
        _rebuildMarker(drone);
        _syncBlinkTimer();
        setState(() {});
        break;

      case 'score_update':
        _scores[drone] = (payload['score'] as num).toInt();
        setState(() {});
        break;

      case 'bullet_create':
      case 'bullet_move':
        _updateBullet(payload, create: action == 'bullet_create');
        break;

      case 'bullet_destroy':
        _bulletMarkers.remove(payload['bulletId']);
        setState(() {});
        break;

      case 'fence_add':
        _addFence(payload['geometry'], drone);
        setState(() {});
        break;

      case 'fence_remove':
        _fencePolygons.clear();
        setState(() {});
        break;

      case 'obstacle_add':
        _addObstacle(payload['geometry'] as List);
        setState(() {});
        break;

      case 'obstacle_remove':
        _removeObstacle(payload['geometry'] as List);
        setState(() {});
        break;
    }
  }

  void _syncBlinkTimer() {
    final anyLanded = _droneStates.values.any((s) => s == 'landed');

    if (anyLanded && (_blinkTimer == null || !_blinkTimer!.isActive)) {
      _blinkTimer =
          Timer.periodic(const Duration(milliseconds: 500), (_) {
        _blinkVisible = !_blinkVisible;
        for (final email in _droneStates.keys) {
          if (_droneStates[email] == 'landed') _rebuildMarker(email);
        }
        setState(() {});
      });
    } else if (!anyLanded) {
      _blinkTimer?.cancel();
      _blinkTimer = null;
      _blinkVisible = true;
    }
  }

  void _resetScenario() {
    _droneMarkers.clear();
    _bulletMarkers.clear();
    _fencePolygons.clear();
    _obstaclePolys.clear();
    _scores.clear();
    _droneStates.clear();
    _blinkTimer?.cancel();
    _blinkTimer = null;
    _blinkVisible = true;
    _currentZoom = 20;
    _mapLocked = true;
  }

  void _updateDrone(String email, Map<String, dynamic> p) {
    if (!_isCompetitor(email)) return;
    final lat = p['lat'] as double;
    final lon = p['lon'] as double;
    final hdg = (p['heading'] as num?) ?? 0;

    _rebuildMarker(email,
        lat: lat, lon: lon, heading: hdg.toDouble()); 
  }

  void _rebuildMarker(String email,
      {double? lat, double? lon, double? heading}) {
    // usamos última posición conocida si no vienen coords
    final old = _droneMarkers[email];
    final point = LatLng(
        lat ?? old?.point.latitude ?? 0, lon ?? old?.point.longitude ?? 0);
    final hdg = heading ?? 0;
    final color = _playerColor[email]!;
    final state = _droneStates[email] ?? 'active';
    final opacity = state == 'landed'
        ? (_blinkVisible ? 1.0 : 0.0)
        : 1.0; // parpadeo

    _droneMarkers[email] = Marker(
      point: point,
      width: 34,
      height: 34,
      child: Opacity(
        opacity: opacity,
        child: Transform.rotate(
          angle: hdg * pi / 180,
          child: Icon(Icons.airplanemode_active, color: color, size: 34),
        ),
      ),
    );
  }

  void _updateBullet(Map<String, dynamic> p, {required bool create}) {
    final id = p['bulletId'] as String;
    final lat = p['lat'] as double;
    final lon = p['lon'] as double;

    _bulletMarkers[id] = Marker(
      point: LatLng(lat, lon),
      width: 12,
      height: 12,
      child:
          const Icon(Icons.fiber_manual_record, color: Colors.black, size: 12),
    );
    if (!create) setState(() {});
  }

  void _addFence(dynamic geometry, String droneEmail) {
    if (geometry is! List || !_isCompetitor(droneEmail)) return;
    final points = geometry
        .map<LatLng>((pt) =>
            LatLng(pt['lat'] as double, pt['lon'] as double))
        .toList();
    final color = _playerColor[droneEmail]!;

    _fencePolygons[droneEmail] = Polygon(
      points: points,
      color: color.withOpacity(0.25),
      borderColor: color,
      borderStrokeWidth: 3,
    );
  }

  String _obstacleKey(List geom) =>
      geom.map((e) => '${e["lat"]},${e["lon"]}').join('|');

  void _addObstacle(List<dynamic> geometry) {
    _obstaclePolys[_obstacleKey(geometry)] = Polygon(
      points: geometry
          .map<LatLng>(
              (pt) => LatLng(pt['lat'] as double, pt['lon'] as double))
          .toList(),
      color: Colors.black.withOpacity(0.8),
      borderColor: Colors.black,
      borderStrokeWidth: 1,
    );
  }

  void _removeObstacle(List<dynamic> geometry) {
    _obstaclePolys.remove(_obstacleKey(geometry));
  }

  void _showTextDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: Text(content)),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar')),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        center: LatLng(41.2764478, 1.9886568),
        zoom: _currentZoom,
        interactiveFlags:
            _mapLocked ? InteractiveFlag.none : InteractiveFlag.all,
      ),
      children: [
        TileLayer(
          urlTemplate:
              'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
          subdomains: const ['server'],
          userAgentPackageName: 'com.example.seminari_flutter',
        ),
        if (_fencePolygons.isNotEmpty)
          PolygonLayer(polygons: _fencePolygons.values.toList()),
        if (_obstaclePolys.isNotEmpty)
          PolygonLayer(polygons: _obstaclePolys.values.toList()),
        MarkerLayer(markers: [
          ..._droneMarkers.values,
          ..._bulletMarkers.values,
        ]),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final scoreLabel = _scores.isEmpty
        ? const SizedBox.shrink()
        : Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.85),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: _scores.entries.map((e) {
                  final clr = _playerColor[e.key]!;
                  final name = {
                    'dron_rojo1@upc.edu': 'Jugador 1 (Rojo)',
                    'dron_azul1@upc.edu': 'Jugador 2 (Azul)',
                    'dron_verde1@upc.edu': 'Jugador 3 (Verde)',
                    'dron_amarillo1@upc.edu': 'Jugador 4 (Amarillo)',
                  }[e.key] ??
                      e.key.split('@').first;
                  return Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6),
                    child: Text(
                      '$name: ${e.value}',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: clr),
                    ),
                  );
                }).toList(),
              ),
            ),
          );

      return Scaffold(
      backgroundColor: const Color(0xFFEFF2F5),
      body: Stack(
        children: [
          Positioned.fill(child: _buildMap()),
          if (!_gameStarted)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.5),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      '⚠️ Aún no se ha iniciado ninguna partida',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Esperando a que el profesor inicie la partida…',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _styledButton('Descripción', () => _showTextDialog('Descripción del juego', kGameDescription)),
                        const SizedBox(width: 16),
                        _styledButton('Manual', () => _showTextDialog('Manual del juego', kGameManual)),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          if (_gameStarted)
            Positioned(
              bottom: 24,
              right: 16,
              child: Row(
                children: [
                  _styledButton('📖 Descripción', () => _showTextDialog('Descripción del juego', kGameDescription)),
                  const SizedBox(width: 12),
                  _styledButton('🛠 Manual', () => _showTextDialog('Manual del juego', kGameManual)),
                ],
              ),
            ),

          _zoomBtn(70, Icons.add,    () {  }),
          _zoomBtn(130, Icons.remove,() {  }),
          _zoomBtn(190, _mapLocked ? Icons.lock : Icons.lock_open,
                  () => setState(() => _mapLocked = !_mapLocked)),
          scoreLabel,
          if (_gameFinished) _buildGameOverOverlay(context),
        ],
      ),
    );
  }


  Widget _styledButton(String label, VoidCallback onTap) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white.withOpacity(0.85),
        foregroundColor: Colors.black87,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 4,
      ),
      onPressed: onTap,
      child:
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildGameOverOverlay(BuildContext context) => Positioned.fill(
        child: Container(
          color: Colors.black.withOpacity(0.7),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'PARTIDA FINALIZADA',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.home),
                label: const Text('Ir al Home'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.85),
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32, vertical: 16),
                ),
                onPressed: () => GoRouter.of(context).go('/'),
              ),
            ],
          ),
        ),
      );

  Widget _zoomBtn(double top, IconData icon, VoidCallback cb) => Positioned(
    top: top,
    left: 16,
    child: GestureDetector(
      onTap: cb,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.85),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 6,
              offset: Offset(0, 3),
            )
          ],
        ),
        child: Icon(icon, size: 24, color: Colors.black87),
      ),
    ),
  );

  @override
  void dispose() {
    _socket
      ?..offAny()
      ..disconnect()
      ..destroy();
    _blinkTimer?.cancel();
    super.dispose();
  }
}